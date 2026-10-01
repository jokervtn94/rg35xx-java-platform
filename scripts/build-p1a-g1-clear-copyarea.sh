#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G1_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

BASE="$ROOT/out/a7-audio-sdl1"
BASE_JAR="$BASE/freej2me-rg35xx.jar"
BUILD="$ROOT/build/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
OUT="$ROOT/out/p1a-g1-clear-copyarea"
CLASSES="$ROOT/build/p1a-g1-classes"
TEST_CLASSES="$ROOT/build/p1a-g1-test-classes"
[ -f "$BASE_JAR" ] || fail "A7/A8 semantic parent missing"

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

BASE_SEM="$(semantic_digest "$BASE_JAR")"
[ "$BASE_SEM" = 7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf ] || fail "parent semantic mismatch $BASE_SEM"
[ "$(sha256sum "$BASE/librg35xx_input.so"|awk '{print $1}')" = 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d ] || fail input_identity
[ "$(sha256sum "$BASE/librg35xx_video.so"|awk '{print $1}')" = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d ] || fail video_identity
[ "$(sha256sum "$BASE/libaudio.so"|awk '{print $1}')" = 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644 ] || fail audio_identity

echo P1A_G1_PARENT_IDENTITY_GATE=PASS
python3 "$ROOT/scripts/stage-p1a-g1-clear-copyarea.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail canonical_worktree_dirty

rm -rf "$CLASSES" "$TEST_CLASSES" "$OUT"
mkdir -p "$CLASSES" "$TEST_CLASSES" "$OUT"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/p1a-g1-sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" @"$BUILD/p1a-g1-sources.list"

JAR="$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$CLASSES" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$JAR" -C "$UPSTREAM" META-INF; fi

python3 - "$BASE_JAR" "$JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    if set(a.namelist()) != set(b.namelist()):
        raise SystemExit('P1A_G1_SCOPE_FAIL entry-set')
    diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/mobile/PlatformGraphics.class','org/recompile/rg35xx/RG35XXCore2D.class']
if diff != expected:
    raise SystemExit('P1A_G1_SCOPE_FAIL changed='+repr(diff))
print('P1A_G1_CHANGED_JAR_ENTRIES='+','.join(diff))
print('P1A_G1_SCOPE_GATE=PASS')
PY

python3 - "$JAR" <<'PY'
import sys,zipfile
bad=[]
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=(b[6]<<8)|b[7]
            if major>50: bad.append((n,major))
if bad: raise SystemExit('P1A_G1_JAVA6_FAIL '+repr(bad[:20]))
print('P1A_G1_JAVA6_GATE=PASS')
PY

# Differential target gate plus protected graphics regressions.
GATE_SOURCES=(
  "$ROOT/tests/p1a/RG35XXG1ClearCopyDifferentialGate.java"
  "$ROOT/tests/a5/RG35XXCore2DHostGate.java"
  "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
  "$ROOT/tests/a6/RG35XXRawDrawRectHostGate.java"
  "$ROOT/tests/a6/RG35XXRawRectPolygonHostGate.java"
  "$ROOT/tests/a6/RG35XXRawClipTranslateHostGate.java"
  "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
)
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$JAR" \
  -d "$TEST_CLASSES" "${GATE_SOURCES[@]}"

run_gate(){ "$JAVA8/bin/java" -Djava.awt.headless=true -cp "$JAR:$TEST_CLASSES" "$1"; }
run_gate org.recompile.rg35xx.p1a.RG35XXG1ClearCopyDifferentialGate
run_gate org.recompile.rg35xx.a5.RG35XXCore2DHostGate
run_gate org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate
run_gate org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate
run_gate org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate
run_gate org.recompile.rg35xx.a6.RG35XXRawClipTranslateHostGate
run_gate org.recompile.rg35xx.a6.RG35XXAdam7HostGate

echo P1A_G1_PROTECTED_GRAPHICS_REGRESSION=PASS
cp "$BASE/librg35xx_input.so" "$BASE/librg35xx_video.so" "$BASE/libaudio.so" "$OUT/"
CAND_SHA="$(sha256sum "$JAR"|awk '{print $1}')"
CAND_SEM="$(semantic_digest "$JAR")"
cat > "$OUT/P1A-G1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G1-CLEAR-COPYAREA
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
PARENT_SEMANTIC_SHA256=$BASE_SEM
EXACT_A8_GOLDEN_PLATFORM_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
CANDIDATE_PLATFORM_SHA256=$CAND_SHA
CANDIDATE_PLATFORM_SEMANTIC_SHA256=$CAND_SEM
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class,org/recompile/rg35xx/RG35XXCore2D.class
CHANGED_METHODS=PlatformGraphics.clearRect,PlatformGraphics.copyArea,RG35XXCore2D.copyAreaAliased
CORE2D_DELTA=copyAreaAliased_ONLY
COPYAREA_ALIAS_ORDER=TOP_TO_BOTTOM_LEFT_TO_RIGHT
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
GAME_SPECIFIC_CODE=NO
BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
EOF
(cd "$OUT" && sha256sum freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so > SHA256SUMS.txt)
echo P1A_G1_BUILD=PASS
cat "$OUT/P1A-G1-IDENTITY.txt"
