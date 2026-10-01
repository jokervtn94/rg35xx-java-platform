#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "A8_COMP02_FILLTRIANGLE_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

PARENT="$ROOT/out/a7-audio-sdl1"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
DST="$ROOT/out/a8-comp02-filltriangle-boundary"
CLASSES="$BUILD/a8-comp02-filltriangle-classes"

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so; do
  [ -f "$PARENT/$f" ] || fail "accepted A7 parent artifact missing: $f"
done

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

PARENT_SHA="$(sha256sum "$PARENT_JAR" | awk '{print $1}')"
PARENT_SEMANTIC="$(semantic_digest "$PARENT_JAR")"
INPUT_SHA="$(sha256sum "$PARENT/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$PARENT/librg35xx_video.so" | awk '{print $1}')"
AUDIO_SHA="$(sha256sum "$PARENT/libaudio.so" | awk '{print $1}')"

# A8 is a consolidation of this exact A7 semantic runtime. Native owners must
# remain bit-identical because graphics Java backing is the only failure owner.
[ "$PARENT_SEMANTIC" = "7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf" ] || fail "A7/A8 semantic parent changed: $PARENT_SEMANTIC"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input owner changed: $INPUT_SHA"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video owner changed: $VIDEO_SHA"
[ "$AUDIO_SHA" = "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644" ] || fail "audio owner changed: $AUDIO_SHA"
echo A8_COMP02_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-a8-comp02-filltriangle-boundary.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical Aweigit worktree dirty"

rm -rf "$CLASSES" "$DST"
mkdir -p "$CLASSES" "$DST"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/a8-comp02-filltriangle-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/a8-comp02-filltriangle-sources.list"

CANDIDATE_JAR="$DST/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$CANDIDATE_JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then
  "$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$UPSTREAM" META-INF
fi

# Fail closed unless the decompressed JAR differs from the A7/A8 semantic
# parent in exactly PlatformGraphics.class.
python3 - "$PARENT_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('A8_COMP02_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist())
          if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/mobile/PlatformGraphics.class']
if diff != expected:
    raise SystemExit('A8_COMP02_SCOPE_FAIL changed='+repr(diff))
print('A8_COMP02_CHANGED_JAR_ENTRIES='+','.join(diff))
print('A8_COMP02_ONE_CLASS_SCOPE_GATE=PASS')
PY

# Java 6 runtime compatibility remains mandatory.
python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
    pg=z.read('org/recompile/mobile/PlatformGraphics.class')
    if b'Asphalt' in pg or b'b25c855e5b04364e1e5ec36f06f32750' in pg:
        raise SystemExit('A8_COMP02_GAME_SPECIFIC_RUNTIME_CONTAMINATION')
if bad: raise SystemExit('A8_COMP02_JAVA6_FAIL '+repr(bad[:20]))
print('A8_COMP02_JAVA6_GATE=PASS')
print('A8_COMP02_GAME_SPECIFIC_RUNTIME=NO')
PY

# Method-level guard: the seven-argument DirectGraphics overload must retain
# parent bytecode. Only the six-argument MIDP Graphics method gets the raw path.
PARENT_JAVAP="$DST/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
CANDIDATE_JAVAP="$DST/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$PARENT_JAVAP"
"$JAVA8/bin/javap" -classpath "$CANDIDATE_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$CANDIDATE_JAVAP"
python3 - "$PARENT_JAVAP" "$CANDIDATE_JAVAP" <<'PY'
import sys,re
base=open(sys.argv[1],encoding='utf-8').read()
new=open(sys.argv[2],encoding='utf-8').read()

def block(text, sig):
    start=text.find(sig)
    if start < 0: raise SystemExit('A8_COMP02_METHOD_GATE_FAIL missing '+sig)
    m=re.search(r'\n  (?:public|private|protected) ', text[start+len(sig):])
    return text[start:] if not m else text[start:start+len(sig)+m.start()]

sig7='public void fillTriangle(int, int, int, int, int, int, int);'
if block(base,sig7) != block(new,sig7):
    raise SystemExit('A8_COMP02_METHOD_GATE_FAIL DirectGraphics 7arg drift')
sig6='public void fillTriangle(int, int, int, int, int, int);'
b6=block(base,sig6); n6=block(new,sig6)
if b6 == n6: raise SystemExit('A8_COMP02_METHOD_GATE_FAIL six-arg unchanged')
for token in ['isRG35XXRaw', 'rg35xxFillTriangle']:
    if token not in n6: raise SystemExit('A8_COMP02_METHOD_GATE_FAIL six-arg missing '+token)
print('A8_COMP02_FILLTRIANGLE_6ARG_DELTA_GATE=PASS')
print('A8_COMP02_DIRECTGRAPHICS_7ARG_IDENTITY_GATE=PASS')
PY

# Target owner host gate.
HOST="$BUILD/a8-comp02-filltriangle-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$HOST" "$ROOT/tests/a8/RG35XXRawFillTriangleHostGate.java"
"$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$HOST" org.recompile.rg35xx.a8.RG35XXRawFillTriangleHostGate \
  | tee "$DST/A8-COMP02-FILLTRIANGLE-HOST-GATE.txt"
