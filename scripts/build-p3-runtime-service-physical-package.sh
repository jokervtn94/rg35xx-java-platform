#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P3_PHYSICAL_PACKAGE_BUILD_FAIL=$*" >&2; exit 1; }

BASE="${P3_BASE_PAYLOAD:-$ROOT/out/p3-base-payload}"
EXERCISER="$ROOT/out/p3-runtime-service-exerciser/RG35XX-Platform-Exerciser-P3-RuntimeService.jar"
OUT="$ROOT/out/p3-runtime-service-physical"
PKGROOT="$OUT/RG35XX-P3-RUNTIME-SERVICE-PHYSICAL-R1"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P3-RUNTIME-SERVICE"
ZIP="$OUT/RG35XX-P3-RUNTIME-SERVICE-PHYSICAL-R1.zip"

EXPECTED_PLATFORM="${P3_EXPECTED_PLATFORM:-b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117}"
EXPECTED_INPUT="6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c"
EXPECTED_FONT_NATIVE="29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
EXPECTED_VIDEO="c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
EXPECTED_AUDIO="4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644"
EXPECTED_FONT="1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10"

for file in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so librg35xx_font.so libaudio.so font.ttf; do
  [ -f "$BASE/$file" ] || fail "base-missing:$file"
done
[ -f "$EXERCISER" ] || fail exerciser_missing

test "$(sha256sum "$BASE/freej2me-rg35xx.jar" | awk '{print $1}')" = "$EXPECTED_PLATFORM" || fail platform_hash
test "$(sha256sum "$BASE/librg35xx_input.so" | awk '{print $1}')" = "$EXPECTED_INPUT" || fail input_hash
test "$(sha256sum "$BASE/librg35xx_video.so" | awk '{print $1}')" = "$EXPECTED_VIDEO" || fail video_hash
test "$(sha256sum "$BASE/librg35xx_font.so" | awk '{print $1}')" = "$EXPECTED_FONT_NATIVE" || fail font_native_hash
test "$(sha256sum "$BASE/libaudio.so" | awk '{print $1}')" = "$EXPECTED_AUDIO" || fail audio_hash
test "$(sha256sum "$BASE/font.ttf" | awk '{print $1}')" = "$EXPECTED_FONT" || fail font_hash

rm -rf "$OUT"
mkdir -p "$PAYLOAD"
for file in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so librg35xx_font.so libaudio.so font.ttf; do
  cp "$BASE/$file" "$PAYLOAD/$file"
done
if [ -d "$BASE/licenses" ]; then cp -a "$BASE/licenses" "$PAYLOAD/"; fi
if [ -f "$BASE/NOTICE.txt" ]; then cp "$BASE/NOTICE.txt" "$PAYLOAD/"; fi
cp "$EXERCISER" "$PAYLOAD/"

P3_SHA="$(sha256sum "$PAYLOAD/$(basename "$EXERCISER")" | awk '{print $1}')"
cat > "$PAYLOAD/P3-RUNTIME-SERVICE-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P3_RUNTIME_SERVICE_MODULES
PACKAGE=RG35XX-P3-RUNTIME-SERVICE-PHYSICAL-R1
P2C_PARENT_PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R11
P2C_PARENT_PLATFORM_SHA256=$EXPECTED_PLATFORM
P2C_PARENT_INPUT_SHA256=$EXPECTED_INPUT
P2C_PARENT_VIDEO_SHA256=$EXPECTED_VIDEO
P2C_PARENT_FONT_NATIVE_SHA256=$EXPECTED_FONT_NATIVE
P2C_PARENT_AUDIO_SHA256=$EXPECTED_AUDIO
P2C_PARENT_FONT_SHA256=$EXPECTED_FONT
P3_EXERCISER_SHA256=$P3_SHA
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
LOGICAL_RESOLUTION=176x208
P3_SCOPE=LIFECYCLE,RMS,FILECONNECTION,WAV,MIDI
P2C_PHYSICAL_ACCEPTANCE=PASS
P3_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
EOF_ID

cat > "$PKGROOT/SD/Roms/APPS/RG35XX-P3-RUNTIME-SERVICE.sh" <<'EOF_LAUNCH'
#!/bin/sh
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-P3-RUNTIME-SERVICE"
EVID=/mnt/mmc/RG35XX-P3-RUNTIME-SERVICE-EVIDENCE
MASTER="$EVID/P3-RUNTIME-SERVICE-RUN.log"
SUMMARY="$EVID/P3-RUNTIME-SERVICE-DEVICE-SUMMARY.txt"
DATA="$EVID/data"
RMS="$EVID/rms"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117
EXPECTED_INPUT=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_FONT_NATIVE=29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b
EXPECTED_FONT=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
EXERCISER="$PKG/RG35XX-Platform-Exerciser-P3-RuntimeService.jar"

