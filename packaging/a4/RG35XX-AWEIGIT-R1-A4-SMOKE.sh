#!/bin/sh

OUT=/mnt/mmc/RG35XX-AWEIGIT-R1-A4-SMOKE-RESULT.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-AWEIGIT-R1-A4-SMOKE"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
DATA="$PKG/data"

: >"$OUT"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=A4-SMOKE' >>"$OUT"
echo 'AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63' >>"$OUT"
echo 'A4_SCOPE=BOOT+LCD+INPUT+CANVAS+GAMECANVAS+NORMAL_EXIT' >>"$OUT"
echo 'A4_RAW2D_REQUESTED=YES' >>"$OUT"
echo 'A4_INPUT_TRACE_REQUESTED=YES' >>"$OUT"
echo 'AUDIO=HOLD' >>"$OUT"
echo 'MEDIA=HOLD' >>"$OUT"

a4_fail() {
    echo "A4_LAUNCH_PRECONDITION=FAIL:$1" >>"$OUT"
    echo 'DEVICE_PASS=NO' >>"$OUT"
    echo 'DEVICE_PASS_REVIEW=BLOCKED' >>"$OUT"
    echo 'STABLE=NO' >>"$OUT"
    sync
    exit 20
}

[ -x "$JAMVM" ] || a4_fail 'JAMVM_MISSING'
[ -f "$GLIBJ" ] || a4_fail 'GLIBJ_MISSING'
[ -d "$PKG" ] || a4_fail 'PAYLOAD_DIR_MISSING'
[ -f "$PKG/freej2me-rg35xx.jar" ] || a4_fail 'PLATFORM_JAR_MISSING'
[ -f "$PKG/rg35xx-a4-smoke.jar" ] || a4_fail 'SMOKE_JAR_MISSING'
[ -f "$PKG/librg35xx_input.so" ] || a4_fail 'INPUT_NATIVE_MISSING'
[ -f "$PKG/librg35xx_video.so" ] || a4_fail 'VIDEO_NATIVE_MISSING'
[ -f "$PKG/PAYLOAD-SHA256SUMS.txt" ] || a4_fail 'PAYLOAD_SUMS_MISSING'

JB=$(sha256sum "$JAMVM" | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" | awk '{print $1}')
echo "JAMVM_SHA256_BEFORE=$JB" >>"$OUT"
echo "GLIBJ_SHA256_BEFORE=$GB" >>"$OUT"
[ "$JB" = "$EXPECTED_JAMVM" ] || a4_fail 'JAMVM_HASH_MISMATCH'
[ "$GB" = "$EXPECTED_GLIBJ" ] || a4_fail 'GLIBJ_HASH_MISMATCH'

(
    cd "$PKG" || exit 1
    sha256sum -c PAYLOAD-SHA256SUMS.txt
) >>"$OUT" 2>&1 || a4_fail 'PAYLOAD_HASH_MISMATCH'
echo 'A4_PAYLOAD_HASHES=PASS' >>"$OUT"

mkdir -p "$DATA" || a4_fail 'DATA_DIR_CREATE_FAIL'

echo 'A4_VISUAL_STEP_1=CANVAS_BLUE_BG_GREEN_SQUARE:MOVE_DPAD_AND_PRESS_RELEASE_A' >>"$OUT"
echo 'A4_VISUAL_STEP_2=GAMECANVAS_BLACK_BG_CYAN_SQUARE:MOVE_DPAD_AND_PRESS_RELEASE_A' >>"$OUT"
echo 'A4_VISUAL_EXPECTATION=NO_WHITE_SCREEN_NO_HARD_RESET_NORMAL_RETURN_TO_MENU' >>"$OUT"

LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
"$JAMVM" -Xmx64m \
    -Drg35xx.raw2d=true \
    -Drg35xx.a4.inputtrace=true \
    -Drg35xx.native.dir="$PKG" \
    -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" \
    org.recompile.rg35xx.RG35XXLauncher \
    "$PKG/rg35xx-a4-smoke.jar" 640 480 "$DATA" "$DATA" >>"$OUT" 2>&1
RC=$?

JA=$(sha256sum "$JAMVM" | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" | awk '{print $1}')
echo "JAMVM_EXIT_CODE=$RC" >>"$OUT"
echo "JAMVM_SHA256_AFTER=$JA" >>"$OUT"
echo "GLIBJ_SHA256_AFTER=$GA" >>"$OUT"

if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
    echo 'A4_PROTECTED_HASHES=PASS' >>"$OUT"
else
    echo 'A4_PROTECTED_HASHES=FAIL' >>"$OUT"
fi

PROGRAMMATIC=PASS
[ "$RC" -eq 0 ] || PROGRAMMATIC=FAIL
grep -q '^RG35XX_A4_RAW2D=ENABLED$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_INPUT_TRACE=ENABLED$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_A3_SDL_DRIVER=fbcon$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^RG35XX_A3_SURFACE=640x480 ' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_SMOKE_BOOT=PASS$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_CANVAS_EXECUTION=PASS$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_GAMECANVAS_EXECUTION=PASS$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_SMOKE_DEVICE_ACCEPTANCE_MARKER=PASS$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_NORMAL_EXIT=PASS$' "$OUT" || PROGRAMMATIC=FAIL
grep -q '^A4_PROTECTED_HASHES=PASS$' "$OUT" || PROGRAMMATIC=FAIL

echo "A4_SMOKE_PROGRAMMATIC_RESULT=$PROGRAMMATIC" >>"$OUT"
echo 'DEVICE_PASS=NO_PENDING_MANUAL_REVIEW' >>"$OUT"
echo 'DEVICE_PASS_REVIEW=PENDING' >>"$OUT"
echo 'STABLE=NO' >>"$OUT"
echo 'FULL_PLATFORM_STABLE=NO' >>"$OUT"
sync

[ "$PROGRAMMATIC" = PASS ] && exit 0
exit 2