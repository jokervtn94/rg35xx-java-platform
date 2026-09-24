#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_PERF_P3_BUILD_FAIL=$*" >&2; exit 1; }

# Java/runtime semantics remain exact R5P3I2. Native output already contains PERF-P3.
bash "$ROOT/scripts/build-a6-raw-drawrect-r5p3i2.sh"
BASE="$ROOT/out/a6-realgame-r5p3i2"
DST="$ROOT/out/a6-perf-p3"
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
[ "$VIDEO_SHA" != '756425b563c195dae53e88064272c7a33890fb5189390a6f07c636d5f10d61b6' ] || fail "video native identical to PERF-P2"
echo A6_PERF_P3_JAVA_ENTRY_SEMANTIC_GATE=PASS

SRC="$ROOT/adapter/native/rg35xx_video_sdl1.c"
# P1/P2 gains must remain present.
grep -q 'static int perf_xmap\[RG35XX_LCD_W\]' "$SRC" || fail "PERF-P1 xmap cache lost"
grep -q 'perf2_fast_rgb' "$SRC" || fail "PERF-P2 direct pack lost"
grep -q 'RG35XX_PERF_P2_PIXEL_PACK=FAST' "$SRC" || fail "PERF-P2 format marker lost"
# P3 fixed geometry scaler gates.
grep -q 'static uint32_t perf3_row\[360\]' "$SRC" || fail "P3 row cache missing"
grep -q 'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480' "$SRC" || fail "P3 runtime scaler marker missing"
grep -q 'width == 240 && height == 320 && dw == 360 && dh == 480' "$SRC" || fail "P3 exact geometry gate missing"
grep -q 'memcpy(dst0, perf3_row, 360u \* sizeof(uint32_t))' "$SRC" || fail "P3 row copy missing"
grep -q 'RG35XX_PERF_P3_FRAME=' "$SRC" || fail "P3 telemetry missing"
python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end=s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
b=s[start:end]
if b.count('((long long)x * width) / dw') != 1 or b.count('((long long)y * height) / dh') != 1:
    raise SystemExit('A6_PERF_P3_GATE_FAIL coordinate division regression')
if b.count('SDL_MapRGB_p(screen->format') != 2:
    raise SystemExit('A6_PERF_P3_GATE_FAIL MapRGB source count='+str(b.count('SDL_MapRGB_p(screen->format'))))
if b.count('memcpy(') != 2:
    raise SystemExit('A6_PERF_P3_GATE_FAIL expected two P3 row memcpy sites, got '+str(b.count('memcpy(')))
if 'else if (perf2_fast_rgb)' not in b:
    raise SystemExit('A6_PERF_P3_GATE_FAIL generic PERF-P2 fallback lost')
print('A6_PERF_P3_EXACT_GEOMETRY_GATE=PASS')
print('A6_PERF_P3_P1_P2_REGRESSION_GATE=PASS')
print('A6_PERF_P3_GENERIC_FALLBACK_GATE=PASS')
PY

cp "$ROOT/out/a3/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$ROOT/out/a3/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$SRC" "$DST/A6-PERF-P3-VIDEO-SOURCE.c"
cat > "$DST/A6-PERF-P3-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-P3-FAST-3TO2-SCALER
BASE_DEVICE_PLATFORM=R5P3I2
BASE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
BASE_PLATFORM_SEMANTIC_SHA256=$PLATFORM_SEMANTIC_SHA
BASE_DEVICE_TESTED_SEMANTIC_SHA256=$EXPECTED_SEMANTIC_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
PERF_P1_DEVICE_RESULT=PASS_FUNCTIONAL_NORMAL_EXIT
PERF_P1_DEVICE_AVG_FPS=14.95
PERF_P2_DEVICE_FAST_PACK=PASS
PERF_P2_DEVICE_LAST_FRAME=8400
PERF_P2_DEVICE_LAST_CUMULATIVE_FPS=15.41
GAME_TARGET_FRAME_MS=50
GAME_TARGET_FPS=20
A6_PERF_P3_OWNER=RG35XX_3_TO_2_SCALER_DESTINATION_PIXEL_OVERWORK
A6_PERF_P3_EXACT_GEOMETRY=240x320_TO_360x480
A6_PERF_P3_SOURCE_PACKS_PER_FRAME=76800
A6_PERF_P3_OLD_DEST_PACKS_PER_FRAME=172800
A6_PERF_P3_VERTICAL_DUPLICATION=ROW_MEMCPY
A6_PERF_P3_GENERIC_FALLBACK=PERF_P2
A6_PERF_P3_JAVA_PLATFORM=ENTRY_BYTE_EXACT_R5P3I2
A6_PERF_P3_JAVA_ENTRY_SEMANTIC_GATE=PASS
A6_PERF_P3_INPUT_NATIVE=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
PERFORMANCE-DEVICE-TEST=PENDING
STABLE=NO
EOF
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_PERF_P3_OWNER=RG35XX_3_TO_2_SCALER_DESTINATION_PIXEL_OVERWORK
A6_PERF_P3_SCOPE=VIDEO_NATIVE_EXACT_3_TO_2_SCALER_WITH_PERF_P2_FALLBACK
A6_PERF_P3_JAVA_PLATFORM=ENTRY_BYTE_EXACT_R5P3I2
A6_PERF_P3_JAVA_ENTRY_SEMANTIC_GATE=PASS
A6_PERF_P3_INPUT_NATIVE=UNCHANGED
CANONICAL_GITLINK_MUTATED=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_PERF_P3_BUILD=PASS
cat "$DST/A6-PERF-P3-IDENTITY.txt"
