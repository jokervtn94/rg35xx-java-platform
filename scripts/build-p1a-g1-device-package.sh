#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G1_DEVICE_PACKAGE_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

SRC="$ROOT/out/p1a-g1-clear-copyarea"
PLATFORM="$SRC/freej2me-rg35xx.jar"
[ -f "$PLATFORM" ] || fail "P1A G1 candidate missing"
for f in librg35xx_input.so librg35xx_video.so libaudio.so P1A-G1-IDENTITY.txt; do
  [ -f "$SRC/$f" ] || fail "candidate payload missing $f"
done

grep -q '^BUILD-PASS=YES$' "$SRC/P1A-G1-IDENTITY.txt" || fail "candidate not BUILD-PASS"
grep -q '^DEVICE-PASS=NO$' "$SRC/P1A-G1-IDENTITY.txt" || fail "candidate identity must remain pending device"
grep -q '^CLEARRECT_STATUS=INTERNAL_ONLY_DEFERRED_UNCHANGED$' "$SRC/P1A-G1-IDENTITY.txt" || fail "clearRect scope drift"

BUILD="$ROOT/build/p1a-g1-device"
OUT="$ROOT/out/p1a-g1-device-package"
SD="$OUT/SD"
APPS="$SD/Roms/APPS"
PKG="$APPS/RG35XX-P1A-G1"
rm -rf "$BUILD" "$OUT"
mkdir -p "$BUILD/classes" "$PKG" "$OUT"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PLATFORM" \
  -d "$BUILD/classes" \
  "$ROOT/tests/p1a/RG35XXP1AG1Vectors.java" \
  "$ROOT/tests/p1a/RG35XXP1AG1CanonicalVectorGenerator.java" \
  "$ROOT/tests/p1a/RG35XXP1AG1DeviceMIDlet.java"

"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$PLATFORM:$BUILD/classes" \
  org.recompile.rg35xx.p1a.RG35XXP1AG1CanonicalVectorGenerator \
  > "$BUILD/canonical-vectors.log"
grep -q '^P1A_G1_CANONICAL_VECTOR_GENERATION=PASS$' "$BUILD/canonical-vectors.log" \
  || fail "canonical vector generation"
grep -E '^COPY_[A-Z_]+=-?[0-9]+$' "$BUILD/canonical-vectors.log" \
  > "$BUILD/p1a-g1-expected.txt"
[ "$(wc -l < "$BUILD/p1a-g1-expected.txt" | tr -d ' ')" = 9 ] || fail "expected copyArea vector count"

cat > "$BUILD/p1a-g1-device.mf" <<'MF'
Manifest-Version: 1.0
MIDlet-1: RG35XX P1A G1 CopyArea Test,,org.recompile.rg35xx.p1a.RG35XXP1AG1DeviceMIDlet
MIDlet-Name: RG35XX P1A G1 CopyArea Test
MIDlet-Vendor: RG35XX-AWEIGIT-R1
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

cp "$BUILD/p1a-g1-expected.txt" "$BUILD/classes/"
TESTJAR="$PKG/p1a-g1-platform-test.jar"
"$JAVA8/bin/jar" cfm "$TESTJAR" "$BUILD/p1a-g1-device.mf" -C "$BUILD/classes" .

python3 - "$TESTJAR" <<'PY'
import sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    bad=[]
    for n in z.namelist():
        if n.endswith('.class'):
            b=z.read(n); major=(b[6]<<8)|b[7]
            if major>50: bad.append((n,major))
    if 'p1a-g1-expected.txt' not in z.namelist(): raise SystemExit('expected resource missing')
    if bad: raise SystemExit('Java6 gate failed '+repr(bad))
print('P1A_G1_DEVICE_JAR_JAVA6_GATE=PASS')
PY

cp "$PLATFORM" "$PKG/freej2me-rg35xx.jar"
cp "$SRC/librg35xx_input.so" "$SRC/librg35xx_video.so" "$SRC/libaudio.so" "$PKG/"
cp "$SRC/P1A-G1-IDENTITY.txt" "$PKG/BUILD-IDENTITY.txt"
cp "$BUILD/p1a-g1-expected.txt" "$PKG/CANONICAL-VECTORS.txt"

PLATFORM_SHA="$(sha256sum "$PKG/freej2me-rg35xx.jar" | awk '{print $1}')"
TEST_SHA="$(sha256sum "$TESTJAR" | awk '{print $1}')"
INPUT_SHA="$(sha256sum "$PKG/librg35xx_input.so" | awk '{print $1}')"
VIDEO_SHA="$(sha256sum "$PKG/librg35xx_video.so" | awk '{print $1}')"
AUDIO_SHA="$(sha256sum "$PKG/libaudio.so" | awk '{print $1}')"
VECTORS_SHA="$(sha256sum "$PKG/CANONICAL-VECTORS.txt" | awk '{print $1}')"

