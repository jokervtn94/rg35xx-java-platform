# DP-R8 Sprite transformed collision rectangle A/B — BUILD-PASS

## CI identity
- Branch: `dp-r8-sprite-transformed-collision-rect-ab`
- CI head: `877e927efb6b07e7acce575448eb27c31ca1028f`
- Workflow: `RG35XX DP-R8 Sprite Transformed Collision Rect AB`
- Run ID: `35729255952`
- Job ID: `106750448483`
- Artifact ID: `10694647689`
- Artifact digest: `sha256:5d531947bda31ac7914279dcef161050c63d4ed5db2f616cba55d30bbe147ddd`

## Scope
A = exact rebuilt DP-R7-B runtime (known 6/8 transformed collision result).
B = A plus only Sprite-vs-Sprite transform-aware collision rectangle geometry.

The patch adds one private helper that maps raw collisionRectX/Y/Width/Height
into transformed collision bounds for the current Sprite transform, and uses
those transformed bounds only in collidesWith(Sprite, boolean).

Not changed:
- DP-R7 per-pixel helper core
- TiledLayer collision
- collidesWith(Image)
- edge-touch semantics
- Sprite rendering
- PlatformImage / PlatformGraphics
- audio / input / SDL1 / JamVM / glibj

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B -> DP-R4-B -> DP-R5-B -> DP-R7-B rebuild: PASS
- Forced Sprite.class recompilation: PASS
- Forced runtime JAR repack: PASS
- A/B JAR diff gate: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS

Exact A/B runtime delta:
`DP_R8_CHANGED_JAR_ENTRIES=javax/microedition/lcdui/game/Sprite.class`
`DP_R8_SINGLE_CLASS_GATE=PASS`

## Artifact hashes
- A platform: `4fc90815c9589ca4c652a7404316c95297ae4587b436d34a4092b3b1f54aabf3`
- B platform: `13bb76695a969a232587b74e65ce032aec62f8c3d426a75ca6af7f9aa4b39e9e`
- Diagnostic JAR: `c6aba64212652278cc66a2bf38890b641c41b4d9ca0ddf392641288de1ce1532`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R8-01-SPRITE-TRANSFORMED-COLLISION-RECT-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R8-SPRITE-TRANSFORMED-COLLISION-RECT-AB.txt`

Expected:
- A reproduces DP-R7-B partial result
- B: `DP_R6_TRANSFORM_PASS_COUNT=8`
- B: `DP_R6_DIAGNOSTIC_GATE=PASS`
- B: `DP_R6_RUNTIME_GATE=PASS`
- `DP_R8_B_RUNTIME_GATE=PASS`
- `DP_R8_AB_RESULT=PATCH_CONFIRMED`
- protected hashes PASS

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
