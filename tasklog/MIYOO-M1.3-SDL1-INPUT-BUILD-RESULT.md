# MIYOO M1.3 SDL1 INPUT/GAMEPAD BOOTSTRAP — BUILD RESULT

Date: 2026-09-14
Artifact build commit: 55ec5ff06388a0bb3e1730fda63bdaf93d20539f
Workflow: RG35XX Miyoo M1.3 SDL1 Input Bootstrap
Run ID: 34841689893
Job ID: 103967918547
Artifact ID: 10346825590
Artifact name: rg35xx-miyoo-m1.3-sdl1-input
Artifact digest / ZIP SHA256: 0d9e885cdea822f08ffc0b0550a99df57e689926ac18216f68d9640aeb51f75d
Probe SHA256: c575adc359fdfff94b156ebd190c912b850a0e65e66563e1461689f9de46a5c3

## Required post-build report

- commit SHA: 55ec5ff06388a0bb3e1730fda63bdaf93d20539f
- workflow/run ID: 34841689893
- artifact ID: 10346825590
- artifact digest: 0d9e885cdea822f08ffc0b0550a99df57e689926ac18216f68d9640aeb51f75d
- runtime SHA256: NOT BUILT — M1.3 does not build or replace Java runtime
- core SHA256: NOT BUILT — M1.3 does not build or replace Libretro core
- BUILD-PASS: YES, scope limited to standalone SDL 1.2 joystick/input discovery and bounded raw-state capture
- DEVICE-PASS: NO — real RG35XX device test pending
- STABLE: NO
- exact scope of change: New standalone ELF32 ARM EABI5 soft-float uClibc probe using libdl to load device system SDL 1.2, enumerate/open joystick 0, report capabilities, and capture bounded axis/button/hat state changes for 15 seconds. Existing Java platform files are not replaced.

## Device acceptance gate

Copy `Roms/` from artifact to SD root, merge only, and run `Apps -> M1.3-DEVICE-TEST.sh`.
Immediately press D-pad, A/B/X/Y, Start/Select and L/R repeatedly during the approximately 15-second capture window. Avoid Menu for this checkpoint because GarlicOS may intercept it.

Expected report:
`/mnt/mmc/RG35XX-MIYOO-M1.3-DEVICE-RESULT.txt`

Pass criteria for this checkpoint only:
1. SDL 1.2 joystick init succeeds;
2. at least one joystick is discovered and opens;
3. joystick name/capabilities are reported;
4. raw axis/button/hat changes are captured;
5. probe exits code 0;
6. locked runtime/core/JamVM/glibj hashes before and after are unchanged.

BUILD-PASS does not imply full Miyoo platform DEVICE-PASS or STABLE.
