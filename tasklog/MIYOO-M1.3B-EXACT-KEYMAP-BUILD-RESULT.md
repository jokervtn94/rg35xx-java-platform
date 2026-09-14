# MIYOO M1.3B EXACT RG35XX KEYMAP — BUILD RESULT

## Scope
Read-only exact semantic keymap calibration over `/dev/input/js0` only.

## Build
- Branch: `rg35xx-miyoo-platform-v1`
- Head commit: `e336aa4c9bfe9d6a9ca8b4b584c4b82e18765e70`
- Workflow run: `34845689063`
- Job: `103980948597`
- Artifact ID: `10347973038`
- Artifact name: `rg35xx-miyoo-m1.3b-exact-keymap`
- Artifact SHA256: `0ed7dd44060aa5e0b3e84c80403357c96e34fb39192afa9a4483303050865036`
- Probe SHA256: `c1293e1856307769249fc42a54d8ed53d3bb81af72272b351fe72c4851052719`
- Wrapper SHA256: `e7de065b4e261190824e95610874e963dc8da7c8e68ff3d5db0d020cfea80607`

## Gates passed
- Project rules present.
- M1.3B preflight present.
- Pinned uClibc toolchain used.
- ELF32 ARM EABI5 soft-float.
- Interpreter `/lib/ld-uClibc.so.0`.
- No SDL symbols in probe source.
- No audio/font/JamVM/FreeJ2ME dependency in probe source.
- Device wrapper syntax gate passed.
- Flat GarlicOS `Roms/APPS` package created.

## Classification
- BUILD-PASS = YES
- DEVICE-EVIDENCE = PENDING
- DEVICE-PASS = NO
- STABLE = NO

## Required device test
Run `M1.3B-DEVICE-TEST.sh` and press/release exactly once in this order:

`UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, SELECT, L, R`

Expected success:
- 12 deterministic `KEYMAP` rows,
- `KEYMAP_COUNT=12`,
- `M1_3B_RESULT=PASS`,
- `PROBE_EXIT_CODE=0`,
- locked fallback hashes identical before/after.

Do not promote the semantic keymap or full platform until real-device evidence is returned.