mkdir -p "$DATA" "$RMS" || exit 20
: > "$MASTER"
cat > "$SUMMARY" <<'EOF_SUMMARY'
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P3_RUNTIME_SERVICE_MODULES
PHYSICAL_TEST_LEVEL=MODULE
ORIGINAL_RG35XX_REQUIRED=YES
LOGICAL_RESOLUTION=176x208
P3_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
EOF_SUMMARY

fail(){ echo "P3_DEVICE_RESULT=FAIL:$1" >> "$MASTER"; echo "P3_DEVICE_RESULT=FAIL:$1" >> "$SUMMARY"; sync; exit 20; }
for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so librg35xx_font.so libaudio.so font.ttf P3-RUNTIME-SERVICE-IDENTITY.txt; do
  [ -f "$PKG/$f" ] || fail "MISSING:$f"
done
[ -f "$EXERCISER" ] || fail "MISSING:$EXERCISER"
[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING

hashcheck(){ test "$(sha256sum "$1" | awk '{print $1}')" = "$2" || fail "HASH:$1"; }
hashcheck "$JAMVM" "$EXPECTED_JAMVM"
hashcheck "$GLIBJ" "$EXPECTED_GLIBJ"
hashcheck "$PKG/freej2me-rg35xx.jar" "$EXPECTED_PLATFORM"
hashcheck "$PKG/librg35xx_input.so" "$EXPECTED_INPUT"
hashcheck "$PKG/librg35xx_video.so" "$EXPECTED_VIDEO"
hashcheck "$PKG/librg35xx_font.so" "$EXPECTED_FONT_NATIVE"
hashcheck "$PKG/libaudio.so" "$EXPECTED_AUDIO"
hashcheck "$PKG/font.ttf" "$EXPECTED_FONT"
echo P3_RUNTIME_HASH_GATE_BEFORE=PASS >> "$MASTER"

set +e
LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$JAMVM" -Xmx64m -Drg35xx.raw2d=true \
  -Drg35xx.native.dir="$PKG" -Drg35xx.font.path="$PKG/font.ttf" \
  -Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
  -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher \
  "$EXERCISER" 176 208 "$DATA" "$RMS" > "$EVID/P3-RUNTIME-SERVICE.log" 2>&1
RC=$?
set -e
cat "$EVID/P3-RUNTIME-SERVICE.log" >> "$MASTER"
[ "$RC" -eq 0 ] || fail "JVM_EXIT:$RC"
for marker in \
  P3_RUNTIME_SERVICE_RESULT=PASS \
  P3_TEST_NORMAL_EXIT=BEGIN \
  P3_RMS_CRUD_ENUMERATE=PASS \
  P3_RMS_REOPEN_DELETE=PASS \
  P3_FILE_CREATE_WRITE_READ_DELETE=PASS \
  P3_MMAPI_WAV_START=PASS \
  P3_MMAPI_WAV_PAUSE_RESUME=PASS \
  P3_MMAPI_MIDI_START=PASS \
  P3_MMAPI_MIDI_END_OF_MEDIA=PASS \
  P3_AUDIO_AUDIBLE_REVIEW=REQUIRED_MANUAL; do
  grep -q "^$marker$" "$EVID/P3-RUNTIME-SERVICE.log" || fail "MARKER:$marker"
done
echo P3_DEVICE_PROGRAMMATIC_RESULT=PASS >> "$MASTER"
echo P3_AUDIO_AUDIBLE_DEVICE=REQUIRED_MANUAL >> "$MASTER"
echo P3_PHYSICAL_TEST=NOT_TESTED >> "$MASTER"
sync
EOF_LAUNCH
chmod +x "$PKGROOT/SD/Roms/APPS/RG35XX-P3-RUNTIME-SERVICE.sh"

(cd "$PAYLOAD" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PAYLOAD-SHA256SUMS.txt && sha256sum -c PAYLOAD-SHA256SUMS.txt)
cat > "$PKGROOT/README-FIRST.txt" <<'EOF_README'
RG35XX P3 Runtime Service Module test package.

Copy SD/ to the original RG35XX GarlicOS SD card and run:
RG35XX-P3-RUNTIME-SERVICE

Logs are written to:
/mnt/mmc/RG35XX-P3-RUNTIME-SERVICE-EVIDENCE/

This package is not a baseline promotion. Audio still requires manual audible
observation; programmatic PASS alone is not physical audio acceptance.
EOF_README
mkdir -p "$PKGROOT"
cat > "$PKGROOT/P3-PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_PACKAGE
PROJECT=RG35XX-AWEIGIT-R1
PACKAGE=RG35XX-P3-RUNTIME-SERVICE-PHYSICAL-R1
P2C_PARENT_PHYSICAL_ACCEPTANCE=PASS
P3_EXERCISER_SHA256=$P3_SHA
P3_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_PACKAGE

rm -f "$ZIP"
(cd "$OUT" && zip -qr "$(basename "$ZIP")" "$(basename "$PKGROOT")")
echo P3_PHYSICAL_PACKAGE_BUILD=PASS
echo P3_PHYSICAL_PACKAGE="$ZIP"
echo P3_PHYSICAL_TEST=NOT_TESTED
