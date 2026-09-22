# DP-R3 Sprite Render / drawRegion A/B — DEVICE-PASS (scoped)

Real-device evidence date: 2026-09-22

## Result

A = exact DP-R2 runtime:
- all 8 Sprite transforms reported correct dimensions
- every Sprite.paint() failed with NullPointerException in PlatformGraphics.drawRegion
- A runtime gate FAIL

B = A plus one PlatformGraphics boundary change:
- drawRegion source bounds use image.getWidth()/getHeight()
- all 8 transforms painted successfully
- all 8 transforms preserved all 6 opaque source colors exactly once
- B runtime gate PASS

Critical markers:
- DP_R3_A_RUNTIME_GATE=FAIL
- DP_R3_B_RUNTIME_GATE=PASS
- DP_R3_AB_RESULT=PATCH_CONFIRMED
- PROTECTED_HASHES_BEFORE=PASS
- PROTECTED_HASHES_AFTER=PASS

JamVM before/after:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj before/after:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

## Scope admitted

DEVICE-PASS is admitted for:
- Sprite.paint()
- PlatformGraphics.drawRegion headless source bounds
- TRANS_NONE
- TRANS_ROT90
- TRANS_ROT180
- TRANS_ROT270
- TRANS_MIRROR
- TRANS_MIRROR_ROT90
- TRANS_MIRROR_ROT180
- TRANS_MIRROR_ROT270
- source-color preservation for opaque pixels in the diagnostic

Not yet admitted:
- Sprite pixel collision
- Sprite/TiledLayer collision
- TiledLayer rendering
- LayerManager
- commercial-game compatibility
- audio

The M1_12_R4E_FONT_RESOURCE=NOT_FOUND marker is outside this checkpoint acceptance criteria.

## Status

DP-R3-B-DRAWREGION=DEVICE-PASS_SCOPED
BUILD-PASS=YES
DEVICE-PASS=YES_SCOPED
FULL_PLATFORM_STABLE=NO
