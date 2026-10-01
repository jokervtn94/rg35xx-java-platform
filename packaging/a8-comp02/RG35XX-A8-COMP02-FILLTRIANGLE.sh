#!/bin/sh
# Physical original-RG35XX test launcher for the scoped A8 COMP-02 candidate.
# This is NOT a production launcher and never claims DEVICE-PASS automatically.
DEVICE_PASS=NO_PENDING_PHYSICAL_REVIEW

APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-A8-COMP02-FILLTRIANGLE"
OUT=/mnt/mmc/RG35XX-A8-COMP02-FILLTRIANGLE-RESULT.txt
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=__CANDIDATE_PLATFORM_SHA__
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
EXPECTED_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"

: >"$OUT"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=A8-COMP02-GRAPHICS-FILLTRIANGLE-BOUNDARY-ONLY-PHYSICAL-TEST' >>"$OUT"
echo 'PRODUCTION_PARENT=A8_GOLDEN_ONLY' >>"$OUT"
echo 'FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY' >>"$OUT"
echo "DEVICE_PASS=$DEVICE_PASS" >>"$OUT"

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
echo 'PHYSICAL_REVIEW_REQUIRED=TARGET_FILLTRIANGLE_POINT+DISPLAY+INPUT+GAMEPLAY+HANG+EXIT+AUDIO_WHEN_APPLICABLE' >>"$OUT"
echo "DEVICE_PASS=$DEVICE_PASS" >>"$OUT"
sync
exit "$RC"
