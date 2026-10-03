#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2B_PHYSICAL_PACKAGE_BUILD_FAIL=$*" >&2; exit 1; }

OUT="$ROOT/out/p2b-font-text-candidate-r1"
P2A_OUT="$ROOT/out/p2a-image-decode-candidate"
CAND="$OUT/freej2me-rg35xx.jar"
EX="$OUT/RG35XX-Platform-Exerciser-P2B-FontText.jar"
FONT_NATIVE="$OUT/librg35xx_font.so"
INPUT="$P2A_OUT/librg35xx_input.so"
VIDEO="$P2A_OUT/librg35xx_video.so"
AUDIO="$ROOT/out/p2b-protected-audio/libaudio.so"
CID="$OUT/P2B-FONT-TEXT-IDENTITY.txt"
EID="$OUT/P2B-FONT-TEXT-EXERCISER-IDENTITY.txt"
PKGROOT="$OUT/RG35XX-P2B-FONT-TEXT-PHYSICAL-R1"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P2B-FONT-TEXT"
ZIP="$OUT/RG35XX-P2B-FONT-TEXT-PHYSICAL-R1.zip"
PHYSICAL_HEAD="${GITHUB_SHA:-$(git rev-parse HEAD)}"
RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
CHECKPOINT=121ca5904b7d442161ed4639f30c5fe9f1c5772d
FONT_URL="https://github.com/aweigit/freej2me-miyoomini/releases/download/2.0/miyoomini-freej2me.zip"
FONT_SHA=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724
LICENSE_URL="https://hyperos.mi.com/font-download/MiSans%E5%AD%97%E4%BD%93%E7%9F%A5%E8%AF%86%E4%BA%A7%E6%9D%83%E8%AE%B8%E5%8F%AF%E5%8D%8F%E8%AE%AE.pdf"
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644

for f in "$CAND" "$EX" "$FONT_NATIVE" "$INPUT" "$VIDEO" "$AUDIO" "$CID" "$EID"; do
    [ -f "$f" ] || fail "missing $(basename "$f")"
done
grep -q '^P2B_MODULE_GATE=PASS$' "$CID" || fail p2b_module_gate
grep -q '^PROTECTED_HASHES=PASS$' "$CID" || fail protected_hash_gate
grep -q '^P2B_PHYSICAL_TEST=NOT_TESTED$' "$CID" || fail premature_physical_result
grep -q '^GAME_SPECIFIC_CODE=NO$' "$CID" || fail game_scope
grep -q '^A9_PARENT=NO$' "$CID" || fail a9_parent
grep -q '^METRIC_AND_RASTER_CASE_COUNT=360$' "$EID" || fail exerciser_case_count
grep -q '^DIRECT_RG35XXCORE2D_CALL=NO$' "$EID" || fail exerciser_owner_bypass
grep -q '^COMMERCIAL_GAME_CONTENT=NO$' "$EID" || fail exerciser_scope

PLATFORM_SHA="$(sha256sum "$CAND" | awk '{print $1}')"
EX_SHA="$(sha256sum "$EX" | awk '{print $1}')"
FONT_NATIVE_SHA="$(sha256sum "$FONT_NATIVE" | awk '{print $1}')"
[ "$(sha256sum "$INPUT" | awk '{print $1}')" = "$EXPECTED_INPUT" ] || fail input_hash
[ "$(sha256sum "$VIDEO" | awk '{print $1}')" = "$EXPECTED_VIDEO" ] || fail video_hash
[ "$(sha256sum "$AUDIO" | awk '{print $1}')" = "$EXPECTED_AUDIO" ] || fail audio_hash
grep -q "^EXERCISER_SHA256=$EX_SHA$" "$EID" || fail exerciser_hash_identity

WORK="$ROOT/build/p2b-physical-package"
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
python3 - "$PAYLOAD/licenses/MiSans-LICENSE.pdf" <<'PY'
import sys
p=sys.argv[1]
b=open(p,'rb').read(8)
if not b.startswith(b'%PDF-'): raise SystemExit('P2B_MISANS_LICENSE_PDF_GATE=FAIL')
print('P2B_MISANS_LICENSE_PDF_GATE=PASS')
PY
LICENSE_SHA="$(sha256sum "$PAYLOAD/licenses/MiSans-LICENSE.pdf" | awk '{print $1}')"
cat > "$PAYLOAD/NOTICE.txt" <<'EOF_NOTICE'
FreeJ2ME-RG35XX P2B Font/Text physical module package uses MiSans.

