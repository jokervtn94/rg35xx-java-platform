# RG35XX P1A-G1 Physical Platform Exerciser

## Status

```text
WORK_UNIT=P1A-G1-CLEAR-COPY
OWNER=RG35XX_GRAPHICS_BOUNDARY
HOST-DIFFERENTIAL-PASS=YES
PHYSICAL-EXERCISER-BUILD-PASS=YES
DEVICE-PASS=NO
STABLE=NO
```

This is a platform-module test. It does not use a commercial game as the acceptance surface.

## Locked runtime

- Canonical Aweigit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- G1 host CI run: `36946272693`
- exact packaged G1 platform JAR: `72feb0a928539f428c57978774c6e5a5677c3c23d4203bc63e1a2087fde45ba8`
- G1 semantic digest: `86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527`
- G1 PlatformGraphics class: `c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0`
- input: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- video: `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`
- audio: `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`
- audio prime file: `8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e`
- exerciser CI run: `36947462363`
- exerciser CI head: `906a87e3d772c995fb3be158d30b8f08c1281bb4`
- exerciser JAR: `6c4c0563c8b8eb0923b3677d876986e2cd109bd0ea4b03682571874f86d043fe`

The prime file is packaged and hash-gated as protected identity, but this graphics-only test does not execute `aplay`.

## Exerciser coverage

The MIDlet programmatically checks:

- clear basic;
- clear + clip/translate;
- degenerate clear;
- copy basic;
- copy anchors;
- copy + clip/translate;
- canonical JDK8 live-raster overlap right;
- canonical JDK8 live-raster overlap down;
- transparent-source copy behavior.

The host candidate already passed the broader differential matrix, including horizontal/vertical/diagonal overlaps and semi-alpha JDK8 SrcOver behavior. Physical G1 is intentionally a module acceptance surface, not a replacement for host differential coverage.

## GarlicOS layout

```text
Roms/APPS/
├── P1A-G1-PLATFORM-EXERCISER.sh
└── RG35XX-P1A-G1/
    ├── freej2me-rg35xx.jar
    ├── librg35xx_input.so
    ├── librg35xx_video.so
    ├── libaudio.so
    ├── a7-a1p5-rw-silence-prime.s32le
    ├── RG35XX-P1A-G1-EXERCISER.jar
    └── identity/checksum files
```

Evidence is written under `/mnt/mmc/A8-COMPAT-EVIDENCE/P1A-G1-PLATFORM-EXERCISER-<timestamp>/`.

## Physical acceptance

Expected screen on programmatic PASS: green background with three white horizontal bars. FAIL is a dark red screen with an X. The MIDlet exits after roughly four seconds.

`DEVICE-PASS` remains pending until the original RG35XX physically shows the PASS pattern without crash/hang/visual anomaly and returns normally to GarlicOS, with matching runtime evidence.

No Tier-0 or Tier-1 game result is needed to determine this G1 module result. Tier-0 remains a later promotion regression gate for the completed P1A candidate.
