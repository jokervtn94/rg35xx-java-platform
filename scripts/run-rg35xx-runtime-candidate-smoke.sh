#!/bin/sh
set -u

# Candidate-runtime smoke test.  This exercises the Miyoo/Aweigit platform
# together with the RG35XX video/input native boundary without touching the
# protected /mnt/mmc/CFW/java runtime.

APP=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
PKG="$APP/RG35XX-RUNTIME-CANDIDATE-SMOKE"
RUNTIME="$PKG/runtime"
JAMVM="$RUNTIME/bin/jamvm"
GLIBJ="$RUNTIME/share/classpath/glibj.zip"
CLASSES="$RUNTIME/share/jamvm/classes.zip"
PLATFORM="$PKG/freej2me-rg35xx.jar"
EXERCISER="$PKG/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar"
EVID=${RG35XX_RUNTIME_SMOKE_EVIDENCE:-/mnt/mmc/RG35XX-RUNTIME-CANDIDATE-SMOKE-EVIDENCE}
LOG="$EVID/RUNTIME-SMOKE-PHASE1.log"
DATA="$EVID/data"
RMS="$EVID/rms"

fail() {
	echo "RUNTIME_SMOKE_PRECONDITION=FAIL:$1" | tee -a "$LOG"
	echo 'RUNTIME_SMOKE_RESULT=FAIL' | tee -a "$LOG"
	exit 20
}

mkdir -p "$DATA" "$RMS" 2>/dev/null || exit 20
: >"$LOG" || exit 20

echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$LOG"
echo 'MODE=ALTERNATIVE_RUNTIME_PLATFORM_SMOKE' >>"$LOG"
echo 'BASE=MIYOO_AWEIGIT_PLATFORM' >>"$LOG"
echo 'DEVICE=ORIGINAL_RG35XX_GARLICOS' >>"$LOG"
echo 'RUNTIME_PROTECTED_PATH_MUTATION=NO' >>"$LOG"
echo 'SMOKE_SCOPE=P2C_PHASE1_DEFAULT_MAPPING' >>"$LOG"

[ -x "$JAMVM" ] || fail JAMVM_CANDIDATE_MISSING
[ -f "$GLIBJ" ] || fail GLIBJ_CANDIDATE_MISSING
[ -f "$CLASSES" ] || fail JAMVM_CLASSES_MISSING
[ -f "$PLATFORM" ] || fail PLATFORM_JAR_MISSING
[ -f "$EXERCISER" ] || fail EXERCISER_JAR_MISSING
[ -f "$PKG/librg35xx_input.so" ] || fail INPUT_NATIVE_MISSING
[ -f "$PKG/librg35xx_video.so" ] || fail VIDEO_NATIVE_MISSING
[ -f "$PKG/librg35xx_font.so" ] || fail FONT_NATIVE_MISSING
[ -f "$PKG/font.ttf" ] || fail FONT_ASSET_MISSING

command -v sha256sum >/dev/null 2>&1 || fail SHA256SUM_MISSING
echo "CANDIDATE_JAMVM_SHA256=$(sha256sum "$JAMVM" | awk '{print $1}')" >>"$LOG"
echo "CANDIDATE_GLIBJ_SHA256=$(sha256sum "$GLIBJ" | awk '{print $1}')" >>"$LOG"
echo "CANDIDATE_CLASSES_SHA256=$(sha256sum "$CLASSES" | awk '{print $1}')" >>"$LOG"
echo "PLATFORM_JAR_SHA256=$(sha256sum "$PLATFORM" | awk '{print $1}')" >>"$LOG"
echo "EXERCISER_JAR_SHA256=$(sha256sum "$EXERCISER" | awk '{print $1}')" >>"$LOG"

echo 'JAMVM_VERSION_BEGIN' >>"$LOG"
"$JAMVM" -version >>"$LOG" 2>&1 || fail JAMVM_EXECUTION
echo 'JAMVM_VERSION_END' >>"$LOG"

(
	cd "$PKG" || exit 20
	LD_LIBRARY_PATH="$RUNTIME/lib/classpath:$RUNTIME/lib:$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
	"$JAMVM" -Xmx64m \
		-Dp2c.exerciser.phase=1 \
		-Drg35xx.raw2d=true \
		-Drg35xx.native.dir="$PKG" \
		-Drg35xx.font.path="$PKG/font.ttf" \
		-Drg35xx.font.native.path="$PKG/librg35xx_font.so" \
		-cp "$GLIBJ:$PLATFORM" \
		org.recompile.rg35xx.RG35XXLauncher \
		"$EXERCISER" 176 208 "$DATA" "$RMS"
) >>"$LOG" 2>&1
RC=$?
echo "RUNTIME_SMOKE_EXIT_CODE=$RC" >>"$LOG"

RESULT=PASS
[ "$RC" -eq 0 ] || RESULT=FAIL
grep -q '^RG35XX_A3_LAUNCH=' "$LOG" || RESULT=FAIL
grep -q '^RG35XX_A3_LOGICAL_LCD=176x208$' "$LOG" || RESULT=FAIL
grep -q '^P2C_EXERCISER_RESOLUTION=176x208 RESULT=PASS$' "$LOG" || RESULT=FAIL
grep -q '^P2C_EXERCISER_RESULT=PASS PHASE=1$' "$LOG" || RESULT=FAIL
grep -q '^P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=1$' "$LOG" || RESULT=FAIL

echo "RUNTIME_SMOKE_RESULT=$RESULT" >>"$LOG"
echo 'RUNTIME_SMOKE_DEVICE_PASS=NO' >>"$LOG"
[ "$RESULT" = PASS ] && exit 0
exit 2
