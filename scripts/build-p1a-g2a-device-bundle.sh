#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P1A_G2A_DEVICE_BUNDLE_FAIL=$*" >&2; exit 1; }

PLATDIR="$ROOT/out/p1a-g2a-fillroundrect"
EXDIR="$ROOT/out/p1a-g2a-device-exerciser-jar"
OUT="$ROOT/out/p1a-g2a-device-bundle"
PLATFORM="$PLATDIR/freej2me-rg35xx.jar"
EXERCISER="$EXDIR/RG35XX-P1A-G2A-EXERCISER.jar"
PID="$PLATDIR/P1A-G2A-IDENTITY.txt"
EID="$EXDIR/IDENTITY.txt"
for f in "$PLATFORM" "$EXERCISER" "$PID" "$EID" "$PLATDIR/librg35xx_input.so" "$PLATDIR/librg35xx_video.so"; do
  [ -f "$f" ] || fail "missing $f"
done

PH=$(sha256sum "$PLATFORM"|awk '{print $1}')
EH=$(sha256sum "$EXERCISER"|awk '{print $1}')
IH=$(sha256sum "$PLATDIR/librg35xx_input.so"|awk '{print $1}')
VH=$(sha256sum "$PLATDIR/librg35xx_video.so"|awk '{print $1}')
ECP=$(sed -n 's/^BUILD_CLASSPATH_PLATFORM_SHA256=//p' "$EID")
[ "$PH" = "$ECP" ] || fail "exerciser/platform raw identity mismatch platform=$PH exerciser_classpath=$ECP"
grep -q '^CANDIDATE_PLATFORM_SEMANTIC_SHA256=1e33e7e37b0e0e5d3d0f836f8c29e80e28fb45c961f8fbb05f72af41de76ba51$' "$PID" || fail semantic
grep -q '^CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=e6e377425eb46461c42f4d16b2da77a6f4b287f5ca12add8a97e6869def434db$' "$PID" || fail class
grep -q '^CHANGED_METHODS=fillRoundRect$' "$PID" || fail method_scope
[ "$IH" = '69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d' ] || fail input
[ "$VH" = 'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d' ] || fail video

a=$(sed -n 's/^EXERCISER_JAR_SHA256=//p' "$EID")
[ "$EH" = "$a" ] || fail exerciser

rm -rf "$OUT"; mkdir -p "$OUT"
cp "$PLATFORM" "$OUT/freej2me-rg35xx.jar"
cp "$PLATDIR/librg35xx_input.so" "$OUT/librg35xx_input.so"
cp "$PLATDIR/librg35xx_video.so" "$OUT/librg35xx_video.so"
cp "$PID" "$OUT/P1A-G2A-HOST-IDENTITY.txt"
cp "$EXERCISER" "$OUT/RG35XX-P1A-G2A-EXERCISER.jar"
cp "$EID" "$OUT/EXERCISER-CI-IDENTITY.txt"
cat > "$OUT/BUNDLE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
WORK_UNIT=P1A-G2A-FILLROUNDRECT
ARTIFACT=DEVICE_BOUND_PLATFORM_PLUS_EXERCISER
PLATFORM_JAR_SHA256=$PH
PLATFORM_SEMANTIC_SHA256=1e33e7e37b0e0e5d3d0f836f8c29e80e28fb45c961f8fbb05f72af41de76ba51
PLATFORMGRAPHICS_CLASS_SHA256=e6e377425eb46461c42f4d16b2da77a6f4b287f5ca12add8a97e6869def434db
EXERCISER_JAR_SHA256=$EH
EXERCISER_BUILD_CLASSPATH_PLATFORM_SHA256=$ECP
INPUT_NATIVE_SHA256=$IH
VIDEO_NATIVE_SHA256=$VH
CHANGED_METHODS=fillRoundRect
G1_DEVICE_PARENT=ACCEPTED_EXTERNALLY_BEFORE_G2A_PHYSICAL
COMMERCIAL_GAME_DEPENDENCY=NO
BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
EOF
(
 cd "$OUT"
 sha256sum freej2me-rg35xx.jar librg35xx_input.so librg35xx_video.so RG35XX-P1A-G2A-EXERCISER.jar P1A-G2A-HOST-IDENTITY.txt EXERCISER-CI-IDENTITY.txt BUNDLE-IDENTITY.txt > SHA256SUMS.txt
 sha256sum -c SHA256SUMS.txt
)
echo P1A_G2A_DEVICE_BUNDLE=PASS
cat "$OUT/BUNDLE-IDENTITY.txt"
