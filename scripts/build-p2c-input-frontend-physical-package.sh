#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2C_PHYSICAL_PACKAGE_BUILD_FAIL=$*" >&2; exit 1; }

OUT="$ROOT/out/p2c-input-frontend-candidate-r1"
CAND="$OUT/freej2me-rg35xx.jar"
EX="$OUT/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar"
FONT_NATIVE="$OUT/librg35xx_font.so"
INPUT="$OUT/librg35xx_input.so"
VIDEO="$OUT/librg35xx_video.so"
AUDIO="$ROOT/out/p2c-protected-audio/libaudio.so"
CID="$OUT/P2C-INPUT-FRONTEND-IDENTITY.txt"
EID="$OUT/P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt"
PKGROOT="$OUT/RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND"
ZIP="$OUT/RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip"
PHYSICAL_HEAD="${GITHUB_SHA:-$(git rev-parse HEAD)}"
RUNTIME_CANDIDATE=0738281012b83d748cfb88ba063d21248a3f9c97
HOST_CHECKPOINT=7f8b3bdeadd7b1cd2201f1bf62d8c29ecfb54eac
EXPECTED_PLATFORM=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
FONT_URL="https://github.com/aweigit/freej2me-miyoomini/releases/download/2.0/miyoomini-freej2me.zip"
FONT_SHA=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
LICENSE_URL="https://hyperos.mi.com/font-download/MiSans%E5%AD%97%E4%BD%93%E7%9F%A5%E8%AF%86%E4%BA%A7%E6%9D%83%E8%AE%B8%E5%8F%AF%E5%8D%8F%E8%AE%AE.pdf"

for f in "$CAND" "$EX" "$FONT_NATIVE" "$INPUT" "$VIDEO" "$AUDIO" "$CID" "$EID"; do
  [ -f "$f" ] || fail "missing $(basename "$f")"
done
[ "$(sha256sum "$CAND" | awk '{print $1}')" = "$EXPECTED_PLATFORM" ] || fail platform_hash
[ "$(sha256sum "$INPUT" | awk '{print $1}')" = "$EXPECTED_INPUT" ] || fail input_hash
[ "$(sha256sum "$FONT_NATIVE" | awk '{print $1}')" = "$EXPECTED_FONT_NATIVE" ] || fail font_native_hash
[ "$(sha256sum "$VIDEO" | awk '{print $1}')" = "$EXPECTED_VIDEO" ] || fail video_hash
[ "$(sha256sum "$AUDIO" | awk '{print $1}')" = "$EXPECTED_AUDIO" ] || fail audio_hash
grep -q '^P2C_HOST_MODULE_GATE=PASS$' "$CID" || fail host_module_gate
grep -q '^P2C_LAUNCH_RESOLUTION_CONTRACT_GATE=PASS$' "$CID" || fail resolution_gate
grep -q '^P2C_FINAL_OUTPUT_HASH_GATE=PASS$' "$CID" || fail final_hash_gate
grep -q '^P2C_PHYSICAL_TEST=NOT_TESTED$' "$CID" || fail premature_physical_result
grep -q '^LOGICAL_RESOLUTION=176x208$' "$EID" || fail exerciser_resolution
grep -q '^PHASE_COUNT=3$' "$EID" || fail exerciser_phase_count
grep -q '^PUBLIC_MIDP_CANVAS_KEY_API=YES$' "$EID" || fail exerciser_key_api
grep -q '^PUBLIC_MIDP_POINTER_API=YES$' "$EID" || fail exerciser_pointer_api
grep -q '^GAME_SPECIFIC_CODE=NO$' "$EID" || fail game_scope

EX_SHA="$(sha256sum "$EX" | awk '{print $1}')"
WORK="$ROOT/build/p2c-physical-package"
rm -rf "$WORK" "$PKGROOT" "$ZIP"
mkdir -p "$WORK" "$PAYLOAD/licenses"

