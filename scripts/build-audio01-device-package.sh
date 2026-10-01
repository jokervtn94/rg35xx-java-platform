#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/out/audio01-lifecycle-trace"
OUT="$ROOT/out/audio01-device-package"
APPS="$OUT/Roms/APPS"
PKG="$APPS/RG35XX-AUDIO01-GOW-TRACE"
LAUNCHER="$APPS/AUDIO01-GOW-LIFECYCLE-TRACE-TEST.sh"
fail(){ echo "AUDIO01_PACKAGE_FAIL=$*" >&2; exit 1; }

for f in librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le AUDIO01-IDENTITY.txt; do
  [ -f "$SRC/$f" ] || fail "missing $f"
done

grep -q '^STAGE=AUDIO01-LIFECYCLE-TRACE-ONLY$' "$SRC/AUDIO01-IDENTITY.txt" || fail IDENTITY_STAGE
grep -q '^DIAGNOSTIC_ONLY=YES$' "$SRC/AUDIO01-IDENTITY.txt" || fail IDENTITY_DIAGNOSTIC
TRACE_AUDIO_SHA="$(awk -F= '$1=="AUDIO_TRACE_SHA256"{print $2}' "$SRC/AUDIO01-IDENTITY.txt")"
[ -n "$TRACE_AUDIO_SHA" ] || fail TRACE_AUDIO_SHA_MISSING

rm -rf "$OUT"
mkdir -p "$PKG"
cp "$SRC/librg35xx_input.so" "$SRC/librg35xx_video.so" "$SRC/libaudio.so" \
   "$SRC/a7-a1p5-rw-silence-prime.s32le" "$SRC/AUDIO01-IDENTITY.txt" "$PKG/"

cat > "$PKG/RUNTIME-SHA256SUMS.txt" <<EOF
69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d  librg35xx_input.so
c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d  librg35xx_video.so
$TRACE_AUDIO_SHA  libaudio.so
8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e  a7-a1p5-rw-silence-prime.s32le
EOF
(cd "$PKG" && sha256sum -c RUNTIME-SHA256SUMS.txt)

cat > "$LAUNCHER" <<'EOF'
#!/bin/sh
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-AUDIO01-GOW-TRACE"
BASEPKG=/mnt/mmc/Roms/APPS/RG35XX-A8-COMP02-FILLTRIANGLE
BASEJAR="$BASEPKG/freej2me-rg35xx.jar"
GAME=/mnt/mmc/Roms/JAVA/God-of-War-Betrayal_J2ME_EN_v148.jar
EXPECTED_GAME=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=3c7b22c3227a65897137c210744be1bcc41f075fa0dfa580fdcee7e47734056b
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"
EVIDENCE_ROOT=/mnt/mmc/A8-COMPAT-EVIDENCE
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || true)
[ -n "$STAMP" ] || STAMP=NO-DATE
OUTDIR="$EVIDENCE_ROOT/AUDIO01-GOW-LIFECYCLE-TRACE-$STAMP"
mkdir -p "$OUTDIR" || exit 20
OUT="$OUTDIR/RUNTIME-RESULT.txt"
: >"$OUT"

fail() {
  echo "PRECONDITION=FAIL:$1" >>"$OUT"
  echo 'TECHNICAL_GATE=FAIL' >>"$OUT"
  echo 'DEVICE_PASS=NO' >>"$OUT"
  echo 'STABLE=NO' >>"$OUT"
  sync
  exit 20
}

