#!/usr/bin/env bash
set -euo pipefail

INPUT_ZIP="${1:-}"
OUT_DIR="${2:-$(pwd)/out/p2c-windows-helper-r2}"
EXPECTED_RAW_PACKAGE_SHA256="014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36"
EXPECTED_PLATFORM="471152544509fe0e4822e782b53fdcbda3288a57ac2fb29a2efe7032e283d9a9"
EXPECTED_EXERCISER="baed252f0d68736867b3a6d4f50f3a30199f7705050e5ac898403218bc9784ac"
EXPECTED_FONT="1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10"
EXPECTED_FONT_NATIVE="29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
EXPECTED_INPUT="6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c"
EXPECTED_VIDEO="c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
EXPECTED_AUDIO="4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644"
SOURCE_HEAD="ceca509b39f95f2d172c4b20119ab644522be55b"
READY_DOC="286e4ebbea850a56db27165aec3e40d1ddf97380"
RUNTIME_CANDIDATE="0738281012b83d748cfb88ba063d21248a3f9c97"

fail(){ echo "P2C_WINDOWS_HELPER_R2_FAIL=$*" >&2; exit 1; }
[ -n "$INPUT_ZIP" ] || fail input_zip_required
[ -f "$INPUT_ZIP" ] || fail input_zip_missing
[ "$(sha256sum "$INPUT_ZIP" | awk '{print $1}')" = "$EXPECTED_RAW_PACKAGE_SHA256" ] || fail input_zip_hash

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/work"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
unzip -q "$INPUT_ZIP" -d "$OUT_DIR/work"
PKGROOT="$OUT_DIR/work/RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1"
[ -d "$PKGROOT/SD" ] || fail sd_missing
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND"
[ -d "$PAYLOAD" ] || fail payload_missing

check_hash(){
  local rel="$1" expected="$2"
  [ "$(sha256sum "$PAYLOAD/$rel" | awk '{print $1}')" = "$expected" ] || fail "payload_hash:$rel"
}
check_hash freej2me-rg35xx.jar "$EXPECTED_PLATFORM"
check_hash RG35XX-Platform-Exerciser-P2C-InputFrontend.jar "$EXPECTED_EXERCISER"
check_hash font.ttf "$EXPECTED_FONT"
check_hash librg35xx_font.so "$EXPECTED_FONT_NATIVE"
check_hash librg35xx_input.so "$EXPECTED_INPUT"
check_hash librg35xx_video.so "$EXPECTED_VIDEO"
check_hash libaudio.so "$EXPECTED_AUDIO"

BEFORE="$OUT_DIR/sd-before.sha256"
AFTER="$OUT_DIR/sd-after.sha256"
(
  cd "$PKGROOT/SD"
  find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
) > "$BEFORE"

cat > "$PKGROOT/INSTALL-RG35XX-P2C-INPUT-FRONTEND.ps1" <<'EOF_PS1'
param([string]$SdRoot)
$ErrorActionPreference = "Stop"

