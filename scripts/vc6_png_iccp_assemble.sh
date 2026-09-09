#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${VC6_ASSEMBLY:?set VC6_ASSEMBLY to disposable VC6 output directory}"

fail() { echo "VC6 PNG ICCP FAIL: $*" >&2; exit 1; }
note() { echo "VC6 PNG ICCP: $*"; }

# Start from the exact current B4 observed foundation, including trustworthy
# early-native and first-frame observability.
VC_UPSTREAM="$VC_UPSTREAM" B4_ASSEMBLY="$VC6_ASSEMBLY" sh "$ROOT/scripts/b4_verified_core_assemble.sh"

IMAGE="$VC6_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java"
[ -f "$IMAGE" ] || fail "PlatformImage.java missing"
python3 "$ROOT/scripts/vc6_apply_png_iccp_compat.py" "$IMAGE"

# Positive scope gate: exactly the source-level image boundary is admitted.
grep -Fq 'rg35xxPngIccpCompat' "$IMAGE" || fail "compat helper missing"
grep -Fq 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk' "$IMAGE" || fail "device evidence marker missing"
[ "$(grep -Fc 'ImageIO.read(rg35xxPngIccpCompat(stream))' "$IMAGE")" -eq 3 ] || fail "three decode boundaries not guarded"

# Foundation semantics must still exist.
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$VC6_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" || fail "lazy media lost"
grep -Fq 'RG35XXGoldenFrameTransport' "$VC6_ASSEMBLY/src/org/recompile/freej2me/Libretro.java" || fail "Golden transport lost"
grep -Fq 'B4 FIRST_FRAME_PUBLISH' "$VC6_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c" || fail "video observability lost"

# GNU Classpath and old rejected experiments are never part of this stage.
for bad in \
  'rg35xxStripPngICCP' \
  'RG35XX-PNG-COMPAT-V2' \
  'PNGChunk.class' \
  'ProfileHeader.class' \
  'RG35XX-CV:' \
  'rg35xx_cv_' \
  'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$VC6_ASSEMBLY/src"; then
    fail "forbidden experiment present: $bad"
  fi
done

note "PASS: VC6 PNG iCCP source assembled at $VC6_ASSEMBLY"
