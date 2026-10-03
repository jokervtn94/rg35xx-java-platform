#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2A_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar javap; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
BUILD="$ROOT/build/a3"
STAGE="$BUILD/stage-src"
OUT="$ROOT/out/p1a-g2a-fillroundrect"
CLASSES="$BUILD/p1a-g2a-classes"

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

# Rebuild and gate the exact G1 host parent first.
bash "$ROOT/scripts/build-p1a-g1-clear-copy.sh"
PARENT="$ROOT/out/p1a-g1-clear-copy"
PARENT_JAR="$PARENT/freej2me-rg35xx.jar"
PARENT_ID="$PARENT/P1A-G1-IDENTITY.txt"
[ -f "$PARENT_JAR" ] || fail "G1 parent jar missing"
grep -q '^P1A_G1_DIFFERENTIAL_GATE=PASS$' "$PARENT_ID" || fail "G1 differential parent not locked"
grep -q '^P1A_G1_ALPHA_DIFFERENTIAL_GATE=PASS$' "$PARENT_ID" || fail "G1 alpha parent not locked"
grep -q '^HOST-DIFFERENTIAL-PASS=YES$' "$PARENT_ID" || fail "G1 host parent not locked"
grep -q '^DEVICE-PASS=NO$' "$PARENT_ID" || fail "G1 unexpectedly promoted"

PARENT_SEM="$(semantic_digest "$PARENT_JAR")"
PARENT_PG="$(python3 - "$PARENT_JAR" <<'PY'
import hashlib,sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z: print(hashlib.sha256(z.read('org/recompile/mobile/PlatformGraphics.class')).hexdigest())
PY
)"
[ "$PARENT_SEM" = "86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527" ] || fail "G1 semantic drift $PARENT_SEM"
[ "$PARENT_PG" = "c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0" ] || fail "G1 PlatformGraphics drift $PARENT_PG"
echo P1A_G2A_G1_PARENT_IDENTITY_GATE=PASS

python3 "$ROOT/scripts/stage-p1a-g2a-fillroundrect.py" "$STAGE"
PG_SRC="$STAGE/org/recompile/mobile/PlatformGraphics.java"
rm -rf "$OUT" "$CLASSES"
mkdir -p "$OUT" "$CLASSES"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" "$PG_SRC"
CLASS_LIST="$(cd "$CLASSES" && find . -type f -name '*.class' -printf '%P\n' | LC_ALL=C sort)"
[ "$CLASS_LIST" = "org/recompile/mobile/PlatformGraphics.class" ] || fail "unexpected compile scope: $CLASS_LIST"

CANDIDATE="$OUT/freej2me-rg35xx.jar"
cp "$PARENT_JAR" "$CANDIDATE"
"$JAVA8/bin/jar" uf "$CANDIDATE" -C "$CLASSES" org/recompile/mobile/PlatformGraphics.class

python3 - "$PARENT_JAR" "$CANDIDATE" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()): raise SystemExit('P1A_G2A_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
if diff != ['org/recompile/mobile/PlatformGraphics.class']:
    raise SystemExit('P1A_G2A_SCOPE_FAIL changed='+repr(diff))
print('P1A_G2A_CHANGED_JAR_ENTRIES='+','.join(diff))
print('P1A_G2A_SCOPE_GATE=PASS')
PY

python3 - "$CANDIDATE" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=int.from_bytes(b[6:8],'big')
            if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_G2A_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_G2A_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$PARENT_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/PARENT-PLATFORMGRAPHICS-JAVAP.txt"
"$JAVA8/bin/javap" -classpath "$CANDIDATE" -p -c org.recompile.mobile.PlatformGraphics > "$OUT/CANDIDATE-PLATFORMGRAPHICS-JAVAP.txt"
cp "$PG_SRC" "$OUT/P1A-G2A-PLATFORMGRAPHICS-SOURCE.java.txt"

# G2A differential.
HOST="$BUILD/p1a-g2a-host"
rm -rf "$HOST"; mkdir -p "$HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" \
  -d "$HOST" "$ROOT/tests/p1a/RG35XXG2AFillRoundRectDifferentialGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$HOST" \
  org.recompile.rg35xx.p1a.RG35XXG2AFillRoundRectDifferentialGate \
  | tee "$OUT/P1A-G2A-DIFFERENTIAL-GATE.txt"
grep -q '^P1A_G2A_FILLROUNDRECT_DIFFERENTIAL_GATE=PASS$' "$OUT/P1A-G2A-DIFFERENTIAL-GATE.txt" || fail "G2A differential"
grep -q '^P1A_G2A_SCOPE=fillRoundRect_ONLY$' "$OUT/P1A-G2A-DIFFERENTIAL-GATE.txt" || fail "G2A scope marker"

# Rerun locked G1 gates on the G2A candidate.
G1HOST="$BUILD/p1a-g2a-g1-host"
rm -rf "$G1HOST"; mkdir -p "$G1HOST"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" \
  -d "$G1HOST" "$ROOT/tests/p1a/RG35XXGraphicsG1DifferentialGate.java" "$ROOT/tests/p1a/RG35XXCopyAreaAlphaDifferentialGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$G1HOST" org.recompile.rg35xx.p1a.RG35XXGraphicsG1DifferentialGate | tee "$OUT/G1-DIFFERENTIAL-REGRESSION.txt"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$G1HOST" org.recompile.rg35xx.p1a.RG35XXCopyAreaAlphaDifferentialGate | tee "$OUT/G1-ALPHA-REGRESSION.txt"
grep -q '^P1A_G1_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-DIFFERENTIAL-REGRESSION.txt" || fail "G1 regression"
grep -q '^P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS$' "$OUT/G1-ALPHA-REGRESSION.txt" || fail "G1 alpha regression"

# Preserve accepted pre-P1A raw gates too.
run_gate() {
  local src="$1" cls="$2" marker="$3" out="$4"
  local dir="$BUILD/p1a-g2a-reg-$(basename "$src" .java)"
  rm -rf "$dir"; mkdir -p "$dir"
  "$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$CANDIDATE" -d "$dir" "$ROOT/tests/a6/$src"
  "$JAVA8/bin/java" -cp "$CANDIDATE:$dir" "$cls" | tee "$OUT/$out"
  grep -q "^${marker}$" "$OUT/$out" || fail "regression $src"
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
cat > "$OUT/P1A-G2A-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2A-FILLROUNDRECT
OWNER=RG35XX_GRAPHICS_BOUNDARY
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G1_SEMANTIC_SHA256=$PARENT_SEM
PARENT_G1_PLATFORMGRAPHICS_CLASS_SHA256=$PARENT_PG
CANDIDATE_PLATFORM_JAR_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=$CAND_PG
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
CHANGED_METHODS=fillRoundRect
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
RAW_IMPLEMENTATION=EXISTING_ACCEPTED_FILLRECT
CANONICAL_QUIRK=FINAL_FULL_FILLRECT
CORE2D_CHANGE=NO
G1_REGRESSION=PASS
G1_ALPHA_REGRESSION=PASS
G2A_DIFFERENTIAL_GATE=PASS
NEIGHBOR_G2_METHODS=UNCHANGED_RAW_EXCEPTION
GAME_SPECIFIC_CODE=NO
NO_A9_PARENT=YES
JAMVM_GLIBJ=NOT_TOUCHED
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF
(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo P1A_G2A_BUILD=PASS
cat "$OUT/P1A-G2A-IDENTITY.txt"
