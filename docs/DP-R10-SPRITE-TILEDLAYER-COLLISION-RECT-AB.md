# DP-R10 Sprite <-> TiledLayer transformed collision rectangle A/B

CURRENT_SYMPTOM:
- DP-R9 TiledLayer rendering is real-device PASS.
- Sprite <-> TiledLayer transformed collision passes 6/8 transforms.
- Only ROT270 and MIRROR_ROT90 fail at same-position pixel collision TRUE.
- Empty-cell and far collision gates pass for all 8 transforms.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R8 transformed collision rectangle geometry fixed Sprite-vs-Sprite collision to 8/8 transforms.
- DP-R9 shows the same two-transform signature in Sprite-vs-TiledLayer collision.

PREVIOUS_EVIDENCE_LEVEL:
- TiledLayer basic rendering/animated tile: DEVICE-PASS_SCOPED.
- Sprite-vs-TiledLayer transformed collision: DEVICE-FAIL_6_OF_8.

REGRESSION_RISK:
- High if TiledLayer rendering, LayerManager, collidesWith(Image), edge-touch semantics, audio, input, SDL1, JamVM or glibj are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact rebuilt DP-R8-B runtime.
- B: only collidesWith(TiledLayer, boolean) uses the already DP-R8-proven getTransformedCollisionRectBounds() helper for Sprite collision bounds.
- No TiledLayer.java change.
- No renderer change.
- No per-pixel helper change.
- No LayerManager/audio/input/native/runtime change.

EXPECTED_DEVICE_TEST:
- A reproduces DP-R9: TILE_COLLISION_PASS_COUNT=6.
- B passes TILE_COLLISION_PASS_COUNT=8.
- ROT270 same-position pixel TRUE becomes PASS.
- MIRROR_ROT90 same-position pixel TRUE becomes PASS.
- TiledLayer render gate remains PASS.
- protected JamVM/glibj hashes remain unchanged.
- normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
