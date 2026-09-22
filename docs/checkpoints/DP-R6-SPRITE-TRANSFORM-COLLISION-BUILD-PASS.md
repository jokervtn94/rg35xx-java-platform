# DP-R6 Sprite transformed pixel collision diagnostic — BUILD-PASS

## CI identity
- Branch: `dp-r6-sprite-transform-collision-diagnostic`
- CI head: `8b285a3ab6d2a53ee67b235a1105ebd71d12b187`
- Workflow: `RG35XX DP-R6 Sprite Transform Collision Diagnostic`
- Run ID: `35723769420`
- Job ID: `106732432713`
- Artifact ID: `10692750171`
- Artifact digest: `sha256:494ab84fe117c80d99134d511a360ae973a774378f07f4dfe2f54124e246c754`

## Scope
- Runtime change: NONE.
- Platform is the exact freshly rebuilt DP-R5-B runtime.
- Diagnostic only: all 8 MIDP Sprite transforms on a non-square 3x2 sparse-alpha image.
- Per transform:
  - same-position bounding/pixel TRUE
  - x-offset 1 bounding TRUE + pixel FALSE
  - far bounding/pixel FALSE

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B -> DP-R4-B -> DP-R5-B rebuild: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS
- Runtime change: NONE
- Native input/presenter hashes unchanged

## Artifact hashes
- Platform: `699cb49f3db7115466770027682588f486656ef21a6795ba72ebf77e112ed3ed`
- Diagnostic JAR: `b08edf8d491d3ea6430c2968e37da406d9456e7c8bf773ca23cd1ef4c1db007c`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R6-01-SPRITE-TRANSFORM-COLLISION.sh`

Result:
`/mnt/mmc/RG35XX-DP-R6-SPRITE-TRANSFORM-COLLISION.txt`

Required to admit DEVICE-PASS:
- `DP_R6_TRANSFORM_COUNT=8`
- `DP_R6_TRANSFORM_PASS_COUNT=8`
- `DP_R6_DIAGNOSTIC_GATE=PASS`
- `DP_R6_RUNTIME_GATE=PASS`
- `DP_R6_DEVICE_GATE=PASS`
- `PROTECTED_HASHES_AFTER=PASS`
- exit code 0

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
