# MIYOO M1.3 SDL1 INPUT/GAMEPAD BOOTSTRAP — PREFLIGHT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1

## Mandatory preimplementation report

- CURRENT_SYMPTOM: M1.2A proved SDL 1.2/fbcon video on the original RG35XX, but standalone Miyoo input has not yet been independently validated or mapped.
- HISTORY_FOUND: YES.
- PREVIOUS_FIX: Historical GMU device log shows `sdl_frontend: Opening joystick RG35XX Gamepad.` and kernel history shows `input: RG35XX Gamepad as /devices/platform/gpio-keys-polled.0/input/input1`. This is historical evidence that the device input exists and SDL 1.2 can discover it.
- PREVIOUS_EVIDENCE_LEVEL: DEVICE-EVIDENCE for joystick discovery only; there is no isolated DEVICE-PASS checkpoint for button/axis/hat mapping in the Miyoo standalone branch.
- REGRESSION_RISK: LOW if isolated. Existing R2.3 runtime/core/JamVM/glibj must not be replaced. M1.2A video path must not be modified.
- MINIMAL_PROPOSED_CHANGE: Add a standalone SDL 1.2 joystick probe using the device system libSDL-1.2. It will enumerate joysticks, open joystick 0, report name/axes/buttons/hats/balls, then sample raw states for a bounded 15-second window and log only state changes. No Java, audio, FreeJ2ME runtime or Libretro changes.
- EXPECTED_DEVICE_TEST: Run from GarlicOS Apps. During the 15-second sampling window press D-pad, A/B/X/Y, Start/Select, L/R and Menu. Pass scope requires SDL1 joystick discovery/open success, RG35XX Gamepad identity or equivalent device-visible joystick, raw control changes captured, clean exit, and unchanged locked fallback hashes.

## Classification

CURRENT_STATE: M1.2A SDL1/fbcon video is DEVICE-PASS. Input mapping is DEVICE-TEST-PENDING.

Primary variable: SDL 1.2 joystick/input path only.

## Locked invariants

- Preserve M1.2A SDL1/fbcon video result.
- Do not modify `/mnt/mmc/BIOS/freej2me-lr.jar`.
- Do not modify `/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`.
- Do not modify JamVM or glibj.zip.
- No audio, JVM, font, PNG, NoMask, transparency or Libretro changes.
- Bounded logging only: max 256 state-change lines, 15-second sampling window.
- BUILD-PASS is not DEVICE-PASS.
- STABLE remains NO.
