# DP-R11 LayerManager diagnostic — BUILD-PASS

## CI identity
- Branch: `dp-r11-layermanager-diagnostic`
- CI head: `92f67d519f664b084082166682c9b1b6e4af5467`
- Workflow: `RG35XX DP-R11 LayerManager Diagnostic`
- Run ID: `35817221939`
- Job ID: `107041231339`
- Artifact ID: `10731918854`
- Artifact digest: `sha256:e274de3a30bb712f11f69fdcdcf302410c87d6bcc32a277afb93fbf20df725ed`

## Scope
- Runtime change: NONE.
- Platform is the exact freshly rebuilt DP-R10-B runtime.
- Diagnostic only.
- Tests:
  - append / insert / remove / getLayerAt / getSize
  - z-order: index 0 is front
  - layer visibility
  - view-window clipping + destination translation
  - Graphics translation/clip restoration after LayerManager.paint()
  - invalid negative view-window dimensions exception

## Build gates
- Full clean chain through DP-R10-B rebuild: PASS
- DP-R10 Sprite-only delta gate: PASS
- Java 6 gate: PASS
- Package SHA256SUMS: PASS
- Runtime change: NONE
- Native input/presenter hashes unchanged

## Artifact hashes
- Platform: `35e4969ec6d898c8128b7ee8951797d3a3c43da7f9ae1020c9d198c7a26f929a`
- Diagnostic JAR: `3f9b342c609e86624d9437016c98ac33ecd27799589dd9a968ac4563f4515c70`
- Input native: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter native: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

Protected device identities:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Device test
GarlicOS launcher:
`Roms/APPS/DP-R11-01-LAYERMANAGER-DIAGNOSTIC.sh`

Result:
`/mnt/mmc/RG35XX-DP-R11-LAYERMANAGER-DIAGNOSTIC.txt`

Required to admit DEVICE-PASS:
- `DP_R11_LIST_GATE=PASS`
- `DP_R11_ZORDER_GATE=PASS`
- `DP_R11_VIEWWINDOW_GATE=PASS`
- `DP_R11_GRAPHICS_STATE_GATE=PASS`
- `DP_R11_DIAGNOSTIC_GATE=PASS`
- `DP_R11_RUNTIME_GATE=PASS`
- `DP_R11_DEVICE_GATE=PASS`
- `PROTECTED_HASHES_AFTER=PASS`
- exit code 0

## Status
BUILD-PASS=YES
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
