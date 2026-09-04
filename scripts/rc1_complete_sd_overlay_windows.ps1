param(
    [Parameter(Mandatory=$false)]
    [string]$OverlayPath = (Join-Path $PSScriptRoot '..\RG35XX_Java_RC1_SD_Overlay')
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$FontSha = '7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954'
$SoundFontSha = '9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe'
$FontUrls = @(
    'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.zip',
    'https://downloads.sourceforge.net/project/dejavu/dejavu/2.37/dejavu-fonts-ttf-2.37.zip'
)
$SoundFontUrls = @(
    'https://codeload.github.com/mrbumpy409/GeneralUser-GS/zip/684543d5e5efaef08d02be50dcda8d552478fa60',
    'https://github.com/mrbumpy409/GeneralUser-GS/archive/684543d5e5efaef08d02be50dcda8d552478fa60.zip'
)

function Fail([string]$Message) { throw "RC1 COMPLETE: $Message" }
function Sha256([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }

function Download-One([string]$Url, [string]$OutFile) {
    if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        Write-Host "  curl.exe: $Url"
        & $curl.Source -L --fail --retry 3 --retry-delay 2 --connect-timeout 20 -A 'RG35XX-RC1-Packager/1.1' -o $OutFile $Url
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
        Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
    }

    try {
        Write-Host "  WebClient: $Url"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent','RG35XX-RC1-Packager/1.1')
        $wc.DownloadFile($Url, $OutFile)
        $wc.Dispose()
        if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
    } catch {
        Write-Host "  WebClient failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
    }

    $bits = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue
    if ($bits) {
        try {
            Write-Host "  BITS: $Url"
            Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
            if ((Test-Path -LiteralPath $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
        } catch {
            Write-Host "  BITS failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        }
    }

    return $false
}

function Download-Fallback([string[]]$Urls, [string]$OutFile, [string]$Label) {
    foreach ($url in $Urls) {
        try {
            Write-Host "Downloading $Label..."
            if (Download-One $url $OutFile) { return }
        } catch {
            Write-Host "  source failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Fail "$Label download failed from every pinned source"
}

$OverlayPath = [System.IO.Path]::GetFullPath($OverlayPath)
if (-not (Test-Path -LiteralPath $OverlayPath -PathType Container)) { Fail "overlay directory not found: $OverlayPath" }

$Required = @(
    'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
    'BIOS\freej2me-lr.jar',
    'Roms\JAVA\RG35XX_RC1_Device_Test.jar',
    'Roms\JAVA\RG35XX_RC1_Switch_Probe.jar'
)
foreach ($Rel in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $OverlayPath $Rel) -PathType Leaf)) { Fail "required overlay file missing: $Rel" }
}

$RuntimeDir = Join-Path $OverlayPath 'Java\runtime'
New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('rg35xx-rc1-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

try {
    $FontZip = Join-Path $TempRoot 'dejavu.zip'
    $FontExtract = Join-Path $TempRoot 'dejavu'
    $SoundZip = Join-Path $TempRoot 'generaluser.zip'
    $SoundExtract = Join-Path $TempRoot 'generaluser'

    Download-Fallback $FontUrls $FontZip 'DejaVu Fonts 2.37'
    Expand-Archive -LiteralPath $FontZip -DestinationPath $FontExtract -Force
    $FontCandidate = Get-ChildItem -LiteralPath $FontExtract -Filter 'DejaVuSans.ttf' -File -Recurse | Select-Object -First 1
    if ($null -eq $FontCandidate) { Fail 'DejaVuSans.ttf not found in downloaded 2.37 archive' }
    $ActualFontSha = Sha256 $FontCandidate.FullName
    if ($ActualFontSha -ne $FontSha) { Fail "DejaVuSans.ttf SHA256 mismatch: got $ActualFontSha expected $FontSha" }

    Download-Fallback $SoundFontUrls $SoundZip 'GeneralUser-GS pinned commit archive'
    Expand-Archive -LiteralPath $SoundZip -DestinationPath $SoundExtract -Force
    $SoundCandidate = Get-ChildItem -LiteralPath $SoundExtract -Filter 'GeneralUser-GS.sf2' -File -Recurse | Select-Object -First 1
    if ($null -eq $SoundCandidate) { Fail 'GeneralUser-GS.sf2 not found in pinned commit archive' }
    $ActualSoundSha = Sha256 $SoundCandidate.FullName
    if ($ActualSoundSha -ne $SoundFontSha) { Fail "GeneralUser-GS.sf2 SHA256 mismatch: got $ActualSoundSha expected $SoundFontSha" }

    Copy-Item -LiteralPath $FontCandidate.FullName -Destination (Join-Path $RuntimeDir 'DejaVuSans.ttf') -Force
    Copy-Item -LiteralPath $SoundCandidate.FullName -Destination (Join-Path $RuntimeDir 'GeneralUser-GS.sf2') -Force

    if ((Sha256 (Join-Path $RuntimeDir 'DejaVuSans.ttf')) -ne $FontSha) { Fail 'installed font verification failed' }
    if ((Sha256 (Join-Path $RuntimeDir 'GeneralUser-GS.sf2')) -ne $SoundFontSha) { Fail 'installed SoundFont verification failed' }

    $Manifest = Join-Path $OverlayPath 'SHA256SUMS'
    $Lines = Get-ChildItem -LiteralPath $OverlayPath -File -Recurse |
        Where-Object { $_.FullName -ne $Manifest } |
        Sort-Object FullName |
        ForEach-Object {
            $Rel = $_.FullName.Substring($OverlayPath.Length).TrimStart('\','/') -replace '\\','/'
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
    Write-Host "Complete ZIP:     $CompleteZip"
} finally {
    if (Test-Path -LiteralPath $TempRoot) { Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
