#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_CLASSLOADER_BUILD_FAIL=$*" >&2; exit 1; }

[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
[ -x "$JAVA8/bin/javac" ] || fail "javac missing"
[ -x "$JAVA8/bin/jar" ] || fail "jar missing"
[ -d "$BUILD/stage-src" ] || fail "A5 staged source missing"
[ -f "$BUILD/JAVA6-COMPAT-AUDIT.tsv" ] || fail "A5 audit missing"
grep -q 'A5_CORE2D' "$BUILD/JAVA6-COMPAT-AUDIT.tsv" || fail "A5 core2D stage not present"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty before A6"

python3 "$ROOT/scripts/stage-a6-rg35xx-classloader-race.py" \
  "$BUILD/stage-src" "$BUILD/JAVA6-COMPAT-AUDIT.tsv"
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
bad=[]; majors=set(); required={'org/recompile/mobile/MIDletLoader.class'}
seen=set()
with zipfile.ZipFile(jar) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
      if n in required: seen.add(n)
if bad: raise SystemExit('A6_CLASSLOADER_JAVA6_GATE_FAIL '+repr(bad[:20]))
if required-seen: raise SystemExit('A6_CLASSLOADER_CLASS_GATE_FAIL')
print('A6_CLASSLOADER_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_CLASSLOADER_JAVA6_GATE=PASS')
PY

# Bytecode gate: javap must show synchronized on the one-argument loadClass and
# a call to ClassLoader.findLoadedClass before the game defineClass path.
"$JAVA8/bin/javap" -classpath "$OUT/freej2me-rg35xx.jar" -p -c org.recompile.mobile.MIDletLoader > "$BUILD/a6-midletloader.javap"
grep -q 'public synchronized java.lang.Class loadClass(java.lang.String)' "$BUILD/a6-midletloader.javap" || fail "loadClass not synchronized"
grep -q 'findLoadedClass' "$BUILD/a6-midletloader.javap" || fail "findLoadedClass bytecode missing"
grep -q 'defineClass' "$BUILD/a6-midletloader.javap" || fail "game defineClass path missing"
echo A6_CLASSLOADER_BYTECODE_GATE=PASS

cp "$BUILD/JAVA6-COMPAT-AUDIT.tsv" "$OUT/JAVA6-COMPAT-AUDIT.tsv"
cat >> "$OUT/CANONICAL-DIFF-MANIFEST.txt" <<'EOF'
A6_CLASSLOADER_OVERLAY=YES
A6_CLASSLOADER_OWNER=RG35XX_ADAPTER_DISPOSABLE_SOURCE_EXCEPTION
A6_CLASSLOADER_SCOPE=MIDLET_GAME_CLASS_LOAD_SERIALIZATION+FINDLOADEDCLASS_GUARD
A6_CLASSLOADER_TRIGGER=REAL_GAME_DUPLICATE_CLASS_DEFINITION
A6_CLASSLOADER_GAME_SPECIFIC_NAMES=NO
A6_CLASSLOADER_SEMANTIC_INTENT=PRESERVE_AWEIGIT_DELEGATION_AND_INSTRUMENTATION
CANONICAL_GITLINK_MUTATED=NO
EOF

mkdir -p "$ROOT/out/a6-classloader"
cp "$OUT/freej2me-rg35xx.jar" "$ROOT/out/a6-classloader/freej2me-rg35xx.jar"
cp "$OUT/JAVA6-COMPAT-AUDIT.tsv" "$ROOT/out/a6-classloader/JAVA6-COMPAT-AUDIT.tsv"
cp "$OUT/CANONICAL-DIFF-MANIFEST.txt" "$ROOT/out/a6-classloader/CANONICAL-DIFF-MANIFEST.txt"
cp "$BUILD/a6-midletloader.javap" "$ROOT/out/a6-classloader/A6-MIDLETLOADER-JAVAP.txt"

cat > "$ROOT/out/a6-classloader/A6-CLASSLOADER-FIX-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-CLASSLOADER-RACE-FIX
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A5_PLATFORM_JAR_SHA256=3cc31a9f1b00e6756fb5a314fe7af64e8c9b28cb03dedea4b0a58c7327169db4
A6_PLATFORM_JAR_SHA256=$(sha256sum "$OUT/freej2me-rg35xx.jar" | awk '{print $1}')
A6_CLASSLOADER_OVERLAY=YES
A6_CLASSLOADER_REWRITES=2
A6_CLASSLOADER_GAME_SPECIFIC_NAMES=NO
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF

(cd "$ROOT/out/a6-classloader" && sha256sum freej2me-rg35xx.jar JAVA6-COMPAT-AUDIT.tsv CANONICAL-DIFF-MANIFEST.txt A6-MIDLETLOADER-JAVAP.txt A6-CLASSLOADER-FIX-IDENTITY.txt > SHA256SUMS.txt)

echo A6_CLASSLOADER_BUILD=PASS
cat "$ROOT/out/a6-classloader/A6-CLASSLOADER-FIX-IDENTITY.txt"
