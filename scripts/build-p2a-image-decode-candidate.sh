#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2A_IMAGE_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
PARENT_OUT="$ROOT/out/p1a-complete-graphics-candidate"
PARENT_JAR="$PARENT_OUT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT_OUT/P1A-COMPLETE-GRAPHICS-IDENTITY.txt"
OUT="$ROOT/out/p2a-image-decode-candidate"
CLASSES="$BUILD/p2a-image-classes"
HOST="$BUILD/p2a-image-host"
CORE_SRC="$ROOT/adapter/java/org/recompile/rg35xx/RG35XXCore2D.java"

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
entry_digest(){ python3 - "$1" "$2" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
  print(hashlib.sha256(z.read(sys.argv[2])).hexdigest())
PY
}

# Reconstruct the exact accepted P1A host lineage from the locked git parent.
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p1a-complete-graphics-candidate.sh" | tee "$BUILD/P2A-P1A-PARENT-REBUILD.txt"
grep -q '^P1A_COMPLETE_GRAPHICS_BUILD=PASS$' "$BUILD/P2A-P1A-PARENT-REBUILD.txt" || fail "P1A parent rebuild"
[ -f "$PARENT_JAR" ] || fail "P1A parent jar missing"
[ -f "$PARENT_ID" ] || fail "P1A parent identity missing"
grep -q '^WORK_UNIT=P1A-COMPLETE-GRAPHICS-CANDIDATE$' "$PARENT_ID" || fail "P1A parent work unit"
grep -q '^G4G5_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "P1A parent differential"
grep -q '^G4G5_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "P1A parent canonical"
grep -q '^A9_PARENT=NO$' "$PARENT_ID" || fail "P1A parent A9"
[ -f "$CORE_SRC" ] || fail "materialized Core2D source missing"
grep -q 'private static RawImage decodeAdam7' "$CORE_SRC" || fail "accepted Adam7 source not materialized"

echo P2A_IMAGE_P1A_PARENT_REBUILD=PASS
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(entry_digest "$PARENT_JAR" org/recompile/mobile/PlatformGraphics.class)"
PARENT_CORE="$(entry_digest "$PARENT_JAR" org/recompile/rg35xx/RG35XXCore2D.class)"

rm -rf "$OUT" "$CLASSES" "$HOST"
mkdir -p "$OUT" "$CLASSES" "$HOST"
cp "$CORE_SRC" "$OUT/PARENT-RG35XXCore2D.java.txt"

# Apply only the P2A image-decode owner delta to the accepted materialized source.
python3 "$ROOT/scripts/stage-p2a-image-decode.py" "$ROOT" | tee "$OUT/P2A-IMAGE-STAGE.txt"
grep -q '^P2A_IMAGE_STAGE=PASS$' "$OUT/P2A-IMAGE-STAGE.txt" || fail "stage marker"
grep -q '^P2A_IMAGE_OTHER_CORE2D_METHODS_CHANGE=NO$' "$OUT/P2A-IMAGE-STAGE.txt" || fail "Core2D neighbor scope"
grep -q '^P2A_IMAGE_NATIVE_CHANGE=NO$' "$OUT/P2A-IMAGE-STAGE.txt" || fail "native scope"
grep -q '^P2A_IMAGE_GAME_SPECIFIC_CODE=NO$' "$OUT/P2A-IMAGE-STAGE.txt" || fail "game-specific scope"
cp "$CORE_SRC" "$OUT/CANDIDATE-RG35XXCore2D.java.txt"

# Compile only the RG35XX Core2D owner class on top of the exact P1A jar.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" "$CORE_SRC"
CLASS_LIST="$(cd "$CLASSES" && find . -type f -name '*.class' -printf '%P\n' | LC_ALL=C sort)"
EXPECTED_CLASSES=$'org/recompile/rg35xx/RG35XXCore2D$RawImage.class\norg/recompile/rg35xx/RG35XXCore2D.class'
[ "$CLASS_LIST" = "$EXPECTED_CLASSES" ] || fail "compile scope $CLASS_LIST"

CANDIDATE="$OUT/freej2me-rg35xx.jar"
cp "$PARENT_JAR" "$CANDIDATE"
(
  cd "$CLASSES"
  "$JAVA8/bin/jar" uf "$CANDIDATE" \
    'org/recompile/rg35xx/RG35XXCore2D$RawImage.class' \
    'org/recompile/rg35xx/RG35XXCore2D.class'
)

