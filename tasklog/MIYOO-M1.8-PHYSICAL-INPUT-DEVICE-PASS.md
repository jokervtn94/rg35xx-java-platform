# Miyoo-inspired M1.8 Physical Input — DEVICE-PASS

Date: 2026-09-15
Hardware: original Anbernic RG35XX / GarlicOS
Branch: miyoo-m1.8-midp-input-dispatch
Build commit: f011ba68221dc9820d0d99a38e2377d154dabbc2
CI run: 34959980076 (rerun attempt successful)
Artifact: 10393017078
Artifact digest: sha256:4e8e97efc80e7a0730b75a14530bcc333db39fed96cf7f6998dd2a1dc665487b

## CURRENT_SYMPTOM
M1.7 had already proven raw /dev/input/js0 acquisition on real RG35XX. M1.8 deterministic acceptance had proven M1InputDispatch -> canonical MobilePlatform, but the production physical js0 -> JNI -> M1InputDispatch.poll() -> MobilePlatform path still required real-device evidence.

## HISTORY_FOUND
M1.6 display is DEVICE-PASS. M1.7 raw js0 input is DEVICE-PASS. M1.8 deterministic adapter acceptance passed on device with protected JamVM/glibj hashes unchanged.

## PREVIOUS_FIX
No M1.6/M1.7 mapping or runtime change. Added only a bounded M1.8 physical acceptance harness using production M1InputDispatch.poll() and the existing JNI /dev/input/js0 owner.

## DEVICE EVIDENCE
RG35XX-MIYOO-M1.8-PHYSICAL-JAMVM.log:
- M1_8_PHYSICAL_WINDOW_MS=30000
- M1_8_PHYSICAL_PRESS_COUNT=49
- M1_8_PHYSICAL_RELEASE_COUNT=49
- M1_8_PHYSICAL_REPEAT_COUNT=28
- M1_8_PHYSICAL_ACCEPTANCE_MARKER=PASS

RG35XX-MIYOO-M1.8-PHYSICAL-RESULT.txt:
- JAMVM_EXIT_CODE=0
- M1_8_PHYSICAL_EXECUTION_RESULT=PASS
- JamVM SHA256 before/after: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj SHA256 before/after: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

Press/release counts are balanced (49/49); repeat is observed and bounded by the production adapter. No protected runtime mutation occurred.

## EVIDENCE LEVEL
M1.8_PHYSICAL_INPUT=DEVICE-PASS

Exact locked scope:
/dev/input/js0 -> m1_8_input_jni.c -> M1Input.rawGetState() -> M1InputDispatch.poll() -> MobilePlatform keyPressed/keyReleased/keyRepeated.

This checkpoint does NOT yet claim a real MIDP Canvas/GameCanvas callback/gameplay integration pass. It also does NOT promote the full platform to STABLE.

## REGRESSION RISK
M1.6 display and M1.7 raw input must remain unchanged. JamVM L and glibj remain protected by their proven SHA256 values.

## NEXT MINIMAL CHECKPOINT — M1.9
One primary variable only: integrate the already DEVICE-PASS M1.8 production input path with a real MIDP Canvas/GameCanvas acceptance application while retaining the DEVICE-PASS display path. Validate physical direction/FIRE callbacks/state, visible response, normal exit, protected hashes unchanged, and no display/input regression.

M1.6_DISPLAY=DEVICE-PASS
M1.7_RAW_JS0=DEVICE-PASS
M1.8_PHYSICAL_INPUT_TO_MOBILEPLATFORM=DEVICE-PASS
M1.9_CANVAS_GAMECANVAS_INTEGRATION=PENDING
FULL_PLATFORM_STABLE=NO
