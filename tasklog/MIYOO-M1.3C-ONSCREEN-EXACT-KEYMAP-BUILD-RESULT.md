# MIYOO M1.3C ONSCREEN EXACT RG35XX KEYMAP — BUILD RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Build commit: 93721c13072bc318b8cb626665436447ba5c34a9
Workflow: RG35XX Miyoo M1.3C Onscreen Exact Keymap
Run ID: 34868057782
Job ID: 104056773438
Artifact ID: 10357772528
Artifact name: rg35xx-miyoo-m1.3c-onscreen-keymap
Artifact ZIP SHA256: e101637de6da93b147b3d90d6de28f3e64a5a991f485ee83df2123405c54f9a6
Probe SHA256: 01e1aeef8c54dc26c1203412f3d6eba6d35f793a46c83c77525151d94397bc7b
Wrapper SHA256: db48e2834d73d46f00e05d199729ea8d950fc749952f0a17686d5870bcdbc608

## Required classification
- BUILD-PASS: YES
- DEVICE-EVIDENCE: PENDING
- DEVICE-PASS: NO
- STABLE: NO
- Full Miyoo platform DEVICE-PASS: NO

## Exact scope
Standalone ELF32 ARM EABI5 soft-float uClibc probe only. It reuses the already device-proven SDL1/fbcon screen path and already device-proven read-only `/dev/input/js0` transport to present visible per-control prompts on the physical LCD and capture exact semantic mappings.

No SDL joystick-state API, SDL2, audio, JVM/JamVM, FreeJ2ME runtime/core, font engine, transparency, system SDL replacement, or fallback-platform modifications are included.

## Device acceptance gate
Run `Roms/APPS/M1.3C-DEVICE-TEST.sh` on the original RG35XX and follow only the control name shown on the LCD. The probe must reach 12 deterministic KEYMAP rows, KEYMAP_COUNT=12, M1_3C_RESULT=PASS, PROBE_EXIT_CODE=0, and the four locked fallback hashes must be identical before/after.

Axis duplicate semantics are direction-aware: opposite directions on the same axis are valid distinct semantic controls.
