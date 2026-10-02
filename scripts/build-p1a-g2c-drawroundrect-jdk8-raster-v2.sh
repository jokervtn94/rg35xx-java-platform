#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2C_V2_BUILD_FAIL=$*" >&2; exit 1; }
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
OUT="$ROOT/out/p1a-g2c-drawroundrect-jdk8-raster"
CLASSES="$BUILD/p1a-g2c-v2-classes"
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

# Rebuild exact host-accepted G2B parent; this transitively gates G2A/G1/A6.
bash "$ROOT/scripts/build-p1a-g2b-filltriangle-jdk8-raster.sh"
PARENT="$ROOT/out/p1a-g2b-filltriangle-jdk8-raster"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT/P1A-G2B-IDENTITY.txt"
[ -f "$PARENT_JAR" ] || fail "G2B parent jar missing"
grep -q '^G2B_STRICT_DIFFERENTIAL=PASS$' "$PARENT_ID" || fail "G2B parent differential"
grep -q '^G2B_CANONICAL_EQUIVALENT=YES$' "$PARENT_ID" || fail "G2B parent canonical"
PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(python3 - "$PARENT_JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z: print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
[ "$PARENT_SEM" = "d6cc9aa636b3435de07bff4552d4feb5ad7cada41c63ef66719fec8f192cdb77" ] || fail "G2B semantic drift $PARENT_SEM"
[ "$PARENT_PG" = "a6004238f7c36455f498d024a171159cb69a7fd95647aa5cabcf966e4e625cec" ] || fail "G2B PG drift $PARENT_PG"
echo P1A_G2C_V2_G2B_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-p1a-g2c-drawroundrect-jdk8-raster.py" "$STAGE"
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
  if set(za.namelist()) != set(zb.namelist()): raise SystemExit('P1A_G2C_V2_SCOPE_FAIL entry-set')
  d=[n for n in sorted(za.namelist()) if hashlib.sha256(za.read(n)).digest()!=hashlib.sha256(zb.read(n)).digest()]
if d != ['org/recompile/mobile/PlatformGraphics.class']:
  raise SystemExit('P1A_G2C_V2_SCOPE_FAIL changed='+repr(d))
print('P1A_G2C_V2_CHANGED_JAR_ENTRIES='+','.join(d))
print('P1A_G2C_V2_SCOPE_GATE=PASS')
PY
python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big')
      if m>50: bad.append((n,m))
if bad: raise SystemExit('P1A_G2C_V2_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_G2C_V2_JAVA6_GATE=PASS')
PY
"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-G2C-PLATFORMGRAPHICS-SOURCE.java.txt"

HOST="$BUILD/p1a-g2c-v2-host"; rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$HOST" \
  "$ROOT/tests/p1a/RG35XXG2CDrawRoundRectDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BFillTriangleDifferentialGate.java" \
  "$ROOT/tests/p1a/RG35XXG2BParentRegressionGate.java" \
  "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"

# G2C strict canonical matrix.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2CDrawRoundRectDifferentialGate \
  | tee "$OUT/P1A-G2C-DRAWROUNDRECT-DIFFERENTIAL.txt"
grep -q '^P1A_G2C_STRICT_FAILURE_COUNT=0$' "$OUT/P1A-G2C-DRAWROUNDRECT-DIFFERENTIAL.txt" || fail "G2C strict mismatch"
grep -q '^P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS$' "$OUT/P1A-G2C-DRAWROUNDRECT-DIFFERENTIAL.txt" || fail "G2C marker"
grep -q '^P1A_G2C_CANONICAL_EQUIVALENT=YES$' "$OUT/P1A-G2C-DRAWROUNDRECT-DIFFERENTIAL.txt" || fail "G2C canonical"

# Preserve all G2B triangle behavior. DrawRoundRect is now an implemented parent, not an old NPE sentinel.
"$JAVA8/bin/java" -Djava.awt.headless=true -Dp1a.g2c.parentregression=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BFillTriangleDifferentialGate \
  | tee "$OUT/G2B-TRIANGLE-REGRESSION.txt"
grep -q '^P1A_G2B_STRICT_FAILURE_COUNT=0$' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "G2B regression"
grep -q '^P1A_G2B_SCOPE_CASE=PARENT_DRAWROUNDRECT_G2C EXPECTED=MATCH ACTUAL=MATCH' "$OUT/G2B-TRIANGLE-REGRESSION.txt" || fail "G2C parent marker"

# Protect actual G1/G2A behavior without stale future-method sentinels.
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2BParentRegressionGate \
  | tee "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt"
grep -q '^P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS$' "$OUT/G1-G2A-BEHAVIOR-REGRESSION.txt" || fail "G1/G2A behavior regression"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate \
  | tee "$OUT/G1-ALPHA-REGRESSION.txt"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-ALPHA-REGRESSION.txt" || fail "G1 alpha regression"

# Accepted pre-P1A regressions.
run_gate(){
  local src="$1" cls="$2" marker="$3" log="$4"
  local d="$BUILD/p1a-g2c-v2-$(basename "$src" .java)"
  rm -rf "$d"; mkdir -p "$d"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
    -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$d" "$ROOT/tests/a6/$src"
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
INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so"|awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so"|awk '{print $1}')"
[ "$INPUT_SHA" = "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail input
[ "$VIDEO_SHA" = "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d" ] || fail video
CAND_SHA="$(sha256sum "$CANDIDATE"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$CANDIDATE")"
CAND_PG="$(python3 - "$CANDIDATE" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z: print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
cat > "$OUT/P1A-G2C-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2C-DRAWROUNDRECT-JDK8-RASTER
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G2B_SEMANTIC_SHA256=$PARENT_SEM
PARENT_G2B_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CHANGED_METHODS=Graphics.drawRoundRect
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
RASTER=OPENJDK8_ROUNDRECTITERATOR_PROCESSPATH_DRAW_SUBSET
CORE2D_CHANGE=NO
G2C_STRICT_DIFFERENTIAL=PASS
G2C_CANONICAL_EQUIVALENT=YES
G2B_21_CASE_REGRESSION=PASS
G1_G2A_BEHAVIOR_REGRESSION=PASS
G1_ALPHA_REGRESSION=PASS
A6_PROTECTED_REGRESSIONS=PASS
STALE_G1_FUTURE_METHOD_SENTINELS=NOT_USED
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
echo P1A_G2C_V2_BUILD=PASS
cat "$OUT/P1A-G2C-IDENTITY.txt"
