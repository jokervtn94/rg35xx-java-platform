#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

BASE_BRANCH_BUILD="rebuild-v1/build_foundation.sh"
HIST=196c95bf031121711c150618d130b5a77332d412
JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}

rm -rf build-dp-r2 out/dp-r2
mkdir -p build-dp-r2/historical build-dp-r2/midlet build-dp-r2/manifest out/dp-r2/Roms/APPS/RG35XX-JAVA-DP-R2

# Reproduce the exact clean DP-R1 foundation first.
bash "$BASE_BRANCH_BUILD"
BASE_PLATFORM=out/garlicos/Roms/APPS/RG35XX-JAVA-DP-R1/rg35xx-dp-r1-platform.jar
BASE_INPUT=out/garlicos/Roms/APPS/RG35XX-JAVA-DP-R1/libm1_8_input.so
BASE_PRESENTER=out/garlicos/Roms/APPS/RG35XX-JAVA-DP-R1/libm1_9e_presenter.so
test -f "$BASE_PLATFORM" -a -f "$BASE_INPUT" -a -f "$BASE_PRESENTER"
cp "$BASE_PLATFORM" build-dp-r2/base-platform.jar

hist() {
  p="$1"; d="build-dp-r2/historical/$p"
  mkdir -p "$(dirname "$d")"
  git cat-file -e "$HIST:$p"
  git show "$HIST:$p" >"$d"
}

R14=miyoo-m1/m1_16/patch_platformimage_copy_headless_r14.py
R15=miyoo-m1/m1_16/patch_platformimage_rgb_headless_r15.py
DIAG=miyoo-m1/m1_16/M116R11ImageSpriteIsolationMIDlet.java
hist "$R14"
hist "$R15"
hist "$DIAG"

echo HISTORICAL_SOURCE_COMMIT="$HIST"
echo R14_SHA256="$(sha256sum build-dp-r2/historical/$R14 | awk '{print $1}')"
echo R15_SHA256="$(sha256sum build-dp-r2/historical/$R15 | awk '{print $1}')"
echo DIAG_SHA256="$(sha256sum build-dp-r2/historical/$DIAG | awk '{print $1}')"

# Prior device-evidenced prerequisite, then ONE new primary variable r1.5.
python3 "build-dp-r2/historical/$R14"
python3 "build-dp-r2/historical/$R15"

grep -q 'M1.16-r1.4 PRIMARY VARIABLE: headless LCDUI Image copy only' upstream/src/org/recompile/mobile/PlatformImage.java
grep -q 'M1.16-r1.5 PRIMARY VARIABLE: RGB-image headless allocation only' upstream/src/org/recompile/mobile/PlatformImage.java

(cd upstream && JAVA_HOME="$JAVA8" ant -noinput -buildfile build.xml)
POST_PLATFORM=upstream/build/freej2me_plus.jar
test -f "$POST_PLATFORM"

# Fail closed: only PlatformImage.class may change in runtime JAR content.
python3 - <<'PY'
import zipfile, hashlib
from pathlib import Path

a=Path('build-dp-r2/base-platform.jar')
b=Path('upstream/build/freej2me_plus.jar')

def entries(p):
    out={}
    with zipfile.ZipFile(p) as z:
        for n in z.namelist():
            if n.endswith('/'): continue
            out[n]=hashlib.sha256(z.read(n)).hexdigest()
    return out
A=entries(a); B=entries(b)
names=sorted(set(A)|set(B))
changed=[n for n in names if A.get(n)!=B.get(n)]
print('DP_R2_CHANGED_JAR_ENTRIES=' + ','.join(changed))
expected=['org/recompile/mobile/PlatformImage.class']
if changed != expected:
    raise SystemExit('DP_R2_SINGLE_CLASS_GATE=FAIL changed='+repr(changed))
print('DP_R2_SINGLE_CLASS_GATE=PASS')
PY

# Native files must remain byte-identical to the freshly rebuilt DP-R1 foundation.
cp "$BASE_INPUT" build-dp-r2/libm1_8_input.so
cp "$BASE_PRESENTER" build-dp-r2/libm1_9e_presenter.so

