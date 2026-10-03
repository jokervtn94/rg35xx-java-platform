[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdRoot,

    [Parameter(Mandatory = $true)]
    [string]$GameJar,

    [Parameter(Mandatory = $true)]
    [string]$CandidateId
)

$ErrorActionPreference = 'Stop'

function Resolve-SdRoot {
    param([string]$Value)
    $v = $Value.Trim().Trim('"')
    if ($v -match '^[A-Za-z]$') { $v = "$v`:" }
    if ($v -match '^[A-Za-z]:$') { $v = "$v\" }
    return [System.IO.Path]::GetFullPath($v)
}

$root = Resolve-SdRoot $SdRoot
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "SD root not found: $root"
}

$appsDir = Join-Path $root 'Roms\APPS'
$harness = Join-Path $appsDir 'A8-COMPAT-RUN.sh'
if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) {
    throw "A8 compatibility harness not installed: $harness"
}

$gameInput = $GameJar.Trim().Trim('"')
if ([System.IO.Path]::IsPathRooted($gameInput)) {
    $gamePath = [System.IO.Path]::GetFullPath($gameInput)
} else {
    $gamePath = [System.IO.Path]::GetFullPath((Join-Path $root $gameInput))
}

if (-not (Test-Path -LiteralPath $gamePath -PathType Leaf)) {
    throw "Game JAR not found: $gamePath"
}

$rootPrefix = $root
if (-not $rootPrefix.EndsWith('\')) { $rootPrefix += '\' }
if (-not $gamePath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Game JAR must be located on the selected SD card: $gamePath"
}

$relative = $gamePath.Substring($rootPrefix.Length).TrimStart('\','/')
$deviceGamePath = '/mnt/mmc/' + $relative.Replace('\','/')
$jarHash = (Get-FileHash -LiteralPath $gamePath -Algorithm SHA256).Hash.ToLowerInvariant()

$safeId = ($CandidateId -replace '[^A-Za-z0-9._-]', '_')
if ([string]::IsNullOrWhiteSpace($safeId)) {
    throw 'CandidateId becomes empty after sanitization.'
}

$launcherName = "$safeId-TEST.sh"
$launcherPath = Join-Path $appsDir $launcherName
$launcherText = "#!/bin/sh`nexec sh /mnt/mmc/Roms/APPS/A8-COMPAT-RUN.sh `"$deviceGamePath`" `"$CandidateId`"`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($launcherPath, $launcherText, $utf8NoBom)

$candidateDir = Join-Path $root 'A8-COMPAT-CANDIDATES'
New-Item -ItemType Directory -Path $candidateDir -Force | Out-Null
$recordPath = Join-Path $candidateDir ("$safeId.txt")
@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'BASELINE=A8',
    "CANDIDATE_ID=$CandidateId",
    "JAR_FILENAME=$([System.IO.Path]::GetFileName($gamePath))",
    "JAR_SHA256=$jarHash",
    "WINDOWS_SD_PATH=$gamePath",
    "DEVICE_JAR_PATH=$deviceGamePath",
    "APPS_LAUNCHER=$launcherName",
    'REGISTRATION_RESULT=PASS',
    "TIMESTAMP=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath $recordPath -Encoding UTF8

Write-Host 'A8 compatibility game registered.'
Write-Host "Candidate : $CandidateId"
Write-Host "JAR       : $gamePath"
Write-Host "SHA256    : $jarHash"
Write-Host "Launcher  : $launcherPath"
Write-Host "Record    : $recordPath"
Write-Host 'Launch the new <CandidateId>-TEST entry from the RG35XX APPS menu.'
