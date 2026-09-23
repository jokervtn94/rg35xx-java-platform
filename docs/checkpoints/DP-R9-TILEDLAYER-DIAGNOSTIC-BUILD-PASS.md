# DP-R9 TiledLayer diagnostic — BUILD-PASS

## CI identity
- Branch: `dp-r9-tiledlayer-diagnostic`
- CI head: `6b10ea8c562aab8cb1e85b20e383c10929e26167`
- Workflow: `RG35XX DP-R9 TiledLayer Diagnostic`
- Run ID: `35814309001`
- Job ID: `107032440489`
- Artifact ID: `10730794287`
- Artifact digest: `sha256:3320d32d0cf54fca588664d7b7a49a0170a3111b934d7d03aee278d1dcebe616`

## Scope
Runtime change: NONE.

Platform is the exact freshly rebuilt DP-R8-B runtime.

Diagnostic coverage:
- TiledLayer dimensions and cell state
- transparent tile index 0
- animated tile mapping and rendered result
- offscreen TiledLayer.paint pixel verification
- Sprite-vs-TiledLayer bounding and pixel collision across all 8 Sprite transforms

Visible status:
- blue + yellow = running
- blue + green = all gates PASS
- blue + red = one or more gates FAIL

No LayerManager, audio, input, SDL1, JamVM or glibj changes.

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B -> DP-R4-B -> DP-R5-B -> DP-R7-B -> DP-R8-B rebuild: PASS
- Java 6 gate: PASS
- package SHA256SUMS: PASS
- runtime change: NONE

## Artifact hashes
- Platform: `e32448bc8e1769c3bd84af5d345ce4107d89fdf5c09b312f7063cac00429bd3c`
- Diagnostic JAR: `4f0e5d1c148283d955cdc4386d821bcef962b8ad9293d1092b78e2c3ade457c7`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R9-01-TILEDLAYER-DIAGNOSTIC.sh`

Result:
`/mnt/mmc/RG35XX-DP-R9-TILEDLAYER-DIAGNOSTIC.txt`

Required for full DP-R9 diagnostic PASS:
- `DP_R9_TILE_RENDER_GATE=PASS`
- `DP_R9_TILE_COLLISION_TRANSFORM_COUNT=8`
- `DP_R9_TILE_COLLISION_PASS_COUNT=8`
- `DP_R9_TILE_COLLISION_GATE=PASS`
- `DP_R9_DIAGNOSTIC_GATE=PASS`
- `DP_R9_RUNTIME_GATE=PASS`
- `DP_R9_DEVICE_GATE=PASS`
- `PROTECTED_HASHES_AFTER=PASS`
- exit code 0

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
