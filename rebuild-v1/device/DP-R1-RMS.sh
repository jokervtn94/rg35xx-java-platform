#!/bin/sh
. "$(dirname "$0")/DP-R1-COMMON.sh"
OUT=/mnt/mmc/RG35XX-DP-R1-RMS.txt
: >"$OUT"; check_protected || { echo PRECONDITION=FAIL >>"$OUT"; exit 20; }
"$JAMVM" -Xmx64m -cp "$GLIBJ:$PLATFORM" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/dp-r1-rms.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"
check_protected && echo PROTECTED_HASHES=PASS >>"$OUT" || echo PROTECTED_HASHES=FAIL >>"$OUT"
grep -q 'M1_15_R1_LIFECYCLE_GATE=PASS' "$OUT" && [ "$RC" -eq 0 ] && echo RUNTIME_GATE=PASS >>"$OUT" || echo RUNTIME_GATE=FAIL >>"$OUT"
echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"; echo STABLE=NO >>"$OUT"; sync
