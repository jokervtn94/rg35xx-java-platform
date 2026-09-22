# DP-R5 Sprite getARGBData width/height order A/B

CURRENT_SYMPTOM:
- DP-R4-B direct PlatformImage.getRGB is device-proven exact.
- Same-position pixel collision succeeds.
- Offset-1 pixel collision fails with IllegalArgumentException from PlatformImage.getRGB.
- The overlap at offset 1 is non-square, which exposes the dimensions passed by Sprite.getARGBData().

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R4 PlatformImage.getRGB headless int[] backing is DEVICE-PASS scoped.
- DP-R3-B Sprite.paint/drawRegion and all 8 transforms are DEVICE-PASS scoped.

PREVIOUS_EVIDENCE_LEVEL:
- PlatformImage.getRGB headless: DEVICE-PASS_SCOPED.
- Sprite pixel collision: NOT_PASS.

REGRESSION_RISK:
- High if collision geometry, transforms, TiledLayer, LayerManager, renderer, audio, input, SDL1, JamVM, glibj, or font are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact rebuilt DP-R4-B runtime.
- B: one-line fix in Sprite.getARGBData():
  image.getRGB(..., xOffset, yOffset, height, width)
  -> image.getRGB(..., xOffset, yOffset, width, height)
- No other Sprite logic changes.
- No PlatformImage changes beyond the already admitted DP-R4 patch.

EXPECTED_DEVICE_TEST:
- A must reproduce offset-1 pixel collision failure.
- B must pass same-position collision TRUE.
- B must pass offset-1 bounding TRUE + pixel FALSE without exception.
- B must pass far collision FALSE.
- B must pass an explicit rectangular overlap case that exercises width != height.
- JamVM/glibj hashes unchanged.
- Normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
