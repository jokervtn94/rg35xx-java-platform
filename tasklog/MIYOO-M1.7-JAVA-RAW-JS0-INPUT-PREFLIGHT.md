# MIYOO M1.7 — JAVA -> RAW JS0 INPUT PREFLIGHT

## Mandatory tasklog-first review

CURRENT_SYMPTOM = M1.6_JAVA_DISPLAY_DEVICE_PASS_BUT_JAVA_INPUT_NOT_INTEGRATED
HISTORY_FOUND = YES
PREVIOUS_FIX = RAW_/dev/input/js0_PLUS_EXACT_M1.3C_SEMANTIC_KEYMAP
PREVIOUS_EVIDENCE_LEVEL = M1.3A_RAW_JS0_DEVICE_EVIDENCE_AND_M1.3C_EXACT_KEYMAP_REAL_DEVICE_PASS_RESULT; M1.6_JAVA_DISPLAY_DEVICE_PASS
REGRESSION_RISK = MEDIUM
PRIMARY_VARIABLE = CONNECT_JAVA_TO_RAW_/dev/input/js0_INPUT_ONLY_WHILE_PRESERVING_M1.6_DISPLAY

Historical real-device keymap to preserve exactly:
- UP = axis 7 negative
- DOWN = axis 7 positive
- LEFT = axis 6 negative
- RIGHT = axis 6 positive
- A = button 0
- B = button 1
- X = button 2
- Y = button 3
- START = button 8
- SELECT = button 7
- L = button 5
- R = button 6

M1.3A proved raw js0 events on the original RG35XX. M1.3C calibrated the semantic mapping on the physical LCD. M1.6 proved JamVM L -> Java5 -> JNI -> SDL1/fbcon -> physical LCD and is frozen as the display foundation.

## Minimal proposed change

Extend the isolated Java/JNI test package with raw Linux joystick reading only. Keep the M1.6 SDL1/fbcon display path unchanged in concept. Java requests the next semantic input event from JNI; JNI reads `/dev/input/js0`, maps only the locked M1.3C controls, and returns a compact semantic code. Java displays/logs the recognized control. No MIDP game input dispatch is added yet.

## Forbidden in M1.7

- no SDL joystick input
- no event1 input replacement
- no keymap recalibration or remapping
- no audio/MIDI/SDL_mixer
- no game JAR execution
- no font/transparency/NoMask/VC7/Libretro transport
- no JamVM/glibj modification
- no change to M1.6 display behavior beyond what is necessary to show bounded input-test state

## Expected device test

User follows an on-screen sequence UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, SELECT, L, R. Each required control must be recognized from `/dev/input/js0` using the locked mapping. The test must then exit normally. JamVM/glibj hashes must remain unchanged and M1.6 display must show no regression.

BUILD-PASS != DEVICE-PASS. Full platform remains STABLE=NO.
