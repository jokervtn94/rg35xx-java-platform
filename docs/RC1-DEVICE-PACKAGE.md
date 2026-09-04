# RG35XX Java Platform — RC1 Device Test Package

Status: device-validation staging only. This document does not claim DEVICE-TEST-PASS.

## Purpose

`rc1_package_device_test.sh` creates one deterministic host-side directory containing exactly the BUILD-PASS core/JAR, the pinned runtime font/SoundFont, and the device evidence/checklist files required for manual RG35XX validation.

It deliberately does **not** guess firmware-specific core/JAR install paths and does not overwrite anything on the console automatically.

## Required inputs

Set four host paths:

```sh
CORE_FILE=/path/to/freej2me_plus_libretro.so \
JAR_FILE=/path/to/freej2me_plus-lr.jar \
FONT_FILE=/path/to/DejaVuSans.ttf \
SOUNDFONT_FILE=/path/to/GeneralUser-GS.sf2 \
OUT=/path/to/rg35xx-java-rc1-device-test \
MAKE_ZIP=1 \
sh scripts/rc1_package_device_test.sh
```

The script fails closed unless all four SHA-256 values match the accepted BUILD-PASS/runtime inputs.

## Locked hashes

- core: `3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58`
- JAR: `f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b`
- DejaVuSans.ttf: `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`
- GeneralUser-GS.sf2: `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`

BUILD-PASS identity:

- commit: `086d4987c0d60b5eb9abc3887e73638b24a1b964`
- consolidated run: `33883673553`
- artifact: `9940954185`
- artifact SHA-256: `e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630`

## Output layout

```text
rg35xx-java-rc1-device-test/
├── BUILD-IDENTITY.txt
├── INSTALL-MAP.txt
├── SHA256SUMS
├── core/
│   └── freej2me_plus_libretro.so
├── java/
│   └── freej2me_plus-lr.jar
├── Java/
│   └── runtime/
│       ├── DejaVuSans.ttf
│       └── GeneralUser-GS.sf2
├── tools/
│   └── rc1_device_evidence.sh
└── docs/
    └── RC1-DEVICE-VALIDATION.md
```

The `Java/runtime` subtree mirrors the fixed runtime target under `/mnt/mmc/Java/runtime`.

## Manual device placement

Runtime assets have fixed destinations:

```text
/mnt/mmc/Java/runtime/DejaVuSans.ttf
/mnt/mmc/Java/runtime/GeneralUser-GS.sf2
```

The libretro core and FreeJ2ME JAR locations depend on the firmware/frontend already installed on the RG35XX. The package intentionally leaves these as manual placement items rather than inventing a firmware path.

Before changing any device file, preserve the existing copy. Do not alter or delete game JARs or RMS save data.

## Evidence sequence

1. Copy/install the four validated payload files into their correct device locations.
2. Run `rc1_device_evidence.sh` before testing with `CORE_PATH` and `JAR_PATH` set to the actual installed paths.
3. Execute the validation matrix in `RC1-DEVICE-VALIDATION.md` using real JARs.
4. Run the evidence collector again after testing.
5. Record PASS/FAIL and notes in the generated result template.
6. Only after reviewing the real-device evidence may a new immutable tasklog mark DEVICE-TEST-PASS or DEVICE-TEST-FAIL.

## Non-goals

This packaging step does not add a launcher, does not alter stdout/video IPC, does not change the audio pipe, does not change game-switch/RMS lifecycle, does not bundle proprietary game JARs, and does not imply device validation success.
