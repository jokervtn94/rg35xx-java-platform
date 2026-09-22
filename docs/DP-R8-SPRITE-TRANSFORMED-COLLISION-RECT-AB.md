# DP-R8 Sprite transformed collision rectangle A/B

CURRENT_SYMPTOM:
- DP-R7-B removed all transformed pixel-collision exceptions and improved the diagnostic from 1/8 to 6/8 transforms.
- Only TRANS_ROT270 and TRANS_MIRROR_ROT90 still return a false negative for same-position pixel collision.
- Their offset-1 and far collision gates already pass.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R3-B Sprite.paint/drawRegion: DEVICE-PASS scoped.
- DP-R4-B PlatformImage.getRGB headless: DEVICE-PASS scoped.
- DP-R5-B untransformed Sprite pixel collision: DEVICE-PASS scoped.
- DP-R7-B upstream93d collision core: PARTIAL_DEVICE_EVIDENCE 6/8, not DEVICE-PASS.

REFERENCE:
- J2ME-Loader maintains transformed collision-rectangle bounds separately from raw collisionRectX/Y/Width/Height.
- For 90/270-degree transforms, the transformed collision rectangle swaps width/height and adjusts its origin.
- The pinned FreeJ2ME Sprite swaps Sprite width/height but continues using the raw collision rectangle in Sprite-vs-Sprite collision.

REGRESSION_RISK:
- High if TiledLayer, collidesWith(Image), edge-touch semantics, rendering, PlatformImage, audio, input, SDL1, JamVM or glibj are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact rebuilt DP-R7-B runtime.
- B: only Sprite-vs-Sprite collision uses transform-aware collision rectangle geometry.
- Add one private helper that maps raw collision rectangle to transformed x/y/width/height.
- Do NOT change:
  * per-pixel helper core from DP-R7
  * TiledLayer collision
  * collidesWith(Image)
  * edge-touch semantics
  * Sprite rendering
  * PlatformImage/PlatformGraphics
  * audio/input/SDL1/JamVM/glibj

EXPECTED_DEVICE_TEST:
- A reproduces DP-R7-B: 6/8 transforms.
- B passes 8/8 transforms using the exact same DP-R6 diagnostic.
- ROT270 same-position pixel TRUE.
- MIRROR_ROT90 same-position pixel TRUE.
- Existing six passing transforms remain PASS.
- No exceptions.
- protected JamVM/glibj hashes unchanged.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
