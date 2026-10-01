#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A9_CORE2D_BLIT_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# First rebuild the exact R1 functional fillTriangle parent. This branch is
# intentionally based on the R1 commit before the unvalidated R2 triangle-span
# optimization, so the new performance delta is isolated to Core2D blit.
bash "$ROOT/scripts/build-a9-filltriangle-raw2d.sh"

R1="$ROOT/out/a9-filltriangle-raw2d"
R1_JAR="$R1/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
SRC="$ROOT/adapter/java/org/recompile/rg35xx/RG35XXCore2D.java"
DST="$ROOT/out/a9-core2d-blit-perf"
CLASSES="$BUILD/a9-core2d-blit-classes"

[ -f "$R1_JAR" ] || fail "R1 parent jar missing"
[ -f "$SRC" ] || fail "Core2D source missing"
R1_SHA="$(sha256sum "$R1_JAR" | awk '{print $1}')"
[ "$R1_SHA" = "c4a5adff83c89c891531b2693558583a773a8f8297386f4d36a3cb21ee65f201" ] || fail "R1 platform hash mismatch $R1_SHA"
for f in librg35xx_input.so librg35xx_video.so libaudio.so a7-a1p5-rw-silence-prime.s32le; do
  [ -f "$R1/$f" ] || fail "R1 protected payload missing: $f"
done

echo A9_CORE2D_BLIT_R1_PARENT_IDENTITY=PASS

python3 "$ROOT/scripts/stage-a9-rg35xx-core2d-blit-nocopy.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical Aweigit worktree dirty"

python3 - "$SRC" <<'PY'
import sys
s=open(sys.argv[1], encoding='utf-8').read()
start=s.index('    /** Source-over ARGB blit with clipping and an optional MIDP transform. */')
end=s.index('\n    private static RawImage subRaw', start)
m=s[start:end]
for token in [
    'if (transform == 0)',
    'srcX + width > srcWidth || srcY + height > srcHeight',
    'int sy = srcY + (y - dstY);',
    'int si = sy * srcWidth + srcX + (left - dstX);',
    'sourceOver(src[si], dst[di])',
    'RawImage r = transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);']:
    if token not in m:
        raise SystemExit('A9_CORE2D_BLIT_SOURCE_GATE_FAIL missing '+token)
if 'subRaw(' in m:
    raise SystemExit('A9_CORE2D_BLIT_SOURCE_GATE_FAIL transform-zero temp copy still referenced')
# sourceOver itself must remain present outside the staged method and unmodified by
# this transformer; the transformer performs one exact method replacement only.
if 'private static int sourceOver(int s, int d)' not in s:
    raise SystemExit('A9_CORE2D_BLIT_SOURCE_GATE_FAIL sourceOver missing')
print('A9_CORE2D_BLIT_SOURCE_GATE=PASS')
print('A9_CORE2D_BLIT_TRANSFORM0_TEMP_COPY=REMOVED')
print('A9_CORE2D_BLIT_SOURCE_OVER=UNCHANGED')
print('A9_CORE2D_BLIT_TRANSFORMED_PATH=UNCHANGED')
PY

rm -rf "$CLASSES" "$DST"
mkdir -p "$CLASSES" "$DST"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/a9-core2d-blit-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/a9-core2d-blit-sources.list"

CANDIDATE_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$CANDIDATE_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then
  "$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$UPSTREAM" META-INF
fi

# Relative to the device-proven R1 functional fix, exactly one Java class may
# differ: the Core2D helper that owns the temporary-copy hotspot.
python3 - "$R1_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A9_CORE2D_BLIT_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist())
          if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/rg35xx/RG35XXCore2D.class']
if diff != expected:
    raise SystemExit('A9_CORE2D_BLIT_SCOPE_FAIL changed='+repr(diff))
print('A9_CORE2D_BLIT_CHANGED_FROM_R1='+','.join(diff))
print('A9_CORE2D_BLIT_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
if bad: raise SystemExit('A9_CORE2D_BLIT_JAVA6_FAIL '+repr(bad[:20]))
print('A9_CORE2D_BLIT_JAVA6_GATE=PASS')
PY

HOST="$BUILD/a9-core2d-blit-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$HOST" "$ROOT/tests/a9/RG35XXCore2DBlitNoCopyHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$HOST" org.recompile.rg35xx.a9.RG35XXCore2DBlitNoCopyHostGate \
  | tee "$DST/A9-CORE2D-BLIT-HOST-GATE.txt"
grep -q '^A9_CORE2D_BLIT_NOCOPY_HOST_GATE=PASS$' "$DST/A9-CORE2D-BLIT-HOST-GATE.txt" || fail "no-copy host gate"
grep -q '^A9_CORE2D_BLIT_TRANSFORM_REGRESSION_GATE=PASS$' "$DST/A9-CORE2D-BLIT-HOST-GATE.txt" || fail "transform regression host gate"

# Preserve the original A5 alpha arithmetic gate.
A5HOST="$BUILD/a9-core2d-blit-a5host"
rm -rf "$A5HOST"; mkdir -p "$A5HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$A5HOST" "$ROOT/tests/a5/RG35XXCore2DHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$A5HOST" org.recompile.rg35xx.a5.RG35XXCore2DHostGate \
  | tee "$DST/A5-CORE2D-REGRESSION-GATE.txt"
grep -q '^A5_CORE2D_ALPHA_HOST_GATE=PASS$' "$DST/A5-CORE2D-REGRESSION-GATE.txt" || fail "A5 Core2D regression"

# Preserve the R1 fillTriangle fix that enabled Asphalt 4 gameplay.
TRIHOST="$BUILD/a9-core2d-blit-trihost"
rm -rf "$TRIHOST"; mkdir -p "$TRIHOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$TRIHOST" "$ROOT/tests/a9/RG35XXRawFillTriangleHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$TRIHOST" org.recompile.rg35xx.a9.RG35XXRawFillTriangleHostGate \
  | tee "$DST/A9-FILLTRIANGLE-R1-REGRESSION-GATE.txt"
grep -q '^A9_FILLTRIANGLE_HOST_GATE=PASS$' "$DST/A9-FILLTRIANGLE-R1-REGRESSION-GATE.txt" || fail "R1 fillTriangle regression"

run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/a9-blit-reg-$(basename "$src" .java)"
  rm -rf "$dir"; mkdir -p "$dir"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
    -d "$dir" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$dir" "$cls" | tee "$DST/$out"
  grep -q "^${marker}$" "$DST/$out" || fail "regression gate $src"
}

