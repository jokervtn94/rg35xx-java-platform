# DP-R7 Sprite transformed pixel collision upstream93d A/B — BUILD-PASS

## CI identity
- Branch: `dp-r7-sprite-transform-collision-upstream93d-ab`
- CI head: `e60690ee7e772ee34610d7c7fa8c54e3a2f5ce97`
- Workflow: `RG35XX DP-R7 Sprite Transform Collision Upstream93d AB`
- Run ID: `35724764458`
- Job ID: `106735678744`
- Artifact ID: `10693366230`
- Artifact digest: `sha256:7ee785451d739c08c97d41fee78d2e578e1c87597cd29b09f863d1f84b9f4837`

## Provenance
Upstream reference:
- repository: TASEmulators/freej2me-plus
- commit: `93d866ef7836b4aa6be89d58e1919bcc05c9bb3f`
- date: 2026-09-15
- relevant upstream intent: fix bugs in per-pixel Sprite collision

Only the transformed per-pixel collision helper core is backported:
- `checkPixCollision()`
- `getSpriteIncrAndStartPos()`

Later upstream commit `d7bb54da3205866936bce70958c0256027622b6b`
(edge-touch semantics, collidesWith(Image) coordinate correction, transform validation)
is intentionally NOT part of DP-R7.

## A/B scope
A = exact rebuilt DP-R5-B runtime.
B = A plus only the upstream93d transformed pixel-collision helper core.

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B -> DP-R4-B -> DP-R5-B rebuild: PASS
- Forced runtime JAR repack after Sprite compilation: PASS
- A/B JAR diff gate: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS

Exact A/B runtime delta:
`DP_R7_CHANGED_JAR_ENTRIES=javax/microedition/lcdui/game/Sprite.class`
`DP_R7_SINGLE_CLASS_GATE=PASS`

## Artifact hashes
- A platform: `06b8108df6691b5a3d07ecf0bc542a73b921b4bcd542a65295a3f8ba01e816a3`
- B platform: `4f291cf371c2cfc390778bfc8b5a089f3cf5767d2fc48a47c87743a34ca808e1`
- Diagnostic JAR: `b45c35ac55c6f2d9992519827bad2653d6393cd95f7365d74d4e9036a57a9ec6`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R7-01-SPRITE-TRANSFORM-COLLISION-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R7-SPRITE-TRANSFORM-COLLISION-AB.txt`

Expected:
- A reproduces DP-R6 failure
- B: `DP_R6_TRANSFORM_PASS_COUNT=8`
- B: `DP_R6_DIAGNOSTIC_GATE=PASS`
- B: `DP_R6_RUNTIME_GATE=PASS`
- `DP_R7_B_RUNTIME_GATE=PASS`
- `DP_R7_AB_RESULT=PATCH_CONFIRMED`
- protected hashes PASS

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
