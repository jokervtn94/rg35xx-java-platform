#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC_UPSTREAM:?set VC_UPSTREAM to pinned FreeJ2ME checkout}"
: "${VC7_ASSEMBLY:?set VC7_ASSEMBLY to disposable VC7 output directory}"
: "${VC7_GOLDEN_RUNTIME:?set VC7_GOLDEN_RUNTIME to device-proven Golden freej2me-lr.jar}"

fail() { echo "VC7 FONT FAIL: $*" >&2; exit 1; }
note() { echo "VC7 FONT: $*"; }

# VC7 is layered strictly on VC6. PNG iCCP compatibility, B4 observability,
# Golden async video and lazy media must therefore be present before font work.
VC_UPSTREAM="$VC_UPSTREAM" VC6_ASSEMBLY="$VC7_ASSEMBLY" sh "$ROOT/scripts/vc6_png_iccp_assemble.sh"

IMAGE="$VC7_ASSEMBLY/src/org/recompile/mobile/PlatformGraphics.java"
FONT_OUT="$VC7_ASSEMBLY/resources/org/recompile/mobile/rg35xx-font.bin"
[ -f "$IMAGE" ] || fail "PlatformGraphics.java missing"

# Materialize the exact Golden resource first. The preflight intentionally runs
# BEFORE changing PlatformGraphics so the pinned AWT boundary is verified rather
# than guessed after the fact.
python3 "$ROOT/scripts/vc7_extract_golden_font.py" "$VC7_GOLDEN_RUNTIME" "$FONT_OUT"
VC7_SOURCE="$VC7_ASSEMBLY" VC7_GOLDEN_FONT_BIN="$FONT_OUT" \
  sh "$ROOT/scripts/vc7_golden_font_preflight.sh"
python3 "$ROOT/scripts/vc7_apply_golden_font.py" "$IMAGE"

# Exact Golden resource must now be staged into the JAR resources tree.
[ -f "$FONT_OUT" ] || fail "font resource not staged"
[ "$(wc -c < "$FONT_OUT" | tr -d ' ')" = "727008" ] || fail "font resource size mismatch after stage"
FONT_SHA=$(sha256sum "$FONT_OUT" | awk '{print $1}')
[ "$FONT_SHA" = "7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c" ] || fail "font resource SHA mismatch after stage"

# Scope/admission gates.
grep -Fq 'RG35XX-VC7-FONT: Golden Unicode bitmap renderer' "$IMAGE" || fail "VC7 renderer marker missing"
grep -Fq 'rg35xxDrawSafeText(str, x, y - ascent, anchor);' "$IMAGE" || fail "normal text boundary not replaced"
! grep -Fq 'gc.drawString(str, x, y);' "$IMAGE" || fail "GNU AWT text raster remains in normal drawString path"
grep -Fq 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk' "$VC7_ASSEMBLY/src/org/recompile/mobile/PlatformImage.java" || fail "VC6 PNG compatibility lost"
grep -Fq 'RG35XX-MEDIA-BOOT: eager prepare SKIPPED; lazy media enabled' "$VC7_ASSEMBLY/src/org/recompile/mobile/MobilePlatform.java" || fail "lazy media lost"
grep -Fq 'RG35XXGoldenFrameTransport' "$VC7_ASSEMBLY/src/org/recompile/freej2me/Libretro.java" || fail "Golden frame transport lost"
grep -Fq 'B4 FIRST_FRAME_PUBLISH' "$VC7_ASSEMBLY/src/libretro/rg35xx/golden/rg35xx_golden_video.c" || fail "B4 video observability lost"

# Explicitly reject old font experiments from foundation assembly.
for bad in \
  'RG35XXMetricUnicodeText' \
  'RG35XXBitmapText' \
  'apply_rg35xx_font_overlay' \
  'apply_rg35xx_compound_glyph_fix' \
  'RG35XX-CV:' \
  'RG35XX-MediaWarmup'
do
  if grep -R -Fq "$bad" "$VC7_ASSEMBLY/src" 2>/dev/null; then
    fail "forbidden experiment present: $bad"
  fi
done

note "PASS: VC7 source assembled at $VC7_ASSEMBLY"
note "FONT_SHA256=$FONT_SHA"
