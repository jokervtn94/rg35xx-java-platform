#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_REALGAME_R4_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/java" ] || fail "java missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -x "$JAVA8/bin/javap" ] || fail "javap missing"
[ -d "$BUILD/stage-src" ] || fail "A5 staged source missing"
[ -f "$BUILD/JAVA6-COMPAT-AUDIT.tsv" ] || fail "A5 audit missing"
grep -q 'A5_CORE2D' "$BUILD/JAVA6-COMPAT-AUDIT.tsv" || fail "A5 core2D stage not present"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty before A6"

python3 "$ROOT/scripts/stage-a6-rg35xx-classloader-race.py" \
  "$BUILD/stage-src" "$BUILD/JAVA6-COMPAT-AUDIT.tsv"
python3 "$ROOT/scripts/stage-a6-rg35xx-drawregion-null-guard.py" \
  "$BUILD/stage-src" "$BUILD/JAVA6-COMPAT-AUDIT.tsv"
python3 "$ROOT/scripts/stage-a6-rg35xx-adam7.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty after A6 staging"

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

python3 - "$OUT/freej2me-rg35xx.jar" <<'PY'
import sys, zipfile
jar=sys.argv[1]
bad=[]; majors=set(); required={
 'org/recompile/mobile/MIDletLoader.class',
 'org/recompile/mobile/PlatformGraphics.class',
 'org/recompile/rg35xx/RG35XXCore2D.class'
}
seen=set()
with zipfile.ZipFile(jar) as z:
  names=set(z.namelist())
  if 'org/recompile/rg35xx/RG35XXAdam7.class' in names:
    raise SystemExit('A6_REALGAME_R4_CLASS_GATE_FAIL separate Adam7 class present')
  for n in names:
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A6_REALGAME_R4_JAVA6_GATE_FAIL '+repr(bad[:20]))
if required-seen: raise SystemExit('A6_REALGAME_R4_CLASS_GATE_FAIL missing='+repr(sorted(required-seen)))
print('A6_REALGAME_R4_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_REALGAME_R4_JAVA6_GATE=PASS')
print('A6_ADAM7_SEPARATE_CLASS_GATE=PASS')
PY

# R1 class-loader gate remains mandatory.
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-midletloader.javap"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-midletloader.javap" || fail "loadClass not synchronized"
grep -q 'findLoadedClass' "$BUILD/a6-midletloader.javap" || fail "findLoadedClass bytecode missing"
grep -q 'defineClass' "$BUILD/a6-midletloader.javap" || fail "game defineClass path missing"
echo A6_CLASSLOADER_BYTECODE_GATE=PASS

# R2 drawRegion gate remains mandatory.
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c -l org.recompile.mobile.PlatformGraphics > "$BUILD/a6-platformgraphics.javap"
python3 - "$BUILD/a6-platformgraphics.javap" <<'PY'
import sys
text=open(sys.argv[1],encoding='utf-8').read()
start=text.find('public void drawRegion(javax.microedition.lcdui.Image')
if start < 0: raise SystemExit('A6_DRAWREGION_BYTECODE_GATE_FAIL method missing')
end=text.find('private void rg35xxBlit', start)
if end < 0: raise SystemExit('A6_DRAWREGION_BYTECODE_GATE_FAIL method end missing')
method=text[start:end]
getw=method.find('javax/microedition/lcdui/Image.getWidth')
nullop=min([p for p in (method.find('ifnull'), method.find('ifnonnull')) if p >= 0] or [-1])
platform=method.find('javax/microedition/lcdui/Image.platformImage')
if getw < 0 or nullop < 0 or nullop > getw or platform < 0 or platform > getw:
    raise SystemExit('A6_DRAWREGION_BYTECODE_GATE_FAIL null/platform guard not before getWidth')
print('A6_DRAWREGION_NULL_GUARD_BYTECODE_GATE=PASS')
PY

# R4 gate: Adam7 is implemented inside the already-existing Core2D class.
# No separate adapter class or new static initializer may be introduced.
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.rg35xx.RG35XXCore2D > "$BUILD/a6-core2d.javap"
grep -q 'decodeAdam7' "$BUILD/a6-core2d.javap" || fail "inline Adam7 method missing"
if grep -q 'RG35XXAdam7' "$BUILD/a6-core2d.javap"; then fail "separate Adam7 class reference remains"; fi
if grep -q 'static {};' "$BUILD/a6-core2d.javap"; then fail "unexpected Core2D static initializer"; fi
rm -rf "$BUILD/a6-adam7-host"
mkdir -p "$BUILD/a6-adam7-host"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$OUT/freej2me-rg35xx.jar" \
  -d "$BUILD/a6-adam7-host" "$ROOT/tests/a6/RG35XXAdam7HostGate.java"
