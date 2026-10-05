# RG35XX R1 R4 P6 Physical Acceptance — 2026-10-05

Project: RG35XX-AWEIGIT-R1
Device: original RG35XX
Branch: physical-test/rg35xx-r1-p6-p7-20261005
Candidate: RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4.zip
Candidate SHA256: 0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d
R4 source commit: c38bc78190e3b021ce4d2eb285ebd1c57e8132f1
R4 CI run: 37264599729
R4 Actions artifact: 11325956934
Golden A1P5 prime SHA256: 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e

## Programmatic evidence

- Runtime bootstrap exact existing runtime: PASS.
- A1P5 audio route prime: PASS, exit code 0.
- P1 graphics/Core2D: PASS.
- P2A image decode: PASS.
- P2B font/text: PASS.
- P2C input/frontend phase 1: PASS.
- P2C input/frontend phase 2: PASS.
- P2C input/frontend phase 3: PASS.
- P3 RMS/FileConnection: PASS.
- P3 MMAPI WAV/MIDI technical path: PASS.
- Full P6 programmatic result: PASS.

## User physical observation

User reported on original RG35XX for R4:

- WAV audible: PASS.
- MIDI audible: PASS.
- Rotation 0 -> 1 -> 2 -> 0 visually correct: PASS.
- Test finishes and returns normally to GarlicOS: PASS.

## Classification

P6_AUDIO_AUDIBLE_DEVICE=PASS
P6_ROTATION_VISUAL=PASS
P6_NORMAL_RETURN_TO_GARLICOS=PASS
P6_PHYSICAL_ACCEPTANCE=PASS

P7_TIER0_REGRESSION=NOT_TESTED_ON_R4
P8_PLATFORM_BASELINE_PROMOTION=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
DEVICE_PASS=NO
STABLE=NO

## Next legal step

Run the R4 P7 Tier-0 regression using the exact Golden inputs:

- Vua Cuop Bien: display/input/gameplay/no-hang/normal-exit.
- God of War: display/input/gameplay/no-hang/normal-exit plus physically audible audio continuity from menu into gameplay.

No platform/runtime/native modification is authorized by the P6 result. P8 may be considered only after P7 physical PASS.
