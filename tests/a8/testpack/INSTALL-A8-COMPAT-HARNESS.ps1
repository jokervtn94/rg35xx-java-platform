[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdRoot
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceWrapper = Join-Path $scriptDir 'A8-COMPAT-RUN.sh'
if (-not (Test-Path -LiteralPath $sourceWrapper -PathType Leaf)) {
    $parentDir = Split-Path -Parent $scriptDir
    $sourceWrapper = Join-Path $parentDir 'A8-COMPAT-RUN.sh'
}
if (-not (Test-Path -LiteralPath $sourceWrapper -PathType Leaf)) {
    throw "Harness payload missing. Expected A8-COMPAT-RUN.sh beside this installer or in its parent directory."
}

$appsDir = Join-Path $root 'Roms\APPS'
$productionLauncher = Join-Path $appsDir 'RG35XX-AWEIGIT-R1.sh'
if (-not (Test-Path -LiteralPath $productionLauncher -PathType Leaf)) {
    throw "Accepted A8 production launcher not found: $productionLauncher"
}

New-Item -ItemType Directory -Path $appsDir -Force | Out-Null
$destinationWrapper = Join-Path $appsDir 'A8-COMPAT-RUN.sh'
Copy-Item -LiteralPath $sourceWrapper -Destination $destinationWrapper -Force

$sourceHash = (Get-FileHash -LiteralPath $sourceWrapper -Algorithm SHA256).Hash.ToLowerInvariant()
$destinationHash = (Get-FileHash -LiteralPath $destinationWrapper -Algorithm SHA256).Hash.ToLowerInvariant()
if ($sourceHash -ne $destinationHash) {
    throw "Harness copy verification failed"
}

$resultFile = Join-Path $root 'A8-COMPAT-HARNESS-INSTALL-RESULT.txt'
@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'BASELINE=A8',
    'ACTION=INSTALL_COMPAT_HARNESS_ONLY',
    "SD_ROOT=$root",
    "PRODUCTION_LAUNCHER=$productionLauncher",
    'PRODUCTION_RUNTIME_MODIFIED=NO',
    "HARNESS_DESTINATION=$destinationWrapper",
    "HARNESS_SHA256=$destinationHash",
    'INSTALL_RESULT=PASS',
    "TIMESTAMP=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath $resultFile -Encoding UTF8

Write-Host 'A8 compatibility harness installed successfully.'
Write-Host "SD root  : $root"
Write-Host "Harness  : $destinationWrapper"
Write-Host "SHA256   : $destinationHash"
Write-Host "Result   : $resultFile"
Write-Host 'A8 production runtime was not modified.'
