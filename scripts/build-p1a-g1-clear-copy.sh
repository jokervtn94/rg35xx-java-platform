#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G1_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
OUT="$ROOT/out/p1a-g1-clear-copy"
CLASSES="$BUILD/p1a-g1-classes"

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

# Reconstruct accepted graphics parent, then exact accepted A7/A8 Java semantics.
bash "$ROOT/scripts/build-a6-corpus3-cliptranslate-fix.sh"
bash "$ROOT/scripts/build-a7-audio-java-a1p1.sh"

PARENT="$ROOT/out/a7-audio-sdl1"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
[ -f "$PARENT_JAR" ] || fail "accepted A7/A8 semantic parent jar missing"

PARENT_SEMANTIC="$(semantic_digest "$PARENT_JAR")"
INPUT_SHA="$(sha256sum "$PARENT/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$PARENT/librg35xx_video.so" | awk '{print $1}')"
[ "$PARENT_SEMANTIC" = "7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf" ] || fail "A8 semantic parent mismatch $PARENT_SEMANTIC"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input identity drift $INPUT_SHA"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video identity drift $VIDEO_SHA"

PARENT_PG_SHA="$(python3 - "$PARENT_JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
[ "$PARENT_PG_SHA" = "b06b027b46e3545dfcaf716dc370462919b6005ad2120907f1ce07326555b853" ] || fail "PlatformGraphics parent class drift $PARENT_PG_SHA"
echo P1A_G1_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-p1a-g1-clear-copy.py" "$STAGE"
PG_SRC="$STAGE/org/recompile/mobile/PlatformGraphics.java"
[ -f "$PG_SRC" ] || fail "staged PlatformGraphics missing"

rm -rf "$OUT" "$CLASSES"
mkdir -p "$OUT" "$CLASSES"

# Compile only the owner class. Do not regenerate unrelated class families.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" "$PG_SRC"

CLASS_LIST="$(cd "$CLASSES" && find . -type f -name '*.class' -printf '%P\n' | LC_ALL=C sort)"
[ "$CLASS_LIST" = "org/recompile/mobile/PlatformGraphics.class" ] || fail "owner compile emitted unexpected classes: $CLASS_LIST"

CANDIDATE_JAR="$OUT/freej2me-rg35xx.jar"
cp "$PARENT_JAR" "$CANDIDATE_JAR"
"$JAVA8/bin/jar" uf "$CANDIDATE_JAR" -C "$CLASSES" org/recompile/mobile/PlatformGraphics.class

python3 - "$PARENT_JAR" "$CANDIDATE_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('P1A_G1_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
if diff != ['org/recompile/mobile/PlatformGraphics.class']:
    raise SystemExit('P1A_G1_SCOPE_FAIL changed='+repr(diff))
print('P1A_G1_CHANGED_JAR_ENTRIES='+','.join(diff))
print('P1A_G1_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE_JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_G1_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_G1_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-G1-PLATFORMGRAPHICS-SOURCE.java.txt"

# Canonical differential gate: G1 becomes MATCH; later groups stay failing.
HOST="$BUILD/p1a-g1-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$HOST" "$ROOT/tests/p1a/RG35XXGraphicsG1DifferentialGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE_JAR:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXGraphicsG1DifferentialGate \
  | tee "$OUT/P1A-G1-DIFFERENTIAL-GATE.txt"
grep -q '^P1A_G1_DIFFERENTIAL_GATE=PASS$' "$OUT/P1A-G1-DIFFERENTIAL-GATE.txt" || fail "G1 differential marker missing"
grep -q '^P1A_G1_SCOPE=clearRect+copyArea_ONLY$' "$OUT/P1A-G1-DIFFERENTIAL-GATE.txt" || fail "G1 scope marker missing"
grep -q '^P1A_G1_COPYAREA_OVERLAP=JDK8_LIVE_RASTER_TOP_TO_BOTTOM_LEFT_TO_RIGHT$' "$OUT/P1A-G1-DIFFERENTIAL-GATE.txt" || fail "G1 overlap marker missing"

# Semi-alpha gate is part of BUILD-PASS: baseline must be bit-identical before
# copyArea, then Java2D and Raw2D must match after JDK8 MUL8/DIV8 SrcOver.
ALPHA_HOST="$BUILD/p1a-g1-alpha-host"
rm -rf "$ALPHA_HOST"; mkdir -p "$ALPHA_HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
  -d "$ALPHA_HOST" "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE_JAR:$ALPHA_HOST" \
  org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate \
  | tee "$OUT/P1A-G1-ALPHA-DIFFERENTIAL-GATE.txt"
grep -q '^P1A_G1_ALPHA_BASELINE_MATCH=true ' "$OUT/P1A-G1-ALPHA-DIFFERENTIAL-GATE.txt" || fail "alpha baseline not equivalent"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/P1A-G1-ALPHA-DIFFERENTIAL-GATE.txt" || fail "alpha differential marker missing"

# Preserve accepted raw graphics/PNG gates on the candidate itself.
run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/p1a-g1-reg-$(basename "$src" .java)"
  rm -rf "$dir"; mkdir -p "$dir"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE_JAR" \
    -d "$dir" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE_JAR:$dir" "$cls" | tee "$OUT/$out"
  grep -q "^${marker}$" "$OUT/$out" || fail "regression gate $src"
}

run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt
run_gate RG35XXRawRectPolygonHostGate.java org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS A6-RECTPOLYGON-REGRESSION.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt

cp "$PARENT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$OUT/librg35xx_video.so"

CANDIDATE_SHA="$(sha256sum "$CANDIDATE_JAR" | awk '{print $1}')"
CANDIDATE_SEMANTIC="$(semantic_digest "$CANDIDATE_JAR")"
CANDIDATE_PG_SHA="$(python3 - "$CANDIDATE_JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"

cat > "$OUT/P1A-G1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G1-CLEAR-COPY
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_A8_SEMANTIC_SHA256=$PARENT_SEMANTIC
PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG_SHA
CANDIDATE_PLATFORM_JAR_SHA256=$CANDIDATE_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CANDIDATE_SEMANTIC
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CANDIDATE_PG_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
CHANGED_METHODS=clearRect,copyArea
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
CORE2D_CHANGE=NO
CANONICAL_AWT_FALLBACK=PRESERVED
P1A_G1_COPYAREA_OVERLAP=JDK8_LIVE_RASTER_TOP_TO_BOTTOM_LEFT_TO_RIGHT
P1A_G1_COPYAREA_ALPHA=JDK8_MUL8_DIV8_SRCOVER
P1A_G1_DIFFERENTIAL_GATE=PASS
P1A_G1_ALPHA_DIFFERENTIAL_GATE=PASS
HOST-DIFFERENTIAL-PASS=YES
A6_CLIPTRANSLATE_REGRESSION=PASS
A6_DRAWRECT_REGRESSION=PASS
A6_DRAWLINE_REGRESSION=PASS
A6_RECTPOLYGON_REGRESSION=PASS
A6_ADAM7_REGRESSION=PASS
GAME_SPECIFIC_CODE=NO
NO_A9_PARENT=YES
AUDIO_NATIVE=NOT_REBUILT_G1_HOST_SCOPE
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo P1A_G1_BUILD=PASS
cat "$OUT/P1A-G1-IDENTITY.txt"
