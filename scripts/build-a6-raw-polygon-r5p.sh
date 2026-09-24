#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5P_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Materialize exact R5 FastPath parent first.
bash "$ROOT/scripts/build-a6-raw-drawline-r5.sh"
[ -f "$OUT/freej2me-rg35xx.jar" ] || fail "R5 platform missing"
R5_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"

python3 "$ROOT/scripts/stage-a6-rg35xx-raw-polygon-r5p.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after R5P staging"

rm -rf "$BUILD/classes"
mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$BUILD/classes" @"$BUILD/sources.list"

rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
R5P_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
[ "$R5P_SHA" != "$R5_SHA" ] || fail "R5P jar unexpectedly identical to R5"

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]; bad=[]; majors=set()
required={
 'org/recompile/mobile/MIDletLoader.class',
 'org/recompile/mobile/PlatformGraphics.class',
 'org/recompile/mobile/MobilePlatform.class',
 'org/recompile/rg35xx/RG35XXCore2D.class',
 'org/recompile/rg35xx/RG35XXLauncher.class'
}
seen=set()
with zipfile.ZipFile(jar) as z:
  names=set(z.namelist())
  if 'org/recompile/rg35xx/RG35XXAdam7.class' in names:
    raise SystemExit('A6_R5P_CLASS_GATE_FAIL separate Adam7 class present')
  for n in names:
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A6_R5P_JAVA6_GATE_FAIL '+repr(bad[:20]))
if required-seen: raise SystemExit('A6_R5P_CLASS_GATE_FAIL missing='+repr(sorted(required-seen)))
print('A6_R5P_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5P_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5p-platformgraphics.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5p-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r5p-midletloader.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r5p-core2d.javap"

python3 - "$BUILD/a6-r5p-platformgraphics.javap" <<'PY'
import sys
text=open(sys.argv[1],encoding='utf-8').read()
sa=text.find('public void setAlphaRGB(int);')
fp=text.find('public void fillPolygon(int[], int, int[], int, int, int);')
if sa<0 or fp<0: raise SystemExit('A6_R5P_BYTECODE_GATE_FAIL methods missing')
sa_end=text.find('public int getNativePixelFormat', sa)
fp_end=text.find('public void fillTriangle', fp)
sm=text[sa:sa_end]; fm=text[fp:fp_end]
raw=sm.find('isRG35XXRaw'); awt=sm.find('java/awt/Graphics2D.setColor')
if raw<0 or awt<0 or raw>awt: raise SystemExit('A6_R5P_BYTECODE_GATE_FAIL setAlphaRGB raw-first missing')
if 'rg35xxFillPolygon' not in fm or 'java/awt/Graphics2D.fillPolygon' not in fm:
    raise SystemExit('A6_R5P_BYTECODE_GATE_FAIL fillPolygon raw/fallback missing')
print('A6_R5P_RAW_POLYGON_BYTECODE_GATE=PASS')
PY

grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5p-mobileplatform.javap" || fail "R5 keypress trace lost"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r5p-midletloader.javap" || fail "R1 synchronized loadClass lost"
grep -q 'findLoadedClass' "$BUILD/a6-r5p-midletloader.javap" || fail "R1 findLoadedClass lost"
grep -q 'decodeAdam7' "$BUILD/a6-r5p-core2d.javap" || fail "R4 inline Adam7 lost"
grep -q 'RG35XX_A6_TRACE_ADAM7_BEGIN' "$BUILD/a6-r5p-core2d.javap" || fail "R4T Adam7 trace lost"

echo A6_R5P_PARENT_REGRESSION_BYTECODE_GATE=PASS

# New polygon functional gate.
rm -rf "$BUILD/a6-r5p-polygon-host"
mkdir -p "$BUILD/a6-r5p-polygon-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5p-polygon-host" "$ROOT/tests/a6/RG35XXRawPolygonHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p-polygon-host" \
  org.recompile.rg35xx.a6.RG35XXRawPolygonHostGate | tee "$BUILD/a6-r5p-polygon-host-gate.txt"
grep -q '^A6_R5P_RAW_POLYGON_HOST_GATE=PASS$' "$BUILD/a6-r5p-polygon-host-gate.txt" || fail "polygon host gate missing"

# Re-run R5 drawLine and R4 Adam7 functional gates unchanged.
rm -rf "$BUILD/a6-r5p-drawline-host" "$BUILD/a6-r5p-adam7-host"
mkdir -p "$BUILD/a6-r5p-drawline-host" "$BUILD/a6-r5p-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" -d "$BUILD/a6-r5p-drawline-host" "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p-drawline-host" org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate \
  | tee "$BUILD/a6-r5p-drawline-host-gate.txt"
grep -q '^A6_R5_RAW_DRAWLINE_HOST_GATE=PASS$' "$BUILD/a6-r5p-drawline-host-gate.txt" || fail "drawLine regression"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" -d "$BUILD/a6-r5p-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5p-adam7-host" org.recompile.rg35xx.a6.RG35XXAdam7HostGate \
  | tee "$BUILD/a6-r5p-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r5p-adam7-host-gate.txt" || fail "Adam7 regression"

R5POUT="$ROOT/out/a6-realgame-r5p"
rm -rf "$R5POUT"; mkdir -p "$R5POUT"
cp "$OUT/freej2me-rg35xx.jar" "$R5POUT/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$R5POUT/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$R5POUT/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$R5POUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_R5_FASTPATH_DEVICE_RESULT=FAIL_HARD_RESET_DURING_OPENING_STORY
A6_R5P_FAILURE_OWNER=RAW2D_DIRECTGRAPHICS_FILLPOLYGON_AWT_NULL
A6_R5P_EXCEPTION=NullPointerException_PlatformGraphics.setAlphaRGB_to_fillPolygon
A6_R5P_RAW_SETALPHARGB=YES
A6_R5P_RAW_FILLPOLYGON=YES
A6_R5P_RAW_FILLPOLYGON_SCOPE=RECT_FASTPATH+GENERIC_SCANLINE+SOURCE_OVER+CLIP+TRANSLATE
A6_R5P_GAME_SPECIFIC_NAMES=NO
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5p-platformgraphics.javap" "$R5POUT/A6-R5P-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r5p-mobileplatform.javap" "$R5POUT/A6-R5P-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5p-midletloader.javap" "$R5POUT/A6-R5P-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r5p-core2d.javap" "$R5POUT/A6-R5P-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r5p-polygon-host-gate.txt" "$R5POUT/A6-R5P-POLYGON-HOST-GATE.txt"
cp "$BUILD/a6-r5p-drawline-host-gate.txt" "$R5POUT/A6-R5P-DRAWLINE-REGRESSION-GATE.txt"
cp "$BUILD/a6-r5p-adam7-host-gate.txt" "$R5POUT/A6-R5P-ADAM7-REGRESSION-GATE.txt"

cat > "$R5POUT/A6-REALGAME-R5P-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5P-RAW-POLYGON
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R5_PARENT_PLATFORM_JAR_SHA256=$R5_SHA
A6_R5P_PLATFORM_JAR_SHA256=$R5P_SHA
A6_R5_FASTPATH_DEVICE_RESULT=FAIL_HARD_RESET_DURING_OPENING_STORY
A6_R5P_FAILURE_OWNER=RAW2D_DIRECTGRAPHICS_FILLPOLYGON_AWT_NULL
A6_R5P_NPE_COUNT_OBSERVED=307
A6_R5P_RAW_SETALPHARGB=YES
A6_R5P_RAW_FILLPOLYGON=YES
A6_R5P_RAW_POLYGON_HOST_GATE=PASS
A6_R5_DRAWLINE_REGRESSION_GATE=PASS
A6_R4_ADAM7_REGRESSION_GATE=PASS
A6_R1_CLASSLOADER_FIX=YES
A6_R2_DRAWREGION_NULL_GUARD=YES
A6_R4_ADAM7_INLINE=YES
A6_R4T_PARENT_TRACE=YES
A6_R5_RAW_DRAWLINE_FASTPATH=YES
A6_GAME_SPECIFIC_NAMES=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF
(cd "$R5POUT" && sha256sum * > SHA256SUMS.txt)
echo A6_R5P_BUILD=PASS
cat "$R5POUT/A6-REALGAME-R5P-IDENTITY.txt"
