#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}

rm -rf build-dp-r5 out/dp-r5
mkdir -p build-dp-r5/midlet build-dp-r5/manifest out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5

# Rebuild exact DP-R4 A/B; upstream is left at DP-R4-B.
bash rebuild-v4/build_getrgb_ab.sh

A_PLATFORM=out/dp-r4/Roms/APPS/RG35XX-JAVA-DP-R4/dp-r4-b-platform.jar
INPUT_SO=out/dp-r4/Roms/APPS/RG35XX-JAVA-DP-R4/libm1_8_input.so
PRESENTER_SO=out/dp-r4/Roms/APPS/RG35XX-JAVA-DP-R4/libm1_9e_presenter.so

test -f "$A_PLATFORM" -a -f "$INPUT_SO" -a -f "$PRESENTER_SO"
cp "$A_PLATFORM" build-dp-r5/dp-r5-a-platform.jar

"$JAVA8/bin/javac" -source 1.5 -target 1.5 -bootclasspath "$JAVA8/jre/lib/rt.jar"   -classpath "$A_PLATFORM"   -d build-dp-r5/midlet   rebuild-v5/DP5SpritePixelCollisionDiagnosticMIDlet.java

cat >build-dp-r5/manifest/dp-r5.mf <<'MF'
Manifest-Version: 1.0
MIDlet-1: DP-R5 Sprite Pixel Collision AB,,org.recompile.mobile.DP5SpritePixelCollisionDiagnosticMIDlet
MIDlet-Name: DP-R5 Sprite Pixel Collision AB
MIDlet-Vendor: RG35XX
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

"$JAVA8/bin/jar" cfm build-dp-r5/dp-r5-sprite-pixel-collision.jar   build-dp-r5/manifest/dp-r5.mf -C build-dp-r5/midlet .

python3 rebuild-v5/patch_sprite_getargb_width_height_order.py
grep -q 'DP-R5 PRIMARY VARIABLE: pass getRGB width/height in API order'   upstream/src/javax/microedition/lcdui/game/Sprite.java

(cd upstream && JAVA_HOME="$JAVA8" ant -noinput -buildfile build.xml)
B_PLATFORM=upstream/build/freej2me_plus.jar
test -f "$B_PLATFORM"
cp "$B_PLATFORM" build-dp-r5/dp-r5-b-platform.jar

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

A=entries(Path('build-dp-r5/dp-r5-a-platform.jar'))
B=entries(Path('build-dp-r5/dp-r5-b-platform.jar'))
changed=sorted(n for n in set(A)|set(B) if A.get(n)!=B.get(n))
print('DP_R5_CHANGED_JAR_ENTRIES=' + ','.join(changed))
expected=['javax/microedition/lcdui/game/Sprite.class']
if changed != expected:
    raise SystemExit('DP_R5_SINGLE_CLASS_GATE=FAIL changed='+repr(changed))
print('DP_R5_SINGLE_CLASS_GATE=PASS')
PY

python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [
    Path('build-dp-r5/dp-r5-a-platform.jar'),
    Path('build-dp-r5/dp-r5-b-platform.jar'),
    Path('build-dp-r5/dp-r5-sprite-pixel-collision.jar')
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

PAYLOAD=out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5
cp build-dp-r5/dp-r5-a-platform.jar "$PAYLOAD/"
cp build-dp-r5/dp-r5-b-platform.jar "$PAYLOAD/"
cp build-dp-r5/dp-r5-sprite-pixel-collision.jar "$PAYLOAD/"
cp "$INPUT_SO" "$PAYLOAD/libm1_8_input.so"
cp "$PRESENTER_SO" "$PAYLOAD/libm1_9e_presenter.so"

cat >"$PAYLOAD/DP-R5-SPRITE-COLLISION-AB.sh" <<'SH'
#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R5-SPRITE-COLLISION-AB.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
A_TMP=/tmp/dp-r5-a.$$.log
B_TMP=/tmp/dp-r5-b.$$.log
trap 'rm -f "$A_TMP" "$B_TMP"' EXIT

: >"$OUT"
echo 'RG35XX DP-R5 SPRITE GETARGB WIDTH-HEIGHT A/B' >>"$OUT"
echo PRIMARY_VARIABLE=SPRITE_GETARGBDATA_WIDTH_HEIGHT_ORDER_ONLY >>"$OUT"

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

  "$JAMVM" -Xmx64m     -cp "$GLIBJ:$PLATFORM:$FONTJAR"     org.recompile.mobile.M19CanvasLifecycleLauncher     "$APP/dp-r5-sprite-pixel-collision.jar" >"$TMP" 2>&1
  RC=$?

  echo "===== CASE_$LABEL =====" >>"$OUT"
  cat "$TMP" >>"$OUT"
  echo "DP_R5_"$LABEL"_EXIT_CODE=$RC" >>"$OUT"

  if [ "$RC" = 0 ]    && grep -q 'DP_R5_SAMEPOS_PIXEL_TRUE=PASS' "$TMP"    && grep -q 'DP_R5_OFFSET1_PIXEL_FALSE=PASS' "$TMP"    && grep -q 'DP_R5_RECT_X_PIXEL_FALSE=PASS' "$TMP"    && grep -q 'DP_R5_RECT_Y_PIXEL_FALSE=PASS' "$TMP"    && grep -q 'DP_R5_NON_SQUARE_OVERLAPS=2' "$TMP"    && grep -q 'DP_R5_DIAGNOSTIC_GATE=PASS' "$TMP"    && grep -q 'DP_R5_RUNTIME_GATE=PASS' "$TMP"; then
    echo "DP_R5_"$LABEL"_RUNTIME_GATE=PASS" >>"$OUT"
    return 0
  fi

  echo "DP_R5_"$LABEL"_RUNTIME_GATE=FAIL" >>"$OUT"
  return 1
}

