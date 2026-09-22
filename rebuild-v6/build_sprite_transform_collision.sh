#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}

rm -rf build-dp-r6 out/dp-r6
mkdir -p build-dp-r6/midlet build-dp-r6/manifest out/dp-r6/Roms/APPS/RG35XX-JAVA-DP-R6

# Rebuild exact DP-R5 A/B. The admitted runtime is DP-R5-B.
bash rebuild-v5/build_sprite_collision_ab.sh

PLATFORM=out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5/dp-r5-b-platform.jar
INPUT_SO=out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5/libm1_8_input.so
PRESENTER_SO=out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5/libm1_9e_presenter.so

test -f "$PLATFORM" -a -f "$INPUT_SO" -a -f "$PRESENTER_SO"

"$JAVA8/bin/javac" -source 1.5 -target 1.5 -bootclasspath "$JAVA8/jre/lib/rt.jar"   -classpath "$PLATFORM"   -d build-dp-r6/midlet   rebuild-v6/DP6SpriteTransformCollisionDiagnosticMIDlet.java

cat >build-dp-r6/manifest/dp-r6.mf <<'MF'
Manifest-Version: 1.0
MIDlet-1: DP-R6 Sprite Transform Collision,,org.recompile.mobile.DP6SpriteTransformCollisionDiagnosticMIDlet
MIDlet-Name: DP-R6 Sprite Transform Collision
MIDlet-Vendor: RG35XX
MIDlet-Version: 1.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
MF

"$JAVA8/bin/jar" cfm build-dp-r6/dp-r6-sprite-transform-collision.jar   build-dp-r6/manifest/dp-r6.mf -C build-dp-r6/midlet .

python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [
    Path('out/dp-r5/Roms/APPS/RG35XX-JAVA-DP-R5/dp-r5-b-platform.jar'),
    Path('build-dp-r6/dp-r6-sprite-transform-collision.jar')
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

PAYLOAD=out/dp-r6/Roms/APPS/RG35XX-JAVA-DP-R6
cp "$PLATFORM" "$PAYLOAD/dp-r6-platform.jar"
cp build-dp-r6/dp-r6-sprite-transform-collision.jar "$PAYLOAD/"
cp "$INPUT_SO" "$PAYLOAD/libm1_8_input.so"
cp "$PRESENTER_SO" "$PAYLOAD/libm1_9e_presenter.so"

cat >"$PAYLOAD/DP-R6-SPRITE-TRANSFORM-COLLISION.sh" <<'SH'
#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R6-SPRITE-TRANSFORM-COLLISION.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

: >"$OUT"
echo 'RG35XX DP-R6 SPRITE TRANSFORM PIXEL COLLISION' >>"$OUT"
echo PRIMARY_VARIABLE=DIAGNOSTIC_ONLY_NO_RUNTIME_CHANGE >>"$OUT"

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

"$JAMVM" -Xmx64m   -cp "$GLIBJ:$APP/dp-r6-platform.jar:$FONTJAR"   org.recompile.mobile.M19CanvasLifecycleLauncher   "$APP/dp-r6-sprite-transform-collision.jar" >>"$OUT" 2>&1
RC=$?

echo DP_R6_EXIT_CODE="$RC" >>"$OUT"

JA="$(sha256sum "$JAMVM"|awk '{print $1}')"
GA="$(sha256sum "$GLIBJ"|awk '{print $1}')"
echo JAMVM_SHA256_AFTER="$JA" >>"$OUT"
echo GLIBJ_SHA256_AFTER="$GA" >>"$OUT"

if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
  echo PROTECTED_HASHES_AFTER=PASS >>"$OUT"
else
  echo PROTECTED_HASHES_AFTER=FAIL >>"$OUT"
fi

if [ "$RC" = 0 ]  && grep -q 'DP_R6_TRANSFORM_COUNT=8' "$OUT"  && grep -q 'DP_R6_TRANSFORM_PASS_COUNT=8' "$OUT"  && grep -q 'DP_R6_DIAGNOSTIC_GATE=PASS' "$OUT"  && grep -q 'DP_R6_RUNTIME_GATE=PASS' "$OUT"  && grep -q 'PROTECTED_HASHES_AFTER=PASS' "$OUT"; then
  echo DP_R6_DEVICE_GATE=PASS >>"$OUT"
else
  echo DP_R6_DEVICE_GATE=FAIL >>"$OUT"
fi

echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"
echo STABLE=NO >>"$OUT"
sync
exit "$RC"
SH
chmod +x "$PAYLOAD/DP-R6-SPRITE-TRANSFORM-COLLISION.sh"

cat >out/dp-r6/Roms/APPS/DP-R6-01-SPRITE-TRANSFORM-COLLISION.sh <<'SH'
#!/bin/sh
exec /bin/sh /mnt/mmc/Roms/APPS/RG35XX-JAVA-DP-R6/DP-R6-SPRITE-TRANSFORM-COLLISION.sh
SH
chmod +x out/dp-r6/Roms/APPS/DP-R6-01-SPRITE-TRANSFORM-COLLISION.sh

cat >"$PAYLOAD/README.txt" <<'TXT'
RG35XX DP-R6 Sprite transformed pixel collision diagnostic
Runtime change: NONE.
Platform = exact freshly rebuilt DP-R5-B.
Diagnostic exercises all 8 MIDP Sprite transforms using a non-square sparse-alpha source:
same-position pixel TRUE, x-offset bounding TRUE + pixel FALSE, far FALSE.
No TiledLayer, LayerManager or audio changes.
Run DP-R6-01-SPRITE-TRANSFORM-COLLISION from GarlicOS APPS.
Result: /mnt/mmc/RG35XX-DP-R6-SPRITE-TRANSFORM-COLLISION.txt
DEVICE-PASS=NO until real-device review.
STABLE=NO
TXT

{
echo RG35XX_DP_R6_SPRITE_TRANSFORM_COLLISION
echo BASELINE=DP_R5_B_DEVICE_PASS_SCOPED
echo PRIMARY_VARIABLE=DIAGNOSTIC_ONLY_NO_RUNTIME_CHANGE
echo RUNTIME_CHANGE=NONE
echo PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r6-platform.jar"|awk '{print $1}')"
echo DIAGNOSTIC_JAR_SHA256="$(sha256sum "$PAYLOAD/dp-r6-sprite-transform-collision.jar"|awk '{print $1}')"
echo INPUT_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_8_input.so"|awk '{print $1}')"
echo PRESENTER_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_9e_presenter.so"|awk '{print $1}')"
echo JAMVM_REQUIRED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
echo GLIBJ_REQUIRED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/dp-r6/BUILD-IDENTITY.txt

cp docs/DP-R6-SPRITE-TRANSFORM-COLLISION-DIAGNOSTIC.md out/dp-r6/
(cd out/dp-r6 && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) >out/dp-r6/SHA256SUMS.txt
(cd out/dp-r6 && sha256sum -c SHA256SUMS.txt)

echo RG35XX_DP_R6_BUILD_GATE=PASS
cat out/dp-r6/BUILD-IDENTITY.txt
