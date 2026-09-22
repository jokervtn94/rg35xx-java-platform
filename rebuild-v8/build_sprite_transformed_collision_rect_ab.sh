#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

JAVA8=${JAVA8:-/usr/lib/jvm/java-8-openjdk-amd64}

rm -rf build-dp-r8 out/dp-r8
mkdir -p build-dp-r8 out/dp-r8/Roms/APPS/RG35XX-JAVA-DP-R8

# Rebuild exact DP-R7 A/B. Upstream is left at DP-R7-B.
bash rebuild-v7/build_sprite_transform_collision_upstream93d_ab.sh

A_PLATFORM=out/dp-r7/Roms/APPS/RG35XX-JAVA-DP-R7/dp-r7-b-platform.jar
DIAG=out/dp-r7/Roms/APPS/RG35XX-JAVA-DP-R7/dp-r7-sprite-transform-collision.jar
INPUT_SO=out/dp-r7/Roms/APPS/RG35XX-JAVA-DP-R7/libm1_8_input.so
PRESENTER_SO=out/dp-r7/Roms/APPS/RG35XX-JAVA-DP-R7/libm1_9e_presenter.so

test -f "$A_PLATFORM" -a -f "$DIAG" -a -f "$INPUT_SO" -a -f "$PRESENTER_SO"
cp "$A_PLATFORM" build-dp-r8/dp-r8-a-platform.jar

python3 rebuild-v8/patch_sprite_transformed_collision_rect.py
grep -q 'DP-R8 PRIMARY VARIABLE:' upstream/src/javax/microedition/lcdui/game/Sprite.java

# Force JAR repack after Sprite.java compilation.
rm -f upstream/build/freej2me_plus.jar upstream/build/freej2me_plus-lr.jar
(cd upstream && JAVA_HOME="$JAVA8" ant -noinput -buildfile build.xml)

B_PLATFORM=upstream/build/freej2me_plus.jar
test -f "$B_PLATFORM"
cp "$B_PLATFORM" build-dp-r8/dp-r8-b-platform.jar

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

A=entries(Path('build-dp-r8/dp-r8-a-platform.jar'))
B=entries(Path('build-dp-r8/dp-r8-b-platform.jar'))
changed=sorted(n for n in set(A)|set(B) if A.get(n)!=B.get(n))
print('DP_R8_CHANGED_JAR_ENTRIES=' + ','.join(changed))
expected=['javax/microedition/lcdui/game/Sprite.class']
if changed != expected:
    raise SystemExit('DP_R8_SINGLE_CLASS_GATE=FAIL changed='+repr(changed))
print('DP_R8_SINGLE_CLASS_GATE=PASS')
PY

python3 - <<'PY'
from pathlib import Path
import zipfile
bad=[]
for jar in [
    Path('build-dp-r8/dp-r8-a-platform.jar'),
    Path('build-dp-r8/dp-r8-b-platform.jar'),
    Path('out/dp-r7/Roms/APPS/RG35XX-JAVA-DP-R7/dp-r7-sprite-transform-collision.jar')
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

PAYLOAD=out/dp-r8/Roms/APPS/RG35XX-JAVA-DP-R8
cp build-dp-r8/dp-r8-a-platform.jar "$PAYLOAD/"
cp build-dp-r8/dp-r8-b-platform.jar "$PAYLOAD/"
cp "$DIAG" "$PAYLOAD/dp-r8-sprite-transform-collision.jar"
cp "$INPUT_SO" "$PAYLOAD/libm1_8_input.so"
cp "$PRESENTER_SO" "$PAYLOAD/libm1_9e_presenter.so"

cat >"$PAYLOAD/DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh" <<'SH'
#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
A_TMP=/tmp/dp-r8-a.$$.log
B_TMP=/tmp/dp-r8-b.$$.log
trap 'rm -f "$A_TMP" "$B_TMP"' EXIT

: >"$OUT"
echo 'RG35XX DP-R8 SPRITE TRANSFORMED COLLISION RECT A/B' >>"$OUT"
echo PRIMARY_VARIABLE=SPRITE_VS_SPRITE_TRANSFORMED_COLLISION_RECT_ONLY >>"$OUT"

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

  "$JAMVM" -Xmx64m     -cp "$GLIBJ:$PLATFORM:$FONTJAR"     org.recompile.mobile.M19CanvasLifecycleLauncher     "$APP/dp-r8-sprite-transform-collision.jar" >"$TMP" 2>&1
  RC=$?

  echo "===== CASE_$LABEL =====" >>"$OUT"
  cat "$TMP" >>"$OUT"
  echo "DP_R8_"$LABEL"_EXIT_CODE=$RC" >>"$OUT"

  if [ "$RC" = 0 ]    && grep -q 'DP_R6_TRANSFORM_COUNT=8' "$TMP"    && grep -q 'DP_R6_TRANSFORM_PASS_COUNT=8' "$TMP"    && grep -q 'DP_R6_DIAGNOSTIC_GATE=PASS' "$TMP"    && grep -q 'DP_R6_RUNTIME_GATE=PASS' "$TMP"; then
    echo "DP_R8_"$LABEL"_RUNTIME_GATE=PASS" >>"$OUT"
    return 0
  fi

  echo "DP_R8_"$LABEL"_RUNTIME_GATE=FAIL" >>"$OUT"
  return 1
}