curl -fL --retry 3 --retry-delay 2 "$FONT_URL" -o "$WORK/miyoomini-freej2me.zip"
FONT_ZIP_SHA="$(sha256sum "$WORK/miyoomini-freej2me.zip" | awk '{print $1}')"
ENTRY="$(unzip -Z1 "$WORK/miyoomini-freej2me.zip" | grep -E '(^|/)JAVA/font\.ttf$')"
[ "$(printf '%s\n' "$ENTRY" | sed '/^$/d' | wc -l | tr -d ' ')" = 1 ] || fail "font entry ambiguity"
unzip -p "$WORK/miyoomini-freej2me.zip" "$ENTRY" > "$PAYLOAD/font.ttf"
[ "$(sha256sum "$PAYLOAD/font.ttf" | awk '{print $1}')" = "$FONT_SHA" ] || fail font_hash
[ "$(wc -c < "$PAYLOAD/font.ttf" | tr -d ' ')" = "$FONT_SIZE" ] || fail font_size

curl -fL --retry 3 --retry-delay 2 "$LICENSE_URL" -o "$PAYLOAD/licenses/MiSans-LICENSE.pdf"
head -c 5 "$PAYLOAD/licenses/MiSans-LICENSE.pdf" | grep -q '%PDF-' || fail license_pdf
LICENSE_SHA="$(sha256sum "$PAYLOAD/licenses/MiSans-LICENSE.pdf" | awk '{print $1}')"
cat > "$PAYLOAD/NOTICE.txt" <<'EOF_NOTICE'
FreeJ2ME-RG35XX P2C Input/Frontend physical module package includes the exact
hash-locked MiSans runtime asset inherited from the accepted P2B parent.
MiSans is copied byte-for-byte without modification. See the included official
Xiaomi MiSans license agreement. The font is not intended for standalone
redistribution.
EOF_NOTICE

cp "$CAND" "$EX" "$FONT_NATIVE" "$INPUT" "$VIDEO" "$AUDIO" "$CID" "$EID" "$PAYLOAD/"

cat > "$PAYLOAD/PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1
PHYSICAL_BRANCH_HEAD=$PHYSICAL_HEAD
HOST_MODULE_CHECKPOINT=$HOST_CHECKPOINT
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P2C_PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM
P2C_INPUT_NATIVE_SHA256=$EXPECTED_INPUT
P2C_FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
P2C_VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
P2C_AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
EXERCISER_SHA256=$EX_SHA
FONT_RELEASE_URL=$FONT_URL
FONT_RELEASE_ZIP_SHA256=$FONT_ZIP_SHA
FONT_ENTRY=$ENTRY
FONT_SHA256=$FONT_SHA
FONT_SIZE=$FONT_SIZE
MISANS_LICENSE_SOURCE=$LICENSE_URL
MISANS_LICENSE_SHA256=$LICENSE_SHA
LOGICAL_RESOLUTION=176x208
PHASE_COUNT=3
PHYSICAL_TEST_LEVEL=MODULE
PUBLIC_MIDP_ONLY=YES
RUNTIME_SEMANTIC_DELTA_FROM_HOST_CHECKPOINT=NONE
EVIDENCE_DIRECTORY=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
NORMAL_RETURN_TO_GARLICOS=REQUIRED_MANUAL_OBSERVATION
ROTATION_VISUAL_OBSERVATION=REQUIRED
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
EOF_ID

cat > "$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND.sh" <<'EOF_LAUNCH'
#!/bin/sh
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-P2C-INPUT-FRONTEND"
EVID=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
MASTER="$EVID/P2C-INPUT-FRONTEND-RUN.log"
SUMMARY="$EVID/P2C-INPUT-FRONTEND-DEVICE-SUMMARY.txt"
DATA="$EVID/data"
RMS="$EVID/rms"
P1="$EVID/PHASE1.log"
P2="$EVID/PHASE2.log"
P3="$EVID/PHASE3.log"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
RUNTIME_SOURCE=PROTECTED
RUNTIME_LIBS=
if [ ! -x "$JAMVM" ] || [ ! -f "$GLIBJ" ]; then
  CANDIDATE_RUNTIME=/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
  JAMVM="$CANDIDATE_RUNTIME/bin/jamvm"
  GLIBJ="$CANDIDATE_RUNTIME/share/classpath/glibj.zip"
  EXPECTED_JAMVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
  EXPECTED_GLIBJ=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
  RUNTIME_SOURCE=CANDIDATE_PROBE
  RUNTIME_LIBS="$CANDIDATE_RUNTIME/lib/classpath:$CANDIDATE_RUNTIME/lib:"
