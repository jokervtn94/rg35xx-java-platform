param(
    [Parameter(Mandatory=$false)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'
$ExpectedJamvm = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedPlatform = 'ca61589b71da1413f06ab7f898d490274506638d4d2db3be47a4137970a9263a'
$ExpectedExerciser = '126d586ccaeede8bc8adddf5fa65ee9b5b037ca8468c6dce5aa513bb6bd3fefc'
$ExpectedInput = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d'
$ExpectedVideo = 'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d'

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

if ([string]::IsNullOrWhiteSpace($SdRoot)) {
    $SdRoot = Read-Host 'Nhap ky tu o SD RG35XX (vi du G)'
}
if ([string]::IsNullOrWhiteSpace($SdRoot)) { throw 'SD root is empty.' }
$SdRoot = $SdRoot.Trim()
if ($SdRoot -match '^[A-Za-z]$') { $SdRoot = ($SdRoot.ToUpperInvariant() + ':\') }
elseif ($SdRoot -match '^[A-Za-z]:[\\/]?$') { $SdRoot = ($SdRoot.Substring(0,1).ToUpperInvariant() + ':\') }
else { $SdRoot = [System.IO.Path]::GetFullPath($SdRoot) }
if (-not (Test-Path -LiteralPath $SdRoot -PathType Container)) { throw "SD root not found: $SdRoot" }

$Jamvm = Join-Path $SdRoot 'CFW\java\bin\jamvm'
$Glibj = Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
if (-not (Test-Path -LiteralPath $Jamvm -PathType Leaf)) { throw "Protected JamVM missing: $Jamvm" }
if (-not (Test-Path -LiteralPath $Glibj -PathType Leaf)) { throw "Protected glibj.zip missing: $Glibj" }
$JamvmHash = Get-Sha256 $Jamvm
$GlibjHash = Get-Sha256 $Glibj
if ($JamvmHash -ne $ExpectedJamvm) { throw "JamVM hash mismatch. Nothing installed." }
if ($GlibjHash -ne $ExpectedGlibj) { throw "glibj.zip hash mismatch. Nothing installed." }

$SourceRoot = Join-Path $PSScriptRoot 'SD'
$SourceLauncher = Join-Path $SourceRoot 'Roms\APPS\RG35XX-P1A-GRAPHICS.sh'
$SourcePayload = Join-Path $SourceRoot 'Roms\APPS\RG35XX-P1A-GRAPHICS'
if (-not (Test-Path -LiteralPath $SourceLauncher -PathType Leaf)) { throw "Package launcher missing: $SourceLauncher" }
if (-not (Test-Path -LiteralPath $SourcePayload -PathType Container)) { throw "Package payload missing: $SourcePayload" }

$Critical = @{
    'freej2me-rg35xx.jar' = $ExpectedPlatform
    'RG35XX-Platform-Exerciser-P1A.jar' = $ExpectedExerciser
    'librg35xx_input.so' = $ExpectedInput
    'librg35xx_video.so' = $ExpectedVideo
}
foreach ($Name in $Critical.Keys) {
    $Path = Join-Path $SourcePayload $Name
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Package file missing: $Path" }
    $Hash = Get-Sha256 $Path
    if ($Hash -ne $Critical[$Name]) { throw "Package hash mismatch for $Name. Nothing installed." }
}

$DestApps = Join-Path $SdRoot 'Roms\APPS'
$DestLauncher = Join-Path $DestApps 'RG35XX-P1A-GRAPHICS.sh'
$DestPayload = Join-Path $DestApps 'RG35XX-P1A-GRAPHICS'
New-Item -ItemType Directory -Force -Path $DestApps | Out-Null

$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = Join-Path $SdRoot ("RG35XX-P1A-GRAPHICS-BACKUP-$Stamp")
$NeedBackup = (Test-Path -LiteralPath $DestLauncher) -or (Test-Path -LiteralPath $DestPayload)
if ($NeedBackup) {
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    if (Test-Path -LiteralPath $DestLauncher -PathType Leaf) { Copy-Item -LiteralPath $DestLauncher -Destination (Join-Path $BackupRoot 'RG35XX-P1A-GRAPHICS.sh') }
    if (Test-Path -LiteralPath $DestPayload -PathType Container) { Copy-Item -LiteralPath $DestPayload -Destination (Join-Path $BackupRoot 'RG35XX-P1A-GRAPHICS') -Recurse }
}

if (Test-Path -LiteralPath $DestPayload -PathType Container) { Remove-Item -LiteralPath $DestPayload -Recurse -Force }
New-Item -ItemType Directory -Force -Path $DestPayload | Out-Null
Copy-Item -LiteralPath $SourceLauncher -Destination $DestLauncher -Force
Get-ChildItem -LiteralPath $SourcePayload -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $DestPayload $_.Name) -Force }

Get-ChildItem -LiteralPath $SourcePayload -File | ForEach-Object {
    $Dst = Join-Path $DestPayload $_.Name
    if (-not (Test-Path -LiteralPath $Dst -PathType Leaf)) { throw "Installed file missing: $Dst" }
    if ((Get-Sha256 $_.FullName) -ne (Get-Sha256 $Dst)) { throw "Install verification hash mismatch: $($_.Name)" }
}
if ((Get-Sha256 $SourceLauncher) -ne (Get-Sha256 $DestLauncher)) { throw 'Launcher install verification hash mismatch.' }

$Result = Join-Path $SdRoot 'RG35XX-P1A-GRAPHICS-INSTALL-RESULT.txt'
@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'MODULE=P1A_GRAPHICS',
    'PHYSICAL_TEST_LEVEL=MODULE',
    "INSTALL_TIME=$((Get-Date).ToString('o'))",
    "SD_ROOT=$SdRoot",
    "JAMVM_SHA256=$JamvmHash",
    "GLIBJ_SHA256=$GlibjHash",
    "PLATFORM_JAR_SHA256=$ExpectedPlatform",
    "EXERCISER_SHA256=$ExpectedExerciser",
    "INPUT_NATIVE_SHA256=$ExpectedInput",
    "VIDEO_NATIVE_SHA256=$ExpectedVideo",
    "LAUNCHER=$DestLauncher",
    "PAYLOAD=$DestPayload",
    "BACKUP_CREATED=$NeedBackup",
    "BACKUP_PATH=$BackupRoot",
    'INSTALL_RESULT=PASS',
    'DEVICE_PASS=NO',
    'STABLE=NO'
) | Set-Content -LiteralPath $Result -Encoding ASCII

Write-Host 'P1A graphics physical package install PASS.'
Write-Host "Launch from APPS: RG35XX-P1A-GRAPHICS"
Write-Host "Install result: $Result"
if ($NeedBackup) { Write-Host "Backup: $BackupRoot" }
