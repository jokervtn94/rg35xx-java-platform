#!/bin/sh
. "$(dirname "$0")/DP-R1-COMMON.sh"
OUT=/mnt/mmc/RG35XX-DP-R1-RMS-PERSIST-A.txt
STATE=/mnt/mmc/RG35XX-DP-R1-RMS-PERSIST-A.OK
rm -f "$STATE"; : >"$OUT"; check_protected || { echo PRECONDITION=FAIL >>"$OUT"; exit 20; }
"$JAMVM" -Drg35xx.rms.mode=A -Xmx64m -cp "$GLIBJ:$PLATFORM" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/dp-r1-rms-persist.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"
check_protected && echo PROTECTED_HASHES=PASS >>"$OUT" || echo PROTECTED_HASHES=FAIL >>"$OUT"
grep -q 'M1_15_R11_A_GATE=PASS' "$OUT" && [ "$RC" -eq 0 ] && { echo RUNTIME_GATE=PASS >>"$OUT"; echo OK >"$STATE"; } || echo RUNTIME_GATE=FAIL >>"$OUT"
echo DEVICE_PASS=NO_PHASE_B_REQUIRED >>"$OUT"; echo STABLE=NO >>"$OUT"; sync
