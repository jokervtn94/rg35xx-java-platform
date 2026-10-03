#!/bin/sh
set -u

REPORT=/mnt/mmc/RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC-RESULT.txt
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || dirname -- "$0")
PROBE="$SCRIPT_DIR/p2c_input_capability_probe"

exec >"$REPORT" 2>&1

echo "RG35XX P2C INPUT CAPABILITY DIAGNOSTIC"
date
echo "SCOPE=DIAGNOSTIC_ONLY_ORIGINAL_RG35XX_RAW_JS0"
echo "MODIFIES_PRODUCTION_RUNTIME=NO"
echo "P2C_PHYSICAL_TEST=NOT_TESTED"
echo "RUNTIME_SEMANTIC_DELTA=NONE"
echo "SCRIPT_DIR=$SCRIPT_DIR"
echo

echo "== PROTECTED RUNTIME HASHES BEFORE =="
sha256sum /mnt/mmc/CFW/java/bin/jamvm 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/share/classpath/glibj.zip 2>/dev/null || true
echo

echo "== INPUT DEVICE =="
ls -l /dev/input/js0 /dev/input/event1 2>/dev/null || true
grep -A16 -B1 'RG35XX Gamepad' /proc/bus/input/devices 2>/dev/null || true
echo

echo "== PROBE FILE =="
ls -l "$PROBE" 2>/dev/null || true
sha256sum "$PROBE" 2>/dev/null || true
echo

echo "== DEVICE INSTRUCTION =="
echo "FOLLOW_ONLY_THE_CONTROL_NAME_SHOWN_ON_LCD=YES"
echo "DISPLAY_LABEL_LONE=L1"
echo "DISPLAY_LABEL_LTWO=L2"
echo "DISPLAY_LABEL_RONE=R1"
echo "DISPLAY_LABEL_RTWO=R2"
echo "ORDER=UP,DOWN,LEFT,RIGHT,A,B,X,Y,START,SELECT,L1,L2,R1,R2"
echo "WAIT_FOR_CONFIRMED_BEFORE_NEXT=YES"
echo

echo "== RUN P2C INPUT CAPABILITY PROBE =="
if [ ! -x "$PROBE" ]; then
  echo "PROBE_RESOLUTION=FAIL_PROBE_NOT_FOUND"
  RC=126
else
  "$PROBE"
  RC=$?
fi
echo "PROBE_EXIT_CODE=$RC"
echo

echo "== PROTECTED RUNTIME HASHES AFTER =="
sha256sum /mnt/mmc/CFW/java/bin/jamvm 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/share/classpath/glibj.zip 2>/dev/null || true

if [ "$RC" -eq 0 ]; then
  echo "P2C_DIAGNOSTIC_RESULT=PASS_14_CONTROL_CALIBRATION"
else
  echo "P2C_DIAGNOSTIC_RESULT=FAIL_OR_INCOMPLETE"
fi
echo "P2C_PHYSICAL_TEST=NOT_TESTED"
echo "RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO"
echo "STABLE=NO"
echo "A9_PARENT=NO"
echo "GAME_SPECIFIC_CODE=NO"
echo "REPORT=$REPORT"
sync
exit "$RC"