[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING
[ -f "$BASEJAR" ] || fail EXACT_COMP02_PLATFORM_MISSING
[ -f "$GAME" ] || fail GOW_JAR_MISSING
[ -d "$PKG" ] || fail TRACE_PAYLOAD_MISSING
for F in librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le RUNTIME-SHA256SUMS.txt AUDIO01-IDENTITY.txt; do
  [ -f "$PKG/$F" ] || fail "MISSING:$F"
done

APLAY="$(command -v aplay 2>/dev/null || true)"
[ -n "$APLAY" ] && [ -x "$APLAY" ] || fail APLAY_MISSING

JB=$(sha256sum "$JAMVM"|awk '{print $1}')
GB=$(sha256sum "$GLIBJ"|awk '{print $1}')
PH=$(sha256sum "$BASEJAR"|awk '{print $1}')
IH=$(sha256sum "$PKG/librg35xx_input.so"|awk '{print $1}')
VH=$(sha256sum "$PKG/librg35xx_video.so"|awk '{print $1}')
AH=$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')
PRH=$(sha256sum "$PRIME"|awk '{print $1}')
GH=$(sha256sum "$GAME"|awk '{print $1}')
EXPECTED_AUDIO=$(awk -F= '$1=="AUDIO_TRACE_SHA256"{print $2}' "$PKG/AUDIO01-IDENTITY.txt")

{
  echo 'TEST_ID=AUDIO01-GOW-LIFECYCLE-TRACE'
  echo 'DEVICE=ORIGINAL_RG35XX'
  echo 'BASE=EXACT_PHYSICAL_COMP02_FILLTRIANGLE_DEVICE_PASS_JAR'
  echo 'FAILURE_OWNER=RG35XX_AUDIO_MEDIA'
  echo 'DIAGNOSTIC_ONLY=YES'
  echo 'JAVA_SOURCE=EXISTING_DEVICE_COMP02_EXACT'
  echo 'JAVA_CHANGED=NO'
  echo 'GRAPHICS_CHANGED=NO'
  echo 'INPUT_CHANGED=NO'
  echo 'VIDEO_CHANGED=NO'
  echo "BASE_PLATFORM_JAR=$BASEJAR"
  echo "PLATFORM_JAR_SHA256=$PH"
  echo "JAR_PATH=$GAME"
  echo "JAR_SHA256=$GH"
  echo "JAMVM_SHA256_BEFORE=$JB"
  echo "GLIBJ_SHA256_BEFORE=$GB"
  echo "INPUT_NATIVE_SHA256=$IH"
  echo "VIDEO_NATIVE_SHA256=$VH"
  echo "AUDIO_TRACE_SHA256=$AH"
  echo "PRIME_PCM_SHA256=$PRH"
  echo "TIMESTAMP=$STAMP"
} >"$OUTDIR/IDENTITY.txt"

cat >"$OUTDIR/OBSERVATION.txt" <<'OBS'
TEST_ID=AUDIO01-GOW-LIFECYCLE-TRACE
BOOT=NOT_TESTED
GRAPHICS=NOT_TESTED
INPUT=NOT_TESTED
GAMEPLAY=NOT_TESTED
MENU_AUDIO=NOT_TESTED
GAMEPLAY_INITIAL_AUDIO=NOT_TESTED
GAMEPLAY_AUDIO_AFTER_INITIAL=NOT_TESTED
AUDIO_DISAPPEAR_POINT=NOT_RECORDED
HANG_CRASH=NOT_TESTED
EXIT=NOT_TESTED
RESULT=NEEDS_REVIEW
NOTES=
OBS

[ "$JB" = "$EXPECTED_JAMVM" ] || fail JAMVM_HASH_MISMATCH
[ "$GB" = "$EXPECTED_GLIBJ" ] || fail GLIBJ_HASH_MISMATCH
[ "$PH" = "$EXPECTED_PLATFORM" ] || fail EXACT_COMP02_PLATFORM_HASH_MISMATCH
[ "$IH" = "$EXPECTED_INPUT" ] || fail INPUT_HASH_MISMATCH
[ "$VH" = "$EXPECTED_VIDEO" ] || fail VIDEO_HASH_MISMATCH
[ "$PRH" = "$EXPECTED_PRIME" ] || fail PRIME_HASH_MISMATCH
[ "$GH" = "$EXPECTED_GAME" ] || fail GAME_HASH_MISMATCH
[ -n "$EXPECTED_AUDIO" ] || fail TRACE_AUDIO_EXPECTED_MISSING
[ "$AH" = "$EXPECTED_AUDIO" ] || fail TRACE_AUDIO_HASH_MISMATCH
(cd "$PKG" && sha256sum -c RUNTIME-SHA256SUMS.txt) >>"$OUT" 2>&1 || fail TRACE_RUNTIME_HASH_MISMATCH

echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=AUDIO01-GOW-LIFECYCLE-TRACE-PHYSICAL' >>"$OUT"
echo 'IDENTITY_GATE=PASS' >>"$OUT"
export SDL_AUDIODRIVER=alsa

echo 'A1P5_RW_SILENCE_PRIME=BEGIN' >>"$OUT"
"$APLAY" -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 "$PRIME" >>"$OUT" 2>&1
PRC=$?
echo "A1P5_RW_SILENCE_PRIME_EXIT_CODE=$PRC" >>"$OUT"
[ "$PRC" -eq 0 ] || fail APLAY_PRIME_FAILED
echo 'A1P5_RW_SILENCE_PRIME=PASS' >>"$OUT"

DATA="$PKG/data-gow-trace-$STAMP"
mkdir -p "$DATA" || fail DATA_DIR_CREATE_FAIL
echo 'REAL_GAME_PROCESS=START' >>"$OUT"
LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$JAMVM" -Xmx64m -Drg35xx.raw2d=true -Drg35xx.native.dir="$PKG" \
  -cp "$GLIBJ:$BASEJAR" \
  org.recompile.rg35xx.RG35XXLauncher "$GAME" 240 320 "$DATA" "$DATA" >>"$OUT" 2>&1
RC=$?
echo "RUNTIME_EXIT_CODE=$RC" >>"$OUT"

JA=$(sha256sum "$JAMVM"|awk '{print $1}')
GA=$(sha256sum "$GLIBJ"|awk '{print $1}')
echo "JAMVM_SHA256_AFTER=$JA" >>"$OUT"
echo "GLIBJ_SHA256_AFTER=$GA" >>"$OUT"
if [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
  echo 'PROTECTED_HASHES=PASS' >>"$OUT"
else
  echo 'PROTECTED_HASHES=FAIL' >>"$OUT"
fi
[ "$RC" -eq 0 ] && echo 'NORMAL_EXIT=PASS' >>"$OUT" || echo 'NORMAL_EXIT=FAIL' >>"$OUT"
echo 'ROOT_CAUSE=NOT_YET_PROVEN' >>"$OUT"
echo 'DEVICE_PASS=NO_DIAGNOSTIC_ONLY' >>"$OUT"
echo 'STABLE=NO' >>"$OUT"
echo "WRAPPER_EXIT_CODE=$RC" >>"$OUTDIR/IDENTITY.txt"
echo "EVIDENCE_DIR=$OUTDIR" >>"$OUTDIR/IDENTITY.txt"
sync
exit "$RC"
EOF
chmod +x "$LAUNCHER"

cat > "$OUT/README-FIRST.txt" <<'EOF'
AUDIO-01 GOW LIFECYCLE TRACE - DIAGNOSTIC ONLY
===============================================

Dieu kien bat buoc tren SD:
- /mnt/mmc/Roms/APPS/RG35XX-A8-COMP02-FILLTRIANGLE/freej2me-rg35xx.jar
  SHA256=3c7b22c3227a65897137c210744be1bcc41f075fa0dfa580fdcee7e47734056b
- /mnt/mmc/Roms/JAVA/God-of-War-Betrayal_J2ME_EN_v148.jar
  SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98

1. Merge thu muc Roms vao root SD.
2. GarlicOS -> APPS -> AUDIO01-GOW-LIFECYCLE-TRACE-TEST
3. Vao gameplay den sau diem audio bien mat, choi them mot luc roi thoat binh thuong.
4. Gui evidence:
   /mnt/mmc/A8-COMPAT-EVIDENCE/AUDIO01-GOW-LIFECYCLE-TRACE-<timestamp>/

Diagnostic chi thay libaudio.so bang trace build; Java la EXACT COMP-02 JAR dang co tren SD.
Khong phai ban fix.
EOF

cat > "$OUT/PACKAGE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=AUDIO01-GOW-LIFECYCLE-TRACE-DEVICE-PACKAGE
BASE_COMMIT=e373f3b59423aa7aec5deee8563f0b5ff3a191cb
FAILURE_OWNER=RG35XX_AUDIO_MEDIA
JAVA_SOURCE=EXISTING_DEVICE_COMP02_EXACT
REQUIRED_DEVICE_PLATFORM_JAR_SHA256=3c7b22c3227a65897137c210744be1bcc41f075fa0dfa580fdcee7e47734056b
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_TRACE_SHA256=$TRACE_AUDIO_SHA
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
GOW_SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
PLATFORM_JAR_BUNDLED=NO
GAME_BUNDLED=NO
DIAGNOSTIC_ONLY=YES
DEVICE_PASS=NO
STABLE=NO
EOF

(cd "$OUT" && find . -type f ! -name PACKAGE-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$OUT/PACKAGE-SHA256SUMS.txt"
(cd "$OUT" && sha256sum -c PACKAGE-SHA256SUMS.txt)
echo AUDIO01_DEVICE_PACKAGE=PASS