# Compile the isolated historical Image -> Sprite diagnostic.
"$JAVA8/bin/javac" -source 1.5 -target 1.5 -bootclasspath "$JAVA8/jre/lib/rt.jar"   -classpath "$POST_PLATFORM"   -d build-dp-r2/midlet   "build-dp-r2/historical/$DIAG"

cat >build-dp-r2/manifest/dp-r2.mf <<'MF'
Manifest-Version: 1.0
MIDlet-1: DP-R2 Image Sprite R15,,org.recompile.mobile.M116R11ImageSpriteIsolationMIDlet
MIDlet-Name: DP-R2 Image Sprite R15
MIDlet-Vendor: RG35XX
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF
"$JAVA8/bin/jar" cfm build-dp-r2/dp-r2-image-sprite-r15.jar build-dp-r2/manifest/dp-r2.mf -C build-dp-r2/midlet .

# Java compatibility gate.
python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [Path('upstream/build/freej2me_plus.jar'),Path('build-dp-r2/dp-r2-image-sprite-r15.jar')]:
    with zipfile.ZipFile(jar) as z:
        for n in z.namelist():
            if n.endswith('.class'):
                d=z.read(n)
                major=int.from_bytes(d[6:8],'big')
                if major>50: bad.append((str(jar),n,major))
if bad: raise SystemExit('JAVA6_GATE=FAIL '+repr(bad[:10]))
print('JAVA6_GATE=PASS')
PY

PAYLOAD=out/dp-r2/Roms/APPS/RG35XX-JAVA-DP-R2
cp "$POST_PLATFORM" "$PAYLOAD/rg35xx-dp-r2-platform.jar"
cp build-dp-r2/dp-r2-image-sprite-r15.jar "$PAYLOAD/"
cp build-dp-r2/libm1_8_input.so build-dp-r2/libm1_9e_presenter.so "$PAYLOAD/"

cat >"$PAYLOAD/DP-R2-IMAGE-SPRITE-R15.sh" <<'SH'
#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R2-IMAGE-SPRITE-R15.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
: >"$OUT"
echo 'RG35XX DP-R2 IMAGE-SPRITE R1.5 A/B' >>"$OUT"
echo PRIMARY_VARIABLE=PLATFORMIMAGE_CREATE_RGB_HEADLESS_ONLY >>"$OUT"
JB="$(sha256sum "$JAMVM"|awk '{print $1}')"
GB="$(sha256sum "$GLIBJ"|awk '{print $1}')"
echo JAMVM_SHA256_BEFORE="$JB" >>"$OUT"
echo GLIBJ_SHA256_BEFORE="$GB" >>"$OUT"
if [ "$JB" != "$EXPECTED_JAMVM" ] || [ "$GB" != "$EXPECTED_GLIBJ" ]; then
  echo PROTECTED_HASHES_BEFORE=FAIL >>"$OUT"
  echo DEVICE_PASS=NO >>"$OUT"
  echo STABLE=NO >>"$OUT"
  sync
  exit 41
fi
echo PROTECTED_HASHES_BEFORE=PASS >>"$OUT"

"$JAMVM" -Xmx64m   -cp "$GLIBJ:$APP/rg35xx-dp-r2-platform.jar:$FONTJAR"   org.recompile.mobile.M19CanvasLifecycleLauncher   "$APP/dp-r2-image-sprite-r15.jar" >>"$OUT" 2>&1
RC=$?
echo JAMVM_EXIT_CODE="$RC" >>"$OUT"

JA="$(sha256sum "$JAMVM"|awk '{print $1}')"
GA="$(sha256sum "$GLIBJ"|awk '{print $1}')"
echo JAMVM_SHA256_AFTER="$JA" >>"$OUT"
echo GLIBJ_SHA256_AFTER="$GA" >>"$OUT"
if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
  echo PROTECTED_HASHES_AFTER=PASS >>"$OUT"
else
  echo PROTECTED_HASHES_AFTER=FAIL >>"$OUT"
fi

