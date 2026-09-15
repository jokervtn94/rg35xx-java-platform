# MIYOO M1.8 — RAW JS0 -> FREEJ2ME MIDP INPUT DISPATCH PREFLIGHT

## Required classification

CURRENT_SYMPTOM = M1.7_RAW_JS0_JAVA_INPUT_DEVICE_PASS_BUT_FREEJ2ME_MIDP_CANVAS_DISPATCH_UNKNOWN
HISTORY_FOUND = YES
PREVIOUS_FIX = HISTORICAL_FREEJ2ME_INPUT_OWNER_DISPATCHES_THROUGH_MOBILEPLATFORM_KEYPRESSED_KEYRELEASED_KEYREPEATED; RC1_0013_DOCUMENTED_SINGLE_CONVERSION_AND_NO_DUPLICATE_DISPATCH
PREVIOUS_EVIDENCE_LEVEL = M1.7_RAW_JS0_DEVICE_PASS; HISTORICAL_PLATFORM_EXERCISER_INPUT_PRESS_RELEASE_REPEAT_PASS; RC1_INPUT_INTEGRATION_ONLY_STATIC_AUDIT_NOT_DEVICE_PASS_FOR_THIS_MIYOO_PATH
REGRESSION_RISK = MEDIUM
PRIMARY_VARIABLE = CONNECT_M1.7_LOCKED_RAW_JS0_SEMANTIC_EVENTS_TO_EXISTING_FREEJ2ME_MOBILEPLATFORM_MIDP_KEY_DISPATCH_ONLY
MINIMAL_PROPOSED_CHANGE = PRESERVE_M1.6_DISPLAY_AND_M1.7_RAW_INPUT; ADD_ONE_BOUNDED_ADAPTER_FROM_LOCKED_PHYSICAL_CONTROLS_TO_EXISTING_FREEJ2ME_KEY_OWNER_AND_TEST_PRESS_RELEASE_REPEAT_GAMEACTION
EXPECTED_DEVICE_TEST = REAL_RG35XX_MIDP_TEST_CANVAS_RECEIVES_EXPECTED_KEYPRESSED_KEYRELEASED_AND_BOUNDED_REPEAT_FOR_LOCKED_CONTROLS; GAMEACTION_DIRECTION_FIRE_SEMANTICS_MATCH; NORMAL_EXIT; PROTECTED_HASHES_UNCHANGED; NO_DISPLAY_REGRESSION

## Mandatory tasklog/history comparison

1. M1.7 has real-device DEVICE-PASS for Java5 -> JNI -> `/dev/input/js0` and all 12 locked M1.3C controls. This physical mapping is frozen and must not be recalibrated.
2. Historical Platform Exerciser exercised MIDP `keyPressed`, `keyReleased`, `keyRepeated`, and `getGameAction`; historical evidence reported input press/release/repeat PASS. That proves the older FreeJ2ME platform owner family could deliver MIDP input, but it is not proof that the new Miyoo branch path is integrated.
3. Historical RC1 input contract `patches/0013-libretro-rg35xx-input-engine.patch` established important ownership rules: `MobilePlatform` owns MIDP/vendor dispatch, conversion must happen exactly once, duplicate direct dispatch is forbidden, and held/repeat state must have one owner.
4. `docs/RC1-GRAPHICS-INPUT-LIFECYCLE-AUDIT.md` was only STATIC-AUDIT-PASS. It identified exact transition/repeat sites and warned against duplicate dispatch; it was not DEVICE-PASS for the new path.
5. The pinned Miyoo source `MobilePlatform` already implements `keyPressed`, `keyReleased`, `keyRepeated` and updates GameCanvas key state before forwarding to the current Displayable. Therefore M1.8 must use that existing owner rather than invent a second MIDP dispatcher.

## Important architecture difference from old Libretro path

The historical RC1 contract used frontend slots plus `Mobile.getMobileKey(slot)`. M1.7 instead produces semantic physical RG35XX controls directly from raw js0. M1.8 must not blindly reuse Libretro slot numbers as if raw-js0 semantic IDs were the same namespace. A small explicit semantic-control -> existing FreeJ2ME keycode adapter is required and must be test-gated. This is a new minimal adapter, not a new MIDP event system.

## Preserve

- M1.6 Java -> JNI -> SDL1/fbcon display DEVICE-PASS foundation unchanged.
- M1.7 raw js0 reader and exact M1.3C physical mapping unchanged.
- JamVM L and glibj protected binaries unchanged.
- Existing FreeJ2ME `MobilePlatform` remains MIDP key-state/event owner.
- Existing Canvas/GameCanvas semantics remain authoritative.

## Forbidden in M1.8

- no SDL joystick path
- no keymap recalibration
- no audio/MIDI/SDL_mixer
- no font/transparency/NoMask/VC7/Libretro video transport
- no game-specific remapping
- no second MIDP dispatcher
- no duplicate keyPressed/keyReleased delivery
- no unbounded input logging
- no JamVM/glibj replacement or patch

## Admission rule

BUILD-PASS does not elevate M1.8. DEVICE-PASS requires real RG35XX evidence that raw physical controls traverse the new adapter into actual FreeJ2ME MIDP Canvas callbacks/state with expected press/release and bounded repeat behavior, with normal exit and no regression of protected foundations. Full platform remains STABLE=NO.
