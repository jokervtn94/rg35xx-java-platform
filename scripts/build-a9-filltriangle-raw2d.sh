#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A9_FILLTRIANGLE_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

PARENT="$ROOT/out/a7-audio-sdl1"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DST="$ROOT/out/a9-filltriangle-raw2d"
CLASSES="$BUILD/a9-filltriangle-classes"
PG_SRC="$BUILD/stage-src/org/recompile/mobile/PlatformGraphics.java"

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so; do
  [ -f "$PARENT/$f" ] || fail "accepted A7 artifact missing: $f"
done
[ -f "$PG_SRC" ] || fail "accepted staged PlatformGraphics source missing"

semantic_digest() {
python3 - "$1" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
}

PARENT_SEMANTIC="$(semantic_digest "$PARENT_JAR")"
[ "$PARENT_SEMANTIC" = "7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf" ] || fail "accepted A7 semantic mismatch $PARENT_SEMANTIC"
INPUT_SHA="$(sha256sum "$PARENT/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$PARENT/librg35xx_video.so" | awk '{print $1}')"
AUDIO_SHA="$(sha256sum "$PARENT/libaudio.so" | awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native changed $INPUT_SHA"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native changed $VIDEO_SHA"
[ "$AUDIO_SHA" = "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644" ] || fail "audio native changed $AUDIO_SHA"
echo A9_FILLTRIANGLE_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-a9-rg35xx-filltriangle-raw2d.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical worktree dirty"

rm -rf "$CLASSES" "$DST"
mkdir -p "$CLASSES" "$DST"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/a9-filltriangle-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/a9-filltriangle-sources.list"

CANDIDATE_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$CANDIDATE_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then
  "$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$UPSTREAM" META-INF
fi

python3 - "$PARENT_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A9_FILLTRIANGLE_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/mobile/PlatformGraphics.class']
if diff != expected:
    raise SystemExit('A9_FILLTRIANGLE_SCOPE_FAIL changed='+repr(diff))
