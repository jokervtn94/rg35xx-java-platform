#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5P3I2_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Build exact R5P3I1 parent first: device-proven progress through opening story,
# input pump active before synchronous runJar, R5P3 graphics preserved.
bash "$ROOT/scripts/build-a6-input-lifecycle-r5p3i1-v2.sh"
PARENT_JAR="$ROOT/out/a6-realgame-r5p3i1/freej2me-rg35xx.jar"
[ -f "$PARENT_JAR" ] || fail "R5P3I1 parent missing"
PARENT_SHA="$(sha256sum "$PARENT_JAR" | awk '{print $1}')"
cp "$PARENT_JAR" "$BUILD/r5p3i1-parent.jar"
unzip -Z1 "$PARENT_JAR" | LC_ALL=C sort > "$BUILD/r5p3i1-parent.entries"

python3 "$ROOT/scripts/stage-a6-rg35xx-raw-drawrect-r5p3i2.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty"

rm -rf "$BUILD/classes"; mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$BUILD/classes" @"$BUILD/sources.list"

rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
FIX_JAR="$OUT/freej2me-rg35xx.jar"
FIX_SHA="$(sha256sum "$FIX_JAR" | awk '{print $1}')"
[ "$FIX_SHA" != "$PARENT_SHA" ] || fail "candidate identical to parent"

# Exact entry set must remain unchanged; only PlatformGraphics bytecode may differ.
unzip -Z1 "$FIX_JAR" | LC_ALL=C sort > "$BUILD/r5p3i2.entries"
cmp -s "$BUILD/r5p3i1-parent.entries" "$BUILD/r5p3i2.entries" || fail "JAR entry set changed"
python3 - "$PARENT_JAR" "$FIX_JAR" <<'PY'
import sys, zipfile, hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    diff=[]
    for n in sorted(a.namelist()):
        if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest():
            diff.append(n)
expected=['org/recompile/mobile/PlatformGraphics.class']
if diff != expected:
    raise SystemExit('A6_R5P3I2_SCOPE_FAIL changed='+repr(diff))
print('A6_R5P3I2_CHANGED_ENTRIES='+','.join(diff))
print('A6_R5P3I2_SCOPE_GATE=PASS')
PY

