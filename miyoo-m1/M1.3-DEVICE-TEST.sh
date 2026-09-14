#!/bin/sh
# RG35XX Miyoo M1.3 SDL1 input/gamepad device test.
# Does not replace or modify the existing Java platform.
set +e
OUT="/mnt/mmc/RG35XX-MIYOO-M1.3-DEVICE-RESULT.txt"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PROBE="$SCRIPT_DIR/m1_3_sdl1_input_probe"

exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.3 DEVICE TEST"
date
echo "SCOPE=SDL1_INPUT_ONLY"
echo "MODIFIES_EXISTING_JAVA_PLATFORM=NO"
echo "SCRIPT_DIR=$SCRIPT_DIR"

echo
echo "== LOCKED FALLBACK HASHES BEFORE =="
for f in \
  /mnt/mmc/BIOS/freej2me-lr.jar \
  /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so \
  /mnt/mmc/CFW/java/bin/jamvm \
  /mnt/mmc/CFW/java/share/classpath/glibj.zip; do
  [ -f "$f" ] && sha256sum "$f" 2>&1
done

echo
echo "== INPUT DEVICES =="
ls -l /dev/input 2>&1
cat /proc/bus/input/devices 2>&1 | head -n 160

echo
echo "== PROBE FILE =="
ls -l "$PROBE" 2>&1
sha256sum "$PROBE" 2>&1
[ -x "$PROBE" ] || chmod +x "$PROBE" 2>/dev/null

echo
echo "== SDL1 LIBRARY =="
for s in /usr/lib/libSDL-1.2.so.0 /usr/lib/libSDL-1.2.so.0.11.4; do
  [ -e "$s" ] || continue
  ls -l "$s" 2>&1
  sha256sum "$s" 2>&1
done

echo
echo "== RUN SDL1 INPUT PROBE =="
"$PROBE"
RC=$?
echo "PROBE_EXIT_CODE=$RC"

echo
echo "== LOCKED FALLBACK HASHES AFTER =="
for f in \
  /mnt/mmc/BIOS/freej2me-lr.jar \
  /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so \
  /mnt/mmc/CFW/java/bin/jamvm \
  /mnt/mmc/CFW/java/share/classpath/glibj.zip; do
  [ -f "$f" ] && sha256sum "$f" 2>&1
done

if [ "$RC" -eq 0 ]; then
  echo "DEVICE_TEST=PASS_SDL1_INPUT_CAPTURE"
else
  echo "DEVICE_TEST=FAIL_SDL1_INPUT_CAPTURE"
fi
echo "DEVICE_PASS=NO"
echo "STABLE=NO"
echo "REPORT=$OUT"
sync
exit "$RC"
