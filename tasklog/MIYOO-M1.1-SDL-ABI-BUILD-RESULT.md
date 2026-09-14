# MIYOO M1.1 SDL ABI BOOTSTRAP — BUILD RESULT

Date: 2026-09-14
Artifact build commit: a6a8489cbba3632bc51e9c2bda5ecd7e093fcd3d
Workflow: RG35XX Miyoo M1.1 SDL ABI Bootstrap
Run ID: 34837973547
Job ID: 103956092779
Artifact ID: 10344993251
Artifact name: rg35xx-miyoo-m1.1-sdl-abi-bootstrap
Artifact digest / ZIP SHA256: f4fc4970c8e1ad90352e1a524f6549bd7ff5597b9cbfb312f3e1ec22895b819b
Probe SHA256: 568e96e8264244dbd74f72d601bb3cad4487793c789bbc76f5016c8f499b3f77

## Required post-build report

- commit SHA: a6a8489cbba3632bc51e9c2bda5ecd7e093fcd3d
- workflow/run ID: 34837973547
- artifact ID: 10344993251
- artifact digest: f4fc4970c8e1ad90352e1a524f6549bd7ff5597b9cbfb312f3e1ec22895b819b
- runtime SHA256: NOT BUILT — M1.1 does not build or replace Java runtime
- core SHA256: NOT BUILT — M1.1 does not build or replace Libretro core
- BUILD-PASS: YES, scope limited to standalone native SDL2 ABI probe
- DEVICE-PASS: NO — real RG35XX device test pending
- STABLE: NO
- exact scope of change: New standalone ELF32 ARM EABI5 soft-float uClibc probe using libdl to load the device system SDL2. No Java/game/audio/video platform files are installed or replaced.

## ELF gate

- ELF32 ARM
- EABI5
- soft-float ABI
- dynamic interpreter: /lib/ld-uClibc.so.0
- compile baseline: armv5te / arm926ej-s for maximum compatibility with the already-proven RG35XX uClibc toolchain

## Package validation

PACKAGE-SHA256SUMS excludes itself and `sha256sum -c` passes for every packaged file.

## Device acceptance gate

Copy `Roms/` from the artifact to SD root and run:
`Roms/APPS/Miyoo M1.1 SDL ABI/M1.1-DEVICE-TEST.sh`

Expected report:
`/mnt/mmc/RG35XX-MIYOO-M1.1-DEVICE-RESULT.txt`

Pass criteria for this checkpoint only:
1. probe executes without loader/illegal-instruction failure;
2. SDL2 dlopen succeeds;
3. SDL version and driver inventory print;
4. SDL_Init(0)=PASS;
5. probe exits code 0;
6. current runtime/core/JamVM/glibj hashes before and after are unchanged.

Even if all six pass, status advances only to DEVICE-EVIDENCE / DEVICE-PASS for the SDL ABI bootstrap scope, not for the full Miyoo platform.
