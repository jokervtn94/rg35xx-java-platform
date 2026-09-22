# DP-R5 Sprite getARGBData width/height order A/B — BUILD-PASS

## CI identity
- Branch: `dp-r5-sprite-getargb-wh-order-ab`
- CI head: `ab212cbe91b8c30714980d34c548b70e87084e5b`
- Workflow: `RG35XX DP-R5 Sprite getARGB WH Order AB`
- Run ID: `35722542403`
- Job ID: `106728526178`
- Artifact ID: `10691523594`
- Artifact digest: `sha256:cb66ffa97148bd1bc3282b90465814ccb8f8192dfdaa16ce1ada52ad7aa50858`

## A/B scope
A = exact rebuilt DP-R4-B runtime.
B = A plus one-line Sprite.getARGBData width/height order fix:
`image.getRGB(..., xOffset, yOffset, height, width)`
->
`image.getRGB(..., xOffset, yOffset, width, height)`

No other Sprite logic changed.
No new PlatformImage behavior beyond the already admitted DP-R4 getRGB patch.

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B -> DP-R4-B rebuild: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS
- A/B JAR diff gate: PASS

Exact A/B runtime delta:
`DP_R5_CHANGED_JAR_ENTRIES=javax/microedition/lcdui/game/Sprite.class`
`DP_R5_SINGLE_CLASS_GATE=PASS`

## Artifact hashes
- A platform: `0ad4c37755168720c9719e34f71562d6160ed8411dca25738d4b7239af0f6956`
- B platform: `60db5d541500f4f1f1b16c571b9290e4767ce23176947c44fc69916522f95adf`
- Diagnostic JAR: `c23225aafa1e5717be8825e3d4342ab6e8019267db82de4f5b9d4d4017a7c334`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R5-01-SPRITE-COLLISION-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R5-SPRITE-COLLISION-AB.txt`

Expected interpretation:
- `DP_R5_AB_RESULT=PATCH_CONFIRMED`: A reproduces failure and B passes.
- `DP_R5_AB_RESULT=BASELINE_ALREADY_PASS`: do not promote B solely because it passes.
- `DP_R5_AB_RESULT=PATCH_NOT_CONFIRMED`: do not promote B.

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
