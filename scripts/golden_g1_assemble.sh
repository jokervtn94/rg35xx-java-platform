#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN_FREEJ2ME="13ec186903087156c145268f8706eecfaf9f1e50"
: "${GOLDEN_UPSTREAM:?set GOLDEN_UPSTREAM to pinned FreeJ2ME checkout}"
: "${GOLDEN_ASSEMBLY:?set GOLDEN_ASSEMBLY to disposable output directory}"

fail() { echo "G1 ASSEMBLY FAIL: $*" >&2; exit 1; }
note() { echo "G1 ASSEMBLY: $*"; }

[ -d "$GOLDEN_UPSTREAM/.git" ] || fail "upstream is not a git checkout"
HEAD=$(git -C "$GOLDEN_UPSTREAM" rev-parse HEAD)
[ "$HEAD" = "$PIN_FREEJ2ME" ] || fail "upstream HEAD $HEAD != $PIN_FREEJ2ME"
[ "$GOLDEN_ASSEMBLY" != "$GOLDEN_UPSTREAM" ] || fail "assembly must be separate"

rm -rf "$GOLDEN_ASSEMBLY"
mkdir -p "$GOLDEN_ASSEMBLY"
( cd "$GOLDEN_UPSTREAM" && tar --exclude=.git -cf - . ) | ( cd "$GOLDEN_ASSEMBLY" && tar -xf - )

# Java producer reconstructed from the device-proven JAR.
cp "$ROOT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java" \
   "$GOLDEN_ASSEMBLY/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
python3 "$ROOT/scripts/g1_apply_java_transport.py" \
   "$GOLDEN_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"

# RG35XX device diagnostics proved that boot-time Java Sound/MIDI prewarm is
# unsafe even when moved off-thread.  Keep runJar() lazy-media only.
python3 "$ROOT/scripts/g1_apply_rg35xx_media_boot.py" \
   "$GOLDEN_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java"

# Native receiver + Smart-Fit presenter reconstructed from the Golden core.
mkdir -p "$GOLDEN_ASSEMBLY/src/libretro/rg35xx/golden"
cp "$ROOT/native/golden/rg35xx_golden_video.h" \
   "$GOLDEN_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.h"
cp "$ROOT/native/golden/rg35xx_golden_video.c" \
   "$GOLDEN_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c"
python3 "$ROOT/scripts/g1_apply_native_overlay.py" \
   "$GOLDEN_ASSEMBLY/src/libretro/freej2me_libretro.c"

# CV: boot Java only after retro_load_game() knows the exact JAR path.
python3 "$ROOT/scripts/cv_apply_boot_resolution.py" \
   "$GOLDEN_ASSEMBLY/src/libretro/freej2me_libretro.c"

MC="$GOLDEN_ASSEMBLY/src/libretro/Makefile.common"
grep -Fq 'SOURCES_C += freej2me_libretro.c' "$MC" || fail "unexpected Makefile.common baseline"
cat >> "$MC" <<'EOF'

# RG35XX Golden G1 receiver-thread video transport.
SOURCES_C += rg35xx/golden/rg35xx_golden_video.c
INCLUDES += -Irg35xx/golden
EOF

CORE="$GOLDEN_ASSEMBLY/src/libretro/freej2me_libretro.c"
JAVA="$GOLDEN_ASSEMBLY/src/org/recompile/freej2me/Libretro.java"
MOBILE_PLATFORM="$GOLDEN_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java"

# Video contract.
grep -Fq 'RETRO_PIXEL_FORMAT_RGB565' "$CORE" || fail "RGB565 frontend contract missing"
grep -Fq 'rg35xx_golden_video_start()' "$CORE" || fail "receiver start missing"
grep -Fq 'rg35xx_golden_video_present(' "$CORE" || fail "present owner missing"
grep -Fq 'RG35XXGoldenFrameTransport' "$JAVA" || fail "Java frame worker missing"
grep -Fq 'rg35xxFrames.requestFrame' "$JAVA" || fail "async frame request missing"
grep -Fq 'rg35xxFrames.sendControlFrame' "$JAVA" || fail "restart control frame missing"
if grep -Fq 'status = read_from_pipe(pRead[0], frameHeader, 15)' "$CORE"; then
    fail "synchronous frame-header read survived"
fi
if grep -Fq 'System.out.write(frameBuffer' "$JAVA"; then
    fail "synchronous Java frame write survived"
fi

# RG35XX boot/media contract: no eager or asynchronous warmup in runJar().
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$MOBILE_PLATFORM" || fail "lazy media boot marker missing"
python3 - "$MOBILE_PLATFORM" <<'PY'
import pathlib, sys
s = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
r = s.index('public void runJar()')
end = s.find('\n\tpublic ', r + 1)
if end < 0:
    end = len(s)
body = s[r:end]
if 'loader.start();' not in body:
    raise SystemExit('G1 ASSEMBLY FAIL: loader.start missing')
if 'prepareMediaEngine();' in body:
    raise SystemExit('G1 ASSEMBLY FAIL: boot-time prepareMediaEngine survived')
if 'RG35XX-MediaWarmup' in body:
    raise SystemExit('G1 ASSEMBLY FAIL: async media warmup survived')
PY

# Device-proven Golden runtime contract.
grep -Fq '#define NUM_ARGUMENTS 10' "$CORE" || fail "Golden argv count missing"
grep -Fq 'const char *freej2meapp = "freej2me-lr.jar";' "$CORE" || fail "Golden JAR name missing"
grep -Fq '"/mnt/mmc/CFW/java/bin/jamvm"' "$CORE" || fail "absolute JamVM missing"
grep -Fq '"-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit"' "$CORE" || fail "headless Toolkit property missing"
grep -Fq '"-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment"' "$CORE" || fail "headless GraphicsEnvironment property missing"
grep -Fq '"-Djava.awt.headless=true"' "$CORE" || fail "java.awt.headless property missing"
grep -Fq 'open("/mnt/mmc/freej2me-java-error.log"' "$CORE" || fail "Golden stderr log path missing"
grep -Fq 'execv(cmd, params);' "$CORE" || fail "absolute execv missing"
if grep -Fq 'execvp(cmd, params);' "$CORE"; then fail "PATH-dependent execvp survived"; fi
if grep -Fq 'dup2(' "$CORE"; then :; else fail "pipe ownership unexpectedly absent"; fi

# CV boot-resolution contract.
grep -Fq 'RG35XX-CV: core ready; Java launch deferred to retro_load_game.' "$CORE" || fail "CV deferred Java launch missing"
grep -Fq 'rg35xx_cv_launch_java(info->path)' "$CORE" || fail "CV load-game launch barrier missing"
grep -Fq 'rg35xx_cv_resolution_from_path' "$CORE" || fail "CV filename resolution parser missing"
grep -Fq 'rg35xx_cv_resolution_locked' "$CORE" || fail "CV resolution lock missing"
[ "$(grep -Fc 'booted = javaOpen(params[0], params);' "$CORE")" -eq 1 ] || fail "CV javaOpen must have exactly one owner"

note "PASS: $GOLDEN_ASSEMBLY"