MiSans is provided/licensed by Xiaomi. The exact font file included in this
software package is used as an embedded runtime asset and is copied byte-for-byte
without modification, subsetting, conversion, re-encoding, or glyph changes.

See licenses/MiSans-LICENSE.pdf for the included official Xiaomi MiSans license
agreement. The font file is not intended for standalone redistribution.
EOF_NOTICE

cp "$CAND" "$EX" "$FONT_NATIVE" "$INPUT" "$VIDEO" "$AUDIO" "$CID" "$EID" "$PAYLOAD/"

cat > "$PAYLOAD/PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2B_FONT_TEXT
PACKAGE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1
PHYSICAL_BRANCH_HEAD=$PHYSICAL_HEAD
HOST_MODULE_CHECKPOINT=$CHECKPOINT
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
EXACT_ACCEPTED_P2A_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
CANDIDATE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
EXERCISER_SHA256=$EX_SHA
FONT_NATIVE_SHA256=$FONT_NATIVE_SHA
FONT_RELEASE_URL=$FONT_URL
FONT_RELEASE_ZIP_SHA256=$FONT_ZIP_SHA
FONT_ENTRY=$ENTRY
FONT_SHA256=$FONT_SHA
FONT_SIZE=$FONT_SIZE
FONT_EMBEDDED=YES
FONT_MODIFIED=NO
MISANS_LICENSE_SOURCE=$LICENSE_URL
MISANS_LICENSE_SHA256=$LICENSE_SHA
MISANS_NOTICE_PRESENT=YES
MISANS_LICENSE_PRESENT=YES
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
HOST_MODULE_GATE=PASS
PHYSICAL_TEST_LEVEL=MODULE
PHYSICAL_ACCEPTANCE_SURFACE=ONE_P2B_FONT_TEXT_EXERCISER
EXPECTED_DEVICE_CASES=360
CANONICAL_EXPECTED_SOURCE=PINNED_JDK8_AWT
PUBLIC_MIDP_ONLY=YES
RUNTIME_HASH_LOGGING=REQUIRED_AND_IMPLEMENTED_BY_LAUNCHER
EVIDENCE_DIRECTORY=/mnt/mmc/RG35XX-P2B-FONT-TEXT-EVIDENCE
NORMAL_RETURN_TO_GARLICOS=REQUIRED_MANUAL_OBSERVATION
HUMAN_PHYSICAL_OBSERVATION=FINAL_AUTHORITY
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
EOF_ID

cat > "$PKGROOT/SD/Roms/APPS/RG35XX-P2B-FONT-TEXT.sh" <<'EOF_LAUNCH'
#!/bin/sh
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-P2B-FONT-TEXT"
EVID=/mnt/mmc/RG35XX-P2B-FONT-TEXT-EVIDENCE
LOG="$EVID/P2B-FONT-TEXT-RUN.log"
SUMMARY="$EVID/P2B-FONT-TEXT-DEVICE-SUMMARY.txt"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=__P2B_PLATFORM_SHA256__
EXPECTED_EXERCISER=__P2B_EXERCISER_SHA256__
EXPECTED_FONT_NATIVE=__P2B_FONT_NATIVE_SHA256__
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
EXPECTED_FONT_SIZE=8092724
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830

rm -rf "$EVID"
mkdir -p "$EVID" || exit 20
: >"$LOG"
: >"$SUMMARY"
cat >>"$SUMMARY" <<EOF_SUMMARY
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2B_FONT_TEXT
PHYSICAL_TEST_LEVEL=MODULE
PHYSICAL_ACCEPTANCE_SURFACE=ONE_P2B_FONT_TEXT_EXERCISER
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
ORIGINAL_RG35XX_REQUIRED=YES
CANONICAL_EXPECTED_SOURCE=PINNED_JDK8_AWT
EXPECTED_CASE_COUNT=360
MANUAL_VISUAL_AUTHORITY=REQUIRED
P2B_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_SUMMARY

