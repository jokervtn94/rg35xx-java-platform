#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5P3_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Exact real-device-proven R5 FastPath parent.
bash "$ROOT/scripts/build-a6-raw-drawline-r5.sh"
R5_JAR="$OUT/freej2me-rg35xx.jar"
[ -f "$R5_JAR" ] || fail "R5 parent missing"
R5_SHA="$(sha256sum "$R5_JAR" | awk '{print $1}')"
cp "$R5_JAR" "$BUILD/r5-parent.jar"
R5_PG_SIZE="$(unzip -p "$R5_JAR" org/recompile/mobile/PlatformGraphics.class | wc -c | tr -d ' ')"
R5_CORE_SIZE="$(unzip -p "$R5_JAR" org/recompile/rg35xx/RG35XXCore2D.class | wc -c | tr -d ' ')"
unzip -Z1 "$R5_JAR" | LC_ALL=C sort > "$BUILD/r5-parent.entries"

python3 "$ROOT/scripts/stage-a6-rg35xx-raw-rect-polygon-r5p3.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after R5P3 staging"

rm -rf "$BUILD/classes"; mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$BUILD/classes" @"$BUILD/sources.list"

rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
P3_JAR="$OUT/freej2me-rg35xx.jar"
P3_SHA="$(sha256sum "$P3_JAR" | awk '{print $1}')"
[ "$P3_SHA" != "$R5_SHA" ] || fail "R5P3 unexpectedly identical to R5"

# No class-entry drift is allowed.
unzip -Z1 "$P3_JAR" | LC_ALL=C sort > "$BUILD/r5p3.entries"
cmp -s "$BUILD/r5-parent.entries" "$BUILD/r5p3.entries" || fail "JAR entry set changed vs R5"

P3_PG_SIZE="$(unzip -p "$P3_JAR" org/recompile/mobile/PlatformGraphics.class | wc -c | tr -d ' ')"
P3_CORE_SIZE="$(unzip -p "$P3_JAR" org/recompile/rg35xx/RG35XXCore2D.class | wc -c | tr -d ' ')"
PG_DELTA=$((P3_PG_SIZE - R5_PG_SIZE))
CORE_DELTA=$((P3_CORE_SIZE - R5_CORE_SIZE))
[ "$PG_DELTA" -ge 0 ] || fail "PlatformGraphics shrank unexpectedly"
[ "$PG_DELTA" -le 1200 ] || fail "PlatformGraphics delta too large: $PG_DELTA"
[ "$CORE_DELTA" -ge -8 ] && [ "$CORE_DELTA" -le 8 ] || fail "Core2D logic-size drift: $CORE_DELTA"
echo "A6_R5P3_R5_PLATFORMGRAPHICS_SIZE=$R5_PG_SIZE"
echo "A6_R5P3_PLATFORMGRAPHICS_SIZE=$P3_PG_SIZE"
echo "A6_R5P3_PLATFORMGRAPHICS_DELTA=$PG_DELTA"
echo "A6_R5P3_R5_CORE2D_SIZE=$R5_CORE_SIZE"
echo "A6_R5P3_CORE2D_SIZE=$P3_CORE_SIZE"
echo "A6_R5P3_CORE2D_DELTA=$CORE_DELTA"
echo A6_R5P3_CLASS_SIZE_GATE=PASS

python3 - "$P3_JAR" <<'PY'
import sys, zipfile
jar=sys.argv[1]; bad=[]; majors=set()
with zipfile.ZipFile(jar) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
  if 'org/recompile/rg35xx/RG35XXAdam7.class' in z.namelist():
    raise SystemExit('A6_R5P3_CLASS_GATE_FAIL separate Adam7 class present')
