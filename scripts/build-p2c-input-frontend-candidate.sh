#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2C_INPUT_FRONTEND_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

UPSTREAM="$ROOT/upstream/freej2me-miyoomini"
P2B_OUT="$ROOT/out/p2b-font-text-candidate-r1"
PARENT_JAR="$P2B_OUT/freej2me-rg35xx.jar"
OUT="$ROOT/out/p2c-input-frontend-candidate-r1"
BUILD="$ROOT/build/p2c-input-frontend-r1"
CLASSES="$BUILD/classes"
TEST_CLASSES="$BUILD/test-classes"
CANDIDATE="$OUT/freej2me-rg35xx.jar"
EXPECTED_P2B_JAR_SHA="6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4"
EXPECTED_FONT_NATIVE_SHA="29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
EXPECTED_VIDEO_SHA="c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
CANONICAL_AWEIGIT="ca11dfe8ea1cc273d92460f9a83bbf192023fa63"

rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT" "$CLASSES" "$TEST_CLASSES"

# 1. Reconstruct the already accepted P2B runtime lineage exactly.
JAVA8="$JAVA8" bash "$ROOT/scripts/build-p2b-font-text-candidate-v2.sh" | tee "$OUT/P2C-P2B-PARENT-REBUILD.txt"
grep -q '^P2B_FONT_TEXT_BUILD=PASS$' "$OUT/P2C-P2B-PARENT-REBUILD.txt" || fail "P2B parent build"
grep -q '^P2B_MODULE_GATE=PASS$' "$OUT/P2C-P2B-PARENT-REBUILD.txt" || fail "P2B parent module gate"
[ -f "$PARENT_JAR" ] || fail "P2B parent jar missing"
[ "$(sha256sum "$PARENT_JAR" | awk '{print $1}')" = "$EXPECTED_P2B_JAR_SHA" ] || fail "accepted P2B jar identity"
[ "$(sha256sum "$P2B_OUT/librg35xx_font.so" | awk '{print $1}')" = "$EXPECTED_FONT_NATIVE_SHA" ] || fail "accepted P2B font native identity"
[ "$(sha256sum "$P2B_OUT/librg35xx_video.so" | awk '{print $1}')" = "$EXPECTED_VIDEO_SHA" ] || fail "protected video identity"
cp "$PARENT_JAR" "$CANDIDATE"
cp "$P2B_OUT/librg35xx_font.so" "$OUT/librg35xx_font.so"
cp "$P2B_OUT/librg35xx_video.so" "$OUT/librg35xx_video.so"
echo P2C_ACCEPTED_P2B_PARENT_IDENTITY=PASS

# 2. Compile only the declared Java frontend owner delta as Java 6 bytecode.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$PARENT_JAR:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$CLASSES" \
  "$ROOT/adapter/java/org/recompile/rg35xx/RG35XXFrontendPolicy.java" \
  "$ROOT/adapter/java/org/recompile/rg35xx/RG35XXKeyDispatcher.java" \
  "$ROOT/adapter/java/org/recompile/rg35xx/RG35XXLauncher.java"

[ -f "$CLASSES/org/recompile/rg35xx/RG35XXFrontendPolicy.class" ] || fail "frontend policy class missing"
[ -f "$CLASSES/org/recompile/rg35xx/RG35XXKeyDispatcher.class" ] || fail "dispatcher class missing"
[ -f "$CLASSES/org/recompile/rg35xx/RG35XXLauncher.class" ] || fail "launcher class missing"
"$JAVA8/bin/jar" uf "$CANDIDATE" -C "$CLASSES" org/recompile/rg35xx

python3 - "$PARENT_JAR" "$CANDIDATE" <<'PY'
import hashlib,sys,zipfile
p,c=sys.argv[1:]
expected=sorted([
 'org/recompile/rg35xx/RG35XXFrontendPolicy.class',
 'org/recompile/rg35xx/RG35XXKeyDispatcher.class',
 'org/recompile/rg35xx/RG35XXLauncher$1.class',
 'org/recompile/rg35xx/RG35XXLauncher$FramePresenter.class',
 'org/recompile/rg35xx/RG35XXLauncher$InputPump.class',
 'org/recompile/rg35xx/RG35XXLauncher.class'])
with zipfile.ZipFile(p) as a, zipfile.ZipFile(c) as b:
    pa=set(a.namelist()); cb=set(b.namelist())
    added=sorted(cb-pa)
    removed=sorted(pa-cb)
    changed=sorted(n for n in pa&cb if hashlib.sha256(a.read(n)).digest()!=hashlib.sha256(b.read(n)).digest())
