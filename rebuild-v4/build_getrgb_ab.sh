#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}

rm -rf build-dp-r4 out/dp-r4
mkdir -p build-dp-r4/midlet build-dp-r4/manifest out/dp-r4/Roms/APPS/RG35XX-JAVA-DP-R4

# Rebuild exact DP-R3 A/B. Upstream is left at DP-R3-B after this script.
bash rebuild-v3/build_sprite_render_ab.sh

A_PLATFORM=out/dp-r3/Roms/APPS/RG35XX-JAVA-DP-R3/dp-r3-b-platform.jar
INPUT_SO=out/dp-r3/Roms/APPS/RG35XX-JAVA-DP-R3/libm1_8_input.so
PRESENTER_SO=out/dp-r3/Roms/APPS/RG35XX-JAVA-DP-R3/libm1_9e_presenter.so

test -f "$A_PLATFORM" -a -f "$INPUT_SO" -a -f "$PRESENTER_SO"
cp "$A_PLATFORM" build-dp-r4/dp-r4-a-platform.jar

"$JAVA8/bin/javac" -source 1.5 -target 1.5 -bootclasspath "$JAVA8/jre/lib/rt.jar"   -classpath "$A_PLATFORM"   -d build-dp-r4/midlet   rebuild-v4/DP4GetRGBCollisionDiagnosticMIDlet.java

cat >build-dp-r4/manifest/dp-r4.mf <<'MF'
Manifest-Version: 1.0
MIDlet-1: DP-R4 getRGB Collision AB,,org.recompile.mobile.DP4GetRGBCollisionDiagnosticMIDlet
MIDlet-Name: DP-R4 getRGB Collision AB
MIDlet-Vendor: RG35XX
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

"$JAVA8/bin/jar" cfm build-dp-r4/dp-r4-getrgb-collision-diagnostic.jar   build-dp-r4/manifest/dp-r4.mf -C build-dp-r4/midlet .

python3 rebuild-v4/patch_platformimage_getrgb_headless.py
grep -q 'DP-R4 PRIMARY VARIABLE: headless getRGB backing only' upstream/src/org/recompile/mobile/PlatformImage.java

(cd upstream && JAVA_HOME="$JAVA8" ant -noinput -buildfile build.xml)
B_PLATFORM=upstream/build/freej2me_plus.jar
test -f "$B_PLATFORM"
cp "$B_PLATFORM" build-dp-r4/dp-r4-b-platform.jar

python3 - <<'PY'
import zipfile, hashlib
from pathlib import Path

def entries(p):
    out={}
    with zipfile.ZipFile(p) as z:
        for n in z.namelist():
            if n.endswith('/'): continue
            out[n]=hashlib.sha256(z.read(n)).hexdigest()
    return out

A=entries(Path('build-dp-r4/dp-r4-a-platform.jar'))
B=entries(Path('build-dp-r4/dp-r4-b-platform.jar'))
changed=sorted(n for n in set(A)|set(B) if A.get(n)!=B.get(n))
print('DP_R4_CHANGED_JAR_ENTRIES=' + ','.join(changed))
expected=['org/recompile/mobile/PlatformImage.class']
if changed != expected:
    raise SystemExit('DP_R4_SINGLE_CLASS_GATE=FAIL changed='+repr(changed))
print('DP_R4_SINGLE_CLASS_GATE=PASS')
PY

python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [
    Path('build-dp-r4/dp-r4-a-platform.jar'),
    Path('build-dp-r4/dp-r4-b-platform.jar'),
    Path('build-dp-r4/dp-r4-getrgb-collision-diagnostic.jar')
]:
    with zipfile.ZipFile(jar) as z:
        for n in z.namelist():
            if n.endswith('.class'):
                d=z.read(n)
                major=int.from_bytes(d[6:8],'big')
                if major>50: bad.append((str(jar),n,major))
if bad:
    raise SystemExit('JAVA6_GATE=FAIL '+repr(bad[:10]))
print('JAVA6_GATE=PASS')
PY

PAYLOAD=out/dp-r4/Roms/APPS/RG35XX-JAVA-DP-R4
cp build-dp-r4/dp-r4-a-platform.jar "$PAYLOAD/"
cp build-dp-r4/dp-r4-b-platform.jar "$PAYLOAD/"
cp build-dp-r4/dp-r4-getrgb-collision-diagnostic.jar "$PAYLOAD/"
cp "$INPUT_SO" "$PAYLOAD/libm1_8_input.so"
cp "$PRESENTER_SO" "$PAYLOAD/libm1_9e_presenter.so"

cat >"$PAYLOAD/DP-R4-GETRGB-COLLISION-AB.sh" <<'SH'
#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R4-GETRGB-COLLISION-AB.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
A_TMP=/tmp/dp-r4-a.$$.log
B_TMP=/tmp/dp-r4-b.$$.log
trap 'rm -f "$A_TMP" "$B_TMP"' EXIT

: >"$OUT"
echo 'RG35XX DP-R4 PLATFORMIMAGE GETRGB A/B' >>"$OUT"
echo PRIMARY_VARIABLE=PLATFORMIMAGE_GETRGB_HEADLESS_ONLY >>"$OUT"

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

