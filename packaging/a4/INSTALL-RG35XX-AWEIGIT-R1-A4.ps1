param(
    [Parameter(Mandatory=$false)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'
$ExpectedJamvm = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

if ([string]::IsNullOrWhiteSpace($SdRoot)) {
    $SdRoot = Read-Host 'Nhap ky tu o SD RG35XX (vi du G)'
}
if ([string]::IsNullOrWhiteSpace($SdRoot)) { throw 'SD root is empty.' }

$SdRoot = $SdRoot.Trim()
if ($SdRoot -match '^[A-Za-z]$') {
    $SdRoot = ($SdRoot.ToUpperInvariant() + ':\')
}
elseif ($SdRoot -match '^[A-Za-z]:[\\/]?$') {
    $SdRoot = ($SdRoot.Substring(0,1).ToUpperInvariant() + ':\')
}
else {
    $SdRoot = [System.IO.Path]::GetFullPath($SdRoot)
}
if (-not (Test-Path -LiteralPath $SdRoot -PathType Container)) { throw "SD root not found: $SdRoot" }

$Jamvm = Join-Path $SdRoot 'CFW\java\bin\jamvm'
$Glibj = Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
if (-not (Test-Path -LiteralPath $Jamvm -PathType Leaf)) { throw "Protected JamVM missing: $Jamvm" }
if (-not (Test-Path -LiteralPath $Glibj -PathType Leaf)) { throw "Protected glibj.zip missing: $Glibj" }

$JamvmHash = Get-Sha256 $Jamvm
$GlibjHash = Get-Sha256 $Glibj
if ($JamvmHash -ne $ExpectedJamvm) { throw "JamVM hash mismatch. Expected $ExpectedJamvm, got $JamvmHash. Nothing installed." }
if ($GlibjHash -ne $ExpectedGlibj) { throw "glibj.zip hash mismatch. Expected $ExpectedGlibj, got $GlibjHash. Nothing installed." }

$SourceRoot = Join-Path $PSScriptRoot 'SD'
$SourceLauncher = Join-Path $SourceRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE.sh'
$SourcePayload = Join-Path $SourceRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE'
if (-not (Test-Path -LiteralPath $SourceLauncher -PathType Leaf)) { throw "Package launcher missing: $SourceLauncher" }
if (-not (Test-Path -LiteralPath $SourcePayload -PathType Container)) { throw "Package payload missing: $SourcePayload" }

$DestApps = Join-Path $SdRoot 'Roms\APPS'
$DestLauncher = Join-Path $DestApps 'RG35XX-AWEIGIT-R1-A4-SMOKE.sh'
$DestPayload = Join-Path $DestApps 'RG35XX-AWEIGIT-R1-A4-SMOKE'
New-Item -ItemType Directory -Force -Path $DestApps | Out-Null

$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = Join-Path $SdRoot ("RG35XX-AWEIGIT-R1-A4-BACKUP-$Stamp")
$NeedBackup = (Test-Path -LiteralPath $DestLauncher) -or (Test-Path -LiteralPath $DestPayload)
if ($NeedBackup) {
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    if (Test-Path -LiteralPath $DestLauncher -PathType Leaf) {
        Copy-Item -LiteralPath $DestLauncher -Destination (Join-Path $BackupRoot 'RG35XX-AWEIGIT-R1-A4-SMOKE.sh')
    }
    if (Test-Path -LiteralPath $DestPayload -PathType Container) {
        Copy-Item -LiteralPath $DestPayload -Destination (Join-Path $BackupRoot 'RG35XX-AWEIGIT-R1-A4-SMOKE') -Recurse
    }
}

# Exact owned path only. Never wildcard-clean unrelated Roms/APPS content.
if (Test-Path -LiteralPath $DestPayload -PathType Container) {
    Remove-Item -LiteralPath $DestPayload -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DestPayload | Out-Null
Copy-Item -LiteralPath $SourceLauncher -Destination $DestLauncher -Force
Get-ChildItem -LiteralPath $SourcePayload -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $DestPayload $_.Name) -Force
}

$VerifyNames = @(
    'freej2me-rg35xx.jar',
    'librg35xx_input.so',
    'librg35xx_video.so',
    'rg35xx-a4-smoke.jar',
    'BUILD-IDENTITY.txt',
    'CANONICAL-DIFF-MANIFEST.txt',
    'JAVA6-COMPAT-AUDIT.tsv',
    'PAYLOAD-SHA256SUMS.txt'
)
foreach ($Name in $VerifyNames) {
    $Src = Join-Path $SourcePayload $Name
    $Dst = Join-Path $DestPayload $Name
    if (-not (Test-Path -LiteralPath $Src -PathType Leaf)) { throw "Source file missing: $Src" }
    if (-not (Test-Path -LiteralPath $Dst -PathType Leaf)) { throw "Installed file missing: $Dst" }
    $SH = Get-Sha256 $Src
    $DH = Get-Sha256 $Dst
    if ($SH -ne $DH) { throw "Install verification hash mismatch for $Name" }
}
if ((Get-Sha256 $SourceLauncher) -ne (Get-Sha256 $DestLauncher)) { throw 'Launcher install verification hash mismatch.' }

$Result = Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A4-INSTALL-RESULT.txt'
@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'STAGE=A4-SMOKE',
    "INSTALL_TIME=$((Get-Date).ToString('o'))",
    "SD_ROOT=$SdRoot",
    "JAMVM_SHA256=$JamvmHash",
    "GLIBJ_SHA256=$GlibjHash",
    "LAUNCHER=$DestLauncher",
    "PAYLOAD=$DestPayload",
    "BACKUP_CREATED=$NeedBackup",
    "BACKUP_PATH=$BackupRoot",
    'INSTALL_RESULT=PASS',
    'DEVICE_PASS=NO',
    'STABLE=NO'
) | Set-Content -LiteralPath $Result -Encoding ASCII

Write-Host 'A4 install PASS.'
Write-Host "Launcher: $DestLauncher"
Write-Host "Result:   $Result"
if ($NeedBackup) { Write-Host "Backup:   $BackupRoot" }