run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate \
  A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-R5P3I2-DRAWRECT-REGRESSION-GATE.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-R5-DRAWLINE-REGRESSION-GATE.txt
run_gate RG35XXRawRectPolygonHostGate.java org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate \
  A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS A6-R5P3-POLYGON-REGRESSION-GATE.txt
run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate \
  A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION-GATE.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION-GATE.txt

cp "$R1/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$R1/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$R1/libaudio.so" "$DST/libaudio.so"
cp "$R1/a7-a1p5-rw-silence-prime.s32le" "$DST/a7-a1p5-rw-silence-prime.s32le"

INPUT_SHA="$(sha256sum "$DST/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$DST/librg35xx_video.so" | awk '{print $1}')"
AUDIO_SHA="$(sha256sum "$DST/libaudio.so" | awk '{print $1}')"
PRIME_SHA="$(sha256sum "$DST/a7-a1p5-rw-silence-prime.s32le" | awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native changed"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native changed"
[ "$AUDIO_SHA" = "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644" ] || fail "audio native changed"
[ "$PRIME_SHA" = "8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e" ] || fail "prime changed"

echo A9_CORE2D_BLIT_PROTECTED_NATIVE_IDENTITIES=PASS

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
"$JAVA8/bin/javap" -classpath "$CANDIDATE_JAR" -p -c org.recompile.rg35xx.RG35XXCore2D > "$DST/A9-CORE2D-BLIT-JAVAP.txt"
cp "$SRC" "$DST/A9-CORE2D-BLIT-SOURCE.java.txt"

cat > "$DST/A9-CORE2D-BLIT-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A9-CORE2D-BLIT-PERF-CANDIDATE
BASELINE=A9_R1_FUNCTIONAL_FILLTRIANGLE
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EVIDENCE_GAME=Asphalt_4_Elite_Racing
EVIDENCE_GAME_SHA256=b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b
R1_PLATFORM_SHA256=$R1_SHA
SYSTEM_PROFILE_PROCESS_CPU_MEAN_PCT_APPROX=111.5
SYSTEM_PROFILE_HOT_THREAD_CPU_PCT_APPROX=95
SYSTEM_PROFILE_PRESENTER_COPY_AVG_MS=1
PERF_OWNER_CANDIDATE=A5_CORE2D_TRANSFORM0_BLIT_TEMP_COPY
CANDIDATE_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
CHANGED_FROM_R1_SCOPE=org/recompile/rg35xx/RG35XXCore2D.class
DELTA=TRANSFORM0_BLIT_READ_SOURCE_WINDOW_DIRECTLY_NO_TEMP_RAWIMAGE
TRANSFORM0_TEMP_COPY=REMOVED
SOURCE_OVER_SEMANTICS=UNCHANGED
TRANSFORMED_BLIT_PATH=UNCHANGED
A9_R1_FILLTRIANGLE=UNCHANGED
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
AUDIO_NATIVE_SHA256=$AUDIO_SHA
PRIME_PCM_SHA256=$PRIME_SHA
A9_CORE2D_BLIT_SOURCE_GATE=PASS
A9_CORE2D_BLIT_NOCOPY_HOST_GATE=PASS
A5_CORE2D_ALPHA_REGRESSION=PASS
A9_R1_FILLTRIANGLE_REGRESSION=PASS
A6_REGRESSION_GATES=PASS
PROTECTED_NATIVE_IDENTITIES=PASS
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$DST" && find . -type f ! -name 'A9-CORE2D-BLIT-SHA256SUMS.txt' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > A9-CORE2D-BLIT-SHA256SUMS.txt)
(cd "$DST" && sha256sum -c A9-CORE2D-BLIT-SHA256SUMS.txt)

echo A9_CORE2D_BLIT_BUILD=PASS
cat "$DST/A9-CORE2D-BLIT-IDENTITY.txt"
