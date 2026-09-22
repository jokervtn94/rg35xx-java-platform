# DP-R3 Sprite Render / drawRegion A/B — BUILD-PASS

## CI identity

- Branch: `dp-r3-sprite-render-drawregion-ab`
- CI head: `0020b9221dce1efe01d0aecdd114ff933397f4c2`
- Workflow: `RG35XX DP-R3 Sprite Render drawRegion AB`
- Run ID: `35720809117`
- Job ID: `106723012526`
- Artifact ID: `10690954129`
- Artifact digest: `sha256:37868285b1c265cf9a4c7e2bb556a436c124526ac0ccce304de02ae8cd434f94`

## A/B scope

A:
- exact rebuilt DP-R2 Image -> Sprite r1.5 runtime

B:
- same as A plus ONE PlatformGraphics change:
  drawRegion source bounds use `image.getWidth()/getHeight()`
  instead of `image.getCanvas().getWidth()/getHeight()`

No Sprite implementation change.
No drawTransformedImage algorithm change.
No collision/TiledLayer/LayerManager/audio/input/SDL1/JamVM/glibj change.

## Build gates

- DP-R1 foundation rebuild: PASS
- DP-R2 r1.4+r1.5 rebuild: PASS
- DP-R3 patch anchor: PASS
- Java 6 gate: PASS
- Package checksums: PASS
- A/B JAR diff gate: PASS

Exact A/B runtime JAR delta:

`DP_R3_CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class`

`DP_R3_SINGLE_CLASS_GATE=PASS`

## Artifact hashes

- A platform: `2a200c6507738290c77d70c90c996a2b3d05dbb9efafeaf7a523736c4fa7a289`
- B platform: `aedef67a088679feeab1c85e2b2f382aea7f67d26912af0e2317b211fdf5dd2f`
- Diagnostic JAR: `6b43de533c45d4eef9b1a5d584d880d777c9bf395d61e9c8d2743442f2babf1a`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities remain:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test

GarlicOS launcher:
`Roms/APPS/DP-R3-01-SPRITE-RENDER-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R3-SPRITE-RENDER-AB.txt`

Interpretation:
- `DP_R3_AB_RESULT=PATCH_CONFIRMED`: A failed and B passed; candidate fix proven on device.
- `DP_R3_AB_RESULT=BASELINE_ALREADY_PASS`: A already passed; do not promote B merely because it passes.
- `DP_R3_AB_RESULT=PATCH_NOT_CONFIRMED`: do not promote B.

## Status

BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