actual=sorted(added+changed)
if removed: raise SystemExit('P2C_OWNER_SCOPE_FAIL removed='+repr(removed))
if actual!=expected: raise SystemExit('P2C_OWNER_SCOPE_FAIL actual='+repr(actual)+' expected='+repr(expected))
print('P2C_CHANGED_JAR_ENTRIES='+','.join(actual))
print('P2C_PARENT_ACCEPTED_CLASS_IDENTITY=PASS')
print('P2C_OWNER_SCOPE_VERIFIED=PASS')
PY

python3 - "$CLASSES" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])/'org/recompile/rg35xx'
files=sorted(root.glob('*.class'))
if not files: raise SystemExit('P2C_JAVA6_GATE=FAIL no classes')
for p in files:
    b=p.read_bytes()
    if b[:4] != b'\xca\xfe\xba\xbe': raise SystemExit('bad class '+str(p))
    major=int.from_bytes(b[6:8],'big')
    if major != 50: raise SystemExit('P2C_JAVA6_GATE=FAIL '+p.name+' major='+str(major))
print('P2C_JAVA6_CLASS_COUNT=%d' % len(files))
print('P2C_JAVA6_GATE=PASS')
PY

# 3. Run frontend behavior through the real MobilePlatform/Display boundary.
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" \
  -classpath "$CANDIDATE:$UPSTREAM/lib/jsr305-3.0.2.jar" \
  -d "$TEST_CLASSES" "$ROOT/tests/p2c/RG35XXP2CFrontendHostGate.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$CANDIDATE:$TEST_CLASSES" \
  org.recompile.rg35xx.RG35XXP2CFrontendHostGate | tee "$OUT/P2C-FRONTEND-HOST-GATE.txt"
for marker in \
  P2C_HOST_DEFAULT_MAPPING_GATE=PASS \
  P2C_HOST_PHONE_MODE_GATE=PASS \
  P2C_HOST_KEYMAP_CFG_GATE=PASS \
  P2C_HOST_HOTKEY_GATE=PASS \
  P2C_HOST_POINTER_GATE=PASS \
  P2C_HOST_ROTATION_GATE=PASS \
  P2C_FRONTEND_HOST_GATE=PASS; do
  grep -q "^${marker}$" "$OUT/P2C-FRONTEND-HOST-GATE.txt" || fail "$marker"
done

# 4. Run an independent host C event-model gate against the native owner source.
HOST_CC="${HOST_CC:-gcc}"
"$HOST_CC" -O2 -Wall -Wextra -I"$JAVA8/include" -I"$JAVA8/include/linux" \
  "$ROOT/tests/p2c/rg35xx_input_host_gate.c" -o "$BUILD/rg35xx_input_host_gate"
"$BUILD/rg35xx_input_host_gate" | tee "$OUT/P2C-NATIVE-HOST-GATE.txt"
for marker in \
  P2C_NATIVE_EXISTING_12_CONTROL_GATE=PASS \
  P2C_NATIVE_L2_AXIS2_GATE=PASS \
  P2C_NATIVE_R2_AXIS5_GATE=PASS \
  P2C_NATIVE_14_CONTROL_HOST_GATE=PASS; do
  grep -q "^${marker}$" "$OUT/P2C-NATIVE-HOST-GATE.txt" || fail "$marker"
done

# 5. Build only the changed native input owner with the pinned ARMv5TE uClibC toolchain.
ARM_CC="${ARM_CC:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc}"
ARM_READELF="${ARM_READELF:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-readelf}"
ARM_STRIP="${ARM_STRIP:-/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-strip}"
[ -x "$ARM_CC" ] || fail "ARM compiler missing"
[ -x "$ARM_READELF" ] || fail "ARM readelf missing"
[ -x "$ARM_STRIP" ] || fail "ARM strip missing"
JNI="$UPSTREAM/cpp/native/include"
"$ARM_CC" -shared -fPIC -Os -pipe -fno-strict-aliasing \
  -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -Wall -Wextra \
  -I"$JNI" -I"$JNI/linux" "$ROOT/adapter/native/rg35xx_input.c" -o "$OUT/librg35xx_input.so"
