# DP-R7 Sprite transformed pixel collision upstream-93d A/B

CURRENT_SYMPTOM:
- DP-R6 diagnostic-only runtime reproduced transformed pixel-collision failures on real RG35XX.
- TRANS_NONE passed all gates.
- 7 transformed modes failed with either:
  - IllegalArgumentException from PlatformImage.getRGB out-of-bounds, or
  - ArrayIndexOutOfBoundsException with negative indices in Sprite.checkPixCollision().
- Protected JamVM/glibj identities remained unchanged.

HISTORY_FOUND=YES

UPSTREAM_REFERENCE:
- FreeJ2ME-Plus commit:
  93d866ef7836b4aa6be89d58e1919bcc05c9bb3f
- Date: 2026-09-15
- Commit message states that bugs in per-pixel sprite collision were fixed.
- The relevant upstream change rewrites only the transformed pixel-collision helper logic:
  checkPixCollision()
  getSpriteIncrAndStartPos()
  and removes the old getARGBData helper from that path.

PREVIOUS_FIX:
- DP-R3-B Sprite paint/drawRegion: DEVICE-PASS scoped.
- DP-R4-B PlatformImage.getRGB headless: DEVICE-PASS scoped.
- DP-R5-B Sprite getARGBData width/height order: DEVICE-PASS scoped.
- DP-R6 transformed pixel collision: DEVICE-FAIL, 1/8 transforms passed.

PREVIOUS_EVIDENCE_LEVEL:
- Untransformed Sprite pixel collision: DEVICE-PASS scoped.
- Transformed Sprite pixel collision: DEVICE-FAIL.

REGRESSION_RISK:
- High if edge-touch semantics, collidesWith(Image), TiledLayer, LayerManager,
  renderer, PlatformImage, audio, input, SDL1, JamVM or glibj are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact rebuilt DP-R5-B runtime.
- B: backport only the collision-helper core from upstream commit 93d866ef:
  * checkPixCollision()
  * getSpriteIncrAndStartPos()
- Do NOT backport later commit d7bb54da changes yet.
- No edge-touch semantic change.
- No collidesWith(Image) coordinate fix.
- No TiledLayer/LayerManager change.

EXPECTED_DEVICE_TEST:
- A reproduces DP-R6 transformed collision failures.
- B passes all 8 transforms:
  same-position pixel TRUE,
  x-offset bounding TRUE + pixel FALSE,
  far bounding/pixel FALSE.
- No negative array indices.
- No getRGB out-of-bounds.
- JamVM/glibj hashes unchanged.
- Normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
