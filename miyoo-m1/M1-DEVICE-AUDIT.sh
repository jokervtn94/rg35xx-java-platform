#!/bin/sh
# RG35XX Miyoo M1 read-only device audit. No files outside the report are modified.
set +e
OUT="/mnt/mmc/RG35XX-MIYOO-M1-DEVICE-AUDIT.txt"
exec >"$OUT" 2>&1

echo "RG35XX MIYOO M1 DEVICE AUDIT"
date
echo "READ_ONLY=YES"
echo

echo "== UNAME =="
uname -a 2>&1

echo "== CPUINFO =="
cat /proc/cpuinfo 2>&1

echo "== MEMORY =="
cat /proc/meminfo 2>&1 | head -n 40
command -v free >/dev/null 2>&1 && free -m 2>&1

echo "== MOUNTS =="
mount 2>&1

echo "== LIBC / LOADER =="
(command -v ldd >/dev/null 2>&1 && ldd --version 2>&1) || true
ls -l /lib/ld-* /lib/libc.so* /usr/lib/libc.so* 2>/dev/null

echo "== JVM CANDIDATES =="
for j in /mnt/mmc/CFW/java/bin/jamvm /mnt/mmc/CFW/java/bin/java /usr/bin/java /usr/local/bin/java; do
  if [ -x "$j" ]; then
    echo "JVM=$j"
    "$j" -version 2>&1 | head -n 8
    command -v file >/dev/null 2>&1 && file "$j" 2>&1
    command -v readelf >/dev/null 2>&1 && readelf -h "$j" 2>&1 | head -n 30
  fi
done

echo "== SDL LIBRARIES =="
for root in /lib /usr/lib /usr/local/lib /mnt/mmc/CFW /mnt/mmc/BIOS; do
  [ -d "$root" ] || continue
  find "$root" -type f \( -name 'libSDL2*.so*' -o -name 'libSDL*.so*' -o -name 'libdirectfb*.so*' \) 2>/dev/null | sort
done

echo "== SDL BINARIES / CONFIG =="
for c in sdl2-config sdl-config pkg-config; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "CMD=$c PATH=$(command -v "$c")"
    "$c" --version 2>&1 | head -n 4
  fi
done

echo "== AUDIO DEVICES =="
ls -l /dev/dsp /dev/snd /dev/mixer* 2>/dev/null
cat /proc/asound/cards 2>/dev/null

echo "== FRAMEBUFFER / INPUT =="
ls -l /dev/fb* /dev/input/event* 2>/dev/null
[ -r /sys/class/graphics/fb0/virtual_size ] && cat /sys/class/graphics/fb0/virtual_size
[ -r /sys/class/graphics/fb0/bits_per_pixel ] && cat /sys/class/graphics/fb0/bits_per_pixel

echo "== EXISTING JAVA PLATFORM =="
for f in /mnt/mmc/BIOS/freej2me-lr.jar /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so /mnt/mmc/CFW/java/bin/jamvm /mnt/mmc/CFW/java/share/classpath/glibj.zip; do
  [ -f "$f" ] || continue
  echo "FILE=$f"
  command -v sha256sum >/dev/null 2>&1 && sha256sum "$f" 2>&1
  command -v file >/dev/null 2>&1 && file "$f" 2>&1
  command -v readelf >/dev/null 2>&1 && readelf -h "$f" 2>/dev/null | head -n 30
 done

echo "== ENVIRONMENT =="
env | sort

echo
 echo "AUDIT_COMPLETE=YES"
echo "REPORT=$OUT"
sync