p2b_fail() {
    echo "P2B_DEVICE_PRECONDITION=FAIL:$1" >>"$LOG"
    echo "P2B_DEVICE_PRECONDITION=FAIL:$1" >>"$SUMMARY"
    echo 'P2B_DEVICE_PROGRAMMATIC_RESULT=FAIL' >>"$SUMMARY"
    echo 'P2B_PHYSICAL_TEST=NOT_TESTED' >>"$SUMMARY"
    echo 'DEVICE_PASS=NO' >>"$SUMMARY"
    echo 'RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO' >>"$SUMMARY"
    echo 'STABLE=NO' >>"$SUMMARY"
    sync
    exit 20
}

[ -x "$JAMVM" ] || p2b_fail JAMVM_MISSING
[ -f "$GLIBJ" ] || p2b_fail GLIBJ_MISSING
[ -d "$PKG" ] || p2b_fail PAYLOAD_DIR_MISSING
for F in freej2me-rg35xx.jar RG35XX-Platform-Exerciser-P2B-FontText.jar librg35xx_font.so font.ttf librg35xx_input.so librg35xx_video.so libaudio.so NOTICE.txt licenses/MiSans-LICENSE.pdf PAYLOAD-SHA256SUMS.txt P2B-FONT-TEXT-IDENTITY.txt P2B-FONT-TEXT-EXERCISER-IDENTITY.txt PHYSICAL-PACKAGE-IDENTITY.txt; do
    [ -f "$PKG/$F" ] || p2b_fail "MISSING:$F"
done
grep -q '^P2B_MODULE_GATE=PASS$' "$PKG/P2B-FONT-TEXT-IDENTITY.txt" || p2b_fail HOST_MODULE_GATE_NOT_PASS
grep -q '^PROTECTED_HASHES=PASS$' "$PKG/P2B-FONT-TEXT-IDENTITY.txt" || p2b_fail HOST_PROTECTED_HASH_GATE
grep -q '^P2B_PHYSICAL_TEST=NOT_TESTED$' "$PKG/P2B-FONT-TEXT-IDENTITY.txt" || p2b_fail PREMATURE_PHYSICAL_RESULT
grep -q '^METRIC_AND_RASTER_CASE_COUNT=360$' "$PKG/P2B-FONT-TEXT-EXERCISER-IDENTITY.txt" || p2b_fail EXERCISER_CASE_COUNT
grep -q '^DIRECT_RG35XXCORE2D_CALL=NO$' "$PKG/P2B-FONT-TEXT-EXERCISER-IDENTITY.txt" || p2b_fail DIRECT_BACKEND_CALL
grep -q '^FONT_EMBEDDED=YES$' "$PKG/PHYSICAL-PACKAGE-IDENTITY.txt" || p2b_fail FONT_NOT_EMBEDDED
grep -q '^FONT_MODIFIED=NO$' "$PKG/PHYSICAL-PACKAGE-IDENTITY.txt" || p2b_fail FONT_MODIFIED
grep -q '^MISANS_NOTICE_PRESENT=YES$' "$PKG/PHYSICAL-PACKAGE-IDENTITY.txt" || p2b_fail NOTICE_MISSING
grep -q '^MISANS_LICENSE_PRESENT=YES$' "$PKG/PHYSICAL-PACKAGE-IDENTITY.txt" || p2b_fail LICENSE_MISSING
head -c 5 "$PKG/licenses/MiSans-LICENSE.pdf" | grep -q '%PDF-' || p2b_fail LICENSE_NOT_PDF

