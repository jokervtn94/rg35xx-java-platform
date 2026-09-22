# DP-R4 PlatformImage getRGB A/B — DEVICE EVIDENCE

Real-device evidence date: 2026-09-22

## CASE A — exact DP-R3-B baseline

Observed:
- direct PlatformImage.getRGB: FAIL with NullPointerException in PlatformImage.getRGB
- same-position Sprite bounding collision: PASS
- same-position pixel collision: FAIL with NullPointerException via PlatformImage.getRGB
- offset-1 bounding collision: PASS
- offset-1 pixel collision: FAIL with NullPointerException via PlatformImage.getRGB
- far collision false: PASS
- runtime gate: FAIL

## CASE B — headless PlatformImage.getRGB only

Observed:
- direct PlatformImage.getRGB return: PASS
- direct PlatformImage.getRGB exact ARGB data: PASS
- same-position bounding collision: PASS
- same-position pixel collision expected true: PASS
- offset-1 bounding collision: PASS
- offset-1 pixel collision: FAIL with IllegalArgumentException:
  getRGB Requested area exceeds bounds of the image
- far collision false: PASS
- runtime gate: FAIL
- protected JamVM/glibj hashes: PASS before and after

Final A/B marker:
- DP_R4_AB_RESULT=PATCH_NOT_CONFIRMED

## Interpretation

The DP-R4 patch is validated only for the PlatformImage.getRGB headless backing boundary:
- A failed direct getRGB because the headless image had no AWT canvas.
- B returned exact expected ARGB pixels.
- B also allowed the same-position pixel-collision path to progress and return the expected true result.

The overall DP-R4 collision checkpoint is NOT DEVICE-PASS because the offset-1 pixel collision still fails downstream.

The next isolated suspect is in Sprite.getARGBData(), which currently calls:

`image.getRGB(argbData, 0, width, xOffset, yOffset, height, width)`

The final two arguments are reversed relative to the getRGB signature `(..., width, height)`. For the offset overlap in this real-device test, the intersection is non-square, exposing the reversal as an out-of-bounds request.

## Status

DP-R4-PLATFORMIMAGE-GETRGB=DEVICE-PASS_SCOPED
DP-R4-OVERALL=DEVICE-FAIL_DOWNSTREAM
SPRITE-PIXEL-COLLISION=NOT_PASS
BUILD-PASS=YES
FULL_PLATFORM_STABLE=NO
