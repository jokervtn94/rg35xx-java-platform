#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build/a3"
OUT="$ROOT/out/a3"
UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
fail(){ echo "A6_PERF_J1_BUILD_FAIL=$*" >&2; exit 1; }

# Build the exact proven Java parent first. The native output is already staged as PERF-P3.
bash "$ROOT/scripts/build-a6-raw-drawrect-r5p3i2.sh"
BASE="$ROOT/out/a6-realgame-r5p3i2"
PARENT_JAR="$BASE/freej2me-rg35xx.jar"
[ -f "$PARENT_JAR" ] || fail "R5P3I2 parent missing"
cp "$PARENT_JAR" "$BUILD/perf-j1-parent.jar"
unzip -Z1 "$PARENT_JAR" | LC_ALL=C sort > "$BUILD/perf-j1-parent.entries"
PARENT_SEM="$(python3 - "$PARENT_JAR" <<'PY'
import sys,zipfile,hashlib,struct
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in sorted(z.namelist()):
    b=z.read(n); nb=n.encode('utf-8')
    h.update(struct.pack('>I',len(nb))); h.update(nb)
    h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
)"
[ "$PARENT_SEM" = 'b79cafa98c467436cf0e782b069839e993a7dc7bdb31b9a423b47c0ff293950e' ] || fail "R5P3I2 semantic parent changed $PARENT_SEM"

python3 "$ROOT/scripts/stage-a6-rg35xx-perf-j1-direct-lcd.py" "$ROOT"
[ -z "$(git -C "$UPSTREAM" status --porcelain --untracked-files=no)" ] || fail "canonical dirty"

rm -rf "$BUILD/classes"; mkdir -p "$BUILD/classes"
find "$BUILD/stage-src" "$ROOT/adapter/java" -type f -name '*.java' -print | LC_ALL=C sort > "$BUILD/sources.list"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$UPSTREAM/lib/jsr305-3.0.2.jar" -d "$BUILD/classes" @"$BUILD/sources.list"
rm -f "$OUT/freej2me-rg35xx.jar"
"$JAVA8/bin/jar" cfm "$OUT/freej2me-rg35xx.jar" "$BUILD/manifests/rg35xx-aweigit-r1.mf" -C "$BUILD/classes" .
if [ -d "$UPSTREAM/META-INF" ]; then "$JAVA8/bin/jar" uf "$OUT/freej2me-rg35xx.jar" -C "$UPSTREAM" META-INF; fi
FIX_JAR="$OUT/freej2me-rg35xx.jar"
unzip -Z1 "$FIX_JAR" | LC_ALL=C sort > "$BUILD/perf-j1.entries"
cmp -s "$BUILD/perf-j1-parent.entries" "$BUILD/perf-j1.entries" || fail "JAR entry set changed"

python3 - "$PARENT_JAR" "$FIX_JAR" <<'PY'
import sys,zipfile,hashlib
base,new=sys.argv[1:3]
with zipfile.ZipFile(base) as a, zipfile.ZipFile(new) as b:
  diff=[n for n in sorted(a.namelist()) if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest()]
expected=['org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class']
if diff != expected:
  raise SystemExit('A6_PERF_J1_SCOPE_FAIL changed='+repr(diff))
print('A6_PERF_J1_CHANGED_ENTRIES='+','.join(diff))
print('A6_PERF_J1_SCOPE_GATE=PASS')
PY

python3 - "$FIX_JAR" <<'PY'
import sys,zipfile
bad=[]; majors=set()
with zipfile.ZipFile(sys.argv[1]) as z:
  for n in z.namelist():
    if n.endswith('.class'):
      b=z.read(n); m=int.from_bytes(b[6:8],'big'); majors.add(m)
      if m>50: bad.append((n,m))