fi
EXPECTED_PLATFORM=533442c7e67965c8ac095898bfb32c9fcdd233471cd19e64ca2012ceaca00c60
EXPECTED_EXERCISER=__P2C_EXERCISER_SHA256__
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644

rm -rf "$EVID"
mkdir -p "$DATA" "$RMS" || exit 20
: >"$MASTER"
cat >"$SUMMARY" <<'EOF_SUMMARY'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
PHYSICAL_TEST_LEVEL=MODULE
ORIGINAL_RG35XX_REQUIRED=YES
LOGICAL_RESOLUTION=176x208
P2C_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_SUMMARY
echo "P2C_RUNTIME_SOURCE=$RUNTIME_SOURCE" >>"$MASTER"
echo "P2C_RUNTIME_SOURCE=$RUNTIME_SOURCE" >>"$SUMMARY"

p2c_fail() {
  echo "P2C_DEVICE_PRECONDITION=FAIL:$1" >>"$MASTER"
  echo "P2C_DEVICE_PRECONDITION=FAIL:$1" >>"$SUMMARY"
  echo 'P2C_DEVICE_PROGRAMMATIC_RESULT=FAIL' >>"$SUMMARY"
  sync
  exit 20
}

for F in freej2me-rg35xx.jar RG35XX-Platform-Exerciser-P2C-InputFrontend.jar librg35xx_font.so font.ttf librg35xx_input.so librg35xx_video.so libaudio.so NOTICE.txt licenses/MiSans-LICENSE.pdf PAYLOAD-SHA256SUMS.txt P2C-INPUT-FRONTEND-IDENTITY.txt P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt PHYSICAL-PACKAGE-IDENTITY.txt; do
  [ -f "$PKG/$F" ] || p2c_fail "MISSING:$F"
done
[ -x "$JAMVM" ] || p2c_fail JAMVM_MISSING
[ -f "$GLIBJ" ] || p2c_fail GLIBJ_MISSING

grep -q '^P2C_HOST_MODULE_GATE=PASS$' "$PKG/P2C-INPUT-FRONTEND-IDENTITY.txt" || p2c_fail HOST_MODULE_GATE
grep -q '^P2C_LAUNCH_RESOLUTION_CONTRACT_GATE=PASS$' "$PKG/P2C-INPUT-FRONTEND-IDENTITY.txt" || p2c_fail RESOLUTION_GATE
grep -q '^P2C_FINAL_OUTPUT_HASH_GATE=PASS$' "$PKG/P2C-INPUT-FRONTEND-IDENTITY.txt" || p2c_fail FINAL_HASH_GATE
grep -q '^PHASE_COUNT=3$' "$PKG/P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt" || p2c_fail EXERCISER_PHASES