grep -q '^A8_COMP02_FILLTRIANGLE_HOST_GATE=PASS$' "$DST/A8-COMP02-FILLTRIANGLE-HOST-GATE.txt" || fail "target host gate missing"

# Re-run the final accepted A6 raw graphics gates. Deliberately do not run the
# superseded generic R5P polygon gate; final A8 intentionally narrows raw
# DirectGraphics.fillPolygon to the accepted four-corner rectangle contract.
run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/a8-comp02-reg-$(basename "$src" .java)"
  rm -rf "$dir"; mkdir -p "$dir"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
    -d "$dir" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$dir" "$cls" | tee "$DST/$out"
  grep -q "^${marker}$" "$DST/$out" || fail "regression gate $src"
}

run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate \
  A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION-GATE.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION-GATE.txt
run_gate RG35XXRawRectPolygonHostGate.java org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate \
  A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS A6-RECTPOLYGON-REGRESSION-GATE.txt
run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate \
  A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION-GATE.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION-GATE.txt

# Non-owner native binaries are copied bit-for-bit from the accepted A7/A8
# semantic parent and then re-hashed.
cp "$PARENT/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$PARENT/libaudio.so" "$DST/libaudio.so"
[ "$(sha256sum "$DST/librg35xx_input.so"|awk '{print $1}')" = "$INPUT_SHA" ] || fail input-copy
[ "$(sha256sum "$DST/librg35xx_video.so"|awk '{print $1}')" = "$VIDEO_SHA" ] || fail video-copy
[ "$(sha256sum "$DST/libaudio.so"|awk '{print $1}')" = "$AUDIO_SHA" ] || fail audio-copy

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
CANDIDATE_SEMANTIC="$(semantic_digest "$CANDIDATE_JAR")"
[ "$CANDIDATE_SEMANTIC" != "$PARENT_SEMANTIC" ] || fail "candidate semantic unchanged"

cat > "$DST/A8-COMP02-FILLTRIANGLE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A8-COMP02-GRAPHICS-FILLTRIANGLE-BOUNDARY-ONLY
PRODUCTION_PARENT=A8_GOLDEN_ONLY
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
TARGET_JAR=Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar
TARGET_JAR_SHA256=b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
FAILURE_SCOPE=PlatformGraphics.fillTriangle_6ARG_RAW2D_GC_NULL
PARENT_PLATFORM_JAR_SHA256=$PARENT_SHA
PARENT_PLATFORM_SEMANTIC_SHA256=$PARENT_SEMANTIC
CANDIDATE_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CANDIDATE_SEMANTIC
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
CHANGED_METHOD=Graphics.fillTriangle_6ARG_RAW_PATH_ONLY
DIRECTGRAPHICS_FILLPOLYGON=UNCHANGED_FINAL_A8_RECT_ONLY_CONTRACT
DIRECTGRAPHICS_FILLTRIANGLE_7ARG=BYTECODE_IDENTICAL_TO_PARENT
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
AUDIO_NATIVE_SHA256=$AUDIO_SHA
A8_COMP02_FILLTRIANGLE_HOST_GATE=PASS
A6_DRAWRECT_REGRESSION_GATE=PASS
A6_DRAWLINE_REGRESSION_GATE=PASS
A6_RECTPOLYGON_REGRESSION_GATE=PASS
A6_CLIPTRANSLATE_REGRESSION_GATE=PASS
A6_ADAM7_REGRESSION_GATE=PASS
GAME_SPECIFIC_RUNTIME_CODE=NO
COMMERCIAL_GAME_JAR_BUNDLED=NO
BUILD-PASS=YES
DEVICE-PASS=NO
TARGET_DEVICE_TEST=PENDING
VUA_CUOP_BIEN_PHYSICAL_REGRESSION=PENDING
GOD_OF_WAR_PHYSICAL_REGRESSION=PENDING
STABLE=NO
EOF

cat > "$DST/CANDIDATE-SCOPE.txt" <<EOF
AUTHORITY=RG35XX-PORT-RULER-LOCKED-v1
CANDIDATE=GRAPHICS-FILLTRIANGLE-BOUNDARY-ONLY
CANONICAL_BEHAVIOR=AWT_Graphics2D_fillPolygon_three_vertices_current_color
RG35XX_DIFFERENCE=RAW2D_gc_is_null
OWNER=RG35XX_GRAPHICS_BOUNDARY
JAVA_CHANGED_SCOPE=PlatformGraphics.class_only
NATIVE_CHANGED_SCOPE=NONE
INPUT_CHANGED=NO
VIDEO_PRESENTER_CHANGED=NO
AUDIO_CHANGED=NO
LIFECYCLE_CHANGED=NO
RMS_CHANGED=NO
VENDOR_API_CHANGED=NO
A9_CODE_IMPORTED=NO
DEVICE_ACCEPTANCE_REQUIRED=YES
EOF

(cd "$DST" && find . -maxdepth 1 -type f ! -name A8-COMP02-SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum) > "$DST/A8-COMP02-SHA256SUMS.txt"
(cd "$DST" && sha256sum -c A8-COMP02-SHA256SUMS.txt)

echo A8_COMP02_FILLTRIANGLE_BUILD=PASS
cat "$DST/A8-COMP02-FILLTRIANGLE-IDENTITY.txt"
