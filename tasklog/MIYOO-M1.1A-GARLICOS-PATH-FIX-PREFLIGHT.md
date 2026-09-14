# MIYOO M1.1A GARLICOS PATH FIX — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory historical-first report

- CURRENT_SYMPTOM: Real-device M1.1 result did not execute the SDL2 probe. The wrapper ran from `/mnt/mmc/Roms/APPS/M1.1-DEVICE-TEST.sh` and searched for `/mnt/mmc/Roms/APPS/m1_1_sdl2_probe`, while the artifact packaged both files under `Roms/APPS/Miyoo M1.1 SDL ABI/`. Exit code was 127. This is a launcher/package path mismatch, not an SDL2 ABI failure.
- HISTORY_FOUND: YES. Project history contains installer/path-mismatch incidents and the hard rules require fail-closed path handling. M1.1 build itself passed ELF/package gates, but there is no real-device SDL2 execution evidence yet.
- PREVIOUS_FIX: M1.1 packaged the script and probe in a subdirectory and relied on resolving the script directory at runtime. GarlicOS execution in the observed device path flattened/located the script directly under `Roms/APPS`, so the expected sibling probe was absent.
- PREVIOUS_EVIDENCE_LEVEL: BUILD-PASS for the M1.1 probe. The device result only proves the wrapper executed and existing Java fallback hashes remained unchanged; it does not test the probe or SDL2 ABI.
- REGRESSION_RISK: Rebuilding or changing the probe would mix a packaging fix with ABI behavior. Changing Java/audio/video is forbidden for this checkpoint.
- MINIMAL_PROPOSED_CHANGE: Keep the exact M1.1 probe source and compile flags unchanged. Package `M1.1A-DEVICE-TEST.sh` and `m1_1_sdl2_probe` directly in `Roms/APPS/`, and make the wrapper search only bounded known locations: its own directory, the historical M1.1 subdirectory, and `/mnt/mmc/Roms/APPS`. Fail closed with `FAIL_PROBE_NOT_FOUND` if none exists.
- EXPECTED_DEVICE_TEST: Copy `Roms/` to SD root, run `Apps -> M1.1A-DEVICE-TEST.sh`, and return `/mnt/mmc/RG35XX-MIYOO-M1.1A-DEVICE-RESULT.txt`. The probe must execute, SDL2 dlopen and SDL_Init(0) must pass, exit code must be 0, and all locked fallback hashes must remain unchanged.

## Classification of uploaded M1.1 result

- PLATFORM_HASHES_BEFORE_AFTER: UNCHANGED
- SYSTEM_SDL2_PRESENT: YES
- PROBE_EXECUTED: NO
- FAILURE_CLASS: PACKAGING_PATH_MISMATCH
- SDL2_ABI_RESULT: NOT_TESTED
- DEVICE_PASS: NO
- STABLE: NO

## Scope lock

Primary variable: GarlicOS package/launcher path only.

MUST NOT change:
- `m1_1_sdl2_probe.c`
- compiler/toolchain/ABI flags
- system SDL2
- Java runtime/core/JamVM/glibj
- audio/video/font logic
