#!/bin/sh
set -eu

# Audit the two device-proven RG35XX binaries before using them as a rebuild
# reference. The binaries are deliberately not committed to this repository.
#
# Usage:
#   GOLDEN_JAR=/path/freej2me-lr.jar \
#   GOLDEN_CORE=/path/freej2me_plus_libretro.so \
#   sh scripts/golden_binary_audit.sh

: "${GOLDEN_JAR:?set GOLDEN_JAR to the device-proven freej2me-lr.jar}"
: "${GOLDEN_CORE:?set GOLDEN_CORE to the device-proven freej2me_plus_libretro.so}"

JAR_SHA=de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8
CORE_SHA=4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf
FONT_SHA=7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c
FONT_SIZE=727008

fail() { echo "GOLDEN AUDIT: FAIL: $*" >&2; exit 1; }
note() { echo "GOLDEN AUDIT: $*"; }

[ -f "$GOLDEN_JAR" ] || fail "missing JAR: $GOLDEN_JAR"
[ -f "$GOLDEN_CORE" ] || fail "missing core: $GOLDEN_CORE"

have() { command -v "$1" >/dev/null 2>&1 || fail "required host tool missing: $1"; }
for t in sha256sum unzip javap readelf strings; do have "$t"; done

actual_jar=$(sha256sum "$GOLDEN_JAR" | awk '{print $1}')
actual_core=$(sha256sum "$GOLDEN_CORE" | awk '{print $1}')
[ "$actual_jar" = "$JAR_SHA" ] || fail "JAR SHA256 $actual_jar != $JAR_SHA"
[ "$actual_core" = "$CORE_SHA" ] || fail "core SHA256 $actual_core != $CORE_SHA"
note "artifact hashes PASS"

manifest=$(unzip -p "$GOLDEN_JAR" META-INF/MANIFEST.MF 2>/dev/null || true)
printf '%s\n' "$manifest" | grep -q '^Main-Class: org.recompile.freej2me.Libretro' || fail "unexpected Main-Class"

work=${TMPDIR:-/tmp}/rg35xx-golden-audit.$$
trap 'rm -rf "$work"' EXIT INT TERM
mkdir -p "$work"
(
  cd "$work"
  unzip -qq "$GOLDEN_JAR" org/recompile/freej2me/Libretro.class \
    org/recompile/mobile/PlatformGraphics.class \
    org/recompile/mobile/PlatformFont.class \
    org/recompile/mobile/rg35xx-font.bin
)

major=$(javap -verbose "$work/org/recompile/freej2me/Libretro.class" 2>/dev/null | awk '/major version/ {print $3; exit}')
[ "$major" = 50 ] || fail "Libretro class major=$major, expected 50"

font="$work/org/recompile/mobile/rg35xx-font.bin"
[ -f "$font" ] || fail "embedded golden font resource missing"
font_size=$(wc -c < "$font" | tr -d ' ')
font_sha=$(sha256sum "$font" | awk '{print $1}')
[ "$font_size" = "$FONT_SIZE" ] || fail "font resource size=$font_size, expected $FONT_SIZE"
[ "$font_sha" = "$FONT_SHA" ] || fail "font resource SHA256 $font_sha != $FONT_SHA"
note "Java6 + embedded Unicode bitmap resource PASS"

javap -classpath "$work" -p "$work/org/recompile/freej2me/Libretro.class" > "$work/libretro.sig"
for token in \
  rg35xxStartFrameWorker \
  rg35xxRequestFrameAsync \
  rg35xxSendFrameAsync \
  rg35xxInit565Tables \
  rg35xxArgbSnapshot \
  rg35xx565High \
  rg35xx565Low
do
  grep -q "$token" "$work/libretro.sig" || fail "golden Java video owner missing: $token"
done

javap -classpath "$work" -p "$work/org/recompile/mobile/PlatformGraphics.class" > "$work/graphics.sig"
for token in \
  rg35xxEnsureBitmapFont \
  rg35xxGlyphIndex \
  rg35xxWideChar \
  rg35xxBitmapWidth \
  rg35xxDrawBitmapString \
  rg35xxDrawSafeText
do
  grep -q "$token" "$work/graphics.sig" || fail "golden font owner missing: $token"
done
note "golden Java owner signatures PASS"

readelf -h "$GOLDEN_CORE" > "$work/elf.h"
grep -q 'Class:.*ELF32' "$work/elf.h" || fail "core is not ELF32"
grep -q 'Machine:.*ARM' "$work/elf.h" || fail "core is not ARM"
grep -q 'Version5 EABI' "$work/elf.h" || fail "core is not EABI5"
grep -q 'soft-float ABI' "$work/elf.h" || fail "core ABI is not soft-float"

readelf -d "$GOLDEN_CORE" > "$work/elf.d"
for lib in libc.so.0 libgcc_s.so.1 libstdc++.so.6; do
  grep -q "Shared library: \[$lib\]" "$work/elf.d" || fail "golden runtime dependency missing: $lib"
done

strings -a "$GOLDEN_CORE" > "$work/core.strings"
for token in \
  'RG35XX-VIDEO: receiver thread START' \
  'RG35XX-VIDEO: invalid header' \
  'RG35XX-VIDEO: SMART-FIT source=' \
  'ipc=RGB565-LUT' \
  'RG35XX-AUDIO: async callback' \
  'RG35XX-AUDIO: underrun' \
  '/mnt/mmc/CFW/java/bin/jamvm' \
  '/mnt/mmc/BIOS/freej2me.sf2' \
  '/mnt/mmc/BIOS/freej2me-midi.cmd' \
  '-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit' \
  '-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment'
do
  grep -Fq -- "$token" "$work/core.strings" || fail "golden core contract missing: $token"
done
note "golden native architecture/path strings PASS"

note "PASS"
