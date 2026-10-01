#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/out/a8-comp02-filltriangle-boundary"
OUT="$ROOT/out/a8-comp02-device-package"
PAYLOAD="$OUT/RG35XX-A8-COMP02-FILLTRIANGLE"
LAUNCHER="$ROOT/packaging/a8-comp02/RG35XX-A8-COMP02-FILLTRIANGLE.sh"
fail(){ echo "A8_COMP02_DEVICE_PACKAGE_FAIL=$*" >&2; exit 1; }

for f in freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so libaudio.so A8-COMP02-FILLTRIANGLE-IDENTITY.txt; do
  [ -f "$SRC/$f" ] || fail "candidate artifact missing: $f"
done
[ -f "$LAUNCHER" ] || fail "candidate launcher missing"

grep -q '^BUILD-PASS=YES$' "$SRC/A8-COMP02-FILLTRIANGLE-IDENTITY.txt" || fail BUILD_NOT_PASS
grep -q '^DEVICE-PASS=NO$' "$SRC/A8-COMP02-FILLTRIANGLE-IDENTITY.txt" || fail DEVICE_STATUS_NOT_PENDING

test "$(sha256sum "$SRC/librg35xx_input.so"|awk '{print $1}')" = 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d || fail INPUT_IDENTITY
test "$(sha256sum "$SRC/librg35xx_video.so"|awk '{print $1}')" = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d || fail VIDEO_IDENTITY
test "$(sha256sum "$SRC/libaudio.so"|awk '{print $1}')" = 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644 || fail AUDIO_IDENTITY

PLATFORM_SHA="$(sha256sum "$SRC/freej2me-rg35xx.jar"|awk '{print $1}')"
RECORDED_SHA="$(awk -F= '$1=="CANDIDATE_PLATFORM_JAR_SHA256"{print $2}' "$SRC/A8-COMP02-FILLTRIANGLE-IDENTITY.txt")"
[ -n "$RECORDED_SHA" ] && [ "$PLATFORM_SHA" = "$RECORDED_SHA" ] || fail CANDIDATE_PLATFORM_IDENTITY

rm -rf "$OUT"
mkdir -p "$PAYLOAD"
cp "$SRC/freej2me-rg35xx.jar" "$SRC/librg35xx_input.so" "$SRC/librg35xx_video.so" "$SRC/libaudio.so" "$PAYLOAD/"
cp "$SRC/A8-COMP02-FILLTRIANGLE-IDENTITY.txt" "$PAYLOAD/"
cp "$SRC/CANDIDATE-SCOPE.txt" "$PAYLOAD/"
cp "$LAUNCHER" "$OUT/RG35XX-A8-COMP02-FILLTRIANGLE.sh"
sed -i "s/__CANDIDATE_PLATFORM_SHA__/$PLATFORM_SHA/g" "$OUT/RG35XX-A8-COMP02-FILLTRIANGLE.sh"
grep -q "^EXPECTED_PLATFORM=$PLATFORM_SHA$" "$OUT/RG35XX-A8-COMP02-FILLTRIANGLE.sh" || fail LAUNCHER_PLATFORM_BIND
chmod +x "$OUT/RG35XX-A8-COMP02-FILLTRIANGLE.sh"

head -c 123480 /dev/zero > "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le"
test "$(sha256sum "$PAYLOAD/a7-a1p5-rw-silence-prime.s32le"|awk '{print $1}')" = 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e || fail PRIME_IDENTITY

cat > "$PAYLOAD/RUNTIME-SHA256SUMS.txt" <<EOF
$PLATFORM_SHA  freej2me-rg35xx.jar
69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d  librg35xx_input.so
c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d  librg35xx_video.so
4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644  libaudio.so
8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e  a7-a1p5-rw-silence-prime.s32le
EOF
(cd "$PAYLOAD" && sha256sum -c RUNTIME-SHA256SUMS.txt)

cat > "$OUT/DEVICE-TEST-INSTRUCTIONS.txt" <<EOF
RG35XX A8 COMP-02 FILLTRIANGLE BOUNDARY ONLY
STATUS: EXPERIMENTAL / DEVICE-PASS=NO

1. Copy BOTH items from this package to /mnt/mmc/ on the original RG35XX:
   - RG35XX-A8-COMP02-FILLTRIANGLE.sh
   - RG35XX-A8-COMP02-FILLTRIANGLE/

2. Keep the exact original target game JAR unchanged. Expected SHA256:
   b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b

3. Run:
   sh /mnt/mmc/RG35XX-A8-COMP02-FILLTRIANGLE.sh "/full/path/to/Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar"

4. Physically observe and report only what is seen/heard:
   - Does the game pass the exact pre-patch transition where fillTriangle caused the hidden exit?
   - Display/splash/background status.
   - Input responsiveness.
   - Gameplay progression / hang or crash.
   - Exit behavior.
   - Audible audio if the tested section uses audio.

5. Return this file from the SD card:
   /mnt/mmc/RG35XX-A8-COMP02-FILLTRIANGLE-RESULT.txt

Do NOT replace A8 production with this candidate. Tier-0 Vua Cuop Bien and God of War physical regressions remain mandatory before any promotion consideration.
EOF

cat > "$OUT/PACKAGE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=A8-COMP02-FILLTRIANGLE-PHYSICAL-TEST-PACKAGE
PRODUCTION_PARENT=A8_GOLDEN_ONLY
CANDIDATE_PLATFORM_SHA256=$PLATFORM_SHA
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
TARGET_JAR_BUNDLED=NO
BUILD-PASS=YES
DEVICE-PASS=NO
PHYSICAL-TEST=PENDING
STABLE=NO
EOF

(
  cd "$OUT"
  find . -type f ! -name 'PACKAGE-SHA256SUMS.txt' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > PACKAGE-SHA256SUMS.txt
  sha256sum -c PACKAGE-SHA256SUMS.txt
)

echo A8_COMP02_DEVICE_PACKAGE_BUILD=PASS
cat "$OUT/PACKAGE-IDENTITY.txt"