JB=$(sha256sum "$JAMVM" | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" | awk '{print $1}')
PB=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')
EB=$(sha256sum "$PKG/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" | awk '{print $1}')
FB=$(sha256sum "$PKG/font.ttf" | awk '{print $1}')
NB=$(sha256sum "$PKG/librg35xx_font.so" | awk '{print $1}')
IB=$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')
VB=$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')
AB=$(sha256sum "$PKG/libaudio.so" | awk '{print $1}')
[ "$JB" = "$EXPECTED_JAMVM" ] || p2c_fail JAMVM_HASH
[ "$GB" = "$EXPECTED_GLIBJ" ] || p2c_fail GLIBJ_HASH
[ "$PB" = "$EXPECTED_PLATFORM" ] || p2c_fail PLATFORM_HASH
[ "$EB" = "$EXPECTED_EXERCISER" ] || p2c_fail EXERCISER_HASH
[ "$FB" = "$EXPECTED_FONT" ] || p2c_fail FONT_HASH
[ "$NB" = "$EXPECTED_FONT_NATIVE" ] || p2c_fail FONT_NATIVE_HASH
[ "$IB" = "$EXPECTED_INPUT" ] || p2c_fail INPUT_HASH
[ "$VB" = "$EXPECTED_VIDEO" ] || p2c_fail VIDEO_HASH
[ "$AB" = "$EXPECTED_AUDIO" ] || p2c_fail AUDIO_HASH
(cd "$PKG" && sha256sum -c PAYLOAD-SHA256SUMS.txt) >>"$MASTER" 2>&1 || p2c_fail PAYLOAD_HASH

echo 'P2C_RUNTIME_HASH_GATE_BEFORE=PASS' >>"$MASTER"
cp "$PKG/P2C-INPUT-FRONTEND-IDENTITY.txt" "$PKG/P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt" "$PKG/PHYSICAL-PACKAGE-IDENTITY.txt" "$PKG/PAYLOAD-SHA256SUMS.txt" "$EVID/"
cat >"$EVID/MANUAL-OBSERVATION.txt" <<'EOF_MANUAL'
P2C_INPUT_FRONTEND_MANUAL_OBSERVATION=NOT_TESTED
EXPECTED_PHASE1=GREEN_PASS_AFTER_DEFAULT_14_CONTROLS_AND_PHONE_MODES
EXPECTED_PHASE2=GREEN_PASS_AFTER_CUSTOM_KEYMAP_POINTER_ROTATION
EXPECTED_PHASE3=GREEN_PASS_AFTER_INVALID_KEYMAP_FALLBACK
EXPECTED_ROTATION_VISUAL=SCREEN_ORIENTATION_CHANGES_0_TO_1_TO_2_TO_0
EXPECTED_POINTER=PUBLIC_MIDP_PRESS_RELEASE_AT_6,6
EXPECTED_RETURN=GARLICOS_MENU_AFTER_PHASE3
HUMAN_PHYSICAL_OBSERVATION=FINAL_AUTHORITY
P2C_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_MANUAL

run_phase() {
  PH="$1"; LOG="$2"
  (
    cd "$PKG" || exit 20
    LD_LIBRARY_PATH="${RUNTIME_LIBS}$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$JAMVM" -Xmx64m -Dp2c.exerciser.phase="$PH" -Drg35xx.raw2d=true \
      -Drg35xx.native.dir="$PKG" -Drg35xx.font.path="$PKG/font.ttf" \
      -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
      -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher \
      "$PKG/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" 176 208 "$DATA" "$RMS"
  ) >"$LOG" 2>&1
  return $?
}

rm -f "$DATA/keymap.cfg"
rm -rf "$DATA/config"
echo 'P2C_PHASE1_START=DEFAULT_MAPPING_CLEAN_CONFIG' >>"$MASTER"
run_phase 1 "$P1"; RC1=$?
cat "$P1" >>"$MASTER"

cat > "$DATA/keymap.cfg" <<'EOF_KEYMAP'
{
"左键":"A",
"右键":"Y",
"OK":"B",
"*":"START",
"#":"SELECT",
"0":"X",
"1":"R",
"3":"L",
"7":"R2",
"9":"L2"
}
EOF_KEYMAP
echo 'P2C_PHASE2_START=CUSTOM_KEYMAP' >>"$MASTER"
run_phase 2 "$P2"; RC2=$?
cat "$P2" >>"$MASTER"

cat > "$DATA/keymap.cfg" <<'EOF_BAD'
{"invalid":"mapping"}
EOF_BAD
# Phase 3 validates invalid-keymap fallback against the canonical default
# phone profile.  Start it from a clean phone-mode config so a failed phase 2
# cannot leave the persisted n-mode profile as an unrelated test input.
rm -rf "$DATA/config"
echo 'P2C_PHASE3_START=INVALID_KEYMAP_FAILSAFE' >>"$MASTER"
run_phase 3 "$P3"; RC3=$?
cat "$P3" >>"$MASTER"

JA=$(sha256sum "$JAMVM" | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" | awk '{print $1}')
PA=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')
EA=$(sha256sum "$PKG/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar" | awk '{print $1}')
FA=$(sha256sum "$PKG/font.ttf" | awk '{print $1}')
NA=$(sha256sum "$PKG/librg35xx_font.so" | awk '{print $1}')
IA=$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')
VA=$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')
AA=$(sha256sum "$PKG/libaudio.so" | awk '{print $1}')
HASH_RESULT=PASS
[ "$JB" = "$JA" ] || HASH_RESULT=FAIL
[ "$GB" = "$GA" ] || HASH_RESULT=FAIL
[ "$PB" = "$PA" ] || HASH_RESULT=FAIL
[ "$EB" = "$EA" ] || HASH_RESULT=FAIL
[ "$FB" = "$FA" ] || HASH_RESULT=FAIL
[ "$NB" = "$NA" ] || HASH_RESULT=FAIL
[ "$IB" = "$IA" ] || HASH_RESULT=FAIL
[ "$VB" = "$VA" ] || HASH_RESULT=FAIL
[ "$AB" = "$AA" ] || HASH_RESULT=FAIL

PROGRAMMATIC=PASS
[ "$RC1" -eq 0 ] || PROGRAMMATIC=FAIL
[ "$RC2" -eq 0 ] || PROGRAMMATIC=FAIL
[ "$RC3" -eq 0 ] || PROGRAMMATIC=FAIL
[ "$HASH_RESULT" = PASS ] || PROGRAMMATIC=FAIL
grep -q '^RG35XX_A3_LOGICAL_LCD=176x208$' "$P1" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_P2C_PHONE_MODE=p$' "$P1" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_RESOLUTION=176x208 RESULT=PASS$' "$P1" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=1$' "$P1" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=1$' "$P1" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_P2C_PHONE_MODE=n$' "$P2" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_POINTER_PRESS=6,6 RESULT=PASS$' "$P2" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_POINTER_RELEASE=6,6 RESULT=PASS$' "$P2" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=2$' "$P2" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=2$' "$P2" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_P2C_PHONE_MODE=p$' "$P3" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=3$' "$P3" || PROGRAMMATIC=FAIL
grep -q '^P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=3$' "$P3" || PROGRAMMATIC=FAIL
if grep -q '^P2C_EXERCISER_RESULT=FAIL' "$MASTER"; then PROGRAMMATIC=FAIL; fi

echo "P2C_PROTECTED_HASHES=$HASH_RESULT" >>"MASTER"
echo "P2C_DEVICE_PROGRAMMATIC_RESULT=$PROGRAMMATIC" >>"MASTER"
cat >>"$SUMMARY" <<EOF_RESULT
P2C_PHASE1_EXIT_CODE=$RC1
P2C_PHASE2_EXIT_CODE=$RC2
P2C_PHASE3_EXIT_CODE=$RC3
P2C_PROTECTED_HASHES=$HASH_RESULT
P2C_DEVICE_PROGRAMMATIC_RESULT=$PROGRAMMATIC
P2C_INPUT_FRONTEND_MANUAL_OBSERVATION=NOT_TESTED
P2C_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_RESULT
sync
[ "$PROGRAMMATIC" = PASS ] && exit 0
exit 2
EOF_LAUNCH

python3 - "$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND.sh" "$EX_SHA" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(encoding='utf-8')
old='__P2C_EXERCISER_SHA256__'
if s.count(old)!=1: raise SystemExit('P2C_LAUNCHER_PLACEHOLDER_FAIL')
s=s.replace(old,sys.argv[2])
p.write_text(s,encoding='utf-8')
PY
chmod +x "$PKGROOT/SD/Roms/APPS/RG35XX-P2C-INPUT-FRONTEND.sh"

cat > "$PKGROOT/README-FIRST.txt" <<EOF_README
RG35XX P2C INPUT/FRONTEND PHYSICAL MODULE R1
============================================

Pre-device status:
  P2C host/module gate: PASS
  P2C physical test: NOT_TESTED
  Full platform device baseline: NO
  Stable: NO

Runtime candidate:
  $RUNTIME_CANDIDATE

Install:
  Copy the contents of SD/ to the root of the ORIGINAL RG35XX SD card.
  Launch RG35XX-P2C-INPUT-FRONTEND from GarlicOS Apps.

The module runs three human-driven phases at logical 176x208:
  1) default 14 controls + p/n/e/s/m phone modes; leaves mode n persisted
  2) verifies persisted n, custom keymap, virtual pointer, rotation; returns p
  3) invalid keymap fail-safe to defaults

