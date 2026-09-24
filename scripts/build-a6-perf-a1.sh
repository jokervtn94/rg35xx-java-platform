#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_PERF_A1_BUILD_FAIL=$*" >&2; exit 1; }

# Java/game semantics remain exact device-proven R5P3I2/PERF-P3.
bash "$ROOT/scripts/build-a6-raw-drawrect-r5p3i2.sh"
BASE="$ROOT/out/a6-realgame-r5p3i2"
DST="$ROOT/out/a6-perf-a1"
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
EXPECTED_INPUT_SHA='69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d'
P3_VIDEO_SHA='c361433a2c853986318938961fa978d01f085640a3a6e839e2b26656f38ff999'
[ "$PLATFORM_SEMANTIC_SHA" = "$EXPECTED_SEMANTIC_SHA" ] || fail "platform semantic digest changed $PLATFORM_SEMANTIC_SHA"
[ "$INPUT_SHA" = "$EXPECTED_INPUT_SHA" ] || fail "input native changed $INPUT_SHA"
[ "$VIDEO_SHA" != "$P3_VIDEO_SHA" ] || fail "A1 video unexpectedly identical to synchronous P3"
echo A6_PERF_A1_JAVA_SEMANTIC_GATE=PASS

SRC="$ROOT/adapter/native/rg35xx_video_sdl1.c"
# P1/P2/P3 rendering must remain available as the fallback and worker algorithm.
grep -q 'static int perf_xmap\[RG35XX_LCD_W\]' "$SRC" || fail "PERF-P1 xmap cache lost"
grep -q 'perf2_fast_rgb' "$SRC" || fail "PERF-P2 direct pack lost"
grep -q 'static uint32_t perf3_row\[360\]' "$SRC" || fail "PERF-P3 row cache lost"
grep -q 'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480' "$SRC" || fail "P3 scaler marker lost"
# A1 architecture gates.
grep -q 'RG35XX_PERF_A1_ASYNC=ENABLED MODE=LATEST_ONLY SLOTS=3 SOURCE=240x320 WORKER=P3_SCALE_PLUS_SDL_FLIP' "$SRC" || fail "A1 enable marker missing"
grep -q 'RG35XX_PERF_A1_QUEUE SUBMITS=' "$SRC" || fail "A1 queue telemetry missing"
grep -q 'memcpy(perf_a1_frames\[slot\], src, PERF_A1_PIXELS \* sizeof(uint32_t))' "$SRC" || fail "A1 source snapshot missing"
grep -q 'perf_a1_render_exact(perf_a1_frames\[slot\])' "$SRC" || fail "A1 worker render missing"
grep -q 'RG35XX_PERF_A1_ASYNC=GEOMETRY_CHANGE_FALLBACK_P3' "$SRC" || fail "A1 geometry fallback missing"
grep -q 'perf_a1_stop();' "$SRC" || fail "A1 shutdown join missing"
# The architecture diagnostic must not leak into the candidate.
! grep -q 'RG35XX_ARCH_DIAG_PRESENT' "$SRC" || fail "ARCH-DIAG contamination"

python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end=s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
b=s[start:end]
if b.count('SDL_Flip_p(screen)') != 1:
    raise SystemExit('A6_PERF_A1_GATE_FAIL JNI synchronous fallback flip count='+str(b.count('SDL_Flip_p(screen)')))
if 'width == PERF_A1_W && height == PERF_A1_H' not in b:
    raise SystemExit('A6_PERF_A1_GATE_FAIL exact async geometry gate missing')
if 'perf_a1_stop();' not in b:
    raise SystemExit('A6_PERF_A1_GATE_FAIL generic fallback stop missing')
if 'memcpy(perf_a1_frames[slot], src, PERF_A1_PIXELS * sizeof(uint32_t));' not in b:
    raise SystemExit('A6_PERF_A1_GATE_FAIL snapshot missing')