python3 - "$PARENT_JAR" "$CANDIDATE" <<'PY'
import sys,zipfile,hashlib
a,b=sys.argv[1:3]
with zipfile.ZipFile(a) as za,zipfile.ZipFile(b) as zb:
  if set(za.namelist()) != set(zb.namelist()):
    raise SystemExit('P2A_IMAGE_SCOPE_FAIL entry-set')
  changed=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
expected=['org/recompile/rg35xx/RG35XXCore2D$RawImage.class','org/recompile/rg35xx/RG35XXCore2D.class']
if changed != expected:
  raise SystemExit('P2A_IMAGE_SCOPE_FAIL changed='+repr(changed))
print('P2A_IMAGE_CHANGED_JAR_ENTRIES='+','.join(changed))
print('P2A_IMAGE_OWNER_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]; majors=set()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); major=int.from_bytes(b[6:8],'big'); majors.add(major)
      if major>50: bad.append((n,major))
if bad: raise SystemExit('P2A_IMAGE_JAVA6_FAIL '+repr(bad[:20]))
print('P2A_IMAGE_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('P2A_IMAGE_JAVA6_GATE=PASS')
PY

CAND_PG="$(entry_digest "$CANDIDATE" org/recompile/mobile/PlatformGraphics.class)"
[ "$CAND_PG" = "$PARENT_PG" ] || fail "PlatformGraphics drift"
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.rg35xx.RG35XXCore2D > "$OUT/PARENT-CORE2D-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.rg35xx.RG35XXCore2D > "$OUT/CANDIDATE-CORE2D-JAVAP.txt"

# Strict P2A differential: all legal type/depth/interlace combinations x all five filters,
# plus exhaustive sample sweeps for every newly materialized conversion family.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p2a/RG35XXP2AImageDecodeDifferentialGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p2a.RG35XXP2AImageDecodeDifferentialGate \
  | tee "$OUT/P2A-IMAGE-STRICT-DIFFERENTIAL.txt"
DIFF="$OUT/P2A-IMAGE-STRICT-DIFFERENTIAL.txt"
grep -q '^P2A_IMAGE_MATRIX_CASE_COUNT=150$' "$DIFF" || fail "matrix count"
grep -q '^P2A_IMAGE_CANONICAL_PASS_COUNT=150$' "$DIFF" || fail "canonical count"
grep -q '^P2A_IMAGE_RAW_MATCH_COUNT=150$' "$DIFF" || fail "match count"
grep -q '^P2A_IMAGE_RAW_MISMATCH_COUNT=0$' "$DIFF" || fail "pixel mismatch"
grep -q '^P2A_IMAGE_RAW_UNSUPPORTED_COUNT=0$' "$DIFF" || fail "unsupported"
grep -q '^P2A_IMAGE_GRAY16_SWEEP_PIXELS=65536$' "$DIFF" || fail "gray16 sweep"
grep -q '^P2A_IMAGE_RGB16_SWEEP_PIXELS=65536$' "$DIFF" || fail "rgb16 sweep"
grep -q '^P2A_IMAGE_RGBA16_ALPHA_SWEEP_PIXELS=65536$' "$DIFF" || fail "alpha16 sweep"
grep -q '^P2A_IMAGE_DIFFERENTIAL_GATE=PASS$' "$DIFF" || fail "differential gate"
grep -q '^P2A_IMAGE_CANONICAL_EQUIVALENT=YES$' "$DIFF" || fail "canonical equivalence"

# Re-run accepted Core2D/graphics/image owner regressions against the candidate jar.
REG="$BUILD/p2a-regression"
rm -rf "$REG"; mkdir -p "$REG"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$REG" \
  "$ROOT/tests/a5/RG35XXCore2DHostGate.java" \
  "$ROOT/tests/a6/RG35XXAdam7HostGate.java" \
  "$ROOT/tests/a6/RG35XXRawClipTranslateHostGate.java" \
  "$ROOT/tests/a6/RG35XXRawDrawRectHostGate.java" \
  "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java" \
  "$ROOT/tests/p1a/RG35XXCompleteGraphicsG4G5DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXDGDrawVectorD6DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXDGFillVectorD4DifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2DArcFamilyDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

run_reg(){
  local cls="$1" marker="$2" log="$3"
  "$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$REG" "$cls" | tee "$OUT/$log"
  grep -q "^${marker}$" "$OUT/$log" || fail "regression $cls"
}
run_reg org.recompile.rg35xx.a5.RG35XXCore2DHostGate A5_CORE2D_ALPHA_HOST_GATE=PASS A5-CORE2D-ALPHA-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXAdam7HostGate A6_ADAM7_HOST_GATE=PASS A6-ADAM7-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS A6-CLIPTRANSLATE-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS A6-DRAWRECT-REGRESSION.txt
run_reg org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate A6_R5_RAW_DRAWLINE_HOST_GATE=PASS A6-DRAWLINE-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXCompleteGraphicsG4G5DifferentialGate P1A_COMPLETE_G4G5_DIFFERENTIAL_GATE=PASS P1A-G4G5-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXDGDrawVectorD6DifferentialGate P1A_DG_D6_DRAW_VECTOR_DIFFERENTIAL_GATE=PASS P1A-D6-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXDGFillVectorD4DifferentialGate P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS P1A-D4-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2DArcFamilyDifferentialGate P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS P1A-G2D-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS P1A-G2C-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS P1A-G1G2A-REGRESSION.txt
run_reg org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS P1A-G1-ALPHA-REGRESSION.txt

grep -q '^P1A_COMPLETE_G4G5_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-G4G5-REGRESSION.txt" || fail "G4G5 strict regression"
grep -q '^P1A_DG_D6_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-D6-REGRESSION.txt" || fail "D6 strict regression"
grep -q '^P1A_DG_D4_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-D4-REGRESSION.txt" || fail "D4 strict regression"
grep -q '^P1A_G2D_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-G2D-REGRESSION.txt" || fail "G2D strict regression"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-G2C-REGRESSION.txt" || fail "G2C strict regression"

# Non-owner native identities are inherited byte-for-byte from accepted P1A.
cp "$PARENT_OUT/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PARENT_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input native drift"
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail "video native drift"

CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_CORE="$(entry_digest "$CANDIDATE" org/recompile/rg35xx/RG35XXCore2D.class)"
cat > "$OUT/P2A-IMAGE-DECODE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P2A-IMAGE-DECODE-CANDIDATE
CURRENT_PHASE=P2_IMAGE_FONT_FRONTEND
CURRENT_MODULE=P2A_IMAGE_DECODE
OWNER=RG35XX_IMAGE_DECODE_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_GIT_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
AUDIT_BRANCH_PARENT=NO
A9_PARENT=NO
P1A_RUNTIME_PARENT_REBUILT=YES
PARENT_SEMANTIC_SHA256=$PARENT_SEM
PARENT_CORE2D_CLASS_SHA256=$PARENT_CORE
PARENT_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
CHANGED_JAR_ENTRIES=org/recompile/rg35xx/RG35XXCore2D\$RawImage.class,org/recompile/rg35xx/RG35XXCore2D.class
DECLARED_IMAGE_FORMAT=PNG
LEGAL_MATRIX_CASES=150
LEGAL_MATRIX_FILTERS=0,1,2,3,4
LEGAL_MATRIX_INTERLACE=0,1
GRAY1_2_4_MODEL=DIRECT_ROUNDED_SAMPLE_SCALE
GRAY8_16_MODEL=LINEAR_GRAY_TO_SRGB_IEC61966_2_1
RGB16_ALPHA16_MODEL=ROUNDED_16_TO_8_SCALE
NONINDEXED_TRNS=PINNED_MIYOO_JDK8_CANONICAL_LIMITATION_RETAINED
INDEXED_TRNS=SUPPORTED
P2A_STRICT_DIFFERENTIAL=PASS
P2A_CANONICAL_EQUIVALENT=YES
P1A_PROTECTED_REGRESSIONS=PASS
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_CORE2D_CLASS_SHA256=$CAND_CORE
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
CANONICAL_DIFF_VERIFIED=YES
OWNER_SCOPE_VERIFIED=YES
UNRELATED_CLASS_DIFF=NONE
PROTECTED_HASHES=PASS
JAVA6_GATE=PASS
HOST_MODULE_GATE=PASS
PHYSICAL_TEST_REQUIRED=YES
PHYSICAL_TEST_LEVEL=MODULE
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
DEVICE-PASS=NO
STABLE=NO
EOF

echo P2A_IMAGE_BUILD=PASS
echo P2A_IMAGE_HOST_MODULE_GATE=PASS
echo P2A_IMAGE_DEVICE_PASS=NO
