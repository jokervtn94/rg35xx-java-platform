# DP-R9 TiledLayer Diagnostic — REAL DEVICE EVIDENCE

Real-device evidence date: 2026-09-23

## Runtime identity

- Primary variable: diagnostic only
- Runtime change: NONE
- Baseline: DP-R8-B DEVICE-PASS scoped
- Protected JamVM/glibj hashes: PASS before and after

## TiledLayer rendering

Real-device result:
- dimensions: PASS
- cell state: PASS
- static tile + transparent tile rendering: PASS
- animated tile state: PASS
- animated tile rendering: PASS
- TILE_RENDER_GATE=PASS

This admits TiledLayer basic rendering / transparent-cell / animated-tile behavior for the exact diagnostic scope.

## Sprite <-> TiledLayer collision

Per-transform result:
- TRANS_NONE: PASS
- TRANS_ROT90: PASS
- TRANS_ROT180: PASS
- TRANS_ROT270: FAIL only at SAME_PIXEL_TRUE
- TRANS_MIRROR: PASS
- TRANS_MIRROR_ROT90: FAIL only at SAME_PIXEL_TRUE
- TRANS_MIRROR_ROT180: PASS
- TRANS_MIRROR_ROT270: PASS

For both failing transforms:
- same-position bounding collision: PASS
- same-position pixel collision expected TRUE: FAIL
- empty-cell bounding FALSE: PASS
- empty-cell pixel FALSE: PASS
- far bounding FALSE: PASS
- far pixel FALSE: PASS

Summary:
- TILE_COLLISION_TRANSFORM_COUNT=8
- TILE_COLLISION_PASS_COUNT=6
- TILE_COLLISION_GATE=FAIL
- DIAGNOSTIC_GATE=FAIL
- RUNTIME_GATE=FAIL
- exit code=2
- protected hashes after=PASS

## Interpretation

This reproduces exactly the two transforms that required transformed collision-rectangle geometry in Sprite-vs-Sprite collision before DP-R8: ROT270 and MIRROR_ROT90.

The TiledLayer renderer itself is not implicated. The remaining suspect is the Sprite collision rectangle used by collidesWith(TiledLayer, boolean), which still uses raw collisionRectX/Y/Width/Height while DP-R8 only changed collidesWith(Sprite, boolean) to use transformed collision bounds.

## Status

DP-R9-TILEDLAYER-RENDER=DEVICE-PASS_SCOPED
DP-R9-SPRITE-TILEDLAYER-COLLISION=DEVICE-FAIL_6_OF_8
BUILD-PASS=YES
FULL_PLATFORM_STABLE=NO
