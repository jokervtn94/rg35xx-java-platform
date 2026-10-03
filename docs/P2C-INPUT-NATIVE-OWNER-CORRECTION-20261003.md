# P2C Input Native Owner Correction — 2026-10-03

This record corrects one over-constrained statement in the preceding P2C audit after original-RG35XX hardware evidence closed the L2/R2 identity gap.

## Evidence

The original RG35XX diagnostic proved:

```text
L2=axis:2 baseline=-32767 press=32767 release=-32767
R2=axis:5 baseline=-32767 press=32767 release=-32767
KEYMAP_COUNT=14
P2C_INPUT_CAPABILITY_RESULT=PASS
PROBE_EXIT_CODE=0
```

The accepted production `adapter/native/rg35xx_input.c` is the sole `/dev/input/js0` owner. It currently tracks only axes 6/7 and emits only the existing twelve semantic bits. Therefore Java cannot consume the measured L2/R2 controls without either changing this rightful hardware owner or creating a forbidden second `/dev/input/js0` owner.

## Correction

The earlier classification `P2C_NATIVE_INPUT_CHANGE_EXPECTED=NO` is superseded.

```text
P2C_NATIVE_INPUT_CHANGE_EXPECTED=YES_EVIDENCE_DRIVEN_OWNER_DELTA
OWNER=adapter/native/rg35xx_input.c
WHY_MIYOO_AS_IS_CANNOT_WORK=ACCEPTED_NATIVE_BITMAP_DOES_NOT_EXPORT_MEASURED_L2_R2
MINIMUM_NATIVE_DELTA=TRACK_AXIS2_AXIS5_AND_ADD_TWO_NEW_SEMANTIC_BITS_ONLY
EXISTING_12_CONTROL_BITS=MUST_REMAIN_BIT_AND_BEHAVIOR_COMPATIBLE
SECOND_JS0_OWNER=FORBIDDEN
```

This is allowed by the locked Miyoo-first rule because `/dev/input/js0` acquisition, RG35XX physical mapping, and measured hardware differences are RG35XX boundary ownership. The accepted input-native SHA remains protected evidence and may not be silently replaced: any new input-native identity must be explicitly tied to this P2C owner delta and pass host/module plus module-level physical acceptance before promotion.

## Allowed / forbidden scope

```text
FILES_ALLOWED_TO_CHANGE_RUNTIME=
  adapter/native/rg35xx_input.c
  adapter/java/org/recompile/rg35xx/RG35XXKeyDispatcher.java
  adapter/java/org/recompile/rg35xx/RG35XXLauncher.java
  adapter/java/org/recompile/rg35xx/RG35XXFrontendPolicy.java

FILES_FORBIDDEN_TO_CHANGE_RUNTIME=
  javax.microedition.lcdui.Canvas
  javax.microedition.lcdui.game.GameCanvas
  org.recompile.mobile.MobilePlatform canonical key/pointer semantics
  adapter/java/org/recompile/rg35xx/RG35XXCore2D.java
  adapter/native/rg35xx_video_sdl1.c
  adapter/native/rg35xx_audio_sdl1_mixer.c
  adapter/native/rg35xx_font_jdk8.cpp
  JamVM
  glibj
  P1/P2A/P2B unrelated accepted owners
```

`RG35XXInput.java` should remain unchanged unless build evidence proves a JNI signature change is necessary; the current 32-bit `int` bitmap has sufficient capacity for 14 controls.

## Status

```text
AUDIT_ERROR_CORRECTION=PASS
HARDWARE_EVIDENCE=PASS
RUNTIME_PATCH=ALLOWED_OWNER_SCOPED_ONLY
P2C_HOST_MODULE_GATE=NOT_TESTED
P2C_PHYSICAL_TEST=NOT_TESTED
RUNTIME_SEMANTIC_DELTA=NOT_ACCEPTED_YET
P2=PARTIAL
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```
