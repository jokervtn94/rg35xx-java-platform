#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A6_ARCHDIAG_BUILD_FAIL=$*" >&2; exit 1; }

# Rebuild exact R5P3I2 Java/runtime semantics and package the already-staged
# PERF-P3 native presenter plus sampled timing telemetry.
bash "$ROOT/scripts/build-a6-perf-p3.sh"
BASE="$ROOT/out/a6-perf-p3"
DST="$ROOT/out/a6-perf-archdiag"
rm -rf "$DST"; mkdir -p "$DST"
cp -a "$BASE/." "$DST/"

PLATFORM_SHA="$(sha256sum "$BASE/freej2me-rg35xx.jar" | awk '{print $1}')"
INPUT_SHA="$(sha256sum "$BASE/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$BASE/librg35xx_video.so" | awk '{print $1}')"
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
EXPECTED_SEMANTIC='b79cafa98c467436cf0e782b069839e993a7dc7bdb31b9a423b47c0ff293950e'
P3_VIDEO='c361433a2c853986318938961fa978d01f085640a3a6e839e2b26656f38ff999'
INPUT_EXPECTED='69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d'
[ "$PLATFORM_SEMANTIC_SHA" = "$EXPECTED_SEMANTIC" ] || fail "platform semantic changed $PLATFORM_SEMANTIC_SHA"
[ "$INPUT_SHA" = "$INPUT_EXPECTED" ] || fail "input changed $INPUT_SHA"
[ "$VIDEO_SHA" != "$P3_VIDEO" ] || fail "diagnostic video unexpectedly identical to device P3"

SRC="$ROOT/adapter/native/rg35xx_video_sdl1.c"
grep -q 'RG35XX_PERF_P3_SCALER=FAST_3_TO_2_240x320_TO_360x480' "$SRC" || fail "P3 scaler lost"
grep -q 'RG35XX_PERF_P2_PIXEL_PACK=FAST' "$SRC" || fail "P2 pack lost"
grep -q 'RG35XX_ARCH_DIAG_PRESENT SAMPLES=' "$SRC" || fail "architecture diagnostic marker missing"
grep -q '((perf_frame_count + 1ul) % 60ul) == 0ul' "$SRC" || fail "sample cadence changed"
python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('Java_org_recompile_rg35xx_RG35XXVideo_presentARGB')
end=s.index('Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay', start)
b=s[start:end]
# Functional P3 hot path remains exactly one physical flip per present.
if b.count('SDL_Flip_p(screen)') != 1:
    raise SystemExit('A6_ARCHDIAG_SCOPE_FAIL SDL_Flip count='+str(b.count('SDL_Flip_p(screen)')))
# Timing only: no sleeps, no extra present call, no thread creation.
for bad in ('Thread.sleep','pthread_create','usleep(','nanosleep('):
    if bad in b:
        raise SystemExit('A6_ARCHDIAG_SCOPE_FAIL unexpected '+bad)
for need in ('archdiag_array_ms','archdiag_scale_ms','archdiag_release_ms','archdiag_flip_ms','archdiag_total_ms'):
    if need not in b:
        raise SystemExit('A6_ARCHDIAG_SCOPE_FAIL missing '+need)
print('A6_ARCHDIAG_SCOPE_GATE=PASS')
print('A6_ARCHDIAG_SEMANTIC_CHANGE=NO')
PY

cp "$SRC" "$DST/A6-PERF-ARCHDIAG-VIDEO-SOURCE.c"
cat > "$DST/A6-PERF-ARCHDIAG-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-ARCHDIAG-PRESENT-PHASE-TIMING
PARENT_DEVICE_PLATFORM=PERF-P3
PARENT_DEVICE_RESULT=PASS_FUNCTIONAL_NORMAL_EXIT_PROTECTED_HASHES
PARENT_DEVICE_CUMULATIVE_FPS=16.56
PARENT_DEVICE_LAST6_WINDOW_FPS=18.13
BASE_PLATFORM_JAR_SHA256=$PLATFORM_SHA
BASE_PLATFORM_SEMANTIC_SHA256=$PLATFORM_SEMANTIC_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
PARENT_PERF_P3_VIDEO_SHA256=$P3_VIDEO
DIAGNOSTIC_VIDEO_SHA256=$VIDEO_SHA
GAME_TARGET_FRAME_MS=50
GAME_TARGET_FPS=20
A6_ARCHDIAG_REASON=PARENT_CANNOT_ISOLATE_JNI_SCALE_RELEASE_FLIP_COST
A6_ARCHDIAG_SAMPLE_EVERY_FRAMES=60
A6_ARCHDIAG_REPORT_EVERY_FRAMES=300
A6_ARCHDIAG_PHASES=ARRAY,SCALE,RELEASE,FLIP,TOTAL
A6_ARCHDIAG_SEMANTIC_CHANGE=NO
A6_ARCHDIAG_P3_RENDER_PATH=PRESERVED
A6_ARCHDIAG_INPUT_NATIVE=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
DIAGNOSTIC-DEVICE-TEST=PENDING
STABLE=NO
EOF
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_ARCHDIAG_REASON=PARENT_CANNOT_ISOLATE_JNI_SCALE_RELEASE_FLIP_COST
A6_ARCHDIAG_SCOPE=VIDEO_NATIVE_TIMING_TELEMETRY_ONLY
A6_ARCHDIAG_SAMPLE_EVERY_FRAMES=60
A6_ARCHDIAG_SEMANTIC_CHANGE=NO
A6_ARCHDIAG_JAVA_PLATFORM=ENTRY_BYTE_EXACT_R5P3I2
A6_ARCHDIAG_INPUT_NATIVE=UNCHANGED
CANONICAL_GITLINK_MUTATED=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_ARCHDIAG_BUILD=PASS
cat "$DST/A6-PERF-ARCHDIAG-IDENTITY.txt"
