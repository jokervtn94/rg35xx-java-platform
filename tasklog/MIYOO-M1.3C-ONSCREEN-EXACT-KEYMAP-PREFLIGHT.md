# MIYOO M1.3C ONSCREEN EXACT RG35XX KEYMAP — PREFLIGHT

## IDENTIFY_CURRENT_SYMPTOM
M1.3B.1 fixed immutable INIT baseline handling and completed 12 harness steps, but the semantic assignments are not trustworthy because the device user could not see the currently expected control on the physical LCD. The report therefore contains a sequence that does not match known D-pad behavior: UP was captured as axis 6 -32767, while subsequent DOWN/LEFT/RIGHT were captured as buttons.

A second harness limitation is now explicit: the old duplicate rule rejected reuse of the same raw axis index. A joystick D-pad commonly represents opposite directions on the same axis, so UP/DOWN and LEFT/RIGHT must be allowed to share an axis when their press values/signs differ.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- M1.2A SDL1/fbcon video: scope-specific DEVICE-PASS on original RG35XX; physical LCD displayed all four colors.
- M1.3 SDL1 joystick-state capture: FAIL.
- M1.3A raw /dev/input/js0 transport: scope-specific DEVICE-PASS with 104 real events.
- M1.3B: TEST-HARNESS FAIL due mutable baseline.
- M1.3B.1: baseline/release mechanism PASS, but exact semantic map NOT LOCKED because the user could not follow invisible EXPECT prompts and the axis duplicate model is insufficient.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Do not return to SDL joystick state polling. Do not alter the device-proven SDL1/fbcon path. Reuse only the already-proven transports and change the semantic calibration UI/state machine.

## CHECK PREVIOUS FIX AND DEVICE EVIDENCE
- SDL1/fbcon video transport = DEVICE-PASS.
- raw /dev/input/js0 transport = DEVICE-PASS.
- immutable INIT baseline handling = DEVICE-EVIDENCE/PASS for harness behavior.
- exact semantic keymap = NOT DEVICE-PASS.

## CLASSIFY CURRENT STATE
CURRENT_SYMPTOM = SEMANTIC_KEYMAP_NOT_RELIABLE_WITH_HEADLESS_SEQUENTIAL_PROMPTS
HISTORY_FOUND = YES
PREVIOUS_FIX = SDL1_FBCON_VIDEO_PLUS_RAW_JS0_INPUT
PREVIOUS_EVIDENCE_LEVEL = BOTH_TRANSPORTS_DEVICE_PASS_SCOPE_SPECIFIC
REGRESSION_RISK = LOW_IF_STANDALONE_READ_ONLY_CALIBRATION_ONLY

## CHOOSE MINIMAL CHANGE
MINIMAL_PROPOSED_CHANGE = standalone calibration probe that combines the already-proven SDL1/fbcon display path with read-only /dev/input/js0. The physical LCD must show exactly one large instruction at a time: PRESS UP, PRESS DOWN, PRESS LEFT, PRESS RIGHT, PRESS A, PRESS B, PRESS X, PRESS Y, PRESS START, PRESS SELECT, PRESS L, PRESS R. Advance only after one valid press and matching release for the displayed semantic control.

Harness rules:
- baseline is sourced only from JS_EVENT_INIT and remains immutable;
- drain stale non-INIT input before displaying/waiting for each step;
- buttons are unique by button index;
- axes are unique by (axis index, press direction/value), allowing opposite directions on the same axis;
- release must return the same raw control to immutable baseline;
- render CONFIRMED briefly after each accepted control;
- bounded 60-second press timeout and 10-second release timeout per control;
- output deterministic KEYMAP rows and fail closed on duplicate semantic raw assignment, timeout, video init failure, or js0 open failure.

## FORBIDDEN CHANGES
No SDL joystick state API, no SDL2, no audio, no JVM/JamVM, no FreeJ2ME runtime/core, no font engine, no transparency, no input-device writes, no replacement of system SDL libraries, and no modification to the locked fallback platform.

## EXPECTED DEVICE TEST
1. Launch `M1.3C-DEVICE-TEST.sh` from Apps.
2. Follow the instruction shown on the RG35XX LCD; press/release only the named control.
3. Complete all 12 controls.
4. Report must contain exactly 12 KEYMAP rows, KEYMAP_COUNT=12, M1_3C_RESULT=PASS and PROBE_EXIT_CODE=0.
5. D-pad is expected to resolve as axis controls; opposite directions may share the same axis with opposite values.
6. Locked runtime/core/JamVM/glibj hashes must remain identical before/after.

Passing grants DEVICE-PASS only to the exact semantic keymap checkpoint. FULL MIYOO PLATFORM remains DEVICE-PASS NO / STABLE NO.
