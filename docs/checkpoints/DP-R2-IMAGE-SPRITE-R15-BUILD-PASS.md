# DP-R2 Image -> Sprite r1.5 A/B — BUILD-PASS

## Build identity

- Branch: `dp-r2-image-sprite-r15-ab`
- Head used by CI artifact: `d06039d7e61a2f75343db1f170e76d870273845c`
- Workflow: `RG35XX DP-R2 Image Sprite r1.5 AB`
- Run ID: `35719682520`
- Job ID: `106719387033`
- Artifact ID: `10689424725`
- Artifact name: `rg35xx-dp-r2-image-sprite-r15-ab`
- Artifact digest: `sha256:80923d346b984d748046eb8ae2dbf62c7fd726ba98257ffb494daefcf17d3e0c`

## Scope

Baseline:
- DP-R1 standalone SDL1/fbcon rebuild
- upstream pin `13ec186903087156c145268f8706eecfaf9f1e50`
- tree `ad47ab16e9025f0eb3d2067bc3b1897dc71987df`

Historical prerequisite:
- r1.4 headless LCDUI Image copy patch
- provenance commit `196c95bf031121711c150618d130b5a77332d412`
- patch SHA256 `5f4878ddbc708e1f852c17f908cefe728d54ee83814560a82abc38da391b0b07`

Primary variable:
- r1.5 headless `Image.createRGBImage(...)` backing in `PlatformImage`
- patch SHA256 `ae7b73ef5c45be1748e22be02bb1feca040315210fbd8bd2d65597a5f2ee97e8`

Diagnostic source SHA256:
- `9e3b68cd2943e3c0d25790eed6032b742fdcab02ee3ea2d93eb9d4b6b3f45f08`

## Build gates

- DP-R1 clean foundation rebuild: PASS
- M1.16-r1.4 patch application: PASS
- M1.16-r1.5 patch application: PASS
- Java 6 class gate: PASS
- Package SHA256SUMS verification: PASS
- GarlicOS top-level launcher syntax: PASS
- Runtime JAR entry diff gate: PASS

Exact runtime JAR content delta:

`DP_R2_CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformImage.class`

No other JAR entry changed in byte content.

## Artifact hashes

- DP-R1 baseline JAR from this CI run:
  `4d61e7d58f5ba7a215d43097702bf08e3faaa7e9ce9f99a21c567830223c0787`
- DP-R2 platform JAR:
  `b448b5291e20c6ffd824fbe7054a382973ee41412556b49ce18b5d9e9ee6dbd1`
- Input native:
  `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native:
  `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`
- Diagnostic JAR:
  `8b78194beb71db55c80001fecb70ce81454edf85d590d5c6de3ab34c44762896`

Protected device requirements:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device acceptance

Run from GarlicOS APPS:

`DP-R2-01-IMAGE-SPRITE-R15`

Expected log:

`/mnt/mmc/RG35XX-DP-R2-IMAGE-SPRITE-R15.txt`

Required:
- A_MUTABLE Sprite constructor PASS
- B_COPY Sprite constructor PASS
- C_RGB Sprite constructor PASS
- no GtkToolkit/libgtkpeer failure
- diagnostic/runtime gate PASS
- JamVM exit 0
- protected hashes PASS
- normal return to GarlicOS
- no hard reset

## Status

BUILD-PASS=YES  
DEVICE-PASS=NO  
DEVICE-TEST-PENDING=YES  
STABLE=NO
