# MIYOO M1.3A RAW JS0 INPUT PREFLIGHT

CURRENT_SYMPTOM: M1.3 SDL1 discovers and opens RG35XX Gamepad but captures zero state changes during the bounded 15 s sampling window.

HISTORY_FOUND: YES. Historical GMU logs show SDL frontend opening `RG35XX Gamepad`; kernel/device logs show `/dev/input/js0` and `/dev/input/event1` backed by `gpio-keys-polled.0/input/input1`.

PREVIOUS_FIX: No isolated mapping fix exists. M1.3 already calls `SDL_JoystickUpdate()` in its polling loop, so repeating the same SDL1 state-polling approach is not justified.

PREVIOUS_EVIDENCE_LEVEL: Hardware/input device presence and historical GMU opening = DEVICE-EVIDENCE. M1.3 SDL1 state capture = FAIL. M1.2A SDL1/fbcon video remains DEVICE-PASS and must not be changed.

REGRESSION_RISK: LOW if test is read-only against `/dev/input/js0`; do not modify video, audio, JVM, font, runtime, core, or installed Java platform.

MINIMAL_PROPOSED_CHANGE: Replace only the input observation layer for this checkpoint: SDL1 joystick state polling -> direct Linux joystick API read from `/dev/input/js0`. Keep bounded logging and preserve locked fallback hashes before/after.

EXPECTED_DEVICE_TEST: Run for 20 seconds and press D-pad, A/B/X/Y, Start/Select, L/R. Device report must contain raw `JS_EVENT_AXIS` and/or `JS_EVENT_BUTTON` records with numbers and values. Locked runtime/core/JamVM/glibj hashes must remain unchanged.

STATUS BEFORE BUILD:
- M1.2A SDL1/fbcon VIDEO = DEVICE-PASS
- M1.3 SDL1 INPUT STATE CAPTURE = FAIL
- M1.3A RAW JS0 = EXPERIMENTAL / DEVICE-TEST-PENDING
- FULL MIYOO PLATFORM = DEVICE-PASS NO
- STABLE = NO
