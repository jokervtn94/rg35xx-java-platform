#!/bin/sh
OUT=/mnt/mmc/RG35XX-AWEIGIT-R1-A7-REGRESSION-VUA-A1P5-RESULT.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-AWEIGIT-R1-A7-PARENT-REGRESSION-A1P5"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
PRIME="$PKG/a7-a1p5-rw-silence-prime.s32le"
fail() {
  echo "PRECONDITION=FAIL:$1" >>"$OUT"
  echo "TECHNICAL_GATE=FAIL" >>"$OUT"
  echo "DEVICE_PASS=NO" >>"$OUT"
  echo "STABLE=NO" >>"$OUT"
  sync
  exit 20
}
[ -x "$JAMVM" ] || fail JAMVM_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_MISSING
[ -d "$PKG" ] || fail PAYLOAD_MISSING
for F in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le RUNTIME-SHA256SUMS.txt; do [ -f "$PKG/$F" ] || fail "MISSING:$F"; done
APLAY="$(command -v aplay 2>/dev/null || true)"
[ -n "$APLAY" ] && [ -x "$APLAY" ] || fail APLAY_MISSING
JB=$(sha256sum "$JAMVM"|awk '{print $1}'); GB=$(sha256sum "$GLIBJ"|awk '{print $1}')
PH=$(sha256sum "$PKG/freej2me-rg35xx.jar"|awk '{print $1}')
IH=$(sha256sum "$PKG/librg35xx_input.so"|awk '{print $1}')
VH=$(sha256sum "$PKG/librg35xx_video.so"|awk '{print $1}')
AH=$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')
echo "JAMVM_SHA256_BEFORE=$JB" >>"$OUT"; echo "GLIBJ_SHA256_BEFORE=$GB" >>"$OUT"
echo "PLATFORM_JAR_SHA256=$PH" >>"$OUT"; echo "INPUT_NATIVE_SHA256=$IH" >>"$OUT"; echo "VIDEO_NATIVE_SHA256=$VH" >>"$OUT"; echo "AUDIO_NATIVE_SHA256=$AH" >>"$OUT"
[ "$JB" = "$EXPECTED_JAMVM" ] || fail JAMVM_HASH_MISMATCH
[ "$GB" = "$EXPECTED_GLIBJ" ] || fail GLIBJ_HASH_MISMATCH
[ "$PH" = "$EXPECTED_PLATFORM" ] || fail PLATFORM_HASH_MISMATCH
[ "$IH" = "$EXPECTED_INPUT" ] || fail INPUT_HASH_MISMATCH
[ "$VH" = "$EXPECTED_VIDEO" ] || fail VIDEO_HASH_MISMATCH
[ "$AH" = "$EXPECTED_AUDIO" ] || fail AUDIO_HASH_MISMATCH
(cd "$PKG" && sha256sum -c RUNTIME-SHA256SUMS.txt) >>"$OUT" 2>&1 || fail RUNTIME_HASH_MISMATCH
export SDL_AUDIODRIVER=alsa
echo 'A1P5_RW_SILENCE_PRIME=BEGIN' >>"$OUT"
"$APLAY" -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 "$PRIME" >>"$OUT" 2>&1
PRC=$?
echo "A1P5_RW_SILENCE_PRIME_EXIT_CODE=$PRC" >>"$OUT"
[ "$PRC" -eq 0 ] || fail APLAY_PRIME_FAILED
echo 'A1P5_RW_SILENCE_PRIME=PASS' >>"$OUT"

GAME="$PKG/Vua-Cuop-Bien-240x320.jar"
EXPECTED_GAME=220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578
DATA="$PKG/data-vua"
: >"$OUT"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=A7-PARENT-REGRESSION-A1P5' >>"$OUT"
echo 'GAME_KEY=VUA_CUOP_BIEN' >>"$OUT"
echo 'GAME_FILE=Vua-Cuop-Bien-240x320.jar' >>"$OUT"
echo 'GAME_SHA256_EXPECTED=220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578' >>"$OUT"
echo 'SCOPE=BOOT,RENDER,INPUT,BASIC_GAMEPLAY,RMS_IF_EXERCISED,AUDIO_IF_PRESENT,NORMAL_EXIT' >>"$OUT"
echo 'EXCLUDED=SMS,HTTP,PAYMENT,NETWORK' >>"$OUT"
echo 'A1P5_DELTA=PREJAVA_APLAY_RW_INTERLEAVED_ZERO_PCM_350MS' >>"$OUT"
[ -f "$GAME" ] || fail GAME_MISSING
GH=$(sha256sum "$GAME"|awk '{print $1}')
echo "GAME_SHA256=$GH" >>"$OUT"
[ "$GH" = "$EXPECTED_GAME" ] || fail GAME_HASH_MISMATCH
mkdir -p "$DATA" || fail DATA_DIR_CREATE_FAIL
echo 'IDENTITY_GATE=PASS' >>"$OUT"
echo 'REAL_GAME_PROCESS=START' >>"$OUT"
LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$JAMVM" -Xmx64m -Drg35xx.raw2d=true -Drg35xx.native.dir="$PKG" -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher "$GAME" 240 320 "$DATA" "$DATA" >>"$OUT" 2>&1
RC=$?
echo "RUNTIME_EXIT_CODE=$RC" >>"$OUT"
JA=$(sha256sum "$JAMVM"|awk '{print $1}'); GA=$(sha256sum "$GLIBJ"|awk '{print $1}')
echo "JAMVM_SHA256_AFTER=$JA" >>"$OUT"; echo "GLIBJ_SHA256_AFTER=$GA" >>"$OUT"
if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
 echo 'PROTECTED_HASHES=PASS' >>"$OUT"
else
 echo 'PROTECTED_HASHES=FAIL' >>"$OUT"
fi
[ "$RC" -eq 0 ] && echo 'NORMAL_EXIT=PASS' >>"$OUT" || echo 'NORMAL_EXIT=FAIL' >>"$OUT"
echo 'REAL_GAME_GATE=PENDING_HUMAN_REVIEW' >>"$OUT"
echo 'DEVICE_PASS=NO_PENDING_REAL_DEVICE_REVIEW' >>"$OUT"
echo 'STABLE=NO' >>"$OUT"
sync
exit "$RC"
