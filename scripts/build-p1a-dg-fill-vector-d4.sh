#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_DG_D4_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
OUT="$ROOT/out/p1a-dg-fill-vector-d4"
CLASSES="$BUILD/p1a-dg-d4-classes"
HOST="$BUILD/p1a-dg-d4-host"
PARENT_OUT="$ROOT/out/p1a-g2d-arc-family-jdk8-raster"
PARENT_JAR="$PARENT_OUT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT_OUT/P1A-G2D-IDENTITY.txt"
PARENT_FIX="$PARENT_OUT/P1A-G2D-IDENTITY-CORRECTION.txt"

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

# Runtime parent is the host-locked G2D lineage. Diagnostic D1-D3.x commits are evidence only.
bash "$ROOT/scripts/build-p1a-g2d-arc-family-jdk8-raster-identityfix.sh"
[ -f "$PARENT_JAR" ] || fail "parent jar missing"
[ -f "$PARENT_ID" ] || fail "parent identity missing"
[ -f "$PARENT_FIX" ] || fail "parent identity correction missing"
grep -q '^FILL_RASTER=OPENJDK8_FILLPATH_PROCESSPATH_PIE_FIXEDPOINT_NONZERO_ACTIVE_EDGE_SCAN$' "$PARENT_ID" || fail "parent fill raster identity"
grep -q '^G2D_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "parent G2D strict"
grep -q '^G2D_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "parent G2D canonical"
grep -q '^RUNTIME_JAR_SHA_UNCHANGED=YES$' "$PARENT_FIX" || fail "parent metadata-only correction"
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(class_digest "$PARENT_JAR")"
[ "$PARENT_SEM" = "98c4f5f858888c072b6f56a64b25624b413ef2b95b2b1e30d08ee16a5103c040" ] || fail "parent semantic drift $PARENT_SEM"
[ "$PARENT_PG" = "85995f6d08af9fcd648a3601398cbe2fd5a2f0cca1ae6e1fafb8a843dea28b5e" ] || fail "parent PlatformGraphics drift $PARENT_PG"
echo P1A_DG_D4_RUNTIME_PARENT_GATE=PASS

# Apply only the DirectGraphics fill-vector boundary stage to the materialized parent source.
python3 "$ROOT/scripts/stage-p1a-dg-fill-vector-d4.py" "$STAGE"
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
    raise SystemExit('P1A_DG_D4_SCOPE_FAIL entry-set')
  d=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if d != ['org/recompile/mobile/PlatformGraphics.class']:
  raise SystemExit('P1A_DG_D4_SCOPE_FAIL changed='+repr(d))
