#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_PERF_P1_BUILD_FAIL=$*" >&2; exit 1; }

# Java/runtime semantics must remain exact R5P3I2.
bash "$ROOT/scripts/build-a6-raw-drawrect-r5p3i2.sh"
BASE="$ROOT/out/a6-realgame-r5p3i2"
DST="$ROOT/out/a6-perf-p1"
[ -f "$BASE/freej2me-rg35xx.jar" ] || fail "R5P3I2 platform missing"
rm -rf "$DST"; mkdir -p "$DST"
cp -a "$BASE/." "$DST/"

PLATFORM_SHA="$(sha256sum "$BASE/freej2me-rg35xx.jar" | awk '{print $1}')"
INPUT_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_video.so" | awk '{print $1}')"

# Exact tested Java platform and input native must remain unchanged.
[ "$PLATFORM_SHA" = '8ecbcb1964967e55994ba2401471c19fb23f9efdc285a568c2c303b0fb54cafd' ] || fail "platform JAR changed $PLATFORM_SHA"
[ "$INPUT_SHA" = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d' ] || fail "input native changed $INPUT_SHA"
[ "$VIDEO_SHA" != '9094819d7c81576b63bd0cde9531404a3fb82b8d5b845dbae152152f2e1a2a7a' ] || fail "video native did not change"

# Static owner/scope gates on the staged native presenter.
SRC="$ROOT/adapter/native/rg35xx_video_sdl1.c"
grep -q 'static int perf_xmap\[RG35XX_LCD_W\]' "$SRC" || fail "xmap cache missing"
grep -q 'static int perf_ymap\[RG35XX_LCD_H\]' "$SRC" || fail "ymap cache missing"
grep -q 'int sx = perf_xmap\[x\];' "$SRC" || fail "cached sx missing"
grep -q 'int sy = perf_ymap\[y\];' "$SRC" || fail "cached sy missing"
grep -q 'RG35XX_PERF_P1_FRAME=' "$SRC" || fail "perf metric missing"
python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end=s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
b=s[start:end]
# Divisions may exist only in geometry-map rebuild, exactly once per axis.
if b.count('((long long)x * width) / dw') != 1:
    raise SystemExit('A6_PERF_P1_GATE_FAIL x division count='+str(b.count('((long long)x * width) / dw')))
if b.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P1_GATE_FAIL y division count='+str(b.count('((long long)y * height) / dh')))
if b.count('for (y = 0; y < RG35XX_LCD_H; ++y)') != 1:
    raise SystemExit('A6_PERF_P1_GATE_FAIL framebuffer clear scope')
print('A6_PERF_P1_DIVISION_GATE=PASS')
print('A6_PERF_P1_CLEAR_GATE=PASS')
PY

cp "$ROOT/out/a3/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$ROOT/out/a3/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$SRC" "$DST/A6-PERF-P1-VIDEO-SOURCE.c"
cat > "$DST/A6-PERF-P1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-P1-CACHED-NATIVE-PRESENTER
BASE_DEVICE_PLATFORM=R5P3I2
BASE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
PERF_EVIDENCE_BASELINE_FPS_APPROX=10.4
GAME_TARGET_FRAME_MS=50
GAME_TARGET_FPS=20
A6_PERF_P1_OWNER=RG35XX_NATIVE_PRESENT_SCALER
A6_PERF_P1_XY_MAP=CACHED_ON_GEOMETRY_CHANGE
A6_PERF_P1_BLACK_CLEAR=GEOMETRY_CHANGE_ONLY
A6_PERF_P1_PIXEL_FORMAT=UNCHANGED_SDL_MAPRGB
A6_PERF_P1_SCALING=UNCHANGED_NEAREST_NEIGHBOR
A6_PERF_P1_JAVA_PLATFORM=UNCHANGED_EXACT_R5P3I2
A6_PERF_P1_INPUT_NATIVE=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
PERFORMANCE-DEVICE-TEST=PENDING
STABLE=NO
EOF
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_PERF_P1_OWNER=RG35XX_NATIVE_PRESENT_SCALER
A6_PERF_P1_SCOPE=VIDEO_NATIVE_CACHED_XY_MAP+GEOMETRY_CLEAR_ONLY
A6_PERF_P1_JAVA_PLATFORM=UNCHANGED_EXACT_R5P3I2
CANONICAL_GITLINK_MUTATED=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_PERF_P1_BUILD=PASS
cat "$DST/A6-PERF-P1-IDENTITY.txt"