if [ "$RC" = 0 ]  && grep -q 'M1_16_R11_A_MUTABLE_SPRITE_CTOR=PASS' "$OUT"  && grep -q 'M1_16_R11_B_COPY_SPRITE_CTOR=PASS' "$OUT"  && grep -q 'M1_16_R11_C_RGB_SPRITE_CTOR=PASS' "$OUT"  && grep -q 'M1_16_R11_A_RESULT=PASS' "$OUT"  && grep -q 'M1_16_R11_B_RESULT=PASS' "$OUT"  && grep -q 'M1_16_R11_C_RESULT=PASS' "$OUT"  && grep -q 'M1_16_R11_DIAGNOSTIC_GATE=PASS' "$OUT"  && grep -q 'M1_16_R11_RUNTIME_GATE=PASS' "$OUT"  && grep -q 'PROTECTED_HASHES_AFTER=PASS' "$OUT"; then
  echo DP_R2_RUNTIME_GATE=PASS >>"$OUT"
else
  echo DP_R2_RUNTIME_GATE=FAIL >>"$OUT"
fi
echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"
echo STABLE=NO >>"$OUT"
sync
exit "$RC"
SH
chmod +x "$PAYLOAD/DP-R2-IMAGE-SPRITE-R15.sh"

# GarlicOS top-level launcher wrapper.
cat >out/dp-r2/Roms/APPS/DP-R2-01-IMAGE-SPRITE-R15.sh <<'SH'
#!/bin/sh
exec /bin/sh /mnt/mmc/Roms/APPS/RG35XX-JAVA-DP-R2/DP-R2-IMAGE-SPRITE-R15.sh
SH
chmod +x out/dp-r2/Roms/APPS/DP-R2-01-IMAGE-SPRITE-R15.sh

cat >"$PAYLOAD/README.txt" <<'TXT'
RG35XX DP-R2 IMAGE -> SPRITE r1.5 A/B
Primary variable: PlatformImage createRGBImage headless backing only.
r1.4 LCDUI Image copy is reused as historical device-evidenced prerequisite.
No Sprite implementation, renderer, input, SDL1, font, RMS, audio, JamVM, or glibj changes.
Run DP-R2-01-IMAGE-SPRITE-R15 from GarlicOS APPS.
Result: /mnt/mmc/RG35XX-DP-R2-IMAGE-SPRITE-R15.txt
DEVICE-PASS=NO until real-device review.
STABLE=NO
TXT

BASE_SHA="$(sha256sum build-dp-r2/base-platform.jar|awk '{print $1}')"
POST_SHA="$(sha256sum "$PAYLOAD/rg35xx-dp-r2-platform.jar"|awk '{print $1}')"
INPUT_SHA="$(sha256sum "$PAYLOAD/libm1_8_input.so"|awk '{print $1}')"
PRES_SHA="$(sha256sum "$PAYLOAD/libm1_9e_presenter.so"|awk '{print $1}')"
TEST_SHA="$(sha256sum "$PAYLOAD/dp-r2-image-sprite-r15.jar"|awk '{print $1}')"

{
echo RG35XX_DP_R2_IMAGE_SPRITE_R15_AB
echo BASELINE=DP-R1_STANDALONE_SDL1_FBCON
echo HISTORICAL_SOURCE_COMMIT="$HIST"
echo PRIMARY_VARIABLE=PLATFORMIMAGE_CREATE_RGB_HEADLESS_ONLY
echo PRIOR_DEVICE_EVIDENCE=R14_LCDUI_IMAGE_COPY_HEADLESS
echo BASE_PLATFORM_SHA256="$BASE_SHA"
echo R2_PLATFORM_SHA256="$POST_SHA"
echo INPUT_SO_SHA256="$INPUT_SHA"
echo PRESENTER_SO_SHA256="$PRES_SHA"
echo TEST_JAR_SHA256="$TEST_SHA"
echo JAMVM_REQUIRED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
echo GLIBJ_REQUIRED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/dp-r2/BUILD-IDENTITY.txt

cp docs/DP-R2-IMAGE-SPRITE-R15-AB.md out/dp-r2/
(cd out/dp-r2 && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) >out/dp-r2/SHA256SUMS.txt
(cd out/dp-r2 && sha256sum -c SHA256SUMS.txt)

echo RG35XX_DP_R2_BUILD_GATE=PASS
cat out/dp-r2/BUILD-IDENTITY.txt
