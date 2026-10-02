#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_DG_D6_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
PARENT_OUT="$ROOT/out/p1a-dg-fill-vector-d4"
PARENT_JAR="$PARENT_OUT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT_OUT/P1A-DG-D4-IDENTITY.txt"
OUT="$ROOT/out/p1a-dg-draw-vector-d6"
CLASSES="$BUILD/p1a-dg-d6-classes"
HOST="$BUILD/p1a-dg-d6-host"

semantic_digest(){ python3 - "$1" <<'PY'
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
class_digest(){ python3 - "$1" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
  print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
}

# Reconstruct the exact accepted host parent. Diagnostic D5.x branches are evidence only.
bash "$ROOT/scripts/build-p1a-dg-fill-vector-d4.sh"
[ -f "$PARENT_JAR" ] || fail "D4 parent jar missing"
[ -f "$PARENT_ID" ] || fail "D4 identity missing"
grep -q '^WORK_UNIT=P1A-DG-FILL-VECTOR-D4$' "$PARENT_ID" || fail "D4 identity work unit"
grep -q '^D4_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "D4 differential"
grep -q '^D4_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "D4 canonical"
grep -q '^CORE2D_CHANGE=NO$' "$PARENT_ID" || fail "D4 Core2D scope"
grep -q '^A9_PARENT=NO$' "$PARENT_ID" || fail "D4 A9 gate"
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(class_digest "$PARENT_JAR")"
echo P1A_DG_D6_RUNTIME_PARENT_GATE=PASS

# Stage only the missing raw draw-vector boundary on top of D4 materialized source.
python3 "$ROOT/scripts/stage-p1a-dg-draw-vector-d6.py" "$STAGE"
PG_SRC="$STAGE/org/recompile/mobile/PlatformGraphics.java"
[ -f "$PG_SRC" ] || fail "staged PlatformGraphics missing"
rm -rf "$OUT" "$CLASSES" "$HOST"
mkdir -p "$OUT" "$CLASSES" "$HOST"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" "$PG_SRC"
CLASS_LIST="$(cd "$CLASSES" && find . -type f -name '*.class' -printf '%P\n' | LC_ALL=C sort)"
[ "$CLASS_LIST" = "org/recompile/mobile/PlatformGraphics.class" ] || fail "compile scope $CLASS_LIST"

CANDIDATE="$OUT/freej2me-rg35xx.jar"
cp "$PARENT_JAR" "$CANDIDATE"
"$JAVA8/bin/jar" uf "$CANDIDATE" -C "$CLASSES" org/recompile/mobile/PlatformGraphics.class
python3 - "$PARENT_JAR" "$CANDIDATE" <<'PY'
import sys,zipfile,hashlib
a,b=sys.argv[1:3]
with zipfile.ZipFile(a) as za,zipfile.ZipFile(b) as zb:
  if set(za.namelist()) != set(zb.namelist()):
    raise SystemExit('P1A_DG_D6_SCOPE_FAIL entry-set')
  d=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if d != ['org/recompile/mobile/PlatformGraphics.class']:
  raise SystemExit('P1A_DG_D6_SCOPE_FAIL changed='+repr(d))
print('P1A_DG_D6_CHANGED_JAR_ENTRIES='+','.join(d))
print('P1A_DG_D6_SCOPE_GATE=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); major=int.from_bytes(b[6:8],'big')
      if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_DG_D6_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_DG_D6_JAVA6_GATE=PASS')
PY
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-DG-D6-PLATFORMGRAPHICS-SOURCE.java.txt"

# Compile the new strict gate plus protected parent regressions against D6.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p1a/RG35XXDGDrawVectorD6DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXDGFillVectorD4DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2DArcFamilyDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXDGDrawVectorD6DifferentialGate \
  | tee "$OUT/D6-DRAW-VECTOR-DIFFERENTIAL.txt"
D6LOG="$OUT/D6-DRAW-VECTOR-DIFFERENTIAL.txt"
grep -q '^P1A_DG_D6_TRIANGLE_CASE_COUNT=30$' "$D6LOG" || fail "D6 triangle count"
grep -q '^P1A_DG_D6_POLYGON_FIXED_COUNT=100$' "$D6LOG" || fail "D6 fixed count"
grep -q '^P1A_DG_D6_POLYGON_FUZZ_COUNT=320$' "$D6LOG" || fail "D6 fuzz count"
grep -q '^P1A_DG_D6_OFFSET_CASE_COUNT=5$' "$D6LOG" || fail "D6 offset count"
grep -q '^P1A_DG_D6_STATE_FAILURE_COUNT=0$' "$D6LOG" || fail "D6 state"
grep -q '^P1A_DG_D6_STRICT_FAILURE_COUNT=0$' "$D6LOG" || fail "D6 mismatch"
grep -q '^P1A_DG_D6_DRAW_VECTOR_DIFFERENTIAL_GATE=PASS$' "$D6LOG" || fail "D6 gate"
grep -q '^P1A_DG_D6_CANONICAL_EQUIVALENT=YES$' "$D6LOG" || fail "D6 canonical"

# D4 fill-vector remains exact after D6.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXDGFillVectorD4DifferentialGate \
  | tee "$OUT/D4-FILL-VECTOR-REGRESSION.txt"
grep -q '^P1A_DG_D4_STRICT_FAILURE_COUNT=0$' "$OUT/D4-FILL-VECTOR-REGRESSION.txt" || fail "D4 regression"
grep -q '^P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS$' "$OUT/D4-FILL-VECTOR-REGRESSION.txt" || fail "D4 marker"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate \
  | tee "$OUT/G2D-ARC-FAMILY-REGRESSION.txt"
grep -q '^P1A_G2D_STRICT_FAILURE_COUNT=0$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D regression"
grep -q '^P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D marker"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate \
  | tee "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C regression"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate \
  | tee "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt"
grep -q '^P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS$' "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt" || fail "G1/G2A regression"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate \
  | tee "$OUT/G1-ALPHA-REGRESSION.txt"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-ALPHA-REGRESSION.txt" || fail "G1 alpha regression"

# A6 raw geometry / clip / image gates stay protected.
run_gate(){
  local src="$1" cls="$2" marker="$3" log="$4"
  local d="$BUILD/p1a-dg-d6-$(basename "$src" .java)"; rm -rf "$d"; mkdir -p "$d"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$d" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE:$d" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $src"
}
run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt

# Non-owner native identities remain byte-for-byte protected.
cp "$PARENT_OUT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native drift"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native drift"

CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_PG="$(class_digest "$CANDIDATE")"
cat > "$OUT/P1A-DG-D6-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-DG-DRAW-VECTOR-D6
CURRENT_PHASE=P1_CORE_2D
CURRENT_MODULE=P1A_GRAPHICS
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_RUNTIME_PARENT=2c2b1f2b0ca99d42ef9965a24f1eb7678eca428a
D4_PARENT_SEMANTIC_SHA256=$PARENT_SEM
D4_PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
D53B_DIAGNOSTIC_EVIDENCE=159ae7baa27ee232e49bce63092b37ebdbce8f43
D54_DIAGNOSTIC_EVIDENCE=9c1cb7aefa816f621e4f06b85f48edeffee0aa93
DIAGNOSTIC_BRANCH_PARENT=NO
A9_PARENT=NO
MIYOO_SOURCE=src/org/recompile/mobile/PlatformGraphics.java
FREEJ2ME_REFERENCE=NOT_REQUIRED_BEYOND_PINNED_MIYOO_API
JDK_OPENJDK_REFERENCE=GENERALRENDERER_DRAWPOLYGONS_PLUS_STROKE_SPAN_PIPELINE
EXACT_RG35XX_GAP=RAW2D_GC_NULL_NO_DIRECTGRAPHICS_DRAWPOLYGON_DRAWTRIANGLE_BACKING
CHANGED_METHODS=DirectGraphics.drawPolygon,DirectGraphics.drawTriangle
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
OPAQUE_BACKEND=OPENJDK8_GENERALRENDERER_DODRAWPOLY_DODRAWLINE_ADJUSTLINE
ALPHA_BACKEND=D53B_LINE_ONLY_CLOSED_MITER_W1_QUARTER_NORMALIZED_SOFTWARE_SSI
ALPHA_MODEL=G1_EXACT_8BIT_SRCOVER
D6_TRIANGLE_CASES=30
D6_POLYGON_FIXED_CASES=100
D6_POLYGON_FUZZ_CASES=320
D6_OFFSET_CASES=5
D6_STRICT_DIFFERENTIAL=PASS
D6_CANONICAL_EQUIVALENT=YES
D4_FILL_VECTOR_REGRESSION=PASS
G2D_ARC_FAMILY_REGRESSION=PASS
G2C_DRAWROUNDRECT_REGRESSION=PASS
G1_G2A_BEHAVIOR_REGRESSION=PASS
G1_ALPHA_REGRESSION=PASS
A6_PROTECTED_REGRESSIONS=PASS
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
CORE2D_CHANGE=NO
NATIVE_CHANGE=NO
INPUT_CHANGE=NO
VIDEO_CHANGE=NO
AUDIO_CHANGE=NO
LIFECYCLE_CHANGE=NO
RMS_CHANGE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
NO_A9_PARENT=YES
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
MODULE_GATE=PENDING_P1A_INTEGRATION
PHYSICAL_TEST_REQUIRED=NO_METHOD_LEVEL
PHYSICAL_TEST_LEVEL=MODULE_LATER
DEVICE-PASS=NO
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)

echo P1A_DG_D6_BUILD=PASS
cat "$OUT/P1A-DG-D6-IDENTITY.txt"
