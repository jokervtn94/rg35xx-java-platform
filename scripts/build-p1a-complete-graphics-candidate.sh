#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_COMPLETE_GRAPHICS_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
PARENT_OUT="$ROOT/out/p1a-dg-draw-vector-d6"
PARENT_JAR="$PARENT_OUT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT_OUT/P1A-DG-D6-IDENTITY.txt"
OUT="$ROOT/out/p1a-complete-graphics-candidate"
CLASSES="$BUILD/p1a-complete-graphics-classes"
HOST="$BUILD/p1a-complete-graphics-host"

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

# Production ancestry is exact D6 host-accepted code. G4/G5 diagnostic is evidence only.
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p1a-dg-draw-vector-d6-v2.sh" | tee "$BUILD/P1A-COMPLETE-D6-PARENT-REBUILD.txt"
[ -f "$PARENT_JAR" ] || fail "D6 parent jar missing"
[ -f "$PARENT_ID" ] || fail "D6 identity missing"
grep -q '^WORK_UNIT=P1A-DG-DRAW-VECTOR-D6$' "$PARENT_ID" || fail "D6 work unit"
grep -q '^D6_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "D6 differential"
grep -q '^D6_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "D6 canonical"
grep -q '^DIAGNOSTIC_BRANCH_PARENT=NO$' "$PARENT_ID" || fail "D6 diagnostic ancestry"
grep -q '^A9_PARENT=NO$' "$PARENT_ID" || fail "D6 A9 parent"
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(class_digest "$PARENT_JAR")"
[ "$PARENT_SEM" = "388404ae9050c02d04c97271e942d36a9499181f9349782f6b45ae32c1b5b553" ] || fail "D6 semantic drift $PARENT_SEM"
[ "$PARENT_PG" = "1ee9413109ffe0adda8e9e566e3c66e2b90e9a3217b77922fb497ada07d59fa0" ] || fail "D6 PlatformGraphics drift $PARENT_PG"
echo P1A_COMPLETE_GRAPHICS_D6_PARENT_GATE=PASS

# Apply only the remaining G4/G5 DirectGraphics raw boundary to D6 materialized source.
python3 "$ROOT/scripts/stage-p1a-complete-graphics-g4g5.py" "$STAGE" | tee "$BUILD/P1A-COMPLETE-G4G5-STAGE.txt"
grep -q '^P1A_COMPLETE_G4G5_STAGE=PASS$' "$BUILD/P1A-COMPLETE-G4G5-STAGE.txt" || fail "G4G5 stage marker"
grep -q '^P1A_COMPLETE_CORE2D_CHANGE=NO$' "$BUILD/P1A-COMPLETE-G4G5-STAGE.txt" || fail "Core2D scope"
grep -q '^P1A_COMPLETE_NATIVE_CHANGE=NO$' "$BUILD/P1A-COMPLETE-G4G5-STAGE.txt" || fail "native scope"
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
    raise SystemExit('P1A_COMPLETE_GRAPHICS_SCOPE_FAIL entry-set')
  d=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if d != ['org/recompile/mobile/PlatformGraphics.class']:
  raise SystemExit('P1A_COMPLETE_GRAPHICS_SCOPE_FAIL changed='+repr(d))
