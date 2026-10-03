#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_R5P3I1_BUILD_FAIL=$*" >&2; exit 1; }

bash "$ROOT/scripts/build-a6-raw-rect-polygon-r5p3.sh"
PARENT_JAR="$ROOT/out/a6-realgame-r5p3/freej2me-rg35xx.jar"
PARENT_SHA="$(sha256sum "$PARENT_JAR" | awk '{print $1}')"
cp "$PARENT_JAR" "$BUILD/r5p3-input-parent.jar"
unzip -Z1 "$PARENT_JAR" | LC_ALL=C sort > "$BUILD/r5p3-input-parent.entries"

python3 "$ROOT/scripts/stage-a6-rg35xx-input-lifecycle-r5p3i1.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty"

rm -rf "$BUILD/classes"; mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" -d "$BUILD/classes" @"$BUILD/sources.list"
rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
FIX_JAR="$OUT/freej2me-rg35xx.jar"
FIX_SHA="$(sha256sum "$FIX_JAR" | awk '{print $1}')"
[ "$FIX_SHA" != "$PARENT_SHA" ] || fail "candidate identical to parent"

unzip -Z1 "$FIX_JAR" | LC_ALL=C sort > "$BUILD/r5p3i1.entries"
cmp -s "$BUILD/r5p3-input-parent.entries" "$BUILD/r5p3i1.entries" || fail "JAR entry set changed"

python3 - "$PARENT_JAR" "$FIX_JAR" <<'PY'
import sys, zipfile, hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
    diff=[]
    for n in sorted(a.namelist()):
        if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest(): diff.append(n)
for n in diff:
    if not n.startswith('org/recompile/rg35xx/RG35XXLauncher') or not n.endswith('.class'):
        raise SystemExit('A6_R5P3I1_SCOPE_FAIL changed='+repr(diff))
if 'org/recompile/rg35xx/RG35XXLauncher.class' not in diff:
    raise SystemExit('A6_R5P3I1_SCOPE_FAIL outer launcher unchanged')
print('A6_R5P3I1_CHANGED_ENTRIES='+','.join(diff))
print('A6_R5P3I1_SCOPE_GATE=PASS')
PY

python3 - "$FIX_JAR" <<'PY'
import sys,zipfile
bad=[]; majors=set()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
if bad: raise SystemExit('A6_R5P3I1_JAVA6_GATE_FAIL '+repr(bad[:20]))
print('A6_R5P3I1_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_R5P3I1_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.rg35xx.RG35XXLauncher > "$BUILD/a6-r5p3i1-launcher.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-r5p3i1-mobileplatform.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.PlatformGraphics > "$BUILD/a6-r5p3i1-platformgraphics.javap"
python3 - "$BUILD/a6-r5p3i1-launcher.javap" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
for x in ['RG35XX_A6_TRACE_INPUT_START_BEFORE_RUNJAR','RG35XX_A6_TRACE_RUNJAR_BEGIN','RG35XX_A6_TRACE_RUNJAR_RETURN']:
    if x not in s: raise SystemExit('A6_R5P3I1_ORDER_GATE_FAIL marker='+x)
a=s.find('RG35XXLauncher$InputPump.start'); b=s.find('MobilePlatform.runJar')
if a<0 or b<0 or a>=b: raise SystemExit('A6_R5P3I1_ORDER_GATE_FAIL start=%d run=%d'%(a,b))
print('A6_R5P3I1_INPUT_BEFORE_RUNJAR_GATE=PASS')
PY

grep -q 'RG35XX_A6_TRACE_KEYPRESS_ENTER' "$BUILD/a6-r5p3i1-mobileplatform.javap" || fail "keypress trace lost"
grep -q 'RG35XXCore2D.sourceOver' "$BUILD/a6-r5p3i1-platformgraphics.javap" || fail "polygon fix lost"

DST="$ROOT/out/a6-realgame-r5p3i1"
rm -rf "$DST"; mkdir -p "$DST"
cp "$FIX_JAR" "$DST/freej2me-rg35xx.jar"
cp "$ROOT/out/a6-realgame-r5p3/JAVA6-COMPAT-AUDIT.tsv" "$DST/JAVA6-COMPAT-AUDIT.tsv"
cp "$ROOT/out/a6-realgame-r5p3/CANONICAL-DIFF-MANIFEST.txt" "$DST/CANONICAL-DIFF-MANIFEST.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_R5P3I1_OWNER=RG35XX_LAUNCHER_INPUT_LIFECYCLE_AFTER_SYNCHRONOUS_RUNJAR
A6_R5P3I1_INPUT_ORDER=INPUT_START_BEFORE_RUNJAR
A6_R5P3I1_DISPLAY_READY_DEFER=UNCHANGED
A6_R5P3I1_KEY_MAPPING=UNCHANGED
A6_R5P3I1_CHANGED_SCOPE=RG35XXLauncher_CLASS_FAMILY_ONLY
CANONICAL_GITLINK_MUTATED=NO
EOF
cp "$BUILD/a6-r5p3i1-launcher.javap" "$DST/A6-R5P3I1-LAUNCHER-JAVAP.txt"
cp "$BUILD/a6-r5p3i1-mobileplatform.javap" "$DST/A6-R5P3I1-MOBILEPLATFORM-JAVAP.txt"
cp "$BUILD/a6-r5p3i1-platformgraphics.javap" "$DST/A6-R5P3I1-PLATFORMGRAPHICS-JAVAP.txt"
cat > "$DST/A6-REALGAME-R5P3I1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-REALGAME-R5P3I1-INPUT-LIFECYCLE
PRODUCTION_BASELINE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A6_R5P3_PARENT_PLATFORM_JAR_SHA256=$PARENT_SHA
A6_R5P3I1_PLATFORM_JAR_SHA256=$FIX_SHA
A6_R5P3_DEVICE_RESULT=FAIL_HARD_RESET_INPUT_POLL_NEVER_STARTED
A6_R5P3_LAST_FRAME=300
A6_R5P3_LAST_WATCHDOG=13
A6_R5P3_INPUT_POLL_COUNT=0
A6_R5P3I1_OWNER=RG35XX_LAUNCHER_INPUT_LIFECYCLE_AFTER_SYNCHRONOUS_RUNJAR
A6_R5P3I1_INPUT_ORDER=INPUT_START_BEFORE_RUNJAR
A6_R5P3I1_DISPLAY_READY_DEFER=UNCHANGED
A6_R5P3I1_KEY_MAPPING=UNCHANGED
A6_R5P3I1_SCOPE_GATE=PASS
A6_R5P3I1_INPUT_BEFORE_RUNJAR_GATE=PASS
A6_R5P3_POLYGON_FIX=PRESERVED
A6_R5_DRAWLINE_FASTPATH=PRESERVED
A6_R4_ADAM7=PRESERVED
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
EOF
(cd "$DST" && sha256sum * > SHA256SUMS.txt)
echo A6_R5P3I1_BUILD=PASS
cat "$DST/A6-REALGAME-R5P3I1-IDENTITY.txt"
