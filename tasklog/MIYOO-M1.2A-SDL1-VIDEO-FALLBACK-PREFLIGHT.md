# MIYOO M1.2A SDL 1.2 VIDEO FALLBACK — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory historical-first report

- CURRENT_SYMPTOM: M1.2 standalone SDL2 video probe executes but `SDL_Init(SDL_INIT_VIDEO)` fails on real original RG35XX with `No available video device`; physical LCD remains unchanged and the app exits normally. Device environment has `DISPLAY=` empty and SDL2 reports only x11/dummy video drivers.
- HISTORY_FOUND: YES. Historical real-device GMU log on this RG35XX family reports `Available screen real estate: 640 x 480 pixels @ 32 bpp`, `Opening joystick RG35XX Gamepad`, `SDL-Video init done`, and `Display surface initialized`. Device audit also confirms system SDL 1.2 (`/usr/lib/libSDL-1.2.so.0.11.4`) is installed alongside SDL2.
- PREVIOUS_FIX: No prior Miyoo standalone SDL2 framebuffer fix exists. Historical working application used an SDL frontend that successfully initialized display on RG35XX. This makes the existing SDL 1.2 stack a higher-evidence candidate than inventing a new SDL2 framebuffer build.
- PREVIOUS_EVIDENCE_LEVEL: M1.1A native uClibc + SDL2 dlopen/basic init is DEVICE-PASS for its limited scope. M1.2 SDL2 VIDEO is real-device FAIL. Historical GMU SDL frontend is DEVICE-EVIDENCE for working 640x480 display and RG35XX gamepad.
- REGRESSION_RISK: Low if implemented as a standalone read-only Apps probe. High if replacing system SDL libraries or modifying R2.3 Java/Libretro files, therefore those actions are forbidden.
- MINIMAL_PROPOSED_CHANGE: One primary variable only: switch standalone video probe from system SDL2 video API to the already-installed system SDL 1.2 video API, loaded dynamically with libdl. Do not touch input, audio, JVM, Java runtime, Libretro core, font, or system libraries.
- EXPECTED_DEVICE_TEST: Run from GarlicOS Apps. Probe must dlopen system SDL 1.2, call `SDL_Init(SDL_INIT_VIDEO)`, report active driver, create a 640x480 32-bpp surface with `SDL_SetVideoMode`, fill/flip four full-screen test colors for ~1 second each, then exit cleanly. Existing fallback hashes must remain unchanged.

## Evidence comparison

M1.2 real-device result:
- ELF/probe executes: PASS
- SDL2 basic ABI from M1.1A: PASS
- SDL2 VIDEO init: FAIL (`No available video device`)
- DISPLAY: empty
- SDL2 video drivers previously enumerated: x11, dummy
- visual output: none

Historical GMU result:
- RG35XX detected
- screen real estate: 640x480 @ 32 bpp
- SDL-Video init done
- display surface initialized
- RG35XX Gamepad opened

## Scope lock

Primary variable: system SDL 1.2 video path instead of system SDL2 video path.

MUST NOT:
- replace any system SDL library
- modify current Java runtime/core/JamVM/glibj
- add input mapping yet
- add audio or SDL_mixer
- add JVM/FreeJ2ME
- claim full Miyoo DEVICE-PASS/STABLE

## Status before implementation

M1.1A_SDL2_BASIC_ABI: DEVICE-PASS
M1.2_SDL2_VIDEO: FAIL
M1.2A_SDL1_VIDEO: DEVICE-TEST-PENDING
FULL_MiYOO_PLATFORM_DEVICE_PASS: NO
STABLE: NO
