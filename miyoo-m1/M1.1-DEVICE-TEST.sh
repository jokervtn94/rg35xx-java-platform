#!/bin/sh
# RG35XX Miyoo M1.1 standalone SDL2 ABI device test.
# Does not replace or modify the existing Java platform.
set +e
BASE="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
[ -n "$BASE" ] || BASE="/mnt/mmc/Roms/APPS/Miyoo M1.1"
OUT="/mnt/mmc/RG35XX-MIYOO-M1.1-DEVICE-RESULT.txt"
PROBE="$BASE/m1_1_sdl2_probe"

exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.1 DEVICE TEST"
date
echo "SCOPE=STANDALONE_SDL2_ABI_ONLY"
echo "MODIFIES_EXISTING_JAVA_PLATFORM=NO"
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
 echo "== PROBE FILE =="
ls -l "$PROBE" 2>&1
command -v file >/dev/null 2>&1 && file "$PROBE" 2>&1
command -v readelf >/dev/null 2>&1 && {
  readelf -h "$PROBE" 2>&1 | head -n 40
  readelf -A "$PROBE" 2>&1 | head -n 80
}
sha256sum "$PROBE" 2>&1

echo
 echo "== SYSTEM SDL2 ELF =="
for s in /usr/lib/libSDL2-2.0.so.0 /usr/lib/libSDL2-2.0.so.0.8.0; do
  [ -e "$s" ] || continue
  ls -l "$s" 2>&1
  sha256sum "$s" 2>&1
  command -v file >/dev/null 2>&1 && file "$s" 2>&1
  command -v readelf >/dev/null 2>&1 && readelf -A "$s" 2>&1 | head -n 80
 done

echo
 echo "== RUN PROBE =="
if [ ! -x "$PROBE" ]; then
  chmod +x "$PROBE" 2>/dev/null
fi
"$PROBE"
RC=$?
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
