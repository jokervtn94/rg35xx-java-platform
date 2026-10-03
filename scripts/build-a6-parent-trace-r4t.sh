#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_PARENT_TRACE_R4T_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"

# Materialize the exact R4 candidate first. This applies R1/R2/R4 overlays and
# runs the existing R4 gates before any trace-only instrumentation is staged.
bash "$ROOT/scripts/build-a6-classloader-fix.sh"
[ -f "$OUT/freej2me-rg35xx.jar" ] || fail "R4 platform missing"
[ -f "$ROOT/out/a6-realgame-r4/A6-REALGAME-FIX-R4-IDENTITY.txt" ] || fail "R4 identity missing"
R4_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"

python3 "$ROOT/scripts/stage-a6-rg35xx-parent-trace-r4t.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after trace staging"

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
TRACE_SHA="$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
[ "$TRACE_SHA" != "$R4_SHA" ] || fail "trace jar unexpectedly identical to R4"

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]
bad=[]; majors=set(); required={
 'org/recompile/mobile/MIDletLoader.class',
 'org/recompile/mobile/PlatformGraphics.class',
 'org/recompile/rg35xx/RG35XXCore2D.class',
 'org/recompile/rg35xx/RG35XXLauncher.class'
}
seen=set()
with zipfile.ZipFile(jar) as z:
  names=set(z.namelist())
  if 'org/recompile/rg35xx/RG35XXAdam7.class' in names:
    raise SystemExit('A6_PARENT_TRACE_R4T_CLASS_GATE_FAIL separate Adam7 class present')
  for n in names:
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A6_PARENT_TRACE_R4T_JAVA6_GATE_FAIL '+repr(bad[:20]))
if required-seen: raise SystemExit('A6_PARENT_TRACE_R4T_CLASS_GATE_FAIL missing='+repr(sorted(required-seen)))
print('A6_PARENT_TRACE_R4T_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_PARENT_TRACE_R4T_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-r4t-core2d.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXLauncher > "$BUILD/a6-r4t-launcher.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-r4t-midletloader.javap"
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r4t-platformgraphics.javap"

grep -q 'decodeAdam7' "$BUILD/a6-r4t-core2d.javap" || fail "inline Adam7 missing"
grep -q 'RG35XX_A6_TRACE_ADAM7_BEGIN' "$BUILD/a6-r4t-core2d.javap" || fail "Adam7 begin trace marker missing"
grep -q 'RG35XX_A6_TRACE_ADAM7_RETURN' "$BUILD/a6-r4t-core2d.javap" || fail "Adam7 return trace marker missing"
if grep -q 'RG35XXAdam7' "$BUILD/a6-r4t-core2d.javap"; then fail "separate Adam7 reference remains"; fi
grep -q 'RG35XX_A6_PARENT_TRACE=ENABLED' "$BUILD/a6-r4t-launcher.javap" || fail "watchdog trace marker missing"
grep -q 'RG35XX_A6_TRACE_WATCHDOG' "$BUILD/a6-r4t-launcher.javap" || fail "watchdog heartbeat marker missing"
grep -q 'RG35XX_A6_TRACE_FRAME' "$BUILD/a6-r4t-launcher.javap" || fail "frame heartbeat marker missing"
grep -q 'RG35XX_A6_TRACE_INPUT_POLL' "$BUILD/a6-r4t-launcher.javap" || fail "input heartbeat marker missing"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-r4t-midletloader.javap" || fail "R1 synchronized loadClass missing"
grep -q 'findLoadedClass' "$BUILD/a6-r4t-midletloader.javap" || fail "R1 findLoadedClass missing"
grep -q 'platformImage' "$BUILD/a6-r4t-platformgraphics.javap" || fail "R2 PlatformGraphics gate unavailable"

echo A6_PARENT_TRACE_R4T_BYTECODE_GATE=PASS

# Trace property is false on host, so R4 functional Adam7 output must remain exact.
rm -rf "$BUILD/a6-r4t-adam7-host"
mkdir -p "$BUILD/a6-r4t-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-r4t-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-r4t-adam7-host" \
  org.recompile.rg35xx.a6.RG35XXAdam7HostGate | tee "$BUILD/a6-r4t-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-r4t-adam7-host-gate.txt" || fail "Adam7 host regression"

TRACEOUT="$ROOT/out/a6-parent-trace-r4t"
rm -rf "$TRACEOUT"
mkdir -p "$TRACEOUT"
cp "$OUT/freej2me-rg35xx.jar" "$TRACEOUT/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$TRACEOUT/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$TRACEOUT/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$TRACEOUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_R4_DEVICE_RESULT=FAIL_HARD_RESET_AFTER_VISIBLE_GAME_SCREEN
A6_R4_PARENT_LOG_LIMIT=HARD_RESET_CUT_LOG_AFTER_CHANNEL_FLAG
A6_R4_HOST_ANIMATION_PNG_COUNT=107
A6_R4_HOST_ANIMATION_PNG_REFERENCE_MATCH=107_OF_107
A6_PARENT_TRACE_R4T=YES
A6_PARENT_TRACE_R4T_OWNER=RG35XX_ADAPTER_TELEMETRY_ONLY
A6_PARENT_TRACE_R4T_SCOPE=ADAM7_BEGIN_RETURN+WATCHDOG+FRAME_HEARTBEAT+INPUT_HEARTBEAT
A6_PARENT_TRACE_R4T_PROPERTY=rg35xx.a6.parenttrace
A6_PARENT_TRACE_R4T_SEMANTIC_CHANGE=NO
EOF
cp "$BUILD/a6-r4t-core2d.javap" "$TRACEOUT/A6-R4T-CORE2D-JAVAP.txt"
cp "$BUILD/a6-r4t-launcher.javap" "$TRACEOUT/A6-R4T-LAUNCHER-JAVAP.txt"
cp "$BUILD/a6-r4t-midletloader.javap" "$TRACEOUT/A6-R4T-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-r4t-platformgraphics.javap" "$TRACEOUT/A6-R4T-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-r4t-adam7-host-gate.txt" "$TRACEOUT/A6-R4T-ADAM7-HOST-GATE.txt"

cat > "$TRACEOUT/A6-PARENT-TRACE-R4T-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PARENT-TRACE-R4T
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R4_BASE_PLATFORM_JAR_SHA256=$R4_SHA
A6_R4_TRACE_PLATFORM_JAR_SHA256=$TRACE_SHA
A6_R4_DEVICE_RESULT=FAIL_HARD_RESET_AFTER_VISIBLE_GAME_SCREEN
A6_PARENT_TRACE_R4T=YES
A6_PARENT_TRACE_R4T_PROPERTY=rg35xx.a6.parenttrace
A6_PARENT_TRACE_R4T_SEMANTIC_CHANGE=NO
A6_TRACE_ADAM7_BEGIN_RETURN=YES
A6_TRACE_WATCHDOG_2S=YES
A6_TRACE_FRAME_HEARTBEAT=YES
A6_TRACE_INPUT_HEARTBEAT=YES
A6_ADAM7_IMPLEMENTATION=INLINE_EXISTING_RG35XXCORE2D_NO_NEW_CLASS
A6_ADAM7_HOST_GATE=PASS
A6_GAME_SPECIFIC_NAMES=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$TRACEOUT" && sha256sum * > SHA256SUMS.txt)
echo A6_PARENT_TRACE_R4T_BUILD=PASS
cat "$TRACEOUT/A6-PARENT-TRACE-R4T-IDENTITY.txt"