[ "$INPUT_SHA" = 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d ] || fail input_hash
[ "$VIDEO_SHA" = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d ] || fail video_hash
[ "$AUDIO_SHA" = 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644 ] || fail audio_hash

cat > "$APPS/P1A-G1-PLATFORM-TEST.sh" <<EOF
#!/bin/sh
APP="\$(CDPATH= cd -- "\$(dirname -- "\$0")" 2>/dev/null && pwd)"
PKG="\$APP/RG35XX-P1A-G1"
TESTJAR="\$PKG/p1a-g1-platform-test.jar"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EVIDENCE_ROOT=/mnt/mmc/RG35XX-PLATFORM-EVIDENCE
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
EXPECTED_PLATFORM=$PLATFORM_SHA
EXPECTED_TEST=$TEST_SHA
EXPECTED_INPUT=$INPUT_SHA
EXPECTED_VIDEO=$VIDEO_SHA
EXPECTED_AUDIO=$AUDIO_SHA
EXPECTED_VECTORS=$VECTORS_SHA
STAMP="\$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"
EVIDENCE="\$EVIDENCE_ROOT/P1A-G1-\$STAMP"
mkdir -p "\$EVIDENCE" || exit 20
OUT="\$EVIDENCE/RUNTIME-RESULT.txt"
: >"\$OUT"
fail(){ echo "PRECONDITION=FAIL:\$1" >>"\$OUT"; echo 'TECHNICAL_GATE=FAIL' >>"\$OUT"; echo 'DEVICE_PASS=NO' >>"\$OUT"; sync; exit 20; }
sha(){ sha256sum "\$1" 2>/dev/null | awk '{print \$1}'; }
[ -x "\$JAMVM" ] || fail JAMVM_MISSING
[ -f "\$GLIBJ" ] || fail GLIBJ_MISSING
for F in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so p1a-g1-platform-test.jar CANONICAL-VECTORS.txt; do [ -f "\$PKG/\$F" ] || fail "MISSING:\$F"; done
JB="\$(sha "\$JAMVM")"; GB="\$(sha "\$GLIBJ")"; PH="\$(sha "\$PKG/freej2me-rg35xx.jar")"; TH="\$(sha "\$TESTJAR")"; IH="\$(sha "\$PKG/librg35xx_input.so")"; VH="\$(sha "\$PKG/librg35xx_video.so")"; AH="\$(sha "\$PKG/libaudio.so")"; EH="\$(sha "\$PKG/CANONICAL-VECTORS.txt")"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"\$OUT"
echo 'WORK_UNIT=P1A-G1-COPYAREA' >>"\$OUT"
echo 'CLEARRECT_STATUS=INTERNAL_ONLY_DEFERRED_UNCHANGED' >>"\$OUT"
echo "JAMVM_SHA256=\$JB" >>"\$OUT"; echo "GLIBJ_SHA256=\$GB" >>"\$OUT"; echo "PLATFORM_SHA256=\$PH" >>"\$OUT"; echo "TEST_JAR_SHA256=\$TH" >>"\$OUT"; echo "INPUT_SHA256=\$IH" >>"\$OUT"; echo "VIDEO_SHA256=\$VH" >>"\$OUT"; echo "AUDIO_SHA256=\$AH" >>"\$OUT"; echo "CANONICAL_VECTORS_SHA256=\$EH" >>"\$OUT"
[ "\$JB" = "\$EXPECTED_JAMVM" ] || fail JAMVM_HASH
[ "\$GB" = "\$EXPECTED_GLIBJ" ] || fail GLIBJ_HASH
[ "\$PH" = "\$EXPECTED_PLATFORM" ] || fail PLATFORM_HASH
[ "\$TH" = "\$EXPECTED_TEST" ] || fail TEST_HASH
[ "\$IH" = "\$EXPECTED_INPUT" ] || fail INPUT_HASH
[ "\$VH" = "\$EXPECTED_VIDEO" ] || fail VIDEO_HASH
[ "\$AH" = "\$EXPECTED_AUDIO" ] || fail AUDIO_HASH
[ "\$EH" = "\$EXPECTED_VECTORS" ] || fail VECTORS_HASH
echo 'IDENTITY_GATE=PASS' >>"\$OUT"
mkdir -p "\$PKG/data" || fail DATA_DIR
LD_LIBRARY_PATH="\$PKG\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}" "\$JAMVM" -Xmx64m -Drg35xx.raw2d=true -Drg35xx.native.dir="\$PKG" -cp "\$GLIBJ:\$PKG/freej2me-rg35xx.jar" org.recompile.rg35xx.RG35XXLauncher "\$TESTJAR" 240 320 "\$PKG/data" "\$PKG/data" >>"\$OUT" 2>&1
RC=\$?
echo "RUNTIME_EXIT_CODE=\$RC" >>"\$OUT"
grep -q '^P1A_G1_PROGRAMMATIC=PASS$' "\$OUT" && PROG=PASS || PROG=FAIL
grep -q '^P1A_G1_HUMAN_EXIT_BUTTON=FIRE$' "\$OUT" && FIRE=PASS || FIRE=FAIL
echo "PROGRAMMATIC_VECTOR_GATE=\$PROG" >>"\$OUT"
echo "FIRE_EXIT_GATE=\$FIRE" >>"\$OUT"
if [ "\$RC" -eq 0 ] && [ "\$PROG" = PASS ] && [ "\$FIRE" = PASS ]; then echo 'TECHNICAL_GATE=PASS' >>"\$OUT"; else echo 'TECHNICAL_GATE=FAIL' >>"\$OUT"; fi
JA="\$(sha "\$JAMVM")"; GA="\$(sha "\$GLIBJ")"
[ "\$JA" = "\$EXPECTED_JAMVM" ] && [ "\$GA" = "\$EXPECTED_GLIBJ" ] && echo 'PROTECTED_HASHES=PASS' >>"\$OUT" || echo 'PROTECTED_HASHES=FAIL' >>"\$OUT"
echo 'DEVICE_PASS=NO_PENDING_PHYSICAL_REVIEW' >>"\$OUT"
cat >"\$EVIDENCE/OBSERVATION.txt" <<'OBS'
SCREEN_VISIBLE=NOT_REVIEWED
VECTOR_CHECK_TEXT=NOT_REVIEWED
COPY_PANEL_A_LOOKS_CORRECT=NOT_REVIEWED
COPY_PANEL_B_LOOKS_CORRECT=NOT_REVIEWED
CLIP_TRANSLATE_PANEL_LOOKS_CORRECT=NOT_REVIEWED
NO_VISIBLE_SMEAR_OR_CORRUPTION=NOT_REVIEWED
FIRE_RETURNED_TO_GARLICOS=NOT_REVIEWED
HUMAN_DEVICE_PASS=NO_PENDING_REVIEW
OBS
cp "\$PKG/BUILD-IDENTITY.txt" "\$EVIDENCE/BUILD-IDENTITY.txt" 2>/dev/null || true
cp "\$PKG/CANONICAL-VECTORS.txt" "\$EVIDENCE/CANONICAL-VECTORS.txt" 2>/dev/null || true
sync
exit "\$RC"
EOF
chmod +x "$APPS/P1A-G1-PLATFORM-TEST.sh"

