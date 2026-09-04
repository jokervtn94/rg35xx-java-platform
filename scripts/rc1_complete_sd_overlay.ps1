$ErrorActionPreference = 'Stop'

# RGJ-RC1-011BO
# Completes an existing RG35XX RC1 SD overlay with the exact pinned runtime assets.
# Fail closed on any hash mismatch. Does not imply DEVICE-TEST-PASS.

param(
    [string]$OverlayPath = (Join-Path $PSScriptRoot '..\RG35XX_Java_RC1_SD_Overlay')
)

$FontSha = '7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954'
$SoundFontSha = '9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe'
$DejaVuUrl = 'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.zip'
$SoundFontUrl = 'https://raw.githubusercontent.com/mrbumpy409/GeneralUser-GS/684543d5e5efaef08d02be50dcda8d552478fa60/GeneralUser-GS.sf2'

function Fail([string]$Message) {
    throw "RC1 COMPLETE: $Message"
}

function Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

$OverlayPath = [System.IO.Path]::GetFullPath($OverlayPath)
if (-not (Test-Path -LiteralPath $OverlayPath -PathType Container)) {
    Fail "overlay directory not found: $OverlayPath"
}

$Required = @(
    'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
    'BIOS\freej2me-lr.jar',
    'Roms\JAVA\RG35XX_RC1_Device_Test.jar',
    'Roms\JAVA\RG35XX_RC1_Switch_Probe.jar'
)
foreach ($Rel in $Required) {
    $P = Join-Path $OverlayPath $Rel
    if (-not (Test-Path -LiteralPath $P -PathType Leaf)) {
        Fail "required overlay file missing: $Rel"
    }
}

$RuntimeDir = Join-Path $OverlayPath 'Java\runtime'
New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null

$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('rg35xx-rc1-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

try {
    $FontZip = Join-Path $TempRoot 'dejavu-fonts-ttf-2.37.zip'
    $FontExtract = Join-Path $TempRoot 'dejavu'
    $SoundFontTmp = Join-Path $TempRoot 'GeneralUser-GS.sf2'

    Write-Host 'RC1 COMPLETE: downloading DejaVu Fonts 2.37...'
    Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'RG35XX-RC1-Packager' } -Uri $DejaVuUrl -OutFile $FontZip
    Expand-Archive -LiteralPath $FontZip -DestinationPath $FontExtract -Force
    $FontCandidate = Get-ChildItem -LiteralPath $FontExtract -Filter 'DejaVuSans.ttf' -File -Recurse | Select-Object -First 1
    if ($null -eq $FontCandidate) { Fail 'DejaVuSans.ttf not found in pinned release archive' }
    $ActualFontSha = Sha256 $FontCandidate.FullName
    if ($ActualFontSha -ne $FontSha) {
        Fail "DejaVuSans.ttf SHA256 mismatch: got $ActualFontSha expected $FontSha"
    }

    Write-Host 'RC1 COMPLETE: downloading GeneralUser-GS pinned commit...'
    Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'RG35XX-RC1-Packager' } -Uri $SoundFontUrl -OutFile $SoundFontTmp
    $ActualSoundFontSha = Sha256 $SoundFontTmp
    if ($ActualSoundFontSha -ne $SoundFontSha) {
        Fail "GeneralUser-GS.sf2 SHA256 mismatch: got $ActualSoundFontSha expected $SoundFontSha"
    }

    $FontDst = Join-Path $RuntimeDir 'DejaVuSans.ttf'
    $SoundFontDst = Join-Path $RuntimeDir 'GeneralUser-GS.sf2'
    Copy-Item -LiteralPath $FontCandidate.FullName -Destination $FontDst -Force
    Copy-Item -LiteralPath $SoundFontTmp -Destination $SoundFontDst -Force

    if ((Sha256 $FontDst) -ne $FontSha) { Fail 'installed font hash mismatch' }
    if ((Sha256 $SoundFontDst) -ne $SoundFontSha) { Fail 'installed SoundFont hash mismatch' }

    $Manifest = Join-Path $OverlayPath 'SHA256SUMS'
    $Lines = Get-ChildItem -LiteralPath $OverlayPath -File -Recurse |
        Where-Object { $_.FullName -ne $Manifest } |
        Sort-Object FullName |
        ForEach-Object {
            $Rel = $_.FullName.Substring($OverlayPath.Length).TrimStart('\\','/') -replace '\\','/'
            "$(Sha256 $_.FullName)  $Rel"
        }
    [System.IO.File]::WriteAllLines($Manifest, $Lines, (New-Object System.Text.UTF8Encoding($false)))

    $Parent = Split-Path -Parent $OverlayPath
    $Base = Split-Path -Leaf $OverlayPath
    $CompleteZip = Join-Path $Parent ($Base + '_COMPLETE.zip')
    if (Test-Path -LiteralPath $CompleteZip) { Remove-Item -LiteralPath $CompleteZip -Force }
    Compress-Archive -Path $OverlayPath -DestinationPath $CompleteZip -CompressionLevel Optimal

    Write-Host ''
    Write-Host 'RC1 COMPLETE: PASS' -ForegroundColor Green
    Write-Host "Font SHA256:      $FontSha"
    Write-Host "SoundFont SHA256: $SoundFontSha"
    Write-Host "Complete overlay: $OverlayPath"
    Write-Host "Complete ZIP:     $CompleteZip"
    Write-Host 'DEVICE-TEST-PASS is not implied; run the JAR tests on the real RG35XX.'
}
finally {
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