python3 - "$FIX_JAR" <<'PY'
import sys,zipfile
bad=[]; majors=set()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
if bad: raise SystemExit('A6_R5P3I2_JAVA6_GATE_FAIL '+repr(bad[:20]))
print('A6_R5P3I2_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5P3I2_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5p3i2-platformgraphics.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.rg35xx.RG35XXLauncher > "$BUILD/a6-r5p3i2-launcher.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5p3i2-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r5p3i2-core2d.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r5p3i2-midletloader.javap"

# drawRect raw path must route through the already-proven drawLine primitive.
python3 - "$BUILD/a6-r5p3i2-platformgraphics.javap" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
start=s.find('public void drawRect(int, int, int, int);')
end=s.find('public void drawRoundRect', start)
if start<0 or end<0: raise SystemExit('A6_R5P3I2_BYTECODE_FAIL drawRect method not found')
m=s[start:end]
if m.count('Method drawLine:(IIII)V') < 4:
    raise SystemExit('A6_R5P3I2_BYTECODE_FAIL drawLine calls='+str(m.count('Method drawLine:(IIII)V')))
if 'java/awt/Graphics2D.drawRect' not in m:
    raise SystemExit('A6_R5P3I2_BYTECODE_FAIL canonical AWT fallback missing')
print('A6_R5P3I2_DRAWRECT_BYTECODE_GATE=PASS')
PY

# Preserve proven lifecycle/input and prior graphics owners.
grep -q 'RG35XX_A6_TRACE_INPUT_START_BEFORE_RUNJAR' "$BUILD/a6-r5p3i2-launcher.javap" || fail "R5P3I1 lifecycle marker lost"
grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5p3i2-mobileplatform.javap" || fail "keypress trace lost"
grep -q 'RG35XXCore2D.sourceOver' "$BUILD/a6-r5p3i2-platformgraphics.javap" || fail "R5P3 polygon fix lost"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r5p3i2-midletloader.javap" || fail "R1 synchronized loadClass lost"
grep -q 'findLoadedClass' "$BUILD/a6-r5p3i2-midletloader.javap" || fail "R1 findLoadedClass lost"
grep -q 'decodeAdam7' "$BUILD/a6-r5p3i2-core2d.javap" || fail "R4 Adam7 lost"
echo A6_R5P3I2_PARENT_BYTECODE_GATE=PASS

# New drawRect functional gate.
rm -rf "$BUILD/a6-r5p3i2-drawrect-host"; mkdir -p "$BUILD/a6-r5p3i2-drawrect-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$FIX_JAR" -d "$BUILD/a6-r5p3i2-drawrect-host" "$ROOT/tests/a6/RG35XXRawDrawRectHostGate.java"
"$JAVA8/bin/java" -cp "$FIX_JAR:$BUILD/a6-r5p3i2-drawrect-host" org.recompile.rg35xx.a6.RG35XXRawDrawRectHostGate \
  | tee "$BUILD/a6-r5p3i2-drawrect-host-gate.txt"
grep -q '^A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS$' "$BUILD/a6-r5p3i2-drawrect-host-gate.txt" || fail "drawRect host gate missing"

# Preserve R5 drawLine, R5P3 rectangle polygon and R4 Adam7 host gates.
rm -rf "$BUILD/a6-r5p3i2-drawline-host" "$BUILD/a6-r5p3i2-rectpoly-host" "$BUILD/a6-r5p3i2-adam7-host"
mkdir -p "$BUILD/a6-r5p3i2-drawline-host" "$BUILD/a6-r5p3i2-rectpoly-host" "$BUILD/a6-r5p3i2-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$FIX_JAR" -d "$BUILD/a6-r5p3i2-drawline-host" "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
"$JAVA8/bin/java" -cp "$FIX_JAR:$BUILD/a6-r5p3i2-drawline-host" org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate | tee "$BUILD/a6-r5p3i2-drawline-host-gate.txt"
grep -q '^A6_R5_RAW_DRAWLINE_HOST_GATE=PASS$' "$BUILD/a6-r5p3i2-drawline-host-gate.txt" || fail "drawLine regression"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$FIX_JAR" -d "$BUILD/a6-r5p3i2-rectpoly-host" "$ROOT/tests/a6/RG35XXRawRectPolygonHostGate.java"
"$JAVA8/bin/java" -cp "$FIX_JAR:$BUILD/a6-r5p3i2-rectpoly-host" org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate | tee "$BUILD/a6-r5p3i2-rectpoly-host-gate.txt"
grep -q '^A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS$' "$BUILD/a6-r5p3i2-rectpoly-host-gate.txt" || fail "polygon regression"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$FIX_JAR" -d "$BUILD/a6-r5p3i2-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$FIX_JAR:$BUILD/a6-r5p3i2-adam7-host" org.recompile.rg35xx.a6.RG35XXAdam7HostGate | tee "$BUILD/a6-r5p3i2-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r5p3i2-adam7-host-gate.txt" || fail "Adam7 regression"

DST="$ROOT/out/a6-realgame-r5p3i2"
rm -rf "$DST"; mkdir -p "$DST"
cp "$FIX_JAR" "$DST/freej2me-rg35xx.jar"
cp "$ROOT/out/a6-realgame-r5p3i1/JAVA6-COMPAT-AUDIT.tsv" "$DST/JAVA6-COMPAT-AUDIT.tsv"
cp "$ROOT/out/a6-realgame-r5p3i1/CANONICAL-DIFF-MANIFEST.txt" "$DST/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_R5P3I1_DEVICE_RESULT=FAIL_HARD_RESET_OPENING_STORY_DRAWRECT_NPE
A6_R5P3I2_OWNER=RG35XX_RAW2D_PLATFORMGRAPHICS_DRAWRECT_AWT_NULL
A6_R5P3I2_IMPLEMENTATION=FOUR_DEVICE_PROVEN_DRAWLINE_CALLS
A6_R5P3I2_CHANGED_SCOPE=PlatformGraphics_CLASS_ONLY
A6_R5P3I1_INPUT_LIFECYCLE=PRESERVED
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5p3i2-platformgraphics.javap" "$DST/A6-R5P3I2-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r5p3i2-launcher.javap" "$DST/A6-R5P3I2-LAUNCHER-JAVAP.txt"
cp "$BUILD/a6-r5p3i2-mobileplatform.javap" "$DST/A6-R5P3I2-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5p3i2-core2d.javap" "$DST/A6-R5P3I2-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r5p3i2-midletloader.javap" "$DST/A6-R5P3I2-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r5p3i2-drawrect-host-gate.txt" "$DST/A6-R5P3I2-DRAWRECT-HOST-GATE.txt"
cp "$BUILD/a6-r5p3i2-drawline-host-gate.txt" "$DST/A6-R5P3I2-DRAWLINE-REGRESSION-GATE.txt"
cp "$BUILD/a6-r5p3i2-rectpoly-host-gate.txt" "$DST/A6-R5P3I2-POLYGON-REGRESSION-GATE.txt"
cp "$BUILD/a6-r5p3i2-adam7-host-gate.txt" "$DST/A6-R5P3I2-ADAM7-REGRESSION-GATE.txt"
cat > "$DST/A6-REALGAME-R5P3I2-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5P3I2-RAW-DRAWRECT
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R5P3I1_PARENT_PLATFORM_JAR_SHA256=$PARENT_SHA
A6_R5P3I2_PLATFORM_JAR_SHA256=$FIX_SHA
A6_R5P3I1_DEVICE_RESULT=FAIL_HARD_RESET_OPENING_STORY_DRAWRECT_NPE
A6_R5P3I1_INPUT_POLL_LAST=6800
A6_R5P3I1_KEYPRESS_RETURN_COUNT=32
A6_R5P3I1_ADAM7_BEGIN_RETURN=9/9
A6_R5P3I1_DRAWRECT_NPE_COUNT=57
A6_R5P3I2_OWNER=RG35XX_RAW2D_PLATFORMGRAPHICS_DRAWRECT_AWT_NULL
A6_R5P3I2_IMPLEMENTATION=FOUR_DEVICE_PROVEN_DRAWLINE_CALLS
A6_R5P3I2_SCOPE_GATE=PASS
A6_R5P3I2_DRAWRECT_BYTECODE_GATE=PASS
A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS
A6_R5_DRAWLINE_REGRESSION_GATE=PASS
A6_R5P3_POLYGON_REGRESSION_GATE=PASS
A6_R4_ADAM7_REGRESSION_GATE=PASS
A6_R5P3I1_INPUT_LIFECYCLE=PRESERVED
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF
(cd "$DST" && sha256sum * > SHA256SUMS.txt)
echo A6_R5P3I2_BUILD=PASS
cat "$DST/A6-REALGAME-R5P3I2-IDENTITY.txt"
