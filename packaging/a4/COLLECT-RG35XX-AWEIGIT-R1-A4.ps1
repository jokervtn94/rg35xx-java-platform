param(
    [Parameter(Mandatory=$false)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'
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

$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Work = Join-Path $PSScriptRoot ("RG35XX-AWEIGIT-R1-A4-EVIDENCE-$Stamp")
$Zip = "$Work.zip"
New-Item -ItemType Directory -Force -Path $Work | Out-Null

$Files = @(
    (Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A4-INSTALL-RESULT.txt'),
    (Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A4-SMOKE-RESULT.txt'),
    (Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE\BUILD-IDENTITY.txt'),
    (Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE\CANONICAL-DIFF-MANIFEST.txt'),
    (Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE\JAVA6-COMPAT-AUDIT.tsv'),
    (Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE\PAYLOAD-SHA256SUMS.txt')
)
foreach ($File in $Files) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Copy-Item -LiteralPath $File -Destination (Join-Path $Work ([System.IO.Path]::GetFileName($File)))
    }
}

$Jamvm = Join-Path $SdRoot 'CFW\java\bin\jamvm'
$Glibj = Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
$Launcher = Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE.sh'
$Payload = Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A4-SMOKE'

$Inventory = New-Object System.Collections.Generic.List[string]
$Inventory.Add('PROJECT=RG35XX-AWEIGIT-R1')
$Inventory.Add('STAGE=A4-SMOKE')
$Inventory.Add("COLLECT_TIME=$((Get-Date).ToString('o'))")
$Inventory.Add("SD_ROOT=$SdRoot")
foreach ($Pair in @(
    @('JAMVM',$Jamvm),
    @('GLIBJ',$Glibj),
    @('LAUNCHER',$Launcher),
    @('PLATFORM_JAR',(Join-Path $Payload 'freej2me-rg35xx.jar')),
    @('INPUT_NATIVE',(Join-Path $Payload 'librg35xx_input.so')),
    @('VIDEO_NATIVE',(Join-Path $Payload 'librg35xx_video.so')),
    @('SMOKE_JAR',(Join-Path $Payload 'rg35xx-a4-smoke.jar'))
)) {
    $Name = $Pair[0]
    $Path = $Pair[1]
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $Inventory.Add("${Name}_PATH=$Path")
        $Inventory.Add("${Name}_SHA256=$(Get-Sha256 $Path)")
    } else {
        $Inventory.Add("${Name}_MISSING=$Path")
    }
}
$Inventory.Add('DEVICE_PASS_REVIEW=PENDING')
$Inventory.Add('STABLE=NO')
$Inventory | Set-Content -LiteralPath (Join-Path $Work 'A4-EVIDENCE-INVENTORY.txt') -Encoding ASCII

if (Test-Path -LiteralPath $Zip) { Remove-Item -LiteralPath $Zip -Force }
Compress-Archive -Path (Join-Path $Work '*') -DestinationPath $Zip -Force
Remove-Item -LiteralPath $Work -Recurse -Force
Write-Host "Evidence package: $Zip"