print('P1A_COMPLETE_GRAPHICS_CHANGED_JAR_ENTRIES='+','.join(d))
print('P1A_COMPLETE_GRAPHICS_SCOPE_GATE=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); major=int.from_bytes(b[6:8],'big')
      if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_COMPLETE_GRAPHICS_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_COMPLETE_GRAPHICS_JAVA6_GATE=PASS')
PY
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-COMPLETE-PLATFORMGRAPHICS-SOURCE.java.txt"

# Compile final G4/G5 strict differential plus all protected P1A regression owners.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p1a/RG35XXCompleteGraphicsG4G5DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXDGDrawVectorD6DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXDGFillVectorD4DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2DArcFamilyDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXCompleteGraphicsG4G5DifferentialGate \
  | tee "$OUT/G4G5-STRICT-DIFFERENTIAL.txt"
G45="$OUT/G4G5-STRICT-DIFFERENTIAL.txt"
grep -q '^P1A_COMPLETE_G4G5_DRAWIMAGE_CASE_COUNT=24$' "$G45" || fail "G4 drawImage count"
grep -q '^P1A_COMPLETE_G4G5_DRAWPIXELS_INT_CASE_COUNT=16$' "$G45" || fail "G4 int count"
grep -q '^P1A_COMPLETE_G4G5_DRAWPIXELS_SHORT_CASE_COUNT=10$' "$G45" || fail "G4 short count"
grep -q '^P1A_COMPLETE_G4G5_DRAWPIXELS_BYTE_CASE_COUNT=8$' "$G45" || fail "G4 byte count"
grep -q '^P1A_COMPLETE_G4G5_GETPIXELS_INT_CASE_COUNT=3$' "$G45" || fail "G5 int count"
grep -q '^P1A_COMPLETE_G4G5_GETPIXELS_SHORT_CASE_COUNT=10$' "$G45" || fail "G5 short count"
grep -q '^P1A_COMPLETE_G4G5_GETPIXELS_BYTE_STUB_CASE_COUNT=1$' "$G45" || fail "G5 byte stub count"
grep -q '^P1A_COMPLETE_G4G5_TOTAL_CASE_COUNT=72$' "$G45" || fail "G4G5 total count"
grep -q '^P1A_COMPLETE_G4G5_STATE_FAILURE_COUNT=0$' "$G45" || fail "G4G5 state"
grep -q '^P1A_COMPLETE_G4G5_STRICT_FAILURE_COUNT=0$' "$G45" || fail "G4G5 mismatch"
grep -q '^P1A_COMPLETE_G4G5_GETPIXELS_BYTE=CANONICAL_STUB_UNCHANGED$' "$G45" || fail "byte stub"
grep -q '^P1A_COMPLETE_G4G5_DIFFERENTIAL_GATE=PASS$' "$G45" || fail "G4G5 gate"
grep -q '^P1A_COMPLETE_G4G5_CANONICAL_EQUIVALENT=YES$' "$G45" || fail "G4G5 canonical"

run_p1a(){
  local cls="$1" marker="$2" log="$3"
  "$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $cls"
}
run_p1a org.recompile.rg35xx.p1a.RG35XXDGDrawVectorD6DifferentialGate P1A_DG_D6_DRAW_VECTOR_DIFFERENTIAL_GATE=PASS D6-DRAW-VECTOR-REGRESSION.txt
run_p1a org.recompile.rg35xx.p1a.RG35XXDGFillVectorD4DifferentialGate P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS D4-FILL-VECTOR-REGRESSION.txt
run_p1a org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS G2D-ARC-FAMILY-REGRESSION.txt
run_p1a org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS G2C-DRAWROUNDRECT-REGRESSION.txt
run_p1a org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS G1-G2A-BEHAVIOR-REGRESSION.txt
run_p1a org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS G1-ALPHA-REGRESSION.txt

grep -q '^P1A_DG_D6_STRICT_FAILURE_COUNT=0$' "$OUT/D6-DRAW-VECTOR-REGRESSION.txt" || fail "D6 strict regression"
grep -q '^P1A_DG_D4_STRICT_FAILURE_COUNT=0$' "$OUT/D4-FILL-VECTOR-REGRESSION.txt" || fail "D4 strict regression"
grep -q '^P1A_G2D_STRICT_FAILURE_COUNT=0$' "$OUT/G2D-ARC-FAMILY-REGRESSION.txt" || fail "G2D strict regression"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/G2C-DRAWROUNDRECT-REGRESSION.txt" || fail "G2C strict regression"

# Existing A6 owner-boundary regressions remain protected.
run_a6(){
  local src="$1" cls="$2" marker="$3" log="$4"
  local d="$BUILD/p1a-complete-$(basename "$src" .java)"; rm -rf "$d"; mkdir -p "$d"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$d" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE:$d" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "A6 regression $src"
}
run_a6 RG35XXRawClipTranslateHostGate.java org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_a6 RG35XXRawDrawRectHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_a6 RG35XXRawDrawLineHostGate.java org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt
run_a6 RG35XXAdam7HostGate.java org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt

# Non-owner native artifacts are inherited byte-for-byte from D6.
cp "$PARENT_OUT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native drift"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native drift"

CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_PG="$(class_digest "$CANDIDATE")"
cat > "$OUT/P1A-COMPLETE-GRAPHICS-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-COMPLETE-GRAPHICS-CANDIDATE
CURRENT_PHASE=P1_CORE_2D
CURRENT_MODULE=P1A_GRAPHICS
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_RUNTIME_PARENT=093aae62d7caca2941258592c72dfc25b1f204a7
PARENT_WORK_UNIT=P1A-DG-DRAW-VECTOR-D6
PARENT_SEMANTIC_SHA256=$PARENT_SEM
PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
G4G5_DIAGNOSTIC_EVIDENCE=09ac133c24242f6dfa266e8fb3d506b1550ee194
DIAGNOSTIC_BRANCH_PARENT=NO
A9_PARENT=NO
MIYOO_SOURCE=src/org/recompile/mobile/PlatformGraphics.java
FREEJ2ME_REFERENCE=NOT_REQUIRED_BEYOND_PINNED_MIYOO_API
JDK_OPENJDK_REFERENCE=NOT_REQUIRED_G4G5_MIYOO_SEMANTICS_EXPLICIT
EXACT_RG35XX_GAP=RAW2D_DIRECTGRAPHICS_IMAGE_PIXEL_IO_BACKING
CHANGED_METHODS=DirectGraphics.drawImage_manipulation,DirectGraphics.drawPixels_byte,DirectGraphics.drawPixels_int,DirectGraphics.drawPixels_short,DirectGraphics.getPixels_int,DirectGraphics.getPixels_short
CANONICAL_STUB_UNCHANGED=DirectGraphics.getPixels_byte
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
G4_BACKEND=EXISTING_A5_RAW_PLATFORMIMAGE_PLUS_RG35XXBLIT
G5_BACKEND=RAW_PLATFORMIMAGE_FRAMEBUFFER_READ
G4G5_CASES=72
G4G5_STRICT_DIFFERENTIAL=PASS
G4G5_CANONICAL_EQUIVALENT=YES
D6_DRAW_VECTOR_REGRESSION=PASS
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
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
MODULE_GATE=PENDING_P1A_COMPLETE_INTEGRATION
PHYSICAL_TEST_REQUIRED=YES_MODULE_LEVEL_ONLY
DEVICE-PASS=NO
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)

echo P1A_COMPLETE_GRAPHICS_BUILD=PASS
cat "$OUT/P1A-COMPLETE-GRAPHICS-IDENTITY.txt"
