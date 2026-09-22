# DP-R2 Image -> Sprite r1.5 — DEVICE-PASS (scoped)

Real-device evidence date: 2026-09-22

## Device result

Result file: `/mnt/mmc/RG35XX-DP-R2-IMAGE-SPRITE-R15.txt`

Observed markers:
- `PROTECTED_HASHES_BEFORE=PASS`
- `M1_16_R11_A_MUTABLE_SPRITE_CTOR=PASS`
- `M1_16_R11_B_COPY_SPRITE_CTOR=PASS`
- `M1_16_R11_C_RGB_SPRITE_CTOR=PASS`
- `M1_16_R11_A_RESULT=PASS`
- `M1_16_R11_B_RESULT=PASS`
- `M1_16_R11_C_RESULT=PASS`
- `M1_16_R11_DIAGNOSTIC_GATE=PASS`
- `M1_16_R11_RUNTIME_GATE=PASS`
- `JAMVM_EXIT_CODE=0`
- `PROTECTED_HASHES_AFTER=PASS`
- `DP_R2_RUNTIME_GATE=PASS`

Protected hashes:
- JamVM before/after: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj before/after: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Scope admitted

DEVICE-PASS is admitted only for:
- headless mutable Image -> Sprite constructor
- headless copied Image -> Sprite constructor
- headless createRGBImage -> Sprite constructor
- width/height/mutability access for those Images
- protected runtime identity across the test

This does NOT yet admit:
- Sprite.paint()/Graphics.drawRegion
- Sprite transforms
- pixel collision
- TiledLayer
- LayerManager
- commercial-game compatibility
- audio

The marker `M1_12_R4E_FONT_RESOURCE=NOT_FOUND` is outside this checkpoint's acceptance criteria because the diagnostic does not render text and all Image/Sprite/runtime gates passed.

## Status

DP-R2-IMAGE-SPRITE-R15=DEVICE-PASS_SCOPED
BUILD-PASS=YES
DEVICE-PASS=YES_SCOPED
FULL_PLATFORM_STABLE=NO
