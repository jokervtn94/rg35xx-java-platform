# MIYOO M1.3B EXACT RG35XX KEYMAP — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.3 detected and opened `RG35XX Gamepad` through SDL 1.2 but captured zero state changes. M1.3A bypassed SDL and captured 104 real events from `/dev/input/js0` on the original RG35XX, proving the kernel joystick path works. The remaining gap is semantic mapping: which raw axis/button index corresponds to UP/DOWN/LEFT/RIGHT/A/B/X/Y/START/SELECT/L/R.

## SEARCH_TASKLOG_AND_HISTORY
History reviewed before implementation:
- M1.2A established SDL 1.2/fbcon video on real device.
- M1.3 established joystick discovery/open but state capture failed.
- M1.3A established raw `/dev/input/js0` capture and preserved all locked fallback hashes.
- Historical GMU evidence shows `RG35XX Gamepad` existed and was usable, but does not provide a separately device-validated production semantic map for this new standalone platform.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
This is not a hardware absence or ABI failure. The same gamepad is visible as `js0` and `event1`. M1.3A proves press/release activity reaches `js0`. Therefore the next change must not alter SDL/video/JVM/audio or retry SDL joystick state capture.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
- M1.2A SDL1/fbcon video: DEVICE-PASS (scope-specific).
- M1.3 SDL1 joystick state capture: DEVICE-PASS NO.
- M1.3A raw js0 capture: DEVICE-PASS (scope-specific raw input transport).
- Exact semantic keymap: NOT YET DEVICE-PASS.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = RAW_INPUT_WORKS_BUT_SEMANTIC_KEYMAP_NOT_LOCKED
HISTORY_FOUND = YES
PREVIOUS_FIX = RAW_JS0_BYPASS_OF_SDL_STATE_LAYER
PREVIOUS_EVIDENCE_LEVEL = DEVICE-PASS_FOR_RAW_JS0_TRANSPORT_ONLY
REGRESSION_RISK = LOW_IF_READ_ONLY_JS0_CALIBRATION_ONLY

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = add a read-only `/dev/input/js0` calibration probe that records exactly one complete press/release pair per named control, in a fixed user-driven order: UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, SELECT, L, R.

The probe must:
- use only `/dev/input/js0`;
- consume initialization events and establish baseline values;
- wait for one non-baseline press then matching release before advancing;
- print a deterministic `KEYMAP` line for each named control;
- fail closed on timeout, duplicate raw control assignment, missing release, or device open failure;
- never write to input devices;
- never alter the existing Java platform.

## FORBIDDEN CHANGES
- No SDL changes.
- No video changes.
- No audio changes.
- No JVM/JamVM changes.
- No FreeJ2ME runtime/core changes.
- No font/transparency changes.
- No inferred production keymap before real-device calibration.

## EXPECTED_DEVICE_TEST
1. Install flat Apps package.
2. Start `M1.3B-DEVICE-TEST.sh`.
3. After launch, press and release exactly once, in this order: UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, SELECT, L, R.
4. The probe must output 12 unique `KEYMAP` rows and `M1_3B_RESULT=PASS` with exit code 0.
5. Locked fallback hashes before/after must remain identical.

Passing M1.3B grants DEVICE-PASS only to the exact raw-input semantic map. It does not make the whole Miyoo-derived platform STABLE.