"$ARM_STRIP" "$OUT/librg35xx_input.so"
"$ARM_READELF" -h "$OUT/librg35xx_input.so" > "$OUT/P2C-INPUT-NATIVE-ELF.txt"
"$ARM_READELF" -A "$OUT/librg35xx_input.so" > "$OUT/P2C-INPUT-NATIVE-ATTR.txt" || true
grep -q 'Class:.*ELF32' "$OUT/P2C-INPUT-NATIVE-ELF.txt" || fail "input not ELF32"
grep -q 'Machine:.*ARM' "$OUT/P2C-INPUT-NATIVE-ELF.txt" || fail "input not ARM"
grep -q 'Version5 EABI' "$OUT/P2C-INPUT-NATIVE-ELF.txt" || fail "input not EABI5"
grep -q 'soft-float ABI' "$OUT/P2C-INPUT-NATIVE-ELF.txt" || fail "input not soft-float"
strings "$OUT/librg35xx_input.so" | grep -q '/dev/input/js0' || fail "js0 owner missing"
echo P2C_ARM_INPUT_NATIVE_BUILD=PASS

# 6. Final identities and non-owner protection.
P2C_JAR_SHA="$(sha256sum "$CANDIDATE" | awk '{print $1}')"
P2C_INPUT_SHA="$(sha256sum "$OUT/librg35xx_input.so" | awk '{print $1}')"
FONT_SHA="$(sha256sum "$OUT/librg35xx_font.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$OUT/librg35xx_video.so" | awk '{print $1}')"
[ "$FONT_SHA" = "$EXPECTED_FONT_NATIVE_SHA" ] || fail "font native changed"
[ "$VIDEO_SHA" = "$EXPECTED_VIDEO_SHA" ] || fail "video native changed"
[ "$P2C_INPUT_SHA" != "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d" ] || fail "input candidate did not change"

cat > "$OUT/P2C-INPUT-FRONTEND-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P2C-INPUT-FRONTEND-MODULE-CANDIDATE-R1
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
CANONICAL_AWEIGIT=$CANONICAL_AWEIGIT
ACCEPTED_P2B_PLATFORM_JAR_SHA256=$EXPECTED_P2B_JAR_SHA
P2C_PLATFORM_JAR_SHA256=$P2C_JAR_SHA
P2C_INPUT_NATIVE_SHA256=$P2C_INPUT_SHA
P2C_PARENT_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
P2C_FONT_NATIVE_SHA256=$FONT_SHA
P2C_VIDEO_NATIVE_SHA256=$VIDEO_SHA
P2C_HARDWARE_EVIDENCE=PASS_14_CONTROL_CALIBRATION
P2C_L2_OWNER=JS0_AXIS2_BASELINE_-32767_PRESS_32767_BIT12
P2C_R2_OWNER=JS0_AXIS5_BASELINE_-32767_PRESS_32767_BIT13
P2C_CANONICAL_DIFF_VERIFIED=PASS
P2C_OWNER_SCOPE_VERIFIED=PASS
P2C_JAVA6_GATE=PASS
P2C_FRONTEND_HOST_GATE=PASS
P2C_NATIVE_14_CONTROL_HOST_GATE=PASS
P2C_ARM_INPUT_NATIVE_BUILD=PASS
P2C_PARENT_ACCEPTED_CLASS_IDENTITY=PASS
P2C_VIDEO_PARENT_IDENTITY=PASS
P2C_FONT_PARENT_IDENTITY=PASS
P2C_HOST_MODULE_GATE=PASS
PHYSICAL_TEST_REQUIRED=YES
PHYSICAL_TEST_LEVEL=MODULE
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
EOF

(cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$OUT/SHA256SUMS.txt"
(cd "$OUT" && sha256sum -c SHA256SUMS.txt)

echo P2C_CANONICAL_DIFF_VERIFIED=PASS
echo P2C_OWNER_SCOPE_VERIFIED=PASS
echo P2C_JAVA6_GATE=PASS
echo P2C_FRONTEND_HOST_GATE=PASS
echo P2C_NATIVE_14_CONTROL_HOST_GATE=PASS
echo P2C_ARM_INPUT_NATIVE_BUILD=PASS
echo P2C_PARENT_ACCEPTED_CLASS_IDENTITY=PASS
echo P2C_VIDEO_PARENT_IDENTITY=PASS
echo P2C_FONT_PARENT_IDENTITY=PASS
echo P2C_HOST_MODULE_GATE=PASS
echo P2C_PHYSICAL_TEST=NOT_TESTED
echo RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
echo STABLE=NO