print('A9_FILLTRIANGLE_CHANGED_ENTRIES='+','.join(diff))
print('A9_FILLTRIANGLE_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
if bad: raise SystemExit('A9_FILLTRIANGLE_JAVA6_FAIL '+repr(bad[:20]))
print('A9_FILLTRIANGLE_JAVA6_GATE=PASS')
PY

python3 - "$PG_SRC" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.index('\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)')
end=s.index('\n\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)', start)
m=s[start:end]
required=[
    'platformImage != null && platformImage.isRG35XXRaw()',
    'x1 += translateX; y1 += translateY;',
    'int[] pixels = platformImage.getRG35XXPixels();',
    'int clipL = clipX < 0 ? 0 : clipX;',
    'Arrays.fill(pixels, yy * pw + left, yy * pw + right + 1, argb);',
    'gc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);']
for token in required:
    if token not in m:
        raise SystemExit('A9_FILLTRIANGLE_SOURCE_GATE_FAIL missing '+token)
for forbidden in ['rg35xxFillPolygon', 'drawLine(', 'strokeStyle = SOLID']:
    if forbidden in m:
        raise SystemExit('A9_FILLTRIANGLE_SOURCE_GATE_FAIL forbidden '+forbidden)
argb=s[end:s.index('\n\tpublic void getPixels', end)]
if 'platformImage.isRG35XXRaw()' in argb or 'Arrays.fill(' in argb or 'rg35xxFillPolygon' in argb:
    raise SystemExit('A9_FILLTRIANGLE_SOURCE_GATE_FAIL 7arg overload broadened')
print('A9_FILLTRIANGLE_SOURCE_GATE=PASS')
print('A9_FILLTRIANGLE_R2_DIRECT_SPAN_GATE=PASS')
print('A9_FILLTRIANGLE_REJECTED_GENERIC_POLYGON_REINTRODUCED=NO')
PY

HOST="$BUILD/a9-filltriangle-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$HOST" "$ROOT/tests/a9/RG35XXRawFillTriangleHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$HOST" org.recompile.rg35xx.a9.RG35XXRawFillTriangleHostGate \
  | tee "$DST/A9-FILLTRIANGLE-HOST-GATE.txt"
for marker in A9_FILLTRIANGLE_HOST_GATE=PASS A9_FILLTRIANGLE_TRANSLATE_CLIP_GATE=PASS A9_FILLTRIANGLE_DEGENERATE_GATE=PASS; do
  grep -q "^${marker}$" "$DST/A9-FILLTRIANGLE-HOST-GATE.txt" || fail "fillTriangle host gate ${marker}"
done

run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/a9-reg-$(basename "$src" .java)"
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

cp "$PARENT/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$PARENT/libaudio.so" "$DST/libaudio.so"
head -c 123480 /dev/zero > "$DST/a7-a1p5-rw-silence-prime.s32le"
[ "$(sha256sum "$DST/a7-a1p5-rw-silence-prime.s32le" | awk '{print $1}')" = "8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e" ] || fail "prime identity"

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
CANDIDATE_SEMANTIC="$(semantic_digest "$CANDIDATE_JAR")"
"$JAVA8/bin/javap" -classpath "$CANDIDATE_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$DST/A9-FILLTRIANGLE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$DST/A9-FILLTRIANGLE-PLATFORMGRAPHICS-SOURCE.java.txt"

cat > "$DST/A9-FILLTRIANGLE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A9-FILLTRIANGLE-RAW2D-R2-CANDIDATE
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EVIDENCE_GAME=Asphalt_4_Elite_Racing
EVIDENCE_GAME_SHA256=b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b
EVIDENCE_EXCEPTION_R1_FIXED=java.lang.NullPointerException_at_org.recompile.mobile.PlatformGraphics.fillTriangle
R1_DEVICE_RESULT=GAMEPLAY_REACHED_BUT_LAG_AUDIO_PARTIAL_EXIT_HARD_RESET
R1_FRAME300_FPS_X100=1841
R1_FRAME600_FPS_X100=1587
R1_QUEUE600_DROPPED=3
R1_COPY_AVG_MS=1
R2_PERFORMANCE_OWNER=R1_FILLTRIANGLE_SCANLINE_REENTERED_JAVA_DRAWLINE_PER_SPAN
PARENT_PLATFORM_SEMANTIC_SHA256=$PARENT_SEMANTIC
CANDIDATE_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CANDIDATE_SEMANTIC
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
AUDIO_NATIVE_SHA256=$AUDIO_SHA
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
CHANGED_JAR_SCOPE=org/recompile/mobile/PlatformGraphics.class
DELTA=STANDARD_6ARG_FILLTRIANGLE_RAW_SCANLINE_DIRECT_ARRAYS_FILL
RAW_IMPL=SCANLINE_CLIPPED_SPANS_DIRECT_RAW_FRAMEBUFFER_FILL
REJECTED_GENERIC_POLYGON_REINTRODUCED=NO
CANONICAL_AWT_FALLBACK=UNCHANGED
DIRECTGRAPHICS_7ARG_FILLTRIANGLE=UNCHANGED
A9_FILLTRIANGLE_SOURCE_GATE=PASS
A9_FILLTRIANGLE_HOST_GATE=PASS
A6_REGRESSION_GATES=PASS
PROTECTED_NATIVE_IDENTITIES=PASS
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$DST" && find . -type f ! -name 'A9-ARTIFACT-SHA256SUMS.txt' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > A9-ARTIFACT-SHA256SUMS.txt)
(cd "$DST" && sha256sum -c A9-ARTIFACT-SHA256SUMS.txt)
echo A9_FILLTRIANGLE_BUILD=PASS
cat "$DST/A9-FILLTRIANGLE-IDENTITY.txt"
