# P2C Input / Frontend R1 Pre-change Lock — 2026-10-03

## State

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
HARDWARE_EVIDENCE=PASS_14_CONTROL_CALIBRATION
RUNTIME_PATCH=AUTHORIZED_OWNER_SCOPED_ONLY
P2C_HOST_MODULE_GATE=NOT_TESTED
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

This branch is a module candidate rooted directly at official `main`. The diagnostic branch is evidence only and is not a production parent.

## Mandatory port-decision fields

```text
PORT_UNIT=P2C_INPUT_FRONTEND_MODULE
MIYOO_SOURCE=cpp/sdl2/miyoomini.cpp+src/org/recompile/freej2me/Anbu.java+src/org/recompile/freej2me/SDLConfig.java+KEYMAP_ENG.md+README.md
MIYOO_CURRENT_BEHAVIOR=14_PHYSICAL_CONTROLS+DEFAULT_P_PHONE_MAPPING+KEYMAP_CFG+P/N/E/S/M_PHONE_MODES+VIRTUAL_POINTER+ROTATION+LAUNCH_TIME_LOGICAL_RESOLUTION
FREEJ2ME_REFERENCE=MobilePlatform_keyPressed/keyReleased/keyRepeated+pointerPressed/pointerReleased+Canvas/GameCanvas_existing_semantics
JDK_OPENJDK_REFERENCE_IF_REQUIRED=NONE
RG35XX_MEASURED_LIMITATION=ORIGINAL_RG35XX_JS0_L2_AXIS2_BASELINE_-32767_PRESS_32767_AND_R2_AXIS5_BASELINE_-32767_PRESS_32767;CURRENT_NATIVE_DROPS_AXES_2_5;CURRENT_JAVA_MAPPING_DIFFERS_FROM_PINNED_MIYOO_DEFAULT
EXACT_FAILURE_OR_MISSING_CONTRACT=COMPLETE_PHYSICAL_MAPPING+PINNED_DEFAULT_KEY_ROLES+KEYMAP_POLICY+PHONE_MODE_POLICY+POINTER_PRODUCER+ROTATION_POLICY
FAILURE_OWNER=RG35XX_INPUT_FRONTEND_BOUNDARY
WHY_MIYOO_AS_IS_CANNOT_WORK=PINNED_FRONTEND_IS_SDL2_DEVICE_KEYBOARD_OWNER_WHILE_ORIGINAL_RG35XX_ACCEPTED_PORT_USES_RAW_/dev/input/js0_AND_SDL1/FBCON;ADAPTER_MUST_REPRODUCE_ONLY_BOUNDARY_SEMANTICS
MINIMUM_REQUIRED_DELTA=ADD_L2_R2_TO_EXISTING_NATIVE_SEMANTIC_BITMAP;PORT_FRONTEND_ROLE_SELECTION/HOTKEY_STATE_TO_RG35XX_JAVA_OWNER;PRESENT_ROTATED/CURSOR_FRAME_IN_JAVA_BEFORE_PROTECTED_VIDEO_OWNER
FILES_ALLOWED_TO_CHANGE=adapter/native/rg35xx_input.c+adapter/java/org/recompile/rg35xx/RG35XXKeyDispatcher.java+adapter/java/org/recompile/rg35xx/RG35XXFrontendPolicy.java+adapter/java/org/recompile/rg35xx/RG35XXLauncher.java+P2C_BUILD_TEST_WORKFLOW_DOCS
FILES_FORBIDDEN_TO_CHANGE=Canvas+GameCanvas+MobilePlatform_SEMANTICS+Anbu.java+JamVM+glibj+PROTECTED_VIDEO_NATIVE+PROTECTED_AUDIO_NATIVE+P1/P2A/P2B_ACCEPTED_OWNERS
PARENT_REGRESSION_GATES=P1A_GRAPHICS+P2A_IMAGE+P2B_FONT_TEXT+PROTECTED_VIDEO_AUDIO_JAMVM_GLIBJ_IDENTITIES
HOST_DIFFERENTIAL_GATE=EXACT_14_CONTROL_NATIVE_EVENT_MODEL+PINNED_MIYOO_ROLE/MODE/HOTKEY_POLICY+ROTATION/POINTER_COORDINATE_MODEL
MODULE_INTEGRATION_GATE=JAVA6+JAR_OWNER_SCOPE+ARMV5TE_UCLIBC_NATIVE+NO_DIRECT_DISPLAYABLE+PARENT_REGRESSIONS
PHYSICAL_GATE=ONE_INPUT_FRONTEND_MODULE_EXERCISER_ON_ORIGINAL_RG35XX
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

## Measured original-RG35XX authority

The returned device report establishes:

```text
UP=axis7 -32767
DOWN=axis7 +32767
LEFT=axis6 -32767
RIGHT=axis6 +32767
A=button0
B=button1
X=button2
Y=button3
START=button8
SELECT=button7
L1=button5
L2=axis2 baseline=-32767 press=+32767
R1=button6
R2=axis5 baseline=-32767 press=+32767
KEYMAP_COUNT=14
PROBE_EXIT_CODE=0
```

The diagnostic explicitly remained `P2C_PHYSICAL_TEST=NOT_TESTED`; it authorizes implementation but is not module acceptance.

## Pinned Miyoo default role contract

```text
UP    -> KEY_NUM2
DOWN  -> KEY_NUM8
LEFT  -> KEY_NUM4
RIGHT -> KEY_NUM6
Y     -> NOKIA_SOFT1
A     -> NOKIA_SOFT2
X     -> KEY_NUM5
B     -> KEY_NUM0
SELECT-> KEY_STAR
START -> KEY_POUND
L1    -> KEY_NUM1
R1    -> KEY_NUM3
L2    -> KEY_NUM7
R2    -> KEY_NUM9
```

`keymap.cfg` owns the ten configurable roles `left phone button`, `right phone button`, `OK`, `*`, `#`, `0`, `1`, `3`, `7`, `9`. D-pad remains directional. Invalid/missing custom configuration falls back to the pinned defaults.

Phone mode remains frontend keycode selection only:

```text
p -> n -> e -> s -> m -> p
DEFAULT=p
HOTKEY=SELECT+START
PERSIST=YES
```

Virtual pointer remains frontend-produced and terminates at `MobilePlatform.pointerPressed/pointerReleased`:

```text
TOGGLE=SELECT+Y
MOVE=D_PAD_STEP_6
CONFIRM=X
POINTER_DRAGGED_PRODUCED=NO
```

Rotation remains presentation/frontend state, not MIDP Graphics transforms:

```text
HOTKEY=SELECT+B
STATE=0->1->2->0
PROTECTED_VIDEO_NATIVE_CHANGE=NO
```

Launch-time logical width/height is already generic in `RG35XXLauncher`; dynamic resize stays P3 and is not imported here.

## Protected identity rule for this candidate

The accepted input native hash `69a8aeb3...` is parent evidence, not the candidate identity. P2C is the separately documented input-owner phase that may replace only that native owner because measured hardware proves missing axis 2/5 semantics.

All unrelated protected identities remain byte-for-byte gated:

```text
JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
VIDEO_NATIVE=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

## Next gate

Implement exactly the declared owner delta, then require host/module PASS before producing one physical INPUT-FRONTEND-MODULE package.
