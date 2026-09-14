# MIYOO M1.2 SDL VIDEO BOOTSTRAP — BUILD RESULT

Date: 2026-09-14
Artifact build commit: b0e47ebce2e0bcb470f3d1be8c716d9afda0c69f
Workflow: RG35XX Miyoo M1.2 SDL Video Bootstrap
Run ID: 34839712506
Job ID: 103961583155
Artifact ID: 10345253315
Artifact name: rg35xx-miyoo-m1.2-sdl-video
Artifact digest / ZIP SHA256: 6c7926d1638686749d6930eb27c97fa99f0d2b01e932ba4a9669168c7d71dce2
Probe SHA256: 733173d044a13e52ccc0051a4ab2e16aba3daeee5684288a684aa0f3dc205a16

## Required post-build report

- commit SHA: b0e47ebce2e0bcb470f3d1be8c716d9afda0c69f
- workflow/run ID: 34839712506
- artifact ID: 10345253315
- artifact digest: 6c7926d1638686749d6930eb27c97fa99f0d2b01e932ba4a9669168c7d71dce2
- runtime SHA256: NOT BUILT — M1.2 does not build or replace Java runtime
- core SHA256: NOT BUILT — M1.2 does not build or replace Libretro core
- BUILD-PASS: YES, scope limited to standalone SDL2 VIDEO probe
- DEVICE-PASS: NO — real RG35XX video test + visual confirmation pending
- STABLE: NO
- exact scope of change: New standalone ELF32 ARM EABI5 soft-float uClibc probe that dlopens system SDL2, initializes SDL_INIT_VIDEO, rejects dummy driver, creates a 640x480 window/software renderer, presents RED/GREEN/BLUE/WHITE for one second each, cleans up and exits. No input/audio/JVM/Libretro/platform files changed.

## CI gates

All passed:
- project rules + mandatory preflight
- pinned ARM uClibc toolchain
- ELF32 ARM EABI5 soft-float
- video-only marker present
- no SDL_INIT_AUDIO marker
- flat GarlicOS Roms/APPS layout
- package checksum verification

## Device acceptance

Copy/merge `Roms/` to SD root and launch `M1.2-DEVICE-TEST.sh` from Apps.

Expected result file:
`/mnt/mmc/RG35XX-MIYOO-M1.2-DEVICE-RESULT.txt`

For scope DEVICE-PASS, require BOTH:
1. log has SDL_INIT_VIDEO=PASS, non-dummy CURRENT_VIDEO_DRIVER, SDL_CREATE_WINDOW=PASS, SDL_CREATE_RENDERER=PASS, four RENDER_STAGE PASS entries, CLEAN_SHUTDOWN=PASS, M1_2_RESULT=PASS, PROBE_EXIT_CODE=0, and unchanged fallback hashes;
2. user visually confirms the physical RG35XX LCD displayed RED -> GREEN -> BLUE -> WHITE.

If video init fails because only X11/dummy are usable on GarlicOS, stop before M1.3 and classify standalone Miyoo SDL2 video as blocked on the stock system SDL2 build.
