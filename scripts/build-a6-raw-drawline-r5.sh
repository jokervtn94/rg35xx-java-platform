#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Materialize and gate the exact R4T parent first.
bash "$ROOT/scripts/build-a6-parent-trace-r4t.sh"
[ -f "$OUT/freej2me-rg35xx.jar" ] || fail "R4T platform missing"
[ -f "$ROOT/out/a6-parent-trace-r4t/A6-PARENT-TRACE-R4T-IDENTITY.txt" ] || fail "R4T identity missing"
R4T_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"

python3 "$ROOT/scripts/stage-a6-rg35xx-raw-drawline-r5.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after R5 staging"

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
R5_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
[ "$R5_SHA" != "$R4T_SHA" ] || fail "R5 jar unexpectedly identical to R4T"

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]
bad=[]; majors=set(); required={
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
    raise SystemExit('A6_R5_CLASS_GATE_FAIL separate Adam7 class present')
  for n in names:
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A6_R5_JAVA6_GATE_FAIL '+repr(bad[:20]))
if required-seen: raise SystemExit('A6_R5_CLASS_GATE_FAIL missing='+repr(sorted(required-seen)))
print('A6_R5_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5-platformgraphics.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r5-midletloader.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r5-core2d.javap"

python3 - "$BUILD/a6-r5-platformgraphics.javap" <<'PY'
import sys
text=open(sys.argv[1],encoding='utf-8').read()
start=text.find('public void drawLine(int, int, int, int);')
end=text.find('public void drawRect', start)
if start < 0 or end < 0: raise SystemExit('A6_R5_DRAWLINE_BYTECODE_GATE_FAIL method missing')
m=text[start:end]
raw=m.find('isRG35XXRaw')
pix=m.find('getRG35XXPixels')
awt=m.find('java/awt/Graphics2D.drawLine')
if raw < 0 or pix < 0 or awt < 0 or raw > pix or pix > awt:
    raise SystemExit('A6_R5_DRAWLINE_BYTECODE_GATE_FAIL raw path/order missing')
print('A6_R5_RAW_DRAWLINE_BYTECODE_GATE=PASS')
PY

grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5-mobileplatform.javap" || fail "keypress enter trace missing"
grep -q 'RG35XX_A6_TRACE_KEYPRESS_STATE_DONE' "$BUILD/a6-r5-mobileplatform.javap" || fail "keypress state trace missing"
grep -q 'RG35XX_A6_TRACE_KEYPRESS_DISPLAY_BEGIN' "$BUILD/a6-r5-mobileplatform.javap" || fail "keypress display begin trace missing"
grep -q 'RG35XX_A6_TRACE_KEYPRESS_DISPLAY_RETURN' "$BUILD/a6-r5-mobileplatform.javap" || fail "keypress display return trace missing"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r5-midletloader.javap" || fail "R1 synchronized loadClass missing"
grep -q 'findLoadedClass' "$BUILD/a6-r5-midletloader.javap" || fail "R1 findLoadedClass missing"
grep -q 'decodeAdam7' "$BUILD/a6-r5-core2d.javap" || fail "R4 inline Adam7 missing"
grep -q 'RG35XX_A6_TRACE_ADAM7_BEGIN' "$BUILD/a6-r5-core2d.javap" || fail "R4T Adam7 trace missing"

echo A6_R5_KEYPRESS_TRACE_BYTECODE_GATE=PASS

rm -rf "$BUILD/a6-r5-drawline-host"
mkdir -p "$BUILD/a6-r5-drawline-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5-drawline-host" "$ROOT/tests/a6/RG35XXRawDrawLineHostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5-drawline-host" \
  org.recompile.rg35xx.a6.RG35XXRawDrawLineHostGate | tee "$BUILD/a6-r5-drawline-host-gate.txt"
grep -q '^A6_R5_RAW_DRAWLINE_HOST_GATE=PASS$' "$BUILD/a6-r5-drawline-host-gate.txt" || fail "raw drawLine host gate missing"

# R4 Adam7 functional gate must remain exact after the R5 primitive addition.
rm -rf "$BUILD/a6-r5-adam7-host"
mkdir -p "$BUILD/a6-r5-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r5-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r5-adam7-host" \
  org.recompile.rg35xx.a6.RG35XXAdam7HostGate | tee "$BUILD/a6-r5-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r5-adam7-host-gate.txt" || fail "Adam7 host regression"

R5OUT="$ROOT/out/a6-realgame-r5"
rm -rf "$R5OUT"
mkdir -p "$R5OUT"
cp "$OUT/freej2me-rg35xx.jar" "$R5OUT/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$R5OUT/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$R5OUT/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$R5OUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_R4T_DEVICE_RESULT=FAIL_HARD_RESET_TEXT_MISSING
A6_R4T_ADAM7_RUNTIME=PASS_5_BEGIN_5_RETURN
A6_R4T_WATCHDOG_LAST=40
A6_R4T_FRAME_LAST=1140
A6_R4T_INPUT_POLL_LAST=7000
A6_R4T_LAST_RUNTIME_BOUNDARY=INPUT_PRESS_KEY53_BEFORE_PLATFORM_KEYPRESSED_RETURN
A6_R5_RAW_DRAWLINE=YES
A6_R5_RAW_DRAWLINE_OWNER=RG35XX_A5_RAW2D_MISSING_PRIMITIVE
A6_R5_RAW_DRAWLINE_TRIGGER=REAL_GAME_FONT_BIN_GLYPHS_USE_GRAPHICS_DRAWLINE
A6_R5_RAW_DRAWLINE_SCOPE=RAW_FRAMEBUFFER_BRESENHAM_CLIP_TRANSLATE_COLOR_STROKE
A6_R5_GAME_SPECIFIC_NAMES=NO
A6_R5_KEYPRESS_TRACE=YES
A6_R5_KEYPRESS_TRACE_SCOPE=ENTER+STATE_DONE+DISPLAY_BEGIN+DISPLAY_RETURN
A6_R5_KEYPRESS_TRACE_SEMANTIC_CHANGE=NO
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5-platformgraphics.javap" "$R5OUT/A6-R5-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r5-mobileplatform.javap" "$R5OUT/A6-R5-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5-midletloader.javap" "$R5OUT/A6-R5-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r5-core2d.javap" "$R5OUT/A6-R5-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r5-drawline-host-gate.txt" "$R5OUT/A6-R5-DRAWLINE-HOST-GATE.txt"
cp "$BUILD/a6-r5-adam7-host-gate.txt" "$R5OUT/A6-R5-ADAM7-HOST-GATE.txt"

cat > "$R5OUT/A6-REALGAME-R5-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5-RAW-DRAWLINE
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R4T_BASE_PLATFORM_JAR_SHA256=$R4T_SHA
A6_R5_PLATFORM_JAR_SHA256=$R5_SHA
A6_R4T_DEVICE_RESULT=FAIL_HARD_RESET_TEXT_MISSING
A6_R4T_ADAM7_RUNTIME=PASS_5_BEGIN_5_RETURN
A6_R5_RAW_DRAWLINE=YES
A6_R5_RAW_DRAWLINE_OWNER=RG35XX_A5_RAW2D_MISSING_PRIMITIVE
A6_R5_RAW_DRAWLINE_HOST_GATE=PASS
A6_R5_KEYPRESS_TRACE=YES
A6_R5_KEYPRESS_TRACE_SEMANTIC_CHANGE=NO
A6_R1_CLASSLOADER_FIX=YES
A6_R2_DRAWREGION_NULL_GUARD=YES
A6_R4_ADAM7_INLINE=YES
A6_R4T_PARENT_TRACE=YES
A6_GAME_SPECIFIC_NAMES=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$R5OUT" && sha256sum * > SHA256SUMS.txt)
echo A6_R5_BUILD=PASS
cat "$R5OUT/A6-REALGAME-R5-IDENTITY.txt"