cat > "$OUT/README-FIRST.txt" <<'TXT'
P1A-G1 COPYAREA PLATFORM TEST — original RG35XX / GarlicOS

1. Copy the contents of SD/ to the root of the RG35XX SD card.
2. Do not replace /mnt/mmc/CFW/java. The launcher hash-gates the protected JamVM/glibj.
3. On RG35XX open APPS and run: P1A-G1-PLATFORM-TEST
4. The screen must show VECTOR CHECK: PASS and three clean copyArea panels without smear/stray pixels.
5. Press A/FIRE only after visual review. It should return to GarlicOS.
6. Evidence is written under /mnt/mmc/RG35XX-PLATFORM-EVIDENCE/P1A-G1-<timestamp>/.
7. Exit code/programmatic PASS does NOT make DEVICE-PASS. Report the visual observation separately.

clearRect is intentionally NOT in this runtime/device test: caller audit found it absent from the public MIDP Graphics surface and from staged 2D callers. It remains canonical/unmodified.

This package contains no commercial game and does not modify the accepted production launcher/payload.
TXT

cat > "$OUT/P1A-G1-DEVICE-PACKAGE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G1-COPYAREA
PACKAGE_TYPE=SYNTHETIC_PLATFORM_EXERCISER
PLATFORM_SHA256=$PLATFORM_SHA
TEST_JAR_SHA256=$TEST_SHA
CANONICAL_VECTORS_SHA256=$VECTORS_SHA
INPUT_NATIVE_SHA256=$INPUT_SHA
VIDEO_NATIVE_SHA256=$VIDEO_SHA
AUDIO_NATIVE_SHA256=$AUDIO_SHA
JAMVM_EXPECTED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_EXPECTED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
CLEARRECT_STATUS=INTERNAL_ONLY_DEFERRED_UNCHANGED
GAME_CONTENT=NONE
AUDIO_PRIME=NOT_USED_GRAPHICS_SCOPE_ONLY
BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
EOF

(
  cd "$OUT"
  find . -type f ! -name PACKAGE-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PACKAGE-SHA256SUMS.txt
  sha256sum -c PACKAGE-SHA256SUMS.txt
)

echo P1A_G1_DEVICE_PACKAGE=PASS
cat "$OUT/P1A-G1-DEVICE-PACKAGE-IDENTITY.txt"
