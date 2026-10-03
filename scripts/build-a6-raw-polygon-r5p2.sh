#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5P2_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

bash "$ROOT/scripts/build-a6-raw-drawline-r5.sh"
[ -f "$OUT/freej2me-rg35xx.jar" ] || fail "R5 platform missing"
R5_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"

python3 "$ROOT/scripts/stage-a6-rg35xx-raw-polygon-r5p2.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after R5P2 staging"

rm -rf "$BUILD/classes"; mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" -d "$BUILD/classes" @"$BUILD/sources.list"
rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
R5P2_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
[ "$R5P2_SHA" != "$R5_SHA" ] || fail "R5P2 jar unexpectedly identical to R5"

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]; bad=[]; majors=set()
with zipfile.ZipFile(jar) as z:
  names=set(z.namelist())
  if 'org/recompile/rg35xx/RG35XXAdam7.class' in names:
    raise SystemExit('A6_R5P2_CLASS_GATE_FAIL separate Adam7 class present')
  for n in names:
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
if bad: raise SystemExit('A6_R5P2_JAVA6_GATE_FAIL '+repr(bad[:20]))
print('A6_R5P2_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5P2_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5p2-platformgraphics.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5p2-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r5p2-midletloader.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r5p2-core2d.javap"

python3 - "$BUILD/a6-r5p2-platformgraphics.javap" "$BUILD/a6-r5p2-core2d.javap" <<'PY'
import sys
pg=open(sys.argv[1],encoding='utf-8').read(); core=open(sys.argv[2],encoding='utf-8').read()
sa=pg.find('public void setAlphaRGB(int);'); fp=pg.find('public void fillPolygon(int[], int, int[], int, int, int);')
if sa<0 or fp<0: raise SystemExit('A6_R5P2_BYTECODE_GATE_FAIL methods missing')
sa_end=pg.find('public int getNativePixelFormat',sa); fp_end=pg.find('public void fillTriangle',fp)
sm=pg[sa:sa_end]; fm=pg[fp:fp_end]
if sm.find('isRG35XXRaw')<0 or sm.find('java/awt/Graphics2D.setColor')<0:
  raise SystemExit('A6_R5P2_BYTECODE_GATE_FAIL setAlphaRGB raw/fallback missing')
if 'RG35XXCore2D.fillPolygon' not in fm or 'java/awt/Graphics2D.fillPolygon' not in fm:
  raise SystemExit('A6_R5P2_BYTECODE_GATE_FAIL helper/fallback missing')
if 'public static void fillPolygon' not in core or 'sourceOver' not in core:
  raise SystemExit('A6_R5P2_BYTECODE_GATE_FAIL Core2D polygon helper missing')
if 'rg35xxFillPolygon' in pg or 'rg35xxSourceOver' in pg or 'rg35xxFillSpan' in pg:
  raise SystemExit('A6_R5P2_SCOPE_FAIL heavy raster logic leaked into PlatformGraphics')
print('A6_R5P2_PLATFORMGRAPHICS_MINIMAL_GATE=PASS')
PY

grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5p2-mobileplatform.javap" || fail "R5 keypress trace lost"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r5p2-midletloader.javap" || fail "R1 synchronized loadClass lost"
grep -q 'findLoadedClass' "$BUILD/a6-r5p2-midletloader.javap" || fail "R1 findLoadedClass lost"
grep -q 'decodeAdam7' "$BUILD/a6-r5p2-core2d.javap" || fail "R4 inline Adam7 lost"

rm -rf "$BUILD/a6-r5p2-polygon-host" "$BUILD/a6-r5p2-drawline-host" "$BUILD/a6-r5p2-adam7-host"
mkdir -p "$BUILD/a6-r5p2-polygon-host" "$BUILD/a6-r5p2-drawline-host" "$BUILD/a6-r5p2-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5p2-polygon-host" "$ROOT/tests/a6/RG35XXRawPolygonHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p2-polygon-host" org.recompile.rg35xx.a6.RG35XXRawPolygonHostGate \
  | tee "$BUILD/a6-r5p2-polygon-host-gate.txt"
grep -q '^A6_R5P_RAW_POLYGON_HOST_GATE=PASS$' "$BUILD/a6-r5p2-polygon-host-gate.txt" || fail "polygon host gate missing"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5p2-drawline-host" "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p2-drawline-host" org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  | tee "$BUILD/a6-r5p2-drawline-host-gate.txt"
grep -q '^A6_R5_RAW_DRAWLINE_HOST_GATE=PASS$' "$BUILD/a6-r5p2-drawline-host-gate.txt" || fail "drawLine regression"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5p2-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p2-adam7-host" org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  | tee "$BUILD/a6-r5p2-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r5p2-adam7-host-gate.txt" || fail "Adam7 regression"

R="$ROOT/out/a6-realgame-r5p2"; rm -rf "$R"; mkdir -p "$R"
cp "$OUT/freej2me-rg35xx.jar" "$R/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$R/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$R/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$R/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_R5P_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P2_OWNER=RAW2D_DIRECTGRAPHICS_FILLPOLYGON_AWT_NULL
A6_R5P2_IMPLEMENTATION=PLATFORMGRAPHICS_MINIMAL_CALL_CORE2D_HELPER
A6_R5P2_NEW_CLASS=NO
A6_R5P2_GAME_SPECIFIC_NAMES=NO
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5p2-platformgraphics.javap" "$R/A6-R5P2-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r5p2-mobileplatform.javap" "$R/A6-R5P2-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5p2-midletloader.javap" "$R/A6-R5P2-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r5p2-core2d.javap" "$R/A6-R5P2-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r5p2-polygon-host-gate.txt" "$R/A6-R5P2-POLYGON-HOST-GATE.txt"
cp "$BUILD/a6-r5p2-drawline-host-gate.txt" "$R/A6-R5P2-DRAWLINE-REGRESSION-GATE.txt"
cp "$BUILD/a6-r5p2-adam7-host-gate.txt" "$R/A6-R5P2-ADAM7-REGRESSION-GATE.txt"
cat > "$R/A6-REALGAME-R5P2-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5P2-RAW-POLYGON-CORE2D
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R5_PARENT_PLATFORM_JAR_SHA256=$R5_SHA
A6_R5P2_PLATFORM_JAR_SHA256=$R5P2_SHA
A6_R5P_DEVICE_RESULT=FAIL_HARD_RESET_STARTUP_REGRESSION
A6_R5P2_OWNER=RAW2D_DIRECTGRAPHICS_FILLPOLYGON_AWT_NULL
A6_R5P2_PLATFORMGRAPHICS_MINIMAL=YES
A6_R5P2_CORE2D_POLYGON=YES
A6_R5P2_NEW_CLASS=NO
A6_R5P2_RAW_POLYGON_HOST_GATE=PASS
A6_R5_DRAWLINE_REGRESSION_GATE=PASS
A6_R4_ADAM7_REGRESSION_GATE=PASS
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
(cd "$R" && sha256sum * > SHA256SUMS.txt)
echo A6_R5P2_BUILD=PASS
