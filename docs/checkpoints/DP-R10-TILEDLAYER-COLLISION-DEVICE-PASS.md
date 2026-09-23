# DP-R10 Sprite↔TiledLayer transformed collision rectangle — DEVICE-PASS (scoped)

Real-device evidence date: 2026-09-23

## CASE A — exact DP-R9 / DP-R8-B runtime
- TiledLayer dimensions/cell state/rendering: PASS
- Sprite↔TiledLayer transform collision: 6/8
- ROT270 same-position pixel TRUE: FAIL
- MIRROR_ROT90 same-position pixel TRUE: FAIL
- A runtime gate: FAIL

## CASE B — transform-aware Sprite collision rectangle in collidesWith(TiledLayer)
- TiledLayer dimensions: PASS
- cell state: PASS
- static transparent render: PASS
- animated state/render: PASS
- all 8 Sprite transforms: PASS
- transform pass count: 8/8
- collision gate: PASS
- diagnostic gate: PASS
- runtime gate: PASS
- B exit code: 0
- protected JamVM/glibj hashes: PASS
- A/B result: PATCH_CONFIRMED

## Admitted scope
DEVICE-PASS scoped:
- TiledLayer dimensions/cell state
- transparent tile semantics used by the diagnostic
- animated tile mapping/rendering used by the diagnostic
- TiledLayer.paint() rendering path used by the diagnostic
- Sprite↔TiledLayer bounding/pixel collision for all 8 Sprite transforms used by the diagnostic

Not yet admitted:
- LayerManager ordering/viewport/paint composition
- Sprite↔Image transformed collision
- edge-touch semantics outside the diagnostic
- commercial-game compatibility
- audio/media

The marker M1_12_R4E_FONT_RESOURCE=NOT_FOUND is outside this checkpoint.

## Protected identities
JamVM:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

## Status
DP-R10-TILEDLAYER-COLLISION=DEVICE-PASS_SCOPED
BUILD-PASS=YES
DEVICE-PASS=YES_SCOPED
FULL_PLATFORM_STABLE=NO