"$JAVA8/bin/java" -cp "$OUT/freej2me-rg35xx.jar:$BUILD/a6-adam7-host" \
  org.recompile.rg35xx.a6.RG35XXAdam7HostGate | tee "$BUILD/a6-adam7-host-gate.txt"
grep -q '^A6_ADAM7_HOST_GATE=PASS$' "$BUILD/a6-adam7-host-gate.txt" || fail "Adam7 host gate missing"
echo A6_ADAM7_INLINE_CLASS_GATE=PASS

cp "$BUILD/JAVA6-COMPAT-AUDIT.tsv" "$OUT/JAVA6-COMPAT-AUDIT.tsv"
cat >> "$OUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_CLASSLOADER_OVERLAY=YES
A6_CLASSLOADER_OWNER=RG35XX_ADAPTER_DISPOSABLE_SOURCE_EXCEPTION
A6_CLASSLOADER_SCOPE=MIDLET_GAME_CLASS_LOAD_SERIALIZATION+FINDLOADEDCLASS_GUARD
A6_CLASSLOADER_TRIGGER=REAL_GAME_DUPLICATE_CLASS_DEFINITION
A6_CLASSLOADER_GAME_SPECIFIC_NAMES=NO
A6_CLASSLOADER_SEMANTIC_INTENT=PRESERVE_AWEIGIT_DELEGATION_AND_INSTRUMENTATION
A6_DRAWREGION_NULL_GUARD=YES
A6_DRAWREGION_OWNER=RG35XX_A5_RAW2D_OVERLAY_REGRESSION
A6_DRAWREGION_TRIGGER=REAL_GAME_FIRST_REPAINT_NULL_IMAGE
A6_DRAWREGION_SCOPE=EARLY_RETURN_NULL_IMAGE_OR_PLATFORMIMAGE
A6_DRAWREGION_GAME_SPECIFIC_NAMES=NO
A6_DRAWREGION_SEMANTIC_INTENT=RESTORE_PINNED_AWEIGIT_NO_THROW_INVALID_DRAW_BEHAVIOR
A6_ADAM7_BACKING=YES
A6_ADAM7_OWNER=RG35XX_ADAPTER_PNG_BACKING
A6_ADAM7_TRIGGER=REAL_GAME_IMAGE_CREATEIMAGE_BYTES_INTERLACE_1
A6_ADAM7_SCOPE=PNG_INTERLACE_METHOD_1_7_PASS_DECODE
A6_ADAM7_IMPLEMENTATION=INLINE_EXISTING_RG35XXCORE2D_NO_NEW_CLASS
A6_ADAM7_SEPARATE_CLASS=NO
A6_ADAM7_STATIC_INITIALIZER=NO
A6_ADAM7_GAME_SPECIFIC_NAMES=NO
A6_ADAM7_HOST_GATE=PASS
A6_R3_DEVICE_RESULT=FAIL_SIGSEGV_139_BEFORE_ADAM7_BOUNDARY
CANONICAL_GITLINK_MUTATED=NO
EOF

R4OUT="$ROOT/out/a6-realgame-r4"
rm -rf "$R4OUT"
mkdir -p "$R4OUT"
cp "$OUT/freej2me-rg35xx.jar" "$R4OUT/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$R4OUT/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$R4OUT/CANONICAL-DIFF-MANIFEST.txt"
cp "$BUILD/a6-midletloader.javap" "$R4OUT/A6-MIDLETLOADER-JAVAP.txt"
cp "$BUILD/a6-platformgraphics.javap" "$R4OUT/A6-PLATFORMGRAPHICS-JAVAP.txt"
cp "$BUILD/a6-core2d.javap" "$R4OUT/A6-CORE2D-JAVAP.txt"
cp "$BUILD/a6-adam7-host-gate.txt" "$R4OUT/A6-ADAM7-HOST-GATE.txt"

cat > "$R4OUT/A6-REALGAME-FIX-R4-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-FIX-R4
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A5_PLATFORM_JAR_SHA256=3cc31a9f1b00e6756fb5a314fe7af64e8c9b28cb03dedea4b0a58c7327169db4
A6_PLATFORM_JAR_SHA256=$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')
A6_CLASSLOADER_OVERLAY=YES
A6_DRAWREGION_NULL_GUARD=YES
A6_ADAM7_BACKING=YES
A6_ADAM7_IMPLEMENTATION=INLINE_EXISTING_RG35XXCORE2D_NO_NEW_CLASS
A6_ADAM7_SEPARATE_CLASS=NO
A6_ADAM7_HOST_GATE=PASS
A6_R3_DEVICE_RESULT=FAIL_SIGSEGV_139_BEFORE_ADAM7_BOUNDARY
A6_GAME_SPECIFIC_NAMES=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$R4OUT" && sha256sum * > SHA256SUMS.txt)

echo A6_REALGAME_R4_BUILD=PASS
cat "$R4OUT/A6-REALGAME-FIX-R4-IDENTITY.txt"
