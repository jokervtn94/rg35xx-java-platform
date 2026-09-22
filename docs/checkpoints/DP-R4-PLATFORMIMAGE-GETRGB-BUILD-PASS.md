# DP-R4 PlatformImage getRGB A/B — BUILD-PASS

## CI identity
- Branch: `dp-r4-platformimage-getrgb-ab`
- CI head: `61fb48d36a2920d625d71b0158c1ec3427054eed`
- Workflow: `RG35XX DP-R4 PlatformImage getRGB AB`
- Run ID: `35721648309`
- Job ID: `106725683371`
- Artifact ID: `10691267616`
- Artifact digest: `sha256:b931cdf931b13739fba151e58b6470d4a5feeab1c1051aa0e2a136a0a62b72ab`

## A/B scope
A = exact rebuilt DP-R3-B runtime.
B = A plus one PlatformImage.getRGB headless int[] backing path.
The diagnostic uses square 2x2 images so rectangular width/height-order behavior remains outside this checkpoint.

## Build gates
- Full DP-R1 -> DP-R2 -> DP-R3-B rebuild: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS
- A/B JAR diff gate: PASS

Exact A/B runtime delta:
`DP_R4_CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformImage.class`
`DP_R4_SINGLE_CLASS_GATE=PASS`

## Artifact hashes
- A platform: `92871a84f39d09ad5471110abb6492946e9eae2453d89da215507fee73ebf47f`
- B platform: `c6a77ea02e3fb945cb5c0aa37544a0ede027cfd71b6b2cac2c67326f44fcbcf1`
- Diagnostic JAR: `c53ceba2fc52d9dff04dcd6f4fc6aa1d726c46c9d2d30907463ffc353ff38f56`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R4-01-GETRGB-COLLISION-AB.sh`

Result:
`/mnt/mmc/RG35XX-DP-R4-GETRGB-COLLISION-AB.txt`

Interpretation:
- `DP_R4_AB_RESULT=PATCH_CONFIRMED`: A failed and B passed.
- `DP_R4_AB_RESULT=BASELINE_ALREADY_PASS`: do not promote B solely because it passes.
- `DP_R4_AB_RESULT=PATCH_NOT_CONFIRMED`: do not promote B.

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