if bad: raise SystemExit('A6_PERF_J1_JAVA6_GATE_FAIL '+repr(bad[:20]))
print('A6_PERF_J1_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('A6_PERF_J1_JAVA6_GATE=PASS')
PY

"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c 'org.recompile.rg35xx.RG35XXLauncher$FramePresenter' > "$BUILD/a6-perf-j1-framepresenter.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.rg35xx.RG35XXLauncher > "$BUILD/a6-perf-j1-launcher.javap"
"$JAVA8/bin/javap" -classpath "$FIX_JAR" -p -c org.recompile.mobile.MobilePlatform > "$BUILD/a6-perf-j1-mobileplatform.javap"

grep -q 'MobilePlatform.getRG35XXLCDPixels:()\[I' "$BUILD/a6-perf-j1-framepresenter.javap" || fail "direct LCD call missing"
if grep -q 'java/lang/reflect/Method.invoke' "$BUILD/a6-perf-j1-framepresenter.javap"; then fail "reflection invoke still present"; fi
grep -q 'RG35XX_A6_TRACE_INPUT_START_BEFORE_RUNJAR' "$BUILD/a6-perf-j1-launcher.javap" || fail "input lifecycle lost"
grep -q 'getRG35XXLCDPixels' "$BUILD/a6-perf-j1-mobileplatform.javap" || fail "raw LCD accessor lost"
echo A6_PERF_J1_DIRECT_ACCESS_BYTECODE_GATE=PASS

INPUT_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$ROOT/out/a3/librg35xx_video.so" | awk '{print $1}')"
[ "$INPUT_SHA" = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d' ] || fail "input changed $INPUT_SHA"
[ "$VIDEO_SHA" = 'c361433a2c853986318938961fa978d01f085640a3a6e839e2b26656f38ff999' ] || fail "PERF-P3 video not exact $VIDEO_SHA"

DST="$ROOT/out/a6-perf-j1"
rm -rf "$DST"; mkdir -p "$DST"
cp -a "$BASE/." "$DST/"
cp "$FIX_JAR" "$DST/freej2me-rg35xx.jar"
cp "$ROOT/out/a3/librg35xx_input.so" "$DST/librg35xx_input.so"
cp "$ROOT/out/a3/librg35xx_video.so" "$DST/librg35xx_video.so"
cp "$BUILD/a6-perf-j1-framepresenter.javap" "$DST/A6-PERF-J1-FRAMEPRESENTER-JAVAP.txt"
cp "$BUILD/a6-perf-j1-launcher.javap" "$DST/A6-PERF-J1-LAUNCHER-JAVAP.txt"
cp "$BUILD/a6-perf-j1-mobileplatform.javap" "$DST/A6-PERF-J1-MOBILEPLATFORM-JAVAP.txt"
cat >> "$DST/CANONICAL-DIFF-MANIFEST.txt" <<EOF
A6_PERF_J1_OWNER=RG35XX_FRAMEPRESENTER_REFLECTION_PER_FRAME
A6_PERF_J1_SCOPE=RG35XXLauncher_FramePresenter_CLASS_ONLY
A6_PERF_J1_ACCESS=DIRECT_MOBILEPLATFORM_GETRG35XXLCDPIXELS
A6_PERF_J1_NATIVE_VIDEO=EXACT_PERF_P3_DEVICE_PROVEN
A6_PERF_J1_INPUT_NATIVE=UNCHANGED
CANONICAL_GITLINK_MUTATED=NO
EOF
FIX_SHA="$(sha256sum "$FIX_JAR" | awk '{print $1}')"
cat > "$DST/A6-PERF-J1-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A6-PERF-J1-DIRECT-RAW-LCD-ACCESS
BASE_PLATFORM_SEMANTIC_SHA256=$PARENT_SEM
PLATFORM_JAR_SHA256=$FIX_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
PERF_P3_DEVICE_RESULT=PASS_FUNCTIONAL_NORMAL_EXIT_PROTECTED_HASHES
PERF_P3_DEVICE_CUMULATIVE_FPS=16.56
PERF_P4_DEVICE_RESULT=NO_MEANINGFUL_GAIN_NO_NORMAL_EXIT_EVIDENCE
PERF_P4_DEVICE_CUMULATIVE_FPS=16.41
A6_PERF_J1_OWNER=RG35XX_FRAMEPRESENTER_REFLECTION_PER_FRAME
A6_PERF_J1_ACCESS=DIRECT_MOBILEPLATFORM_GETRG35XXLCDPIXELS
A6_PERF_J1_CHANGED_ENTRY=org/recompile/rg35xx/RG35XXLauncher\$FramePresenter.class
A6_PERF_J1_SCOPE_GATE=PASS
A6_PERF_J1_DIRECT_ACCESS_BYTECODE_GATE=PASS
A6_PERF_J1_NATIVE_VIDEO=EXACT_PERF_P3_DEVICE_PROVEN
A6_PERF_J1_INPUT_NATIVE=UNCHANGED
BUILD-PASS=YES
DEVICE-PASS=NO
PERFORMANCE-DEVICE-TEST=PENDING
STABLE=NO
EOF
(cd "$DST" && sha256sum * > A6-ARTIFACT-SHA256SUMS.txt)
echo A6_PERF_J1_BUILD=PASS
cat "$DST/A6-PERF-J1-IDENTITY.txt"
