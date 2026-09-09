#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN_FREEJ2ME="13ec186903087156c145268f8706eecfaf9f1e50"
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${VC_ASSEMBLY:?set VC_ASSEMBLY to disposable output directory}"

fail() { echo "VC0-VC3 FAIL: $*" >&2; exit 1; }
note() { echo "VC0-VC3: $*"; }

[ -d "$VC_UPSTREAM/.git" ] || fail "upstream is not a git checkout"
HEAD=$(git -C "$VC_UPSTREAM" rev-parse HEAD)
[ "$HEAD" = "$PIN_FREEJ2ME" ] || fail "upstream HEAD $HEAD != $PIN_FREEJ2ME"
[ "$VC_ASSEMBLY" != "$VC_UPSTREAM" ] || fail "assembly must be separate"

rm -rf "$VC_ASSEMBLY"
mkdir -p "$VC_ASSEMBLY"
( cd "$VC_UPSTREAM" && tar --exclude=.git -cf - . ) | ( cd "$VC_ASSEMBLY" && tar -xf - )

# VC2: only the device-proven lazy-media boot change.
python3 "$ROOT/scripts/g1_apply_rg35xx_media_boot.py" \
  "$VC_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java"

# VC3: only the reconstructed Golden async RGB565 transport.
cp "$ROOT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java" \
  "$VC_ASSEMBLY/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
python3 "$ROOT/scripts/g1_apply_java_transport.py" \
  "$VC_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"

mkdir -p "$VC_ASSEMBLY/src/libretro/rg35xx/golden"
cp "$ROOT/native/golden/rg35xx_golden_video.h" \
  "$VC_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.h"
cp "$ROOT/native/golden/rg35xx_golden_video.c" \
  "$VC_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c"
python3 "$ROOT/scripts/g1_apply_native_overlay.py" \
  "$VC_ASSEMBLY/src/libretro/freej2me_libretro.c"

MC="$VC_ASSEMBLY/src/libretro/Makefile.common"
grep -Fq 'SOURCES_C += freej2me_libretro.c' "$MC" || fail "unexpected Makefile.common baseline"
cat >> "$MC" <<'EOF'

# VC3: device-proven Golden receiver-thread video transport.
SOURCES_C += rg35xx/golden/rg35xx_golden_video.c
INCLUDES += -Irg35xx/golden
EOF

CORE="$VC_ASSEMBLY/src/libretro/freej2me_libretro.c"
JAVA="$VC_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"
MOBILE="$VC_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java"
IMAGE="$VC_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java"

# Positive gates: only verified baseline behavior.
grep -Fq 'RETRO_PIXEL_FORMAT_RGB565' "$CORE" || fail "RGB565 contract missing"
grep -Fq 'rg35xx_golden_video_start()' "$CORE" || fail "receiver start missing"
grep -Fq 'rg35xx_golden_video_present(' "$CORE" || fail "nonblocking presenter missing"
grep -Fq 'RG35XXGoldenFrameTransport' "$JAVA" || fail "Java FrameWorker transport missing"
grep -Fq 'rg35xxFrames.requestFrame' "$JAVA" || fail "async frame request missing"
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$MOBILE" || fail "lazy-media marker missing"

# Negative gates: reject every unverified branch experiment from the clean baseline.
for bad in \
  'RG35XX-PNG-COMPAT' \
  'rg35xxStripPngICCP' \
  'RG35XX-PNG-COMPAT-V2' \
  'RG35XX-CV:' \
  'rg35xx_cv_launch_java' \
  'rg35xx_cv_resolution_from_path' \
  'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$VC_ASSEMBLY/src"; then
    fail "unverified feature survived clean assembly: $bad"
  fi
done

# No eager media prewarm may survive runJar().
python3 - "$MOBILE" <<'PY'
import pathlib, sys
s = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
r = s.index('public void runJar()')
e = s.find('\n\tpublic ', r + 1)
if e < 0: e = len(s)
body = s[r:e]
assert 'loader.start();' in body
assert 'prepareMediaEngine();' not in body
assert 'RG35XX-MediaWarmup' not in body
PY

# PlatformImage must remain pinned-upstream at VC3: no compatibility experiments yet.
if grep -Fq 'rg35xx' "$IMAGE"; then
  fail "PlatformImage contains RG35XX experiment before VC6"
fi

# Golden ABI/path contract.
grep -Fq 'const char *freej2meapp = "freej2me-lr.jar";' "$CORE" || fail "runtime JAR name changed"
grep -Fq '"/mnt/mmc/CFW/java/bin/jamvm"' "$CORE" || fail "JamVM absolute path missing"
grep -Fq '"-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit"' "$CORE" || fail "headless Toolkit missing"
grep -Fq '"-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment"' "$CORE" || fail "headless GraphicsEnvironment missing"
grep -Fq '"-Djava.awt.headless=true"' "$CORE" || fail "headless property missing"
grep -Fq 'open("/mnt/mmc/freej2me-java-error.log"' "$CORE" || fail "Java error log path missing"

note "PASS: clean VC0-VC3 assembly at $VC_ASSEMBLY"