helper=s[s.index('static int perf_a1_render_exact'):s.index('static int perf_a1_worker_main')]
for token in ['perf3_row[dx++] = p0;', 'perf3_row[dx++] = p1;', 'SDL_Flip_p(screen)', 'RG35XX_PERF_P3_FRAME=']:
    if token not in helper:
        raise SystemExit('A6_PERF_A1_GATE_FAIL worker P3 token missing '+token)
if helper.count('SDL_Flip_p(screen)') != 1:
    raise SystemExit('A6_PERF_A1_GATE_FAIL worker flip count')
print('A6_PERF_A1_NATIVE_SCOPE_GATE=PASS')
print('A6_PERF_A1_P3_WORKER_GATE=PASS')
print('A6_PERF_A1_GENERIC_FALLBACK_GATE=PASS')
PY

cp "$ROOT/out/a3/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$ROOT/out/a3/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$SRC" "$DST/A6-PERF-A1-VIDEO-SOURCE.c"
cat > "$DST/A6-PERF-A1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-A1-NATIVE-ASYNC-LATEST-FRAME
PARENT_DEVICE_PLATFORM=PERF-P3
PARENT_DEVICE_RESULT=PASS_FUNCTIONAL_NORMAL_EXIT_PROTECTED_HASHES
PARENT_DEVICE_CUMULATIVE_FPS=16.56
ARCHDIAG_DEVICE_RESULT=PASS_NORMAL_EXIT_PROTECTED_HASHES
ARCHDIAG_SAMPLE_WINDOWS=18
ARCHDIAG_SAMPLE_FRAMES=90
ARCHDIAG_ARRAY_AVG_MS=0.00
ARCHDIAG_SCALE_AVG_MS=1.89
ARCHDIAG_RELEASE_AVG_MS=0.00
ARCHDIAG_FLIP_AVG_MS=4.06
ARCHDIAG_TOTAL_AVG_MS=6.22
GAME_TARGET_FRAME_MS=50
A6_PERF_A1_OWNER=SYNCHRONOUS_P3_SCALE_PLUS_SDL_FLIP_6P22MS_AVG
BASE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
BASE_PLATFORM_SEMANTIC_SHA256=$PLATFORM_SEMANTIC_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
PARENT_PERF_P3_VIDEO_SHA256=$P3_VIDEO_SHA
PERF_A1_VIDEO_SHA256=$VIDEO_SHA
A6_PERF_A1_JAVA_PLATFORM=EXACT_DEVICE_TESTED_PERF_P3
A6_PERF_A1_INPUT_NATIVE=UNCHANGED
A6_PERF_A1_QUEUE=LATEST_ONLY_3_NATIVE_SLOTS
A6_PERF_A1_WORKER=EXACT_P3_SCALE_PLUS_SDL_FLIP
A6_PERF_A1_PRODUCER=JNI_SNAPSHOT_AND_RETURN
A6_PERF_A1_GENERIC_GEOMETRY=STOP_ASYNC_AND_SYNC_P3_FALLBACK
A6_PERF_A1_ARCHDIAG_CONTAMINATION=NO
PERF_J1_DEVICE_RESULT=REJECTED_STARTUP_REGRESSION
BUILD-PASS=YES
DEVICE-PASS=NO
PERFORMANCE-DEVICE-TEST=PENDING
STABLE=NO
EOF
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_PERF_A1_OWNER=SYNCHRONOUS_P3_SCALE_PLUS_SDL_FLIP_6P22MS_AVG
A6_PERF_A1_SCOPE=VIDEO_NATIVE_ASYNC_LATEST_FRAME_ONLY
A6_PERF_A1_JAVA_PLATFORM=EXACT_DEVICE_TESTED_PERF_P3
A6_PERF_A1_INPUT_NATIVE=UNCHANGED
A6_PERF_A1_GENERIC_GEOMETRY=SYNC_P3_FALLBACK
CANONICAL_GITLINK_MUTATED=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_PERF_A1_BUILD=PASS
cat "$DST/A6-PERF-A1-IDENTITY.txt"
