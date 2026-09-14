# MIYOO M1.3B.1 EXACT KEYMAP CALIBRATION FIX — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.3B real-device run failed at the first semantic step `UP` with `RELEASE_TIMEOUT`. The report showed the kernel initialization baseline for axis 7 was `0`, but the step later used baseline `32767` and interpreted the release-to-zero event as the press.

## SEARCH_TASKLOG_AND_HISTORY
History reviewed before implementation:
- M1.3 SDL1 joystick discovery/open succeeded but state capture produced zero changes.
- M1.3A direct `/dev/input/js0` captured 104 real events and is DEVICE-PASS for raw input transport.
- M1.3B attempted semantic calibration and failed in the test harness at the first control.
- M1.2A SDL1/fbcon video remains DEVICE-PASS and is outside this change.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
M1.3A proved axis 6/7 directions return to baseline `0` after directional press. M1.3B source updates its `axes[]` / `buttons[]` baseline arrays for every control event during the initialization-drain window, including non-INIT events. Therefore an early real press can overwrite an already-correct initialization baseline.

## CHECK_PREVIOUS_FIX_AND DEVICE EVIDENCE
- Raw `/dev/input/js0`: DEVICE-PASS (M1.3A scope).
- Exact semantic keymap: DEVICE-PASS NO.
- Current M1.3B failure is a TEST HARNESS BUG, not evidence of broken device input.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = CALIBRATION_BASELINE_MUTATED_BY_NON_INIT_EVENT
HISTORY_FOUND = YES
PREVIOUS_FIX = RAW_JS0_INPUT_TRANSPORT_WORKS
PREVIOUS_EVIDENCE_LEVEL = DEVICE-PASS_FOR_RAW_JS0_ONLY
REGRESSION_RISK = LOW

## CHOOSE_MINIMAL_CHANGE
MINIMAL_PROPOSED_CHANGE = keep M1.3B architecture and `/dev/input/js0` transport unchanged; modify only baseline acquisition so `axes[]` and `buttons[]` are written exclusively by `JS_EVENT_INIT` records. Non-INIT records observed during warm-up are drained but MUST NOT mutate baseline. Baseline stays immutable for the full calibration.

Additional harness safety:
- ignore any non-INIT event equal to immutable baseline while waiting for press;
- accept release only when the same raw control returns to immutable baseline;
- keep fixed semantic order UP,DOWN,LEFT,RIGHT,A,B,X,Y,START,SELECT,L,R;
- keep duplicate-control rejection and bounded per-step timeouts.

## FORBIDDEN CHANGES
No SDL, video, audio, JVM/JamVM, FreeJ2ME runtime/core, font, transparency, input device writes, or fallback platform changes.

## EXPECTED_DEVICE_TEST
1. Run `M1.3B.1-DEVICE-TEST.sh`.
2. Press/release exactly once in order: UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, SELECT, L, R.
3. UP/other D-pad axes must release back to immutable baseline `0` rather than a press value.
4. Produce exactly 12 `KEYMAP` rows, `KEYMAP_COUNT=12`, `M1_3B1_RESULT=PASS`, exit code 0.
5. Locked runtime/core/JamVM/glibj hashes must be identical before/after.

Passing grants DEVICE-PASS only to the exact raw semantic keymap checkpoint, not to the full Miyoo-derived platform.
