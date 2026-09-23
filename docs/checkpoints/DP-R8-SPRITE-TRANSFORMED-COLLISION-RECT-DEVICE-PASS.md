# DP-R8 Sprite transformed collision rectangle — DEVICE-PASS (scoped)

Real-device evidence date: 2026-09-23

## Device result

The DP-R8 launcher is diagnostic/headless. It does not render a visible test scene to the LCD, so a black screen during execution is expected and is not itself a failure.

CASE A reproduced the known DP-R7-B partial baseline:
- 8 transforms exercised
- 6 transforms passed
- TRANS_ROT270 same-position pixel collision: FAIL
- TRANS_MIRROR_ROT90 same-position pixel collision: FAIL
- A runtime gate: FAIL

CASE B, with only Sprite-vs-Sprite transform-aware collision rectangle geometry added:
- TRANS_NONE: PASS
- TRANS_ROT90: PASS
- TRANS_ROT180: PASS
- TRANS_ROT270: PASS
- TRANS_MIRROR: PASS
- TRANS_MIRROR_ROT90: PASS
- TRANS_MIRROR_ROT180: PASS
- TRANS_MIRROR_ROT270: PASS
- transform count: 8
- transform pass count: 8
- diagnostic gate: PASS
- runtime gate: PASS
- B exit code: 0
- protected JamVM/glibj hashes after: PASS
- final A/B result: PATCH_CONFIRMED

## Protected identities

JamVM before/after:
`eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

glibj before/after:
`d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Admitted scope

DEVICE-PASS is admitted for:
- Sprite-vs-Sprite transformed collision rectangle geometry
- Sprite-vs-Sprite transformed per-pixel collision for all 8 MIDP Sprite transforms in the diagnostic
- same-position pixel TRUE cases
- x-offset bounding TRUE + pixel FALSE cases
- far bounding/pixel FALSE cases

This checkpoint depends on previously admitted scoped fixes:
- DP-R3 drawRegion headless bounds
- DP-R4 PlatformImage.getRGB headless backing
- DP-R5 Sprite getARGBData width/height order
- DP-R7 upstream93d transformed per-pixel collision core

Not yet admitted:
- Sprite vs TiledLayer collision
- TiledLayer rendering
- LayerManager
- collidesWith(Image) transformed semantics
- edge-touch semantics beyond the diagnostic cases
- commercial-game compatibility
- audio

The marker `M1_12_R4E_FONT_RESOURCE=NOT_FOUND` is outside this checkpoint acceptance criteria because this diagnostic does not render text.

## Status

DP-R8-SPRITE-TRANSFORMED-COLLISION=DEVICE-PASS_SCOPED
BUILD-PASS=YES
DEVICE-PASS=YES_SCOPED
FULL_PLATFORM_STABLE=NO
