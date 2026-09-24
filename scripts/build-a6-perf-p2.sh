#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_PERF_P2_BUILD_FAIL=$*" >&2; exit 1; }

# Rebuild exact functional R5P3I2 Java semantics; native output already contains PERF-P2.
bash "$ROOT/scripts/build-a6-raw-drawrect-r5p3i2.sh"
BASE="$ROOT/out/a6-realgame-r5p3i2"
DST="$ROOT/out/a6-perf-p2"
[ -f "$BASE/freej2me-rg35xx.jar" ] || fail "R5P3I2 platform missing"
rm -rf "$DST"; mkdir -p "$DST"
cp -a "$BASE/." "$DST/"

PLATFORM_SHA="$(sha256sum "$BASE/freej2me-rg35xx.jar" | awk '{print $1}')"
INPUT_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_video.so" | awk '{print $1}')"
PLATFORM_SEMANTIC_SHA="$(python3 - "$BASE/freej2me-rg35xx.jar" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
)"
EXPECTED_SEMANTIC_SHA='b79cafa98c467436cf0e782b069839e993a7dc7bdb31b9a423b47c0ff293950e'
[ "$PLATFORM_SEMANTIC_SHA" = "$EXPECTED_SEMANTIC_SHA" ] || fail "platform semantic digest changed $PLATFORM_SEMANTIC_SHA"
[ "$INPUT_SHA" = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d' ] || fail "input native changed $INPUT_SHA"
[ "$VIDEO_SHA" != 'a821e0337f0cc7abf6986d1779560191ae55e61e7a69379f84dc02c5a9c7f068' ] || fail "video native identical to PERF-P1"
echo A6_PERF_P2_JAVA_ENTRY_SEMANTIC_GATE=PASS

SRC="$ROOT/adapter/native/rg35xx_video_sdl1.c"
# Preserve PERF-P1 wins.
grep -q 'static int perf_xmap\[RG35XX_LCD_W\]' "$SRC" || fail "PERF-P1 xmap cache lost"
grep -q 'static int perf_ymap\[RG35XX_LCD_H\]' "$SRC" || fail "PERF-P1 ymap cache lost"
grep -q 'int sx = perf_xmap\[x\];' "$SRC" || fail "cached sx lost"
grep -q 'int sy = perf_ymap\[y\];' "$SRC" || fail "cached sy lost"
# PERF-P2 owner and fallback gates.
grep -q 'typedef struct RG35XX_SDL_PixelFormat' "$SRC" || fail "SDL 1.2 pixel format compat layout missing"
grep -q 'perf2_fast_rgb' "$SRC" || fail "fast RGB gate missing"
grep -q 'RG35XX_PERF_P2_PIXEL_PACK=FAST' "$SRC" || fail "fast format runtime marker missing"
grep -q 'RG35XX_PERF_P2_PIXEL_PACK=SDL_MAPRGB_FALLBACK' "$SRC" || fail "fallback runtime marker missing"
grep -q 'RG35XX_PERF_P2_FRAME=' "$SRC" || fail "PERF-P2 telemetry missing"
python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end=s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
b=s[start:end]
# PERF-P1 coordinate divisions stay map-rebuild-only.
if b.count('((long long)x * width) / dw') != 1:
    raise SystemExit('A6_PERF_P2_GATE_FAIL x division count='+str(b.count('((long long)x * width) / dw')))
if b.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P2_GATE_FAIL y division count='+str(b.count('((long long)y * height) / dh')))
# Only fallback path may call SDL_MapRGB per frame. Black clear may call it once on geometry rebuild.
if b.count('SDL_MapRGB_p(screen->format') != 2:
    raise SystemExit('A6_PERF_P2_GATE_FAIL MapRGB source count='+str(b.count('SDL_MapRGB_p(screen->format')))
required=[
 '((r >> perf2_rloss) << perf2_rshift)',
 '((g >> perf2_gloss) << perf2_gshift)',
 '((b >> perf2_bloss) << perf2_bshift)',
 '| perf2_amask'
]
for x in required:
    if x not in b: raise SystemExit('A6_PERF_P2_GATE_FAIL map semantics missing '+x)
print('A6_PERF_P2_DIVISION_GATE=PASS')
print('A6_PERF_P2_PIXEL_PACK_SOURCE_GATE=PASS')
print('A6_PERF_P2_FALLBACK_GATE=PASS')
PY

cp "$ROOT/out/a3/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$ROOT/out/a3/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$SRC" "$DST/A6-PERF-P2-VIDEO-SOURCE.c"
cat > "$DST/A6-PERF-P2-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-P2-DIRECT-TRUECOLOR-PACK
BASE_DEVICE_PLATFORM=R5P3I2
BASE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
BASE_PLATFORM_SEMANTIC_SHA256=$PLATFORM_SEMANTIC_SHA
BASE_DEVICE_TESTED_SEMANTIC_SHA256=$EXPECTED_SEMANTIC_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
PERF_P1_DEVICE_RESULT=PASS_FUNCTIONAL_NORMAL_EXIT
PERF_P1_BASELINE_FPS=10.4
PERF_P1_DEVICE_AVG_FPS=14.95
PERF_P1_RELATIVE_GAIN_APPROX=43.8_PERCENT
GAME_TARGET_FRAME_MS=50
GAME_TARGET_FPS=20
A6_PERF_P2_OWNER=RG35XX_NATIVE_PER_PIXEL_SDL_MAPRGB_CALL
A6_PERF_P2_FAST_FORMAT=TRUECOLOR_32BPP_4BYTE_NONPALETTED
A6_PERF_P2_MAPRGB_SEMANTICS=SDL12_RLOSS_SHIFT_PLUS_AMASK
A6_PERF_P2_FALLBACK=SDL_MAPRGB
A6_PERF_P2_P1_XY_CACHE=PRESERVED
A6_PERF_P2_P1_GEOMETRY_CLEAR=PRESERVED
A6_PERF_P2_JAVA_PLATFORM=ENTRY_BYTE_EXACT_R5P3I2
A6_PERF_P2_JAVA_ENTRY_SEMANTIC_GATE=PASS
A6_PERF_P2_INPUT_NATIVE=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
PERFORMANCE-DEVICE-TEST=PENDING
STABLE=NO
EOF
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_PERF_P2_OWNER=RG35XX_NATIVE_PER_PIXEL_SDL_MAPRGB_CALL
A6_PERF_P2_SCOPE=VIDEO_NATIVE_TRUECOLOR_DIRECT_PACK_WITH_SDL_MAPRGB_FALLBACK
A6_PERF_P2_P1_XY_CACHE=PRESERVED
A6_PERF_P2_JAVA_PLATFORM=ENTRY_BYTE_EXACT_R5P3I2
A6_PERF_P2_JAVA_ENTRY_SEMANTIC_GATE=PASS
CANONICAL_GITLINK_MUTATED=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_PERF_P2_BUILD=PASS
cat "$DST/A6-PERF-P2-IDENTITY.txt"