A_PASS=NO
B_PASS=NO

if run_case A "$APP/dp-r5-a-platform.jar" "$A_TMP"; then A_PASS=YES; fi
if run_case B "$APP/dp-r5-b-platform.jar" "$B_TMP"; then B_PASS=YES; fi

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
  echo DP_R5_AB_RESULT=BASELINE_ALREADY_PASS >>"$OUT"
elif [ "$A_PASS" = NO ] && [ "$B_PASS" = YES ]; then
  echo DP_R5_AB_RESULT=PATCH_CONFIRMED >>"$OUT"
else
  echo DP_R5_AB_RESULT=PATCH_NOT_CONFIRMED >>"$OUT"
fi

echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"
echo STABLE=NO >>"$OUT"
sync

if [ "$B_PASS" = YES ] && grep -q 'PROTECTED_HASHES_AFTER=PASS' "$OUT"; then
  exit 0
fi
exit 2
SH
chmod +x "$PAYLOAD/DP-R5-SPRITE-COLLISION-AB.sh"

cat >out/dp-r5/Roms/APPS/DP-R5-01-SPRITE-COLLISION-AB.sh <<'SH'
#!/bin/sh
exec /bin/sh /mnt/mmc/Roms/APPS/RG35XX-JAVA-DP-R5/DP-R5-SPRITE-COLLISION-AB.sh
SH
chmod +x out/dp-r5/Roms/APPS/DP-R5-01-SPRITE-COLLISION-AB.sh

cat >"$PAYLOAD/README.txt" <<'TXT'
RG35XX DP-R5 Sprite getARGBData width/height A/B
A = exact DP-R4-B runtime.
B = one-line Sprite.getARGBData getRGB width/height order fix.
No other Sprite logic, PlatformImage behavior, TiledLayer, LayerManager, audio, input, SDL1, JamVM or glibj changes.
Run DP-R5-01-SPRITE-COLLISION-AB from GarlicOS APPS.
Result: /mnt/mmc/RG35XX-DP-R5-SPRITE-COLLISION-AB.txt
DEVICE-PASS=NO until real-device review.
STABLE=NO
TXT

{
echo RG35XX_DP_R5_SPRITE_GETARGB_WH_ORDER_AB
echo BASELINE=DP_R4_B_GETRGB_DEVICE_PASS_SCOPED
echo PRIMARY_VARIABLE=SPRITE_GETARGBDATA_WIDTH_HEIGHT_ORDER_ONLY
echo A_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r5-a-platform.jar"|awk '{print $1}')"
echo B_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r5-b-platform.jar"|awk '{print $1}')"
echo DIAGNOSTIC_JAR_SHA256="$(sha256sum "$PAYLOAD/dp-r5-sprite-pixel-collision.jar"|awk '{print $1}')"
echo INPUT_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_8_input.so"|awk '{print $1}')"
echo PRESENTER_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_9e_presenter.so"|awk '{print $1}')"
echo JAMVM_REQUIRED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
echo GLIBJ_REQUIRED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/dp-r5/BUILD-IDENTITY.txt

cp docs/DP-R5-SPRITE-GETARGB-WH-ORDER-AB.md out/dp-r5/
(cd out/dp-r5 && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) >out/dp-r5/SHA256SUMS.txt
(cd out/dp-r5 && sha256sum -c SHA256SUMS.txt)

echo RG35XX_DP_R5_BUILD_GATE=PASS
cat out/dp-r5/BUILD-IDENTITY.txt
