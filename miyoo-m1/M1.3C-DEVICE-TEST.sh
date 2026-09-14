#!/bin/sh
set -u

REPORT=/mnt/mmc/RG35XX-MIYOO-M1.3C-DEVICE-RESULT.txt
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || dirname -- "$0")
PROBE="$SCRIPT_DIR/m1_3c_onscreen_keymap_probe"

exec >"$REPORT" 2>&1

echo "RG35XX MIYOO M1.3C DEVICE TEST"
date
echo "SCOPE=ONSCREEN_RAW_JS0_EXACT_KEYMAP_ONLY"
echo "MODIFIES_EXISTING_JAVA_PLATFORM=NO"
echo "SCRIPT_DIR=$SCRIPT_DIR"
echo

echo "== LOCKED FALLBACK HASHES BEFORE =="
sha256sum /mnt/mmc/BIOS/freej2me-lr.jar 2>/dev/null || true
sha256sum /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/bin/jamvm 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/share/classpath/glibj.zip 2>/dev/null || true
echo

echo "== INPUT DEVICE =="
ls -l /dev/input/js0 /dev/input/event1 2>/dev/null || true
grep -A12 -B1 'RG35XX Gamepad' /proc/bus/input/devices 2>/dev/null || true
echo

echo "== PROBE FILE =="
ls -l "$PROBE" 2>/dev/null || true
sha256sum "$PROBE" 2>/dev/null || true
echo

echo "== DEVICE INSTRUCTION =="
echo "FOLLOW_ONLY_THE_CONTROL_NAME_SHOWN_ON_LCD=YES"
echo "ORDER=UP,DOWN,LEFT,RIGHT,A,B,X,Y,START,SELECT,L,R"
echo "WAIT_FOR_CONFIRMED_BEFORE_NEXT=YES"
echo

echo "== RUN M1.3C ONSCREEN KEYMAP PROBE =="
if [ ! -x "$PROBE" ]; then
  echo "PROBE_RESOLUTION=FAIL_PROBE_NOT_FOUND"
  RC=126
else
  "$PROBE"
  RC=$?
fi
echo "PROBE_EXIT_CODE=$RC"
echo

echo "== LOCKED FALLBACK HASHES AFTER =="
sha256sum /mnt/mmc/BIOS/freej2me-lr.jar 2>/dev/null || true
sha256sum /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/bin/jamvm 2>/dev/null || true
sha256sum /mnt/mmc/CFW/java/share/classpath/glibj.zip 2>/dev/null || true

if [ "$RC" -eq 0 ]; then
  echo "DEVICE_TEST=PASS_ONSCREEN_EXACT_RAW_KEYMAP"
else
  echo "DEVICE_TEST=FAIL_ONSCREEN_EXACT_RAW_KEYMAP"
fi
echo "DEVICE_PASS=NO"
echo "STABLE=NO"
echo "REPORT=$REPORT"
exit "$RC"
