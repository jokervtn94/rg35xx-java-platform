#!/bin/sh
# RG35XX Miyoo M1.1A standalone SDL2 ABI device test.
# Packaging/path correction only. Does not replace or modify existing Java platform.
set +e
OUT="/mnt/mmc/RG35XX-MIYOO-M1.1A-DEVICE-RESULT.txt"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PROBE=""

for p in \
  "$SCRIPT_DIR/m1_1_sdl2_probe" \
  "/mnt/mmc/Roms/APPS/m1_1_sdl2_probe" \
  "/mnt/mmc/Roms/APPS/Miyoo M1.1 SDL ABI/m1_1_sdl2_probe"; do
  if [ -f "$p" ]; then
    PROBE="$p"
    break
  fi
done

exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.1A DEVICE TEST"
date
echo "SCOPE=GARLICOS_PATH_FIX_PLUS_SAME_SDL2_ABI_PROBE"
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
echo "== PROBE RESOLUTION =="
if [ -z "$PROBE" ]; then
  echo "PROBE_RESOLUTION=FAIL_PROBE_NOT_FOUND"
  for p in \
    "$SCRIPT_DIR/m1_1_sdl2_probe" \
    "/mnt/mmc/Roms/APPS/m1_1_sdl2_probe" \
    "/mnt/mmc/Roms/APPS/Miyoo M1.1 SDL ABI/m1_1_sdl2_probe"; do
    echo "CHECKED=$p"
    ls -l "$p" 2>&1
  done
  RC=126
else
  echo "PROBE_RESOLUTION=PASS"
  echo "PROBE=$PROBE"
  ls -l "$PROBE" 2>&1
  command -v file >/dev/null 2>&1 && file "$PROBE" 2>&1
  command -v readelf >/dev/null 2>&1 && {
    readelf -h "$PROBE" 2>&1 | head -n 40
    readelf -A "$PROBE" 2>&1 | head -n 80
  }
  sha256sum "$PROBE" 2>&1
  [ -x "$PROBE" ] || chmod +x "$PROBE" 2>/dev/null

  echo
  echo "== SYSTEM SDL2 ELF =="
  for s in /usr/lib/libSDL2-2.0.so.0 /usr/lib/libSDL2-2.0.so.0.8.0; do
    [ -e "$s" ] || continue
    ls -l "$s" 2>&1
    sha256sum "$s" 2>&1
  done

  echo
  echo "== RUN PROBE =="
  "$PROBE"
  RC=$?
fi

echo "PROBE_EXIT_CODE=$RC"

echo
echo "== JVM BASELINE =="
/mnt/mmc/CFW/java/bin/jamvm -version 2>&1 | head -n 8

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
  echo "DEVICE_TEST=PASS_SDL2_ABI"
else
  echo "DEVICE_TEST=FAIL_SDL2_ABI"
fi
echo "DEVICE_PASS=NO"
echo "STABLE=NO"
echo "REPORT=$OUT"
sync
exit "$RC"
