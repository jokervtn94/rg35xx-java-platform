# DP-R7 upstream93d transformed collision — REAL DEVICE EVIDENCE

Real-device evidence date: 2026-09-22

## CASE A — exact DP-R5-B
- TRANS_NONE: PASS
- 7 transformed modes: FAIL
- transform pass count: 1/8
- runtime gate: FAIL

## CASE B — upstream 93d collision-helper core
- TRANS_NONE: PASS
- ROT90: PASS
- ROT180: PASS
- MIRROR: PASS
- MIRROR_ROT180: PASS
- MIRROR_ROT270: PASS
- ROT270: FAIL only at SAME_PIXEL_TRUE
- MIRROR_ROT90: FAIL only at SAME_PIXEL_TRUE
- all offset-1 and far gates for the two remaining transforms: PASS
- transform pass count: 6/8
- runtime gate: FAIL
- protected hashes: PASS
- final result: PATCH_NOT_CONFIRMED

## Interpretation

The upstream 93d helper backport removes the exception class of failures:
- no negative checkPixCollision array indices remain in CASE B
- no getRGB out-of-bounds remains in CASE B

However it is NOT admitted as a complete transformed-collision fix because two transforms still return a false negative at same position.

The remaining failure is consistent with collision-rectangle geometry not being transformed with the Sprite. The pinned FreeJ2ME Sprite stores collisionRectX/Y/Width/Height in untransformed source-frame coordinates while width/height are swapped for 90/270 transforms. J2ME-Loader keeps transformed collision rectangle bounds separately.

## Status
DP-R7-UPSTREAM93D=PARTIAL_DEVICE_EVIDENCE_6_OF_8
DEVICE-PASS=NO
PATCH_CONFIRMED=NO
FULL_PLATFORM_STABLE=NO