function Normalize-SdRoot([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { $Value = Read-Host "Enter RG35XX SD drive (example E, E:, or E:\)" }
  $Value = $Value.Trim().Trim('"')
  if ($Value -match '^[A-Za-z]$') { $Value = "$Value`:" }
  if ($Value -match '^[A-Za-z]:$') { $Value = "$Value\" }
  if ($Value -notmatch '^[A-Za-z]:\\$') { throw "Use a drive root only, for example E, E:, or E:\" }
  $root = [System.IO.Path]::GetPathRoot($Value)
  if (-not (Test-Path -LiteralPath $root)) { throw "Drive not found: $root" }
  $sys = [System.IO.Path]::GetPathRoot($env:SystemRoot)
  if ($root.TrimEnd('\\').ToUpperInvariant() -eq $sys.TrimEnd('\\').ToUpperInvariant()) { throw "Refusing Windows system drive: $root" }
  return $root
}

function Assert-Hash([string]$Path, [string]$Expected, [string]$Name) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "Missing $Name: $Path" }
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
  if ($actual -ne $Expected) { throw "Hash mismatch for $Name: expected=$Expected actual=$actual" }
}

try {
  $src = Join-Path $PSScriptRoot "SD"
  if (-not (Test-Path -LiteralPath $src)) { throw "SD payload missing: $src" }
  $payload = Join-Path $src "Roms\APPS\RG35XX-P2C-INPUT-FRONTEND"
  Assert-Hash (Join-Path $payload "freej2me-rg35xx.jar") "__EXPECTED_PLATFORM__" "platform jar"
  Assert-Hash (Join-Path $payload "RG35XX-Platform-Exerciser-P2C-InputFrontend.jar") "__EXPECTED_EXERCISER__" "exerciser"
  Assert-Hash (Join-Path $payload "font.ttf") "__EXPECTED_FONT__" "font"
  Assert-Hash (Join-Path $payload "librg35xx_font.so") "__EXPECTED_FONT_NATIVE__" "font native"
  Assert-Hash (Join-Path $payload "librg35xx_input.so") "__EXPECTED_INPUT__" "input native"
  Assert-Hash (Join-Path $payload "librg35xx_video.so") "__EXPECTED_VIDEO__" "video native"
  Assert-Hash (Join-Path $payload "libaudio.so") "__EXPECTED_AUDIO__" "audio native"

  $dst = Normalize-SdRoot $SdRoot
  Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force
  $installed = Join-Path $dst "Roms\APPS\RG35XX-P2C-INPUT-FRONTEND"
  Assert-Hash (Join-Path $installed "freej2me-rg35xx.jar") "__EXPECTED_PLATFORM__" "installed platform jar"
  Assert-Hash (Join-Path $installed "RG35XX-Platform-Exerciser-P2C-InputFrontend.jar") "__EXPECTED_EXERCISER__" "installed exerciser"
  Assert-Hash (Join-Path $installed "font.ttf") "__EXPECTED_FONT__" "installed font"
  Assert-Hash (Join-Path $installed "librg35xx_font.so") "__EXPECTED_FONT_NATIVE__" "installed font native"
  Assert-Hash (Join-Path $installed "librg35xx_input.so") "__EXPECTED_INPUT__" "installed input native"
  Assert-Hash (Join-Path $installed "librg35xx_video.so") "__EXPECTED_VIDEO__" "installed video native"
  Assert-Hash (Join-Path $installed "libaudio.so") "__EXPECTED_AUDIO__" "installed audio native"
  if (-not (Test-Path -LiteralPath (Join-Path $dst "Roms\APPS\RG35XX-P2C-INPUT-FRONTEND.sh"))) { throw "Launcher missing after copy" }
  Write-Host "INSTALL_RESULT=PASS"
  Write-Host "Installed exact P2C R3 SD payload to $dst"
  exit 0
} catch {
  Write-Host "INSTALL_RESULT=FAIL"
  Write-Host $_.Exception.Message
  exit 1
} finally {
  Read-Host "Press ENTER to close"
}
EOF_PS1
python3 - "$PKGROOT/INSTALL-RG35XX-P2C-INPUT-FRONTEND.ps1" "$EXPECTED_PLATFORM" "$EXPECTED_EXERCISER" "$EXPECTED_FONT" "$EXPECTED_FONT_NATIVE" "$EXPECTED_INPUT" "$EXPECTED_VIDEO" "$EXPECTED_AUDIO" <<'PY_REPL'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
keys=['PLATFORM','EXERCISER','FONT','FONT_NATIVE','INPUT','VIDEO','AUDIO']
for k,v in zip(keys,sys.argv[2:]): s=s.replace('__EXPECTED_'+k+'__',v)
if '__EXPECTED_' in s: raise SystemExit('P2C_WINDOWS_HELPER_R2_PLACEHOLDER_FAIL')
p.write_text(s)
PY_REPL

cat > "$PKGROOT/INSTALL-RG35XX-P2C-INPUT-FRONTEND.cmd" <<'EOF_CMD'
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-P2C-INPUT-FRONTEND.ps1" %*
set RC=%ERRORLEVEL%
exit /b %RC%
EOF_CMD

cat > "$PKGROOT/COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.ps1" <<'EOF_COLLECT'
param(
  [string]$SdRoot,
  [string]$Output
)
$ErrorActionPreference = "Stop"

function Normalize-SdRoot([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { $Value = Read-Host "Enter RG35XX SD drive (example E, E:, or E:\)" }
  $Value = $Value.Trim().Trim('"')
  if ($Value -match '^[A-Za-z]$') { $Value = "$Value`:" }
  if ($Value -match '^[A-Za-z]:$') { $Value = "$Value\" }
  if ($Value -notmatch '^[A-Za-z]:\\$') { throw "Use a drive root only, for example E, E:, or E:\" }
  $root = [System.IO.Path]::GetPathRoot($Value)
  if (-not (Test-Path -LiteralPath $root)) { throw "Drive not found: $root" }
  return $root
}

try {
  $root = Normalize-SdRoot $SdRoot
  $src = Join-Path $root "RG35XX-P2C-INPUT-FRONTEND-EVIDENCE"
  if (-not (Test-Path -LiteralPath $src)) { throw "Evidence directory missing: $src" }
  if ([string]::IsNullOrWhiteSpace($Output)) { $Output = Join-Path $PSScriptRoot "RG35XX-P2C-INPUT-FRONTEND-EVIDENCE" }
  if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Recurse -Force }
  Copy-Item -LiteralPath $src -Destination $Output -Recurse -Force
  $zip = "$Output.zip"
  if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
  Compress-Archive -Path (Join-Path $Output "*") -DestinationPath $zip -Force
  Write-Host "COLLECT_RESULT=PASS"
  Write-Host "Evidence folder: $Output"
  Write-Host "Evidence ZIP: $zip"
  exit 0
} catch {
  Write-Host "COLLECT_RESULT=FAIL"
  Write-Host $_.Exception.Message
  exit 1
} finally {
  Read-Host "Press ENTER to close"
}
EOF_COLLECT

cat > "$PKGROOT/COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.cmd" <<'EOF_CMD'
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.ps1" %*
set RC=%ERRORLEVEL%
exit /b %RC%
EOF_CMD

cat > "$PKGROOT/WINDOWS-HELPER-R2-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
HELPER=WINDOWS_HELPER_R2
SOURCE_PHYSICAL_R3_HEAD=$SOURCE_HEAD
SOURCE_READY_DOC_COMMIT=$READY_DOC
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
SOURCE_RAW_PACKAGE_SHA256=$EXPECTED_RAW_PACKAGE_SHA256
SD_RUNTIME_PAYLOAD_DELTA=NONE
RUNTIME_SEMANTIC_DELTA=NONE
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
EOF_ID

cat >> "$PKGROOT/README-FIRST.txt" <<'EOF_README'

Windows helper R2:
  Double-click INSTALL-RG35XX-P2C-INPUT-FRONTEND.cmd to install. The helper accepts E, E:, or E:\ and verifies exact payload hashes before and after copying.
  After the device run, double-click COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.cmd to collect the evidence folder and create a ZIP beside the helper.
  These Windows helper changes do not modify any file under SD/ and do not change runtime semantics.
EOF_README

(
  cd "$PKGROOT/SD"
  find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
) > "$AFTER"
cmp -s "$BEFORE" "$AFTER" || fail sd_payload_changed

OUTPUT_ZIP="$OUT_DIR/RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1-WINDOWS-HELPER-R2.zip"
rm -f "$OUTPUT_ZIP"
(
  cd "$OUT_DIR/work"
  zip -qr "$OUTPUT_ZIP" "RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1"
)
OUTPUT_SHA="$(sha256sum "$OUTPUT_ZIP" | awk '{print $1}')"
printf '%s\n' "P2C_WINDOWS_HELPER_R2_SOURCE_PACKAGE_SHA256=$EXPECTED_RAW_PACKAGE_SHA256"
printf '%s\n' "P2C_WINDOWS_HELPER_R2_OUTPUT_PACKAGE_SHA256=$OUTPUT_SHA"
echo P2C_WINDOWS_HELPER_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE
echo P2C_WINDOWS_HELPER_R2_RUNTIME_SEMANTIC_DELTA=NONE
echo P2C_WINDOWS_HELPER_R2_BUILD=PASS
echo P2C_PHYSICAL_TEST=NOT_TESTED
echo RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
echo STABLE=NO
