[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'

$Expected = @{
    JamVM    = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
    GlibJ    = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
    Platform = '057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c'
    Input    = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d'
    Video    = 'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d'
    Audio    = '4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644'
    Prime    = '8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e'
}

function Resolve-SdRoot {
    param([string]$Value)
    $v = $Value.Trim().Trim('"')
    if ($v -match '^[A-Za-z]$') { $v = "$v`:" }
    if ($v -match '^[A-Za-z]:$') { $v = "$v\" }
    return [System.IO.Path]::GetFullPath($v)
}

function Get-Sha256Lower {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Convert-ToDevicePath {
    param([string]$Root, [string]$WindowsPath)
    $rootPrefix = $Root
    if (-not $rootPrefix.EndsWith('\')) { $rootPrefix += '\' }
    if (-not $WindowsPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside selected SD root: $WindowsPath"
    }
    $relative = $WindowsPath.Substring($rootPrefix.Length).TrimStart('\','/')
    return '/mnt/mmc/' + ($relative -replace '\\','/')
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
    throw 'Harness payload missing. Expected A8-COMPAT-RUN.sh beside this installer or in its parent directory.'
}

$appsDir = Join-Path $root 'Roms\APPS'
if (-not (Test-Path -LiteralPath $appsDir -PathType Container)) {
    throw "Roms\APPS not found on SD: $appsDir"
}

$canonicalLauncher = Join-Path $appsDir 'RG35XX-AWEIGIT-R1.sh'
$bridgeLauncher = Join-Path $appsDir 'A8-COMPAT-PRODUCTION-BRIDGE.sh'
$diagnosticFile = Join-Path $root 'A8-COMPAT-SD-DIAGNOSTIC.txt'
$resultFile = Join-Path $root 'A8-COMPAT-HARNESS-INSTALL-RESULT.txt'
$mode = $null
$selectedPayload = $null
$scanLines = New-Object System.Collections.Generic.List[string]

$scanLines.Add('PROJECT=RG35XX-AWEIGIT-R1')
$scanLines.Add('BASELINE=A8')
$scanLines.Add("SD_ROOT=$root")
$scanLines.Add("CANONICAL_LAUNCHER_PRESENT=$([bool](Test-Path -LiteralPath $canonicalLauncher -PathType Leaf))")

if (Test-Path -LiteralPath $canonicalLauncher -PathType Leaf) {
    $mode = 'CANONICAL_A8_LAUNCHER'
} else {
    $jamvm = Join-Path $root 'CFW\java\bin\jamvm'
    $glibj = Join-Path $root 'CFW\java\share\classpath\glibj.zip'

    if (-not (Test-Path -LiteralPath $jamvm -PathType Leaf)) {
        $scanLines.Add('JAMVM=NOT_FOUND')
        $scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8
        throw "Protected JamVM not found: $jamvm. Diagnostic: $diagnosticFile"
    }
    if (-not (Test-Path -LiteralPath $glibj -PathType Leaf)) {
        $scanLines.Add('GLIBJ=NOT_FOUND')
        $scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8
        throw "Protected glibj not found: $glibj. Diagnostic: $diagnosticFile"
    }

    $jamvmHash = Get-Sha256Lower $jamvm
    $glibjHash = Get-Sha256Lower $glibj
    $scanLines.Add("JAMVM_SHA256=$jamvmHash")
    $scanLines.Add("GLIBJ_SHA256=$glibjHash")

    if ($jamvmHash -ne $Expected.JamVM -or $glibjHash -ne $Expected.GlibJ) {
        $scanLines.Add('PROTECTED_RUNTIME_IDENTITY=FAIL')
        $scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8
        throw "Protected JamVM/glibj identity does not match accepted A8. Diagnostic: $diagnosticFile"
    }
    $scanLines.Add('PROTECTED_RUNTIME_IDENTITY=PASS')

    $requiredFiles = @(
        'freej2me-rg35xx.jar',
        'librg35xx_input.so',
        'librg35xx_video.so',
        'libaudio.so',
        'a7-a1p5-rw-silence-prime.s32le'
    )

    $dirs = @()
    $dirs += Get-Item -LiteralPath $appsDir
    $dirs += Get-ChildItem -LiteralPath $appsDir -Directory -Recurse -ErrorAction SilentlyContinue
    $exactMatches = @()

    foreach ($dir in $dirs) {
        $allPresent = $true
        foreach ($name in $requiredFiles) {
            if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName $name) -PathType Leaf)) {
                $allPresent = $false
                break
            }
        }
        if (-not $allPresent) { continue }

        $ph = Get-Sha256Lower (Join-Path $dir.FullName 'freej2me-rg35xx.jar')
        $ih = Get-Sha256Lower (Join-Path $dir.FullName 'librg35xx_input.so')
        $vh = Get-Sha256Lower (Join-Path $dir.FullName 'librg35xx_video.so')
        $ah = Get-Sha256Lower (Join-Path $dir.FullName 'libaudio.so')
        $rh = Get-Sha256Lower (Join-Path $dir.FullName 'a7-a1p5-rw-silence-prime.s32le')

        $isExact = ($ph -eq $Expected.Platform -and $ih -eq $Expected.Input -and $vh -eq $Expected.Video -and $ah -eq $Expected.Audio -and $rh -eq $Expected.Prime)
        $scanLines.Add("PAYLOAD_DIR=$($dir.FullName)")
        $scanLines.Add("  PLATFORM_SHA256=$ph")
        $scanLines.Add("  INPUT_SHA256=$ih")
        $scanLines.Add("  VIDEO_SHA256=$vh")
        $scanLines.Add("  AUDIO_SHA256=$ah")
        $scanLines.Add("  PRIME_SHA256=$rh")
        $scanLines.Add("  A8_EXACT_MATCH=$isExact")

        if ($isExact) { $exactMatches += $dir }
    }

    $shellFiles = Get-ChildItem -LiteralPath $appsDir -File -Filter '*.sh' -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($sh in $shellFiles) {
        $scanLines.Add("APPS_SH=$($sh.Name)")
    }

    if ($exactMatches.Count -eq 0) {
        $scanLines.Add('A8_EXACT_PAYLOAD=NOT_FOUND')
        $scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8
        throw "Canonical launcher is absent and no exact A8 payload was found. Diagnostic: $diagnosticFile"
    }

    $selectedPayload = $exactMatches | Sort-Object @{ Expression = { if ($_.Name -eq 'RG35XX-AWEIGIT-R1') { 0 } else { 1 } } }, FullName | Select-Object -First 1
    $devicePkg = Convert-ToDevicePath $root $selectedPayload.FullName
    if ($devicePkg.Contains("'")) {
        $scanLines.Add('BRIDGE_CREATE=FAIL_UNSUPPORTED_QUOTE_IN_PATH')
        $scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8
        throw "Selected payload path contains an unsupported single quote: $devicePkg"
    }

    $bridgeTemplate = @'
#!/bin/sh
# Auto-generated A8 compatibility bridge.
# Created only after exact A8 payload + protected runtime hash verification on the SD card.

PKG='__PKG__'
OUT=/mnt/mmc/RG35XX-AWEIGIT-R1-RESULT.txt
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"

: >"$OUT"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=A8-COMPAT-VERIFIED-PAYLOAD-BRIDGE' >>"$OUT"
echo 'BASE=A8_DEVICE_PASS_PAYLOAD_IDENTITY' >>"$OUT"
echo "BRIDGE_PACKAGE=$PKG" >>"$OUT"
echo 'FULL_PLATFORM_STABLE=NO' >>"$OUT"

fail() {
  echo "PRECONDITION=FAIL:$1" >>"$OUT"
  echo 'TECHNICAL_GATE=FAIL' >>"$OUT"
  echo 'DEVICE_PASS=NO' >>"$OUT"
  sync
  exit 20
}

GAME="$1"
[ -n "$GAME" ] || fail GAME_ARGUMENT_MISSING
[ -f "$GAME" ] || fail GAME_FILE_MISSING
[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING
[ -d "$PKG" ] || fail PAYLOAD_MISSING
for F in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le; do
  [ -f "$PKG/$F" ] || fail "MISSING:$F"
done
APLAY="$(command -v aplay 2>/dev/null || true)"
[ -n "$APLAY" ] && [ -x "$APLAY" ] || fail APLAY_MISSING

JB=$(sha256sum "$JAMVM"|awk '{print $1}')
GB=$(sha256sum "$GLIBJ"|awk '{print $1}')
PH=$(sha256sum "$PKG/freej2me-rg35xx.jar"|awk '{print $1}')
IH=$(sha256sum "$PKG/librg35xx_input.so"|awk '{print $1}')
VH=$(sha256sum "$PKG/librg35xx_video.so"|awk '{print $1}')
AH=$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')
PRH=$(sha256sum "$PRIME"|awk '{print $1}')
GH=$(sha256sum "$GAME"|awk '{print $1}')
echo "JAMVM_SHA256_BEFORE=$JB" >>"$OUT"
echo "GLIBJ_SHA256_BEFORE=$GB" >>"$OUT"
echo "PLATFORM_JAR_SHA256=$PH" >>"$OUT"
echo "INPUT_NATIVE_SHA256=$IH" >>"$OUT"
echo "VIDEO_NATIVE_SHA256=$VH" >>"$OUT"
echo "AUDIO_NATIVE_SHA256=$AH" >>"$OUT"
echo "PRIME_PCM_SHA256=$PRH" >>"$OUT"
echo "GAME_SHA256=$GH" >>"$OUT"
[ "$JB" = "$EXPECTED_JAMVM" ] || fail JAMVM_HASH_MISMATCH
[ "$GB" = "$EXPECTED_GLIBJ" ] || fail GLIBJ_HASH_MISMATCH
[ "$PH" = "$EXPECTED_PLATFORM" ] || fail PLATFORM_HASH_MISMATCH
[ "$IH" = "$EXPECTED_INPUT" ] || fail INPUT_HASH_MISMATCH
[ "$VH" = "$EXPECTED_VIDEO" ] || fail VIDEO_HASH_MISMATCH
[ "$AH" = "$EXPECTED_AUDIO" ] || fail AUDIO_HASH_MISMATCH
[ "$PRH" = "$EXPECTED_PRIME" ] || fail PRIME_HASH_MISMATCH

echo 'IDENTITY_GATE=PASS' >>"$OUT"
export SDL_AUDIODRIVER=alsa
echo 'A1P5_RW_SILENCE_PRIME=BEGIN' >>"$OUT"
"$APLAY" -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 "$PRIME" >>"$OUT" 2>&1
PRC=$?
echo "A1P5_RW_SILENCE_PRIME_EXIT_CODE=$PRC" >>"$OUT"
[ "$PRC" -eq 0 ] || fail APLAY_PRIME_FAILED
echo 'A1P5_RW_SILENCE_PRIME=PASS' >>"$OUT"

DATA="$PKG/data"
mkdir -p "$DATA" || fail DATA_DIR_CREATE_FAIL
echo 'REAL_GAME_PROCESS=START' >>"$OUT"
LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$JAMVM" -Xmx64m \
  -Drg35xx.raw2d=true \
  -Drg35xx.native.dir="$PKG" \
  -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" \
  org.recompile.rg35xx.RG35XXLauncher "$GAME" 240 320 "$DATA" "$DATA" >>"$OUT" 2>&1
RC=$?
echo "RUNTIME_EXIT_CODE=$RC" >>"$OUT"

JA=$(sha256sum "$JAMVM"|awk '{print $1}')
GA=$(sha256sum "$GLIBJ"|awk '{print $1}')
echo "JAMVM_SHA256_AFTER=$JA" >>"$OUT"
echo "GLIBJ_SHA256_AFTER=$GA" >>"$OUT"
if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
  echo 'PROTECTED_HASHES=PASS' >>"$OUT"
else
  echo 'PROTECTED_HASHES=FAIL' >>"$OUT"
fi
[ "$RC" -eq 0 ] && echo 'NORMAL_EXIT=PASS' >>"$OUT" || echo 'NORMAL_EXIT=FAIL' >>"$OUT"
echo 'DEVICE_PASS=NO_PENDING_A8_REAL_DEVICE_REVIEW' >>"$OUT"
sync
exit "$RC"
'@

    $bridgeText = $bridgeTemplate.Replace('__PKG__', $devicePkg)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($bridgeLauncher, $bridgeText, $utf8NoBom)
    $mode = 'VERIFIED_A8_PAYLOAD_BRIDGE'
    $scanLines.Add("A8_EXACT_PAYLOAD_SELECTED=$($selectedPayload.FullName)")
    $scanLines.Add("A8_DEVICE_PAYLOAD=$devicePkg")
    $scanLines.Add("BRIDGE_LAUNCHER=$bridgeLauncher")
}

$destinationWrapper = Join-Path $appsDir 'A8-COMPAT-RUN.sh'
Copy-Item -LiteralPath $sourceWrapper -Destination $destinationWrapper -Force

$sourceHash = Get-Sha256Lower $sourceWrapper
$destinationHash = Get-Sha256Lower $destinationWrapper
if ($sourceHash -ne $destinationHash) {
    throw 'Harness copy verification failed'
}

$scanLines.Add("INSTALL_MODE=$mode")
$scanLines.Add("HARNESS_SHA256=$destinationHash")
$scanLines.Add('INSTALL_RESULT=PASS')
$scanLines.Add("TIMESTAMP=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
$scanLines | Set-Content -LiteralPath $diagnosticFile -Encoding UTF8

@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'BASELINE=A8',
    'ACTION=INSTALL_COMPAT_HARNESS_ONLY',
    "SD_ROOT=$root",
    "INSTALL_MODE=$mode",
    "CANONICAL_LAUNCHER=$canonicalLauncher",
    "VERIFIED_PAYLOAD=$($selectedPayload.FullName)",
    "BRIDGE_LAUNCHER=$bridgeLauncher",
    'PRODUCTION_RUNTIME_MODIFIED=NO',
    "HARNESS_DESTINATION=$destinationWrapper",
    "HARNESS_SHA256=$destinationHash",
    "DIAGNOSTIC=$diagnosticFile",
    'INSTALL_RESULT=PASS',
    "TIMESTAMP=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath $resultFile -Encoding UTF8

Write-Host 'A8 compatibility harness installed successfully.'
Write-Host "SD root      : $root"
Write-Host "Install mode : $mode"
if ($selectedPayload) { Write-Host "A8 payload   : $($selectedPayload.FullName)" }
Write-Host "Harness      : $destinationWrapper"
if (Test-Path -LiteralPath $bridgeLauncher -PathType Leaf) { Write-Host "Bridge       : $bridgeLauncher" }
Write-Host "Result       : $resultFile"
Write-Host "Diagnostic   : $diagnosticFile"
Write-Host 'Existing A8 runtime files were not modified.'