if bad: raise SystemExit('A6_R5P3_JAVA6_GATE_FAIL '+repr(bad[:20]))
print('A6_R5P3_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5P3_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$P3_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5p3-platformgraphics.javap"
"$JAVA8/bin/javap" -classpath "$P3_JAR" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r5p3-core2d.javap"
"$JAVA8/bin/javap" -classpath "$P3_JAR" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5p3-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$P3_JAR" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r5p3-midletloader.javap"

grep -q 'RG35XXCore2D.sourceOver' "$BUILD/a6-r5p3-platformgraphics.javap" || fail "fillPolygon sourceOver call missing"
grep -q 'java/awt/Graphics2D.fillPolygon' "$BUILD/a6-r5p3-platformgraphics.javap" || fail "canonical AWT fallback missing"
grep -q 'public static int sourceOver(int, int)' "$BUILD/a6-r5p3-core2d.javap" || fail "Core2D sourceOver not public"
grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5p3-mobileplatform.javap" || fail "R5 keypress trace lost"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r5p3-midletloader.javap" || fail "R1 synchronized loadClass lost"
grep -q 'findLoadedClass' "$BUILD/a6-r5p3-midletloader.javap" || fail "R1 findLoadedClass lost"
grep -q 'decodeAdam7' "$BUILD/a6-r5p3-core2d.javap" || fail "R4 inline Adam7 lost"
echo A6_R5P3_PARENT_BYTECODE_GATE=PASS

# Functional rectangle/alpha gate.
rm -rf "$BUILD/a6-r5p3-rect-host"; mkdir -p "$BUILD/a6-r5p3-rect-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$P3_JAR" -d "$BUILD/a6-r5p3-rect-host" "$ROOT/tests/a6/RG35XXRawRectPolygonHostGate.java"
"$JAVA8/bin/java" -cp "$P3_JAR:$BUILD/a6-r5p3-rect-host" org.recompile.rg35xx.a6.RG35XXRawRectPolygonHostGate \
  | tee "$BUILD/a6-r5p3-rect-host-gate.txt"
grep -q '^A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS$' "$BUILD/a6-r5p3-rect-host-gate.txt" || fail "rect polygon gate missing"

# Preserve R5 drawLine and R4 Adam7 functional gates.
rm -rf "$BUILD/a6-r5p3-drawline-host" "$BUILD/a6-r5p3-adam7-host"
mkdir -p "$BUILD/a6-r5p3-drawline-host" "$BUILD/a6-r5p3-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$P3_JAR" -d "$BUILD/a6-r5p3-drawline-host" "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
"$JAVA8/bin/java" -cp "$P3_JAR:$BUILD/a6-r5p3-drawline-host" org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  | tee "$BUILD/a6-r5p3-drawline-host-gate.txt"
grep -q '^A6_R5_RAW_DRAWLINE_HOST_GATE=PASS$' "$BUILD/a6-r5p3-drawline-host-gate.txt" || fail "drawLine regression"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$P3_JAR" -d "$BUILD/a6-r5p3-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$P3_JAR:$BUILD/a6-r5p3-adam7-host" org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  | tee "$BUILD/a6-r5p3-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r5p3-adam7-host-gate.txt" || fail "Adam7 regression"

R5P3OUT="$ROOT/out/a6-realgame-r5p3"
rm -rf "$R5P3OUT"; mkdir -p "$R5P3OUT"
cp "$P3_JAR" "$R5P3OUT/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$R5P3OUT/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$R5P3OUT/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$R5P3OUT/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_R5P_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P2_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P3_OWNER=RAW2D_DIRECTGRAPHICS_RECT_FILLPOLYGON
A6_R5P3_IMPLEMENTATION=R5_PLATFORMGRAPHICS_TINY_RECT_PATH+EXISTING_CORE2D_SOURCEOVER
A6_R5P3_PLATFORMGRAPHICS_DELTA_BYTES=$PG_DELTA
A6_R5P3_CORE2D_DELTA_BYTES=$CORE_DELTA
A6_R5P3_GENERIC_SCANLINE=NO
A6_R5P3_NEW_CLASS=NO
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5p3-platformgraphics.javap" "$R5P3OUT/A6-R5P3-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r5p3-core2d.javap" "$R5P3OUT/A6-R5P3-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r5p3-mobileplatform.javap" "$R5P3OUT/A6-R5P3-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5p3-midletloader.javap" "$R5P3OUT/A6-R5P3-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r5p3-rect-host-gate.txt" "$R5P3OUT/A6-R5P3-RECT-POLYGON-HOST-GATE.txt"
cp "$BUILD/a6-r5p3-drawline-host-gate.txt" "$R5P3OUT/A6-R5P3-DRAWLINE-REGRESSION-GATE.txt"
cp "$BUILD/a6-r5p3-adam7-host-gate.txt" "$R5P3OUT/A6-R5P3-ADAM7-REGRESSION-GATE.txt"
cat > "$R5P3OUT/A6-REALGAME-R5P3-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5P3-RAW-RECT-POLYGON
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R5_PARENT_PLATFORM_JAR_SHA256=$R5_SHA
A6_R5P3_PLATFORM_JAR_SHA256=$P3_SHA
A6_R5P_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P2_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P3_OWNER=RAW2D_DIRECTGRAPHICS_RECT_FILLPOLYGON
A6_R5P3_PLATFORMGRAPHICS_DELTA_BYTES=$PG_DELTA
A6_R5P3_CORE2D_DELTA_BYTES=$CORE_DELTA
A6_R5P3_CLASS_SIZE_GATE=PASS
A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS
A6_R5_DRAWLINE_REGRESSION_GATE=PASS
A6_R4_ADAM7_REGRESSION_GATE=PASS
A6_R5P3_GENERIC_SCANLINE=NO
A6_R5P3_NEW_CLASS=NO
A6_R1_CLASSLOADER_FIX=YES
A6_R2_DRAWREGION_NULL_GUARD=YES
A6_R4_ADAM7_INLINE=YES
A6_R4T_PARENT_TRACE=YES
A6_R5_RAW_DRAWLINE_FASTPATH=YES
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF
(cd "$R5P3OUT" && sha256sum * > SHA256SUMS.txt)
echo A6_R5P3_BUILD=PASS
cat "$R5P3OUT/A6-REALGAME-R5P3-IDENTITY.txt"
