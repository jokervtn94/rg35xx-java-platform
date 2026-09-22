# DP-R5 Sprite getARGBData width/height order — DEVICE-PASS (scoped)

Real-device evidence date: 2026-09-22

## CASE A — exact DP-R4-B runtime
- same-position bounding: PASS
- same-position pixel collision: PASS
- offset-1 bounding: PASS
- offset-1 pixel collision: FAIL
- failure: IllegalArgumentException from PlatformImage.getRGB
- A runtime gate: FAIL

## CASE B — one-line Sprite.getARGBData width/height order fix
- same-position bounding TRUE: PASS
- same-position pixel TRUE: PASS
- offset-1 bounding TRUE: PASS
- offset-1 pixel FALSE: PASS
- far bounding FALSE: PASS
- far pixel FALSE: PASS
- rectangular X overlap pixel FALSE: PASS
- rectangular Y overlap pixel FALSE: PASS
- non-square overlaps exercised: 2
- diagnostic gate: PASS
- runtime gate: PASS
- B exit code: 0
- protected hashes after: PASS
- A/B result: PATCH_CONFIRMED

## Protected identities
JamVM:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

## Admitted scope
DEVICE-PASS:
- Sprite.getARGBData width/height order fix
- Sprite-Sprite bounding collision for tested cases
- Sprite-Sprite pixel collision for untransformed square and rectangular overlap cases

Not yet admitted:
- transformed Sprite pixel collision
- Sprite/TiledLayer collision
- TiledLayer rendering
- LayerManager
- commercial-game compatibility
- audio

The marker M1_12_R4E_FONT_RESOURCE=NOT_FOUND is outside this checkpoint.

## Status
DP-R5-SPRITE-GETARGB-WH=DEVICE-PASS_SCOPED
BUILD-PASS=YES
DEVICE-PASS=YES_SCOPED
FULL_PLATFORM_STABLE=NO
