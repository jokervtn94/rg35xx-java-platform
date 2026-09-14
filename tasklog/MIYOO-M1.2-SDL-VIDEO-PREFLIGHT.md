# MIYOO M1.2 SDL VIDEO BOOTSTRAP — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory historical-first report

- CURRENT_SYMPTOM: M1.1A passed on real original RG35XX: the standalone uClibc ELF executes, dlopen of system SDL2 2.0.8 succeeds, SDL_Init(0) succeeds, and the locked R2.3 fallback hashes remain unchanged. However M1.1A only initialized SDL with flags=0 and did not prove any real display path.
- HISTORY_FOUND: YES. Project history contains proven Libretro/RGB565 rendering paths, but no tasklog entry demonstrates a standalone SDL2 video window/renderer on original RG35XX GarlicOS. Miyoo upstream initializes SDL_INIT_VIDEO, creates a 640x480 window and renderer, and presents frames directly.
- PREVIOUS_FIX: M1.1A fixed only the GarlicOS packaging/path mismatch. No SDL video fix exists yet for this branch.
- PREVIOUS_EVIDENCE_LEVEL: M1.1A standalone loader/SDL2 basic ABI = DEVICE-PASS for that limited scope. Full Miyoo platform = DEVICE-PASS NO / STABLE NO.
- REGRESSION_RISK: Enabling input/audio/JVM at the same time would bundle unrelated variables. System SDL2 advertises only x11 and dummy video drivers, so a real video init may fail on GarlicOS even though SDL_Init(0) passed.
- MINIMAL_PROPOSED_CHANGE: Add one standalone M1.2 native probe which dynamically loads the same system SDL2 and calls SDL_Init(SDL_INIT_VIDEO), creates a 640x480 shown window, creates a software renderer, presents a bounded color pattern for 4 seconds, then destroys all SDL objects and exits. No input, audio, Java, Libretro, font, or existing platform files are changed.
- EXPECTED_DEVICE_TEST: Launch from GarlicOS Apps. PASS requires SDL_INIT_VIDEO=PASS, a real non-dummy current video driver, window creation PASS, renderer creation PASS, four visible color frames/pattern stages, clean exit 0, and unchanged fallback hashes. If SDL selects dummy or video init/window creation fails, classify it as a standalone SDL2 video blocker and do not proceed to input/JVM.

## Source comparison

Pinned Miyoo reference: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63.
Its SDL frontend calls SDL_Init(SDL_INIT_VIDEO), creates a 640x480 SDL window, creates an accelerated/vsync renderer, then renders RGB565 frames. M1.2 deliberately uses a software renderer first to minimize GPU/backend assumptions.

## Scope lock

Primary variable: standalone SDL2 VIDEO subsystem compatibility only.

MUST NOT:
- initialize SDL audio
- add SDL input/game-controller logic
- replace current Java runtime/core/JamVM/glibj
- import R2.x video/audio/font patches
- force SDL_VIDEODRIVER=dummy and call that device success
- claim full Miyoo DEVICE-PASS/STABLE

## Status before implementation

M1.1A_SDL_BASIC_ABI: DEVICE-PASS
SDL2_VIDEO_REAL_DISPLAY: DEVICE-TEST-PENDING
SDL2_INPUT: NOT TESTED
JVM_STRATEGY: UNVERIFIED
FULL_Miyoo_DEVICE_PASS: NO
STABLE: NO
