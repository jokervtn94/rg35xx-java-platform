#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2D_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
OUT="$ROOT/out/p1a-g2d-arc-family-jdk8-raster"
CLASSES="$BUILD/p1a-g2d-classes"
semantic_digest(){ python3 - "$1" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in sorted(z.namelist()):
    b=z.read(n); nb=n.encode('utf-8')
    h.update(struct.pack('>I',len(nb)));h.update(nb)
    h.update(struct.pack('>Q',len(b)));h.update(b)
print(h.hexdigest())
PY
}

# Exact host-accepted G2C parent. This transitively materializes and gates G1/G2A/G2B/A6.
bash "$ROOT/scripts/build-p1a-g2c-drawroundrect-jdk8-raster-v2.sh"
PARENT="$ROOT/out/p1a-g2c-drawroundrect-jdk8-raster"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT/P1A-G2C-IDENTITY.txt"
[ -f "$PARENT_JAR" ] || fail "G2C parent jar missing"
grep -q '^G2C_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "G2C parent strict"
grep -q '^G2C_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "G2C parent canonical"
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(python3 - "$PARENT_JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
[ "$PARENT_SEM" = "a177541d3d0f9a8ad5e322afae03994800f73d8b13b5b141f8343490aa3ae2dc" ] || fail "G2C semantic drift $PARENT_SEM"
[ "$PARENT_PG" = "0b0d5afad448c0e1323a9f1eb66c6a05b6cd13357697f929aa6985551c5e95cb" ] || fail "G2C PG drift $PARENT_PG"
echo P1A_G2D_G2C_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-p1a-g2d-arc-family-jdk8-raster.py" "$STAGE"
PG_SRC="$STAGE/org/recompile/mobile/PlatformGraphics.java"
rm -rf "$OUT" "$CLASSES"; mkdir -p "$OUT" "$CLASSES"
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
  if set(za.namelist())!=set(zb.namelist()): raise SystemExit('P1A_G2D_SCOPE_FAIL entry-set')
  d=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if d!=['org/recompile/mobile/PlatformGraphics.class']:raise SystemExit('P1A_G2D_SCOPE_FAIL changed='+repr(d))
print('P1A_G2D_CHANGED_JAR_ENTRIES='+','.join(d));print('P1A_G2D_SCOPE_GATE=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n);m=int.from_bytes(b[6:8],'big')
      if m>50:bad.append((n,m))
if bad:raise SystemExit('P1A_G2D_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_G2D_JAVA6_GATE=PASS')
PY
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-G2D-PLATFORMGRAPHICS-SOURCE.java.txt"

HOST="$BUILD/p1a-g2d-host";rm -rf "$HOST";mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p1a/RG35XXG2DArcFamilyDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BFillTriangleDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

# New G2D strict matrix + 320 deterministic fuzz cases.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate \
  | tee "$OUT/P1A-G2D-ARC-FAMILY-DIFFERENTIAL.txt"
G2DLOG="$OUT/P1A-G2D-ARC-FAMILY-DIFFERENTIAL.txt"
grep -q '^P1A_G2D_FIXED_CASE_COUNT=37$' "$G2DLOG" || fail "G2D fixed count"
grep -q '^P1A_G2D_FUZZ_CASE_COUNT=320$' "$G2DLOG" || fail "G2D fuzz count"
grep -q '^P1A_G2D_STRICT_FAILURE_COUNT=0$' "$G2DLOG" || fail "G2D mismatch"
grep -q '^P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS$' "$G2DLOG" || fail "G2D differential marker"
grep -q '^P1A_G2D_CANONICAL_EQUIVALENT=YES$' "$G2DLOG" || fail "G2D canonical marker"

# Full G2C 19-case matrix remains bit-exact.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate \
  | tee "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C regression"
grep -q '^P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C marker"

# Full G2B 21-case matrix; G2D arcs are now implemented ancestors, Nokia 7-arg remains unchanged.
"$JAVA8/bin/java" -Djava.awt.headless=true -Dp1a.g2d.parentregression=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BFillTriangleDifferentialGate \
  | tee "$OUT/G2B-TRIANGLE-REGRESSION.txt"
grep -q '^P1A_G2B_STRICT_FAILURE_COUNT=0$' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "G2B regression"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_DRAWARC_G2D EXPECTED=MATCH ACTUAL=MATCH ' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "drawArc ancestry"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_FILLARC_G2D EXPECTED=MATCH ACTUAL=MATCH ' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "fillArc ancestry"
grep -q '^P1A_G2B_SCOPE_CASE=SENTINEL_DG_FILLTRIANGLE_7ARG EXPECTED=RAW_EXCEPTION ACTUAL=RAW_EXCEPTION ' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "DirectGraphics 7arg scope"

# Protect actual G1/G2A behavior and G1 alpha.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate | tee "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt"
grep -q '^P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS$' "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt" || fail "G1/G2A regression"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate | tee "$OUT/G1-ALPHA-REGRESSION.txt"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-ALPHA-REGRESSION.txt" || fail "G1 alpha regression"

run_gate(){
  local src="$1" cls="$2" marker="$3" log="$4"
  local d="$BUILD/p1a-g2d-$(basename "$src" .java)";rm -rf "$d";mkdir -p "$d"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$d" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE:$d" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $src"
}
run_gate RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_gate RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_gate RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt
run_gate RG35XXRawRectPolygonHostGate.java org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS A6-RECTPOLYGON-REGRESSION.txt
run_gate RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt

cp "$PARENT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')";VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail input
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail video
CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')";CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_PG="$(python3 - "$CANDIDATE" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
cat > "$OUT/P1A-G2D-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2D-ARC-FAMILY-JDK8-RASTER
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G2C_SEMANTIC_SHA256=$PARENT_SEM
PARENT_G2C_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CHANGED_METHODS=Graphics.drawArc,Graphics.fillArc
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
DRAW_RASTER=OPENJDK8_ARCITERATOR_PROCESSPATH_DRAW_REUSE_G2C
FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR
CORE2D_CHANGE=NO
G2D_FIXED_CASES=37
G2D_DETERMINISTIC_FUZZ_CASES=320
G2D_STRICT_DIFFERENTIAL=PASS
G2D_CANONICAL_EQUIVALENT=YES
G2C_19_CASE_REGRESSION=PASS
G2B_21_CASE_REGRESSION=PASS
G1_G2A_BEHAVIOR_REGRESSION=PASS
G1_ALPHA_REGRESSION=PASS
A6_PROTECTED_REGRESSIONS=PASS
DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED_RAW_EXCEPTION
GAME_SPECIFIC_CODE=NO
NO_A9_PARENT=YES
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=NO_MODULE_INTEGRATION_PENDING
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo P1A_G2D_BUILD=PASS
cat "$OUT/P1A-G2D-IDENTITY.txt"