run_case() {
  LABEL="$1"
  PLATFORM="$2"
  TMP="$3"

  "$JAMVM" -Xmx64m     -cp "$GLIBJ:$PLATFORM:$FONTJAR"     org.recompile.mobile.M19CanvasLifecycleLauncher     "$APP/dp-r4-getrgb-collision-diagnostic.jar" >"$TMP" 2>&1
  RC=$?

  echo "===== CASE_$LABEL =====" >>"$OUT"
  cat "$TMP" >>"$OUT"
  echo "DP_R4_"$LABEL"_EXIT_CODE=$RC" >>"$OUT"

  if [ "$RC" = 0 ]    && grep -q 'DP_R4_DIRECT_GETRGB_EXACT=PASS' "$TMP"    && grep -q 'DP_R4_SAMEPOS_PIXEL_EXPECT_TRUE=PASS' "$TMP"    && grep -q 'DP_R4_OFFSET1_PIXEL_EXPECT_FALSE=PASS' "$TMP"    && grep -q 'DP_R4_FAR_COLLISION_EXPECT_FALSE=PASS' "$TMP"    && grep -q 'DP_R4_DIAGNOSTIC_GATE=PASS' "$TMP"    && grep -q 'DP_R4_RUNTIME_GATE=PASS' "$TMP"; then
    echo "DP_R4_"$LABEL"_RUNTIME_GATE=PASS" >>"$OUT"
    return 0
  fi

  echo "DP_R4_"$LABEL"_RUNTIME_GATE=FAIL" >>"$OUT"
  return 1
}

A_PASS=NO
B_PASS=NO

if run_case A "$APP/dp-r4-a-platform.jar" "$A_TMP"; then A_PASS=YES; fi
if run_case B "$APP/dp-r4-b-platform.jar" "$B_TMP"; then B_PASS=YES; fi

JA="$(sha256sum "$JAMVM"|awk '{print $1}')"
GA="$(sha256sum "$GLIBJ"|awk '{print $1}')"
echo JAMVM_SHA256_AFTER="$JA" >>"$OUT"
echo GLIBJ_SHA256_AFTER="$GA" >>"$OUT"

if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
  echo PROTECTED_HASHES_AFTER=PASS >>"$OUT"
else
  echo PROTECTED_HASHES_AFTER=FAIL >>"$OUT"
fi

if [ "$A_PASS" = YES ]; then
  echo DP_R4_AB_RESULT=BASELINE_ALREADY_PASS >>"$OUT"
elif [ "$A_PASS" = NO ] && [ "$B_PASS" = YES ]; then
  echo DP_R4_AB_RESULT=PATCH_CONFIRMED >>"$OUT"
else
  echo DP_R4_AB_RESULT=PATCH_NOT_CONFIRMED >>"$OUT"
fi

echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"
echo STABLE=NO >>"$OUT"
sync

if [ "$B_PASS" = YES ] && grep -q 'PROTECTED_HASHES_AFTER=PASS' "$OUT"; then
  exit 0
fi
exit 2
SH
chmod +x "$PAYLOAD/DP-R4-GETRGB-COLLISION-AB.sh"

cat >out/dp-r4/Roms/APPS/DP-R4-01-GETRGB-COLLISION-AB.sh <<'SH'
#!/bin/sh
exec /bin/sh /mnt/mmc/Roms/APPS/RG35XX-JAVA-DP-R4/DP-R4-GETRGB-COLLISION-AB.sh
SH
chmod +x out/dp-r4/Roms/APPS/DP-R4-01-GETRGB-COLLISION-AB.sh

cat >"$PAYLOAD/README.txt" <<'TXT'
RG35XX DP-R4 PlatformImage getRGB A/B
A = exact DP-R3-B runtime.
B = only PlatformImage.getRGB gains a headless int[] backing path.
Diagnostic uses square 2x2 images to isolate getRGB and avoid rectangular width/height-order issues.
No Sprite collision math, TiledLayer, LayerManager, audio, input, SDL1, JamVM or glibj changes.
Run DP-R4-01-GETRGB-COLLISION-AB from GarlicOS APPS.
Result: /mnt/mmc/RG35XX-DP-R4-GETRGB-COLLISION-AB.txt
DEVICE-PASS=NO until real-device review.
STABLE=NO
TXT

{
echo RG35XX_DP_R4_PLATFORMIMAGE_GETRGB_AB
echo BASELINE=DP_R3_B_DRAWREGION_DEVICE_PASS_SCOPED
echo PRIMARY_VARIABLE=PLATFORMIMAGE_GETRGB_HEADLESS_ONLY
echo A_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r4-a-platform.jar"|awk '{print $1}')"
echo B_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r4-b-platform.jar"|awk '{print $1}')"
echo DIAGNOSTIC_JAR_SHA256="$(sha256sum "$PAYLOAD/dp-r4-getrgb-collision-diagnostic.jar"|awk '{print $1}')"
echo INPUT_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_8_input.so"|awk '{print $1}')"
echo PRESENTER_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_9e_presenter.so"|awk '{print $1}')"
echo JAMVM_REQUIRED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
echo GLIBJ_REQUIRED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/dp-r4/BUILD-IDENTITY.txt

cp docs/DP-R4-PLATFORMIMAGE-GETRGB-AB.md out/dp-r4/
(cd out/dp-r4 && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) >out/dp-r4/SHA256SUMS.txt
(cd out/dp-r4 && sha256sum -c SHA256SUMS.txt)

echo RG35XX_DP_R4_BUILD_GATE=PASS
cat out/dp-r4/BUILD-IDENTITY.txt