Follow each on-screen prompt exactly. Each phase must show green PASS, then press A
to continue. During phase 2, visually confirm screen orientation changes for
rotation 0 -> 1 -> 2 -> 0. Final return to GarlicOS must be normal.

Evidence is written to:
  /mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE

Do not call P2C physical PASS until the evidence directory plus human rotation
and normal-return observations have been reviewed.
EOF_README

cat > "$PKGROOT/INSTALL-RG35XX-P2C-INPUT-FRONTEND.ps1" <<'EOF_PS1'
param([Parameter(Mandatory=$true)][string]$SdRoot)
$ErrorActionPreference = "Stop"
$src = Join-Path $PSScriptRoot "SD"
if (-not (Test-Path $src)) { throw "SD payload missing: $src" }
$dst = (Resolve-Path $SdRoot).Path
Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force
Write-Host "Installed RG35XX P2C Input/Frontend physical module to $dst"
EOF_PS1

cat > "$PKGROOT/COLLECT-RG35XX-P2C-INPUT-FRONTEND-EVIDENCE.ps1" <<'EOF_COLLECT'
param(
  [Parameter(Mandatory=$true)][string]$SdRoot,
  [string]$Output = (Join-Path $PSScriptRoot "RG35XX-P2C-INPUT-FRONTEND-EVIDENCE")
)
$ErrorActionPreference = "Stop"
$src = Join-Path (Resolve-Path $SdRoot).Path "RG35XX-P2C-INPUT-FRONTEND-EVIDENCE"
if (-not (Test-Path $src)) { throw "Evidence directory missing: $src" }
if (Test-Path $Output) { Remove-Item $Output -Recurse -Force }
Copy-Item $src $Output -Recurse -Force
Write-Host "Collected evidence to $Output"
EOF_COLLECT