JB=$(sha256sum "$JAMVM" | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" | awk '{print $1}')
PB=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')
EB=$(sha256sum "$PKG/RG35XX-Platform-Exerciser-P2B-FontText.jar" | awk '{print $1}')
FB=$(sha256sum "$PKG/font.ttf" | awk '{print $1}')
NB=$(sha256sum "$PKG/librg35xx_font.so" | awk '{print $1}')
IB=$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')
VB=$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')
AB=$(sha256sum "$PKG/libaudio.so" | awk '{print $1}')
for V in "JAMVM_SHA256_BEFORE=$JB" "GLIBJ_SHA256_BEFORE=$GB" "PLATFORM_JAR_SHA256_BEFORE=$PB" "EXERCISER_SHA256_BEFORE=$EB" "FONT_SHA256_BEFORE=$FB" "FONT_NATIVE_SHA256_BEFORE=$NB" "INPUT_NATIVE_SHA256_BEFORE=$IB" "VIDEO_NATIVE_SHA256_BEFORE=$VB" "AUDIO_NATIVE_SHA256_BEFORE=$AB"; do echo "$V" >>"$LOG"; done
[ "$JB" = "$EXPECTED_JAMVM" ] || p2b_fail JAMVM_HASH_MISMATCH
[ "$GB" = "$EXPECTED_GLIBJ" ] || p2b_fail GLIBJ_HASH_MISMATCH
[ "$PB" = "$EXPECTED_PLATFORM" ] || p2b_fail PLATFORM_HASH_MISMATCH
[ "$EB" = "$EXPECTED_EXERCISER" ] || p2b_fail EXERCISER_HASH_MISMATCH
[ "$FB" = "$EXPECTED_FONT" ] || p2b_fail FONT_HASH_MISMATCH
[ "$(wc -c < "$PKG/font.ttf" | tr -d ' ')" = "$EXPECTED_FONT_SIZE" ] || p2b_fail FONT_SIZE_MISMATCH
[ "$NB" = "$EXPECTED_FONT_NATIVE" ] || p2b_fail FONT_NATIVE_HASH_MISMATCH
[ "$IB" = "$EXPECTED_INPUT" ] || p2b_fail INPUT_HASH_MISMATCH
[ "$VB" = "$EXPECTED_VIDEO" ] || p2b_fail VIDEO_HASH_MISMATCH
[ "$AB" = "$EXPECTED_AUDIO" ] || p2b_fail AUDIO_HASH_MISMATCH
(
    cd "$PKG" || exit 1
    sha256sum -c PAYLOAD-SHA256SUMS.txt
) >>"$LOG" 2>&1 || p2b_fail PAYLOAD_HASH_MISMATCH
echo 'P2B_RUNTIME_HASH_GATE_BEFORE=PASS' >>"$LOG"

for F in PAYLOAD-SHA256SUMS.txt P2B-FONT-TEXT-IDENTITY.txt P2B-FONT-TEXT-EXERCISER-IDENTITY.txt PHYSICAL-PACKAGE-IDENTITY.txt NOTICE.txt; do
    cp "$PKG/$F" "$EVID/" || p2b_fail EVIDENCE_COPY_FAIL
done
cat >"$EVID/MANUAL-OBSERVATION.txt" <<'EOF_MANUAL'
P2B_FONT_TEXT_MANUAL_OBSERVATION=NOT_TESTED
EXPECTED_SCREEN_TITLE=P2B FONT/TEXT
EXPECTED_RESULT=PASS
EXPECTED_CASES=360
EXPECTED_BACKGROUND=GREEN_ON_PASS
EXPECTED_FAILURE_INDICATOR=NONE
EXPECTED_EXIT_ACTION=PRESS_ANY_KEY_AFTER_PASS_REVIEW
EXPECTED_RETURN=GARLICOS_MENU
HUMAN_PHYSICAL_OBSERVATION=FINAL_AUTHORITY
P2B_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_MANUAL

DATA="$EVID/data"
RMS="$EVID/rms"
mkdir -p "$DATA" "$RMS" || p2b_fail DATA_DIR_CREATE_FAIL
echo 'P2B_DEVICE_RUN=START' >>"$LOG"
echo 'P2B_VISUAL_EXPECTATION=P2B_FONT_TEXT_PASS_360_CASES_GREEN_SCREEN' >>"$LOG"
echo 'P2B_EXIT_EXPECTATION=PRESS_ANY_KEY_AFTER_PASS_THEN_RETURN_TO_GARLICOS' >>"$LOG"
(
    cd "$PKG" || exit 20
    LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$JAMVM" -Xmx64m -Drg35xx.raw2d=true -Drg35xx.native.dir="$PKG" \
        -Drg35xx.font.path="$PKG/font.ttf" -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
        -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher \
        "$PKG/RG35XX-Platform-Exerciser-P2B-FontText.jar" 640 480 "$DATA" "$RMS"
) >>"$LOG" 2>&1
RC=$?
echo "P2B_RUNTIME_EXIT_CODE=$RC" >>"$LOG"

JA=$(sha256sum "$JAMVM" | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" | awk '{print $1}')
PA=$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')
EA=$(sha256sum "$PKG/RG35XX-Platform-Exerciser-P2B-FontText.jar" | awk '{print $1}')
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
[ "$JA" = "$EXPECTED_JAMVM" ] || HASH_RESULT=FAIL
[ "$GA" = "$EXPECTED_GLIBJ" ] || HASH_RESULT=FAIL
[ "$PA" = "$EXPECTED_PLATFORM" ] || HASH_RESULT=FAIL
[ "$EA" = "$EXPECTED_EXERCISER" ] || HASH_RESULT=FAIL
[ "$FA" = "$EXPECTED_FONT" ] || HASH_RESULT=FAIL
[ "$NA" = "$EXPECTED_FONT_NATIVE" ] || HASH_RESULT=FAIL
[ "$IA" = "$EXPECTED_INPUT" ] || HASH_RESULT=FAIL
[ "$VA" = "$EXPECTED_VIDEO" ] || HASH_RESULT=FAIL
[ "$AA" = "$EXPECTED_AUDIO" ] || HASH_RESULT=FAIL
echo "P2B_PROTECTED_HASHES=$HASH_RESULT" >>"$LOG"
if [ "$RC" -eq 0 ]; then echo 'P2B_NORMAL_EXIT=PASS' >>"$LOG"; else echo 'P2B_NORMAL_EXIT=FAIL' >>"$LOG"; fi

PROGRAMMATIC=PASS
[ "$RC" -eq 0 ] || PROGRAMMATIC=FAIL
[ "$HASH_RESULT" = PASS ] || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_BOOT=PASS$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_EXPECTED_TABLE=PASS$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_CASE_COUNT=360$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_FAILURE_COUNT=0$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_RESULT=PASS$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^P2B_EXERCISER_EXIT_REQUEST=PASS$' "$LOG" || PROGRAMMATIC=FAIL
[ "$(grep -c 'P2B_EXERCISER_CASE=.* RESULT=PASS ' "$LOG")" -eq 360 ] || PROGRAMMATIC=FAIL
if grep -q 'P2B_EXERCISER_CASE=.* RESULT=FAIL ' "$LOG"; then PROGRAMMATIC=FAIL; fi
grep -q '^RG35XX_A3_SDL_DRIVER=fbcon$' "$LOG" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_A3_SURFACE=640x480 ' "$LOG" || PROGRAMMATIC=FAIL
echo "P2B_DEVICE_PROGRAMMATIC_RESULT=$PROGRAMMATIC" >>"$LOG"

cat >>"$SUMMARY" <<EOF_RESULT
P2B_RUNTIME_EXIT_CODE=$RC
P2B_PROTECTED_HASHES=$HASH_RESULT
P2B_DEVICE_PROGRAMMATIC_RESULT=$PROGRAMMATIC
P2B_FONT_TEXT_MANUAL_OBSERVATION=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_RESULT
if [ "$RC" -eq 0 ]; then echo 'P2B_NORMAL_EXIT=PASS' >>"$SUMMARY"; else echo 'P2B_NORMAL_EXIT=FAIL' >>"$SUMMARY"; fi
sync
[ "$PROGRAMMATIC" = PASS ] && exit 0
exit 2
EOF_LAUNCH

python3 - "$PKGROOT/SD/Roms/APPS/RG35XX-P2B-FONT-TEXT.sh" "$PLATFORM_SHA" "$EX_SHA" "$FONT_NATIVE_SHA" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(encoding='utf-8')
for old,new in [
    ('__P2B_PLATFORM_SHA256__',sys.argv[2]),
    ('__P2B_EXERCISER_SHA256__',sys.argv[3]),
    ('__P2B_FONT_NATIVE_SHA256__',sys.argv[4]),
]:
    if s.count(old)!=1: raise SystemExit('P2B_LAUNCHER_PLACEHOLDER_FAIL '+old)
    s=s.replace(old,new)
if '__P2B_' in s: raise SystemExit('P2B_LAUNCHER_PLACEHOLDER_REMAINS')
p.write_text(s,encoding='utf-8')
PY
chmod +x "$PKGROOT/SD/Roms/APPS/RG35XX-P2B-FONT-TEXT.sh"

cat > "$PKGROOT/README-FIRST.txt" <<EOF_README
RG35XX P2B FONT/TEXT PHYSICAL MODULE R1
========================================

Status before hardware test:
  P2B host/module gate: PASS
  P2B physical test: NOT_TESTED
  Full platform device baseline: NO
  Stable: NO

Runtime candidate:
  $RUNTIME_CANDIDATE

This package tests only the P2B Font/Text module on an ORIGINAL RG35XX.
It embeds the exact hash-locked MiSans runtime asset inside the application
payload, together with the official Xiaomi MiSans license and NOTICE.

Install:
  Copy the contents of SD/ to the root of the RG35XX SD card, preserving paths.
  Then launch RG35XX-P2B-FONT-TEXT from GarlicOS Apps.

Expected:
  - title: P2B FONT/TEXT
  - test completes 360 cases
  - green PASS screen
  - press any key only after PASS review
  - normal return to GarlicOS menu

Evidence is written to:
  /mnt/mmc/RG35XX-P2B-FONT-TEXT-EVIDENCE

Do not call this module/device PASS until the evidence directory and human
screen/normal-return observation have been reviewed.
EOF_README

cat > "$PKGROOT/INSTALL-RG35XX-P2B-FONT-TEXT.ps1" <<'EOF_PS1'
param([Parameter(Mandatory=$true)][string]$SdRoot)
$ErrorActionPreference = "Stop"
$src = Join-Path $PSScriptRoot "SD"
if (-not (Test-Path $src)) { throw "SD payload missing: $src" }
$dst = (Resolve-Path $SdRoot).Path
Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force
Write-Host "Installed RG35XX P2B Font/Text physical module package to $dst"
EOF_PS1

cat > "$PKGROOT/COLLECT-RG35XX-P2B-FONT-TEXT-EVIDENCE.ps1" <<'EOF_COLLECT'
param(
  [Parameter(Mandatory=$true)][string]$SdRoot,
  [string]$Output = (Join-Path $PSScriptRoot "RG35XX-P2B-FONT-TEXT-EVIDENCE")
)
$ErrorActionPreference = "Stop"
$src = Join-Path (Resolve-Path $SdRoot).Path "RG35XX-P2B-FONT-TEXT-EVIDENCE"
if (-not (Test-Path $src)) { throw "Evidence directory missing: $src" }
if (Test-Path $Output) { Remove-Item $Output -Recurse -Force }
Copy-Item $src $Output -Recurse -Force
Write-Host "Collected evidence to $Output"
EOF_COLLECT

(
    cd "$PAYLOAD"
    sha256sum \
      freej2me-rg35xx.jar \
      RG35XX-Platform-Exerciser-P2B-FontText.jar \
      librg35xx_font.so font.ttf \
      librg35xx_input.so librg35xx_video.so libaudio.so \
      P2B-FONT-TEXT-IDENTITY.txt \
      P2B-FONT-TEXT-EXERCISER-IDENTITY.txt \
      NOTICE.txt licenses/MiSans-LICENSE.pdf \
      PHYSICAL-PACKAGE-IDENTITY.txt > PAYLOAD-SHA256SUMS.txt
)

python3 - "$PKGROOT" "$ZIP" <<'PY'
import os,sys,zipfile
root,out=sys.argv[1:]
base=os.path.dirname(root)
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for dp,ds,fs in os.walk(root):
        ds.sort(); fs.sort()
        for f in fs:
            p=os.path.join(dp,f)
            z.write(p,os.path.relpath(p,base))
PY

ZIP_SHA="$(sha256sum "$ZIP" | awk '{print $1}')"
cat > "$OUT/P2B-PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_OUT
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2B_FONT_TEXT
PACKAGE_FILE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1.zip
PACKAGE_SHA256=$ZIP_SHA
PHYSICAL_BRANCH_HEAD=$PHYSICAL_HEAD
HOST_MODULE_CHECKPOINT=$CHECKPOINT
RUNTIME_CANDIDATE_COMMIT=$RUNTIME_CANDIDATE
CANDIDATE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
EXERCISER_SHA256=$EX_SHA
FONT_NATIVE_SHA256=$FONT_NATIVE_SHA
FONT_SHA256=$FONT_SHA
FONT_SIZE=$FONT_SIZE
FONT_RELEASE_ZIP_SHA256=$FONT_ZIP_SHA
MISANS_LICENSE_SHA256=$LICENSE_SHA
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
HOST_MODULE_GATE=PASS
PHYSICAL_PACKAGE_GATE=PASS
FONT_PROVISIONING_GATE=PASS
P2B_PHYSICAL_TEST=NOT_TESTED
HUMAN_PHYSICAL_OBSERVATION=REQUIRED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
EOF_OUT
echo "P2B_PHYSICAL_PACKAGE_SHA256=$ZIP_SHA"
echo P2B_PHYSICAL_PACKAGE_BUILD=PASS
cat "$OUT/P2B-PHYSICAL-PACKAGE-IDENTITY.txt"
