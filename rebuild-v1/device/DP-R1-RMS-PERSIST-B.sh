#!/bin/sh
. "$(dirname "$0")/DP-R1-COMMON.sh"
OUT=/mnt/mmc/RG35XX-DP-R1-RMS-PERSIST-B.txt
STATE=/mnt/mmc/RG35XX-DP-R1-RMS-PERSIST-A.OK
: >"$OUT"; [ -f "$STATE" ] || { echo PRECONDITION=FAIL_NO_PHASE_A >>"$OUT"; exit 21; }
check_protected || { echo PRECONDITION=FAIL >>"$OUT"; exit 20; }
"$JAMVM" -Drg35xx.rms.mode=B -Xmx64m -cp "$GLIBJ:$PLATFORM" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/dp-r1-rms-persist.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"
check_protected && echo PROTECTED_HASHES=PASS >>"$OUT" || echo PROTECTED_HASHES=FAIL >>"$OUT"
grep -q 'M1_15_R11_B_GATE=PASS' "$OUT" && [ "$RC" -eq 0 ] && echo RUNTIME_GATE=PASS >>"$OUT" || echo RUNTIME_GATE=FAIL >>"$OUT"
rm -f "$STATE"; echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"; echo STABLE=NO >>"$OUT"; sync
