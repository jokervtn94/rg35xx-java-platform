# MIYOO M1.8 — STANDALONE MIDP DISPATCH DEVICE A/B

STATUS = DEVICE-TEST-PENDING
FULL_PLATFORM_STABLE = NO

## Preflight
CURRENT_SYMPTOM = M1.7 raw js0 is DEVICE-PASS but real MIDP Canvas/GameCanvas dispatch on the standalone path is not yet DEVICE-PASS.
HISTORY_FOUND = YES. M1.7 commit 3b84f81596d313151786dac8cb162673100d4c7e locked Java5 -> JNI -> /dev/input/js0 and all 12 controls DEVICE-PASS. Historical Platform Exerciser proved MobilePlatform/Canvas press-release-repeat semantics on the older platform only.
PREVIOUS_FIX = Keep MobilePlatform as the only MIDP event owner; convert semantic controls exactly once; do not duplicate dispatch.
PREVIOUS_EVIDENCE_LEVEL = M1.6 DEVICE-PASS; M1.7 DEVICE-PASS; M1.8 adapter/JNI BUILD-PASS; Libretro production integration is reference-only for the standalone platform.
REGRESSION_RISK = MEDIUM if M1.7 mapping is changed or a second dispatcher is introduced.
MINIMAL_PROPOSED_CHANGE = Freeze M1.7 native mapping byte-for-byte and test only semantic-state -> M1InputDispatch -> MobilePlatform -> Canvas/GameCanvas.
EXPECTED_DEVICE_TEST = 12 controls press/release; directions update GameCanvas; A=FIRE; bounded repeat; no double/stuck events; normal exit; JamVM/glibj hashes unchanged; M1.6 display still works.

## Frozen foundations
- M1.6 SDL1/fbcon display: DEVICE-PASS.
- M1.7 raw js0 input: DEVICE-PASS.
- M1.7 physical mapping must not be recalibrated.
- JamVM L SHA256 eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34.
- glibj.zip SHA256 d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea.

## Acceptance
M1.8 may become DEVICE-PASS only after real RG35XX evidence proves press/release, GameCanvas directions, FIRE, bounded repeat, no duplicate/stuck events, normal exit, protected hashes unchanged, and no display regression.

## Forbidden
No audio, font, transparency, VC7, Libretro video transport, keymap recalibration, SDL joystick replacement, game-specific mapping, or second MIDP dispatcher.

## Important
The existing Run 34946875598 / artifact 10386639469 proves the adapter/JNI build contract only. Its Libretro.java integration is REFERENCE ONLY and must not be installed as the standalone platform.