A_PASS=NO
B_PASS=NO

if run_case A "$APP/dp-r8-a-platform.jar" "$A_TMP"; then A_PASS=YES; fi
if run_case B "$APP/dp-r8-b-platform.jar" "$B_TMP"; then B_PASS=YES; fi

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
  echo DP_R8_AB_RESULT=BASELINE_ALREADY_PASS >>"$OUT"
elif [ "$A_PASS" = NO ] && [ "$B_PASS" = YES ]; then
  echo DP_R8_AB_RESULT=PATCH_CONFIRMED >>"$OUT"
else
  echo DP_R8_AB_RESULT=PATCH_NOT_CONFIRMED >>"$OUT"
fi

echo DEVICE_PASS=NO_REVIEW_PENDING >>"$OUT"
echo STABLE=NO >>"$OUT"
sync

if [ "$B_PASS" = YES ] && grep -q 'PROTECTED_HASHES_AFTER=PASS' "$OUT"; then
  exit 0
fi
exit 2
SH
chmod +x "$PAYLOAD/DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh"

cat >out/dp-r8/Roms/APPS/DP-R8-01-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh <<'SH'
#!/bin/sh
exec /bin/sh /mnt/mmc/Roms/APPS/RG35XX-JAVA-DP-R8/DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh
SH
chmod +x out/dp-r8/Roms/APPS/DP-R8-01-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh

cat >"$PAYLOAD/README.txt" <<'TXT'
RG35XX DP-R8 Sprite transformed collision rectangle A/B
A = exact rebuilt DP-R7-B runtime (known 6/8 transformed collision result).
B = A + Sprite-vs-Sprite transform-aware collision rectangle geometry only.
No TiledLayer collision, collidesWith(Image), edge-touch, rendering, PlatformImage,
audio, input, SDL1, JamVM or glibj changes.
Run DP-R8-01-SPRITE-TRANSFORMED-COLLISION-RECT-AB from GarlicOS APPS.
Result: /mnt/mmc/RG35XX-DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.txt
DEVICE-PASS=NO until real-device review.
STABLE=NO
TXT

{
echo RG35XX_DP_R8_SPRITE_TRANSFORMED_COLLISION_RECT_AB
echo BASELINE=DP_R7_B_PARTIAL_DEVICE_EVIDENCE_6_OF_8
echo PRIMARY_VARIABLE=SPRITE_VS_SPRITE_TRANSFORMED_COLLISION_RECT_ONLY
echo A_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r8-a-platform.jar"|awk '{print $1}')"
echo B_PLATFORM_SHA256="$(sha256sum "$PAYLOAD/dp-r8-b-platform.jar"|awk '{print $1}')"
echo DIAGNOSTIC_JAR_SHA256="$(sha256sum "$PAYLOAD/dp-r8-sprite-transform-collision.jar"|awk '{print $1}')"
echo INPUT_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_8_input.so"|awk '{print $1}')"
echo PRESENTER_SO_SHA256="$(sha256sum "$PAYLOAD/libm1_9e_presenter.so"|awk '{print $1}')"
echo JAMVM_REQUIRED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
echo GLIBJ_REQUIRED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
echo BUILD-PASS=YES
echo DEVICE-PASS=NO
echo DEVICE-TEST-PENDING=YES
echo STABLE=NO
} >out/dp-r8/BUILD-IDENTITY.txt

cp docs/DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.md out/dp-r8/
(cd out/dp-r8 && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum) >out/dp-r8/SHA256SUMS.txt
(cd out/dp-r8 && sha256sum -c SHA256SUMS.txt)

echo RG35XX_DP_R8_BUILD_GATE=PASS
cat out/dp-r8/BUILD-IDENTITY.txt
