# DP-R10 Sprite <-> TiledLayer transformed collision rectangle A/B — BUILD-PASS

## CI identity
- Working branch: `dp-r9-tiledlayer-diagnostic`
- CI head: `cbd5e4ea4fd5de05df4d0e3463101222549c993d`
- Workflow: `RG35XX DP-R10 TiledLayer Collision Rect AB`
- Run ID: `35816392276`
- Job ID: `107038720113`
- Artifact ID: `10731947385`
- Artifact digest: `sha256:20b7a7ca3fdc1b8ab8dd13f8f0b415ab89dbe73c864a46b52c702f06b3ce965b`

## Device evidence motivating DP-R10
DP-R9 real-device evidence:
- TiledLayer rendering gate: PASS
- Sprite-vs-TiledLayer collision: 6/8 transforms PASS
- only ROT270 and MIRROR_ROT90 failed at same-position pixel TRUE
- protected JamVM/glibj hashes: PASS

## A/B scope
A = exact rebuilt DP-R8-B runtime used by DP-R9.

B = A plus only Sprite-vs-TiledLayer transform-aware collision rectangle geometry inside `collidesWith(TiledLayer, boolean)`.

The patch reuses the already DP-R8-proven `getTransformedCollisionRectBounds()` helper.

Not changed:
- TiledLayer.java
- TiledLayer rendering
- DP-R7 per-pixel helper core
- Sprite-vs-Sprite collision geometry
- collidesWith(Image)
- LayerManager
- edge-touch semantics
- PlatformImage / PlatformGraphics
- audio / input / SDL1 / JamVM / glibj

## Build gates
- full DP-R1 -> DP-R2 -> DP-R3 -> DP-R4 -> DP-R5 -> DP-R7 -> DP-R8 -> DP-R9 rebuild: PASS
- DP-R10 patch anchor: PASS
- forced Sprite.class recompilation: PASS
- forced runtime JAR repack: PASS
- A/B JAR content diff gate: PASS
- Java 6 gate: PASS
- package SHA256SUMS: PASS

Exact A/B runtime delta:
`DP_R10_CHANGED_JAR_ENTRIES=javax/microedition/lcdui/game/Sprite.class`

`DP_R10_SINGLE_CLASS_GATE=PASS`

## Artifact hashes
- A platform: `e58a6ee37aef3527e970129b9485196ac08417880434866acbfe6ceb7173327a`
- B platform: `61dce830aafde2c47db5dde91aa996ea3fa51cd0923433f2b6bad35dee725db7`
- Diagnostic JAR: `dbd426bea586b90d3f736629ef12a558dd168ef5ff5d39a409ce8e0394f69145`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R10-01-TILEDLAYER-COLLISION-RECT-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R10-TILEDLAYER-COLLISION-RECT-AB.txt`

Expected A/B:
- CASE A reproduces DP-R9 6/8 result and ends visual RED
- CASE B reaches 8/8 and ends visual GREEN
- `DP_R10_A_RUNTIME_GATE=FAIL`
- `DP_R10_B_RUNTIME_GATE=PASS`
- `DP_R10_AB_RESULT=PATCH_CONFIRMED`
- `PROTECTED_HASHES_AFTER=PASS`

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
