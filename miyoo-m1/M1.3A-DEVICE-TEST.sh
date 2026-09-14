#!/bin/sh
OUT=/mnt/mmc/RG35XX-MIYOO-M1.3A-DEVICE-RESULT.txt
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROBE="$SCRIPT_DIR/m1_3a_raw_js0_probe"

{
  echo "RG35XX MIYOO M1.3A DEVICE TEST"
  date
  echo "SCOPE=RAW_JS0_INPUT_ONLY"
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
  ls -l /dev/input/js0 /dev/input/event1 2>&1 || true
  grep -A8 -B1 'RG35XX Gamepad' /proc/bus/input/devices 2>/dev/null || true
  echo
  echo "== PROBE FILE =="
  ls -l "$PROBE" 2>&1 || true
  sha256sum "$PROBE" 2>/dev/null || true
  echo
  echo "== RUN RAW JS0 PROBE =="
  if [ ! -x "$PROBE" ]; then
    echo "PROBE_RESOLUTION=FAIL"
    CODE=126
  else
    "$PROBE"
    CODE=$?
  fi
  echo "PROBE_EXIT_CODE=$CODE"
  echo
  echo "== LOCKED FALLBACK HASHES AFTER =="
  sha256sum /mnt/mmc/BIOS/freej2me-lr.jar 2>/dev/null || true
  sha256sum /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so 2>/dev/null || true
  sha256sum /mnt/mmc/CFW/java/bin/jamvm 2>/dev/null || true
  sha256sum /mnt/mmc/CFW/java/share/classpath/glibj.zip 2>/dev/null || true
  if [ "$CODE" -eq 0 ]; then
    echo "DEVICE_TEST=PASS_RAW_JS0_INPUT"
  else
    echo "DEVICE_TEST=FAIL_RAW_JS0_INPUT"
  fi
  echo "DEVICE_PASS=NO"
  echo "STABLE=NO"
  echo "REPORT=$OUT"
} > "$OUT" 2>&1

sync
exit 0
