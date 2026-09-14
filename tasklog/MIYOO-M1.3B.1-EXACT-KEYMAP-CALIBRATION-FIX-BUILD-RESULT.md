# MIYOO M1.3B.1 EXACT KEYMAP CALIBRATION FIX — BUILD RESULT

BUILD-PASS: YES
DEVICE-PASS: NO
STABLE: NO

Workflow run: 34850933102
Job: 103998399677
Build head: 4108df1c01fe3c76df35892123657608cde8542e
Artifact ID: 10351191349
Artifact SHA256: b22126f9b6373caac85d18e864d241dadc5187e30fedc323997cbde763dc6ab7
Probe SHA256: 686684626c43a29f12c4c05786e271c6153bb15e0ccbec95cae4e70d8aaf32b8
Wrapper SHA256: e437a792f3e8008c6e6f64e18e15b522e70ff288712503d616bac8ebb7a8a2a8

Primary delta:
- M1.3B baseline arrays could be overwritten by non-INIT input during warm-up.
- M1.3B.1 writes baseline arrays ONLY from `JS_EVENT_INIT` records and locks them for the full calibration.
- Non-INIT warm-up records are drained but cannot mutate baseline.

Scope gates passed:
- ELF32 ARM EABI5, soft-float, `/lib/ld-uClibc.so.0`.
- No SDL dependency in probe.
- No video/audio/JVM/runtime/core/font changes.
- Flat GarlicOS Apps package only.

Real-device pass criteria remain:
- user presses/releases UP,DOWN,LEFT,RIGHT,A,B,X,Y,START,SELECT,L,R in order;
- 12 KEYMAP rows;
- KEYMAP_COUNT=12;
- M1_3B1_RESULT=PASS;
- PROBE_EXIT_CODE=0;
- locked fallback hashes unchanged before/after.
