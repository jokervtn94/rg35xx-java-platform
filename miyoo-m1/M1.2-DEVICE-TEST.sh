#!/bin/sh
# RG35XX Miyoo M1.2 SDL2 VIDEO device test.
# Flat GarlicOS APPS layout. Does not modify current Java platform.
set +e
OUT="/mnt/mmc/RG35XX-MIYOO-M1.2-DEVICE-RESULT.txt"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PROBE="$SCRIPT_DIR/m1_2_sdl2_video_probe"

exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1.2 DEVICE TEST"
date
echo "SCOPE=SDL2_VIDEO_ONLY"
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
echo "== PROBE FILE =="
ls -l "$PROBE" 2>&1
sha256sum "$PROBE" 2>&1
[ -x "$PROBE" ] || chmod +x "$PROBE" 2>/dev/null

echo
echo "== DISPLAY ENV BEFORE =="
echo "DISPLAY=${DISPLAY:-}"
echo "SDL_VIDEODRIVER=${SDL_VIDEODRIVER:-}"
[ -e /dev/fb0 ] && ls -l /dev/fb0 2>&1
ps 2>&1 | grep -E 'Xorg|X |minui|retroarch' | grep -v grep || true

echo
echo "== RUN VIDEO PROBE =="
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
  echo "DEVICE_TEST=PASS_SDL2_VIDEO_CODEPATH"
  echo "VISUAL_CONFIRMATION_REQUIRED=YES"
else
  echo "DEVICE_TEST=FAIL_SDL2_VIDEO"
  echo "VISUAL_CONFIRMATION_REQUIRED=NO"
fi
echo "DEVICE_PASS=NO"
echo "STABLE=NO"
echo "REPORT=$OUT"
sync
exit "$RC"
