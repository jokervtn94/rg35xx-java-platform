# DP-R6 Sprite transformed pixel collision diagnostic

CURRENT_SYMPTOM:
- DP-R5-B is real-device PASS for untransformed Sprite pixel collision, including non-square overlap.
- Pixel collision under Sprite transforms is not yet admitted.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R3-B: Sprite.paint()/drawRegion across all 8 transforms = DEVICE-PASS scoped.
- DP-R4-B: headless PlatformImage.getRGB = DEVICE-PASS scoped.
- DP-R5-B: Sprite.getARGBData width/height order = DEVICE-PASS scoped.

PREVIOUS_EVIDENCE_LEVEL:
- Transformed Sprite rendering: DEVICE-PASS scoped.
- Untransformed Sprite pixel collision: DEVICE-PASS scoped.
- Transformed Sprite pixel collision: UNVERIFIED.

REGRESSION_RISK:
- High if we modify Sprite collision math before proving a transformed collision failure exists.

MINIMAL_PROPOSED_CHANGE:
- NO runtime change.
- Rebuild the exact DP-R5-B runtime.
- Add one diagnostic MIDlet only.
- Exercise all 8 Sprite transforms on a non-square 3x2 sparse-alpha source image.
- For each transform:
  1. same-position identical sprites => pixel collision TRUE
  2. x-offset 1 => bounding collision TRUE, pixel collision FALSE
  3. far separation => bounding FALSE, pixel FALSE
- Do not modify Sprite, PlatformImage, PlatformGraphics, TiledLayer, LayerManager, audio, input, SDL1, JamVM, glibj or font.

EXPECTED_DEVICE_TEST:
- 8/8 transforms pass all same/offset/far gates.
- no exception from getARGBData/getRGB/collision transform math.
- JamVM/glibj hashes unchanged.
- normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
