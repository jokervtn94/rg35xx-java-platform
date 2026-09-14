# MIYOO M1.2A SDL 1.2 VIDEO FALLBACK — BUILD RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Artifact build commit: ba436e4e0774404f5a9cea39073b565c9628296f
Workflow: RG35XX Miyoo M1.2A SDL1 Video Fallback
Run ID: 34840729732
Job ID: 103964839953
Artifact ID: 10345379910
Artifact name: rg35xx-miyoo-m1.2a-sdl1-video
Artifact digest / ZIP SHA256: c447ac014609dd67e9faf1e90ad905078a92b479b2d7968d85c86782893a57df
Probe SHA256: 510c9f300c435909f0c93d2ebb9b9c60aa046519cc04f628e5bc1ecc2ce70cc4

## Required post-build report

- commit SHA: ba436e4e0774404f5a9cea39073b565c9628296f
- workflow/run ID: 34840729732
- artifact ID: 10345379910
- artifact digest: c447ac014609dd67e9faf1e90ad905078a92b479b2d7968d85c86782893a57df
- runtime SHA256: NOT BUILT / NOT MODIFIED
- core SHA256: NOT BUILT / NOT MODIFIED
- BUILD-PASS: YES, limited to standalone SDL 1.2 video probe
- DEVICE-PASS: NO — real-device test pending
- STABLE: NO
- exact scope of change: standalone ELF32 ARM EABI5 soft-float uClibc probe dynamically loading the existing system SDL 1.2 library; calls SDL 1.2 video init + 640x480x32 fullscreen mode + four fill/flip frames. No input, audio, JVM, Java, Libretro, font, or system library changes.

## Historical basis

M1.2 SDL2 VIDEO failed on real original RG35XX with `No available video device` and empty DISPLAY. Historical GMU log on RG35XX reports successful SDL video init, 640x480 @ 32 bpp display surface, and RG35XX Gamepad open. Device audit confirms SDL 1.2 system library exists.

## Device acceptance gate

Run `Roms/APPS/M1.2A-DEVICE-TEST.sh` on the real device.
Expected report: `/mnt/mmc/RG35XX-MIYOO-M1.2A-DEVICE-RESULT.txt`.

Pass criteria for this checkpoint only:
1. probe executes normally;
2. SDL 1.2 dlopen succeeds;
3. `SDL1_INIT_VIDEO=PASS`;
4. a real non-dummy video path creates 640x480x32 surface;
5. physical LCD visibly cycles RED -> GREEN -> BLUE -> WHITE;
6. exit code 0;
7. fallback runtime/core/JamVM/glibj hashes remain unchanged.

Even if all pass, only the SDL1 standalone video path may be promoted to DEVICE-PASS. Full Miyoo platform remains DEVICE-PASS NO / STABLE NO.