(
  cd "$PAYLOAD"
  find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt
  sha256sum -c PAYLOAD-SHA256SUMS.txt
)

cat > "$OUT/P2C-PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_TOP
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2C_INPUT_FRONTEND
PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1
PHYSICAL_BRANCH_HEAD=$PHYSICAL_HEAD
HOST_MODULE_CHECKPOINT=$HOST_CHECKPOINT
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
P2C_PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM
P2C_INPUT_NATIVE_SHA256=$EXPECTED_INPUT
P2C_FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
P2C_VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
P2C_AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
EXERCISER_SHA256=$EX_SHA
LOGICAL_RESOLUTION=176x208
PHASE_COUNT=3
HOST_MODULE_GATE=PASS
PHYSICAL_PACKAGE_GATE=PASS
PHYSICAL_TEST_LEVEL=MODULE
RUNTIME_SEMANTIC_DELTA=NONE
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
EOF_TOP

rm -f "$ZIP"
(
  cd "$OUT"
  zip -qr "$(basename "$ZIP")" "$(basename "$PKGROOT")"
)
ZIP_SHA="$(sha256sum "$ZIP" | awk '{print $1}')"
echo "PHYSICAL_ZIP_SHA256=$ZIP_SHA" >> "$OUT/P2C-PHYSICAL-PACKAGE-IDENTITY.txt"
echo "P2C_PHYSICAL_PACKAGE_ZIP_SHA256=$ZIP_SHA"
echo P2C_PHYSICAL_PACKAGE_BUILD=PASS
echo P2C_PHYSICAL_TEST=NOT_TESTED
echo RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
echo STABLE=NO
