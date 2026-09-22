#!/bin/sh
. "$(dirname "$0")/DP-R1-COMMON.sh"
OUT=/mnt/mmc/RG35XX-DP-R1-GAMECANVAS.txt
: >"$OUT"; check_protected || { echo PRECONDITION=FAIL >>"$OUT"; exit 20; }
echo VISUAL=BLUE_BACKGROUND_GREEN_SQUARE_DPAD_MOVES_A_RED_RELEASE_GREEN >>"$OUT"
LD_LIBRARY_PATH="$APP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$JAMVM" -Xmx64m -cp "$GLIBJ:$PLATFORM" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/dp-r1-gamecanvas.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"
check_protected && echo PROTECTED_HASHES=PASS >>"$OUT" || echo PROTECTED_HASHES=FAIL >>"$OUT"
grep -q 'M1_10_NORMAL_EXIT=PASS' "$OUT" && [ "$RC" -eq 0 ] && echo RUNTIME_GATE=PASS_WITH_STALE_HARNESS_MARKER_IGNORED >>"$OUT" || echo RUNTIME_GATE=FAIL >>"$OUT"
echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"; echo STABLE=NO >>"$OUT"; sync
