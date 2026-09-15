# MIYOO M1.7 — JAVA -> RAW JS0 INPUT DEVICE RESULT

BUILD-PASS = YES
DEVICE-EVIDENCE = YES
DEVICE-PASS = YES
DEVICE_PASS_SCOPE = JAVA5 -> JNI -> /dev/input/js0 -> LOCKED_M1.3C_12_CONTROL_MAPPING
FULL_PLATFORM_STABLE = NO

## Real-device evidence

Original RG35XX device result:
- JAMVM_EXIT_CODE=0
- M1_7_JAVA_MARKER=PASS
- M1_7_INPUT_OPEN_RC=0
- UP/DOWN/LEFT/RIGHT/A/B/X/Y/START/SELECT/L/R all returned RC=0 in the required order
- M1_7_INPUT_SEQUENCE_MARKER=PASS
- M1_7_EXECUTION_RESULT=PASS
- protected JamVM L and glibj hashes were unchanged before/after
- no hard hang/reset was reported; test exited normally

Protected hashes:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

Locked physical mapping remains exactly M1.3C:
- UP axis7 negative
- DOWN axis7 positive
- LEFT axis6 negative
- RIGHT axis6 positive
- A/B/X/Y buttons 0/1/2/3
- START button8
- SELECT button7
- L/R buttons5/6

This does not prove MIDP Canvas dispatch or real game input yet. It proves only the Java/JNI/raw-js0 path and exact physical control recognition.