print('P1A_DG_D4_CHANGED_JAR_ENTRIES='+','.join(d))
print('P1A_DG_D4_SCOPE_GATE=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); major=int.from_bytes(b[6:8],'big')
      if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_DG_D4_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_DG_D4_JAVA6_GATE=PASS')
PY
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-DG-D4-PLATFORMGRAPHICS-SOURCE.java.txt"

# Compile D4 and all protected host regressions against the candidate.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p1a/RG35XXDGFillVectorD4DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2DArcFamilyDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BFillTriangleDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

# D4 strict runtime differential: 105 triangle ARGB cases + exact D3 polygon corpus + offset/state.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXDGFillVectorD4DifferentialGate \
  | tee "$OUT/D4-FILL-VECTOR-DIFFERENTIAL.txt"
D4LOG="$OUT/D4-FILL-VECTOR-DIFFERENTIAL.txt"
grep -q '^P1A_DG_D4_TRIANGLE_CASE_COUNT=105$' "$D4LOG" || fail "D4 triangle count"
grep -q '^P1A_DG_D4_POLYGON_FIXED_COUNT=17$' "$D4LOG" || fail "D4 polygon fixed count"
grep -q '^P1A_DG_D4_POLYGON_FUZZ_COUNT=320$' "$D4LOG" || fail "D4 polygon fuzz count"
grep -q '^P1A_DG_D4_OFFSET_CASE_COUNT=1$' "$D4LOG" || fail "D4 offset count"
grep -q '^P1A_DG_D4_STATE_FAILURE_COUNT=0$' "$D4LOG" || fail "D4 state restore"
grep -q '^P1A_DG_D4_RANDOM_SEED=35d3001$' "$D4LOG" || fail "D4 seed"
grep -q '^P1A_DG_D4_STRICT_FAILURE_COUNT=0$' "$D4LOG" || fail "D4 strict mismatch"
grep -q '^P1A_DG_D4_WINDING=EVEN_ODD$' "$D4LOG" || fail "D4 winding"
grep -q '^P1A_DG_D4_ALPHA_MODEL=G1_EXACT_8BIT_SRCOVER$' "$D4LOG" || fail "D4 alpha model"
grep -q '^P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS$' "$D4LOG" || fail "D4 differential marker"
grep -q '^P1A_DG_D4_CANONICAL_EQUIVALENT=YES$' "$D4LOG" || fail "D4 canonical marker"

# G2D 37 fixed + 320 deterministic fuzz remain bit-exact.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate \
  | tee "$OUT/G2D-ARC-FAMILY-REGRESSION.txt"
grep -q '^P1A_G2D_FIXED_CASE_COUNT=37$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D fixed regression"
grep -q '^P1A_G2D_FUZZ_CASE_COUNT=320$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D fuzz regression"
grep -q '^P1A_G2D_STRICT_FAILURE_COUNT=0$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D regression"
grep -q '^P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D marker"

# G2C 19-case matrix remains bit-exact.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate \
  | tee "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C regression"
grep -q '^P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C marker"

# Existing G2B test contains the old 7-arg RAW_EXCEPTION sentinel. D4 intentionally expands
# exactly that capability, so the test must now fail exactly once while all 21 G2B cases pass.
set +e
set +o pipefail
"$JAVA8/bin/java" -Djava.awt.headless=true -Dp1a.g2d.parentregression=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BFillTriangleDifferentialGate \
  | tee "$OUT/G2B-TRIANGLE-SCOPE-EXPANSION.txt"
G2B_RC=${PIPESTATUS[0]}
set -o pipefail
set -e
[ "$G2B_RC" -ne 0 ] || fail "G2B legacy sentinel unexpectedly returned success"
G2BLOG="$OUT/G2B-TRIANGLE-SCOPE-EXPANSION.txt"
G2B_CASE_PASS_COUNT="$(grep -c '^P1A_G2B_CASE=.* MATCH=true ' "$G2BLOG" || true)"
[ "$G2B_CASE_PASS_COUNT" = "21" ] || fail "G2B geometry pass count $G2B_CASE_PASS_COUNT"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_DRAWARC_G2D EXPECTED=MATCH ACTUAL=MATCH ' "$G2BLOG" || fail "G2B drawArc ancestry"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_FILLARC_G2D EXPECTED=MATCH ACTUAL=MATCH ' "$G2BLOG" || fail "G2B fillArc ancestry"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_DRAWROUNDRECT_G2C EXPECTED=MATCH ACTUAL=MATCH ' "$G2BLOG" || fail "G2B drawRoundRect ancestry"
grep -q '^P1A_G2B_SCOPE_CASE=SENTINEL_DG_FILLTRIANGLE_7ARG EXPECTED=RAW_EXCEPTION ACTUAL=MATCH ' "$G2BLOG" || fail "G2B scope expansion sentinel"
grep -q '^P1A_G2B_STRICT_FAILURE_COUNT=1$' "$G2BLOG" || fail "G2B expected single sentinel failure"
echo P1A_DG_D4_G2B_21_CASE_SCOPE_EXPANSION_GATE=PASS | tee "$OUT/G2B-D4-SCOPE-GATE.txt"

# Protect G1/G2A behavior and exact G1 alpha compositing.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate \
  | tee "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt"
grep -q '^P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS$' "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt" || fail "G1/G2A regression"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate \
  | tee "$OUT/G1-ALPHA-REGRESSION.txt"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-ALPHA-REGRESSION.txt" || fail "G1 alpha regression"

run_gate(){
  local src="$1" cls="$2" marker="$3" log="$4"
  local d="$BUILD/p1a-dg-d4-$(basename "$src" .java)"; rm -rf "$d"; mkdir -p "$d"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$d" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE:$d" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $src"
}
run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt

# A6 rectangle-only polygon test is preserved verbatim. D4 intentionally expands only its
# final generic non-rectangle sentinel. Reaching that exact final assertion proves all earlier
# rectangle/alpha/translate/clip assertions in the legacy test still passed.
A6POLY_SRC="RG35XXRawRectPolygonHostGate.java"
A6POLY_CLS="org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate"
A6POLY_DIR="$BUILD/p1a-dg-d4-RG35XXRawRectPolygonHostGate"
A6POLY_LOG="$OUT/A6-RECTPOLYGON-SCOPE-EXPANSION.txt"
rm -rf "$A6POLY_DIR"; mkdir -p "$A6POLY_DIR"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$A6POLY_DIR" "$ROOT/tests/a6/$A6POLY_SRC"
set +e
set +o pipefail
"$JAVA8/bin/java" -cp "$CANDIDATE:$A6POLY_DIR" "$A6POLY_CLS" 2>&1 | tee "$A6POLY_LOG"
A6POLY_RC=${PIPESTATUS[0]}
set -o pipefail
set -e
[ "$A6POLY_RC" -ne 0 ] || fail "A6 rectangle-only legacy sentinel unexpectedly returned success"
A6POLY_FAIL_COUNT="$(grep -c 'A6_R5P3_RAW_RECT_POLYGON_HOST_GATE_FAIL=' "$A6POLY_LOG" || true)"
[ "$A6POLY_FAIL_COUNT" = "1" ] || fail "A6 rectangle polygon failure count $A6POLY_FAIL_COUNT"
grep -q 'A6_R5P3_RAW_RECT_POLYGON_HOST_GATE_FAIL=nonrect-noop' "$A6POLY_LOG" || fail "A6 generic polygon scope expansion sentinel"
if grep 'A6_R5P3_RAW_RECT_POLYGON_HOST_GATE_FAIL=' "$A6POLY_LOG" | grep -vq 'A6_R5P3_RAW_RECT_POLYGON_HOST_GATE_FAIL=nonrect-noop'; then
  fail "A6 rectangle polygon protected assertion regression"
fi
echo P1A_DG_D4_A6_RECTPOLYGON_PROTECTED_PREFIX_GATE=PASS | tee "$OUT/A6-D4-RECTPOLYGON-SCOPE-GATE.txt"
echo P1A_DG_D4_A6_GENERIC_FILLPOLYGON_SCOPE_EXPANSION_GATE=PASS | tee -a "$OUT/A6-D4-RECTPOLYGON-SCOPE-GATE.txt"

run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt

# Protected native adapters are inherited byte-for-byte from G2D parent.
cp "$PARENT_OUT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native drift"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native drift"

CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_PG="$(class_digest "$CANDIDATE")"
cat > "$OUT/P1A-DG-D4-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-DG-FILL-VECTOR-D4
OWNER=OPENJDK8_SHAPESPANITERATOR_APPENDPOLY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_RUNTIME_PARENT=c1f33f6f72d8560b32ef7d98804dfb20fd325dad
DIAGNOSTIC_BRANCH_PARENT=NO
A9_PARENT=NO
PARENT_G2D_SEMANTIC_SHA256=$PARENT_SEM
PARENT_G2D_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CHANGED_METHODS=DirectGraphics.fillTriangle_7arg,DirectGraphics.fillPolygon
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
WINDING=EVEN_ODD
EDGE_PRECISION=DOUBLE_SLOPE_FLOOR_SUBTRACTION_BEFORE_FRACTTOJINT
ALPHA_MODEL=G1_EXACT_8BIT_SRCOVER
COLOR_STATE_RESTORE=PASS
D4_TRIANGLE_CASES=105
D4_POLYGON_FIXED_CASES=17
D4_POLYGON_FUZZ_CASES=320
D4_OFFSET_CASES=1
D4_STRICT_DIFFERENTIAL=PASS
D4_CANONICAL_EQUIVALENT=YES
G2D_37_PLUS_320_REGRESSION=PASS
G2C_19_CASE_REGRESSION=PASS
G2B_21_GEOMETRY_REGRESSION=PASS
G2B_DG_7ARG_SCOPE_EXPANSION=PASS
G1_G2A_BEHAVIOR_REGRESSION=PASS
G1_ALPHA_REGRESSION=PASS
A6_RECTPOLYGON_PROTECTED_PREFIX_REGRESSION=PASS
A6_GENERIC_FILLPOLYGON_SCOPE_EXPANSION=PASS
A6_PROTECTED_REGRESSIONS=PASS
CORE2D_CHANGE=NO
DRAW_VECTOR_CHANGE=NO
DRAWARC_FILLARC_CHANGE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
NO_A9_PARENT=YES
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=NO_MODULE_INTEGRATION_PENDING
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)

echo P1A_DG_D4_BUILD=PASS
cat "$OUT/P1A-DG-D4-IDENTITY.txt"
