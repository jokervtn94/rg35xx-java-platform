# P2C Input / Frontend Contract Audit — 2026-10-03

## Status

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
AUDIT_STATUS=PARTIAL
RUNTIME_PATCH=FORBIDDEN
RUNTIME_SEMANTIC_DELTA=NONE
P2C_HOST_MODULE_GATE=NOT_TESTED
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

This is an audit-only checkpoint. It does not accept or change runtime semantics.

## Exact authority

```text
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
INPUT_NATIVE_PROTECTED_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_PROTECTED_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
JAMVM_PROTECTED_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_PROTECTED_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
AUDIO_NATIVE_PROTECTED_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

Locked phase boundary:

- P2 owns complete physical input mapping, keymap/frontend policy, logical resolution configuration, pointer/touch policy, and rotation policy if supported.
- Dynamic `MobilePlatform.resizeLCD` behavior belongs to P3 and is not a P2C implementation target.

## Canonical ownership that must remain unchanged

### MIDP / Java semantics

Pinned `javax.microedition.lcdui.Canvas` owns:

- `getGameAction` / `getKeyCode` / `getKeyName` semantics;
- `hasPointerEvents() == true`;
- `hasPointerMotionEvents() == false`;
- `hasRepeatEvents() == true`.

Pinned `org.recompile.mobile.MobilePlatform` owns:

- keyPressed / keyReleased / keyRepeated delivery;
- GameCanvas key-state updates;
- pointerPressed / pointerReleased / pointerDragged delivery.

The RG35XX adapter must terminate at `MobilePlatform`. It must not call `Displayable` directly or reproduce Canvas/GameCanvas semantics.

Classification:

```text
javax.microedition.lcdui.Canvas=CANONICAL_UNCHANGED
org.recompile.mobile.MobilePlatform key/pointer semantics=CANONICAL_UNCHANGED
```

## Pinned Miyoo physical frontend contract

Source authority:

- `cpp/sdl2/miyoomini.cpp`
- `src/org/recompile/freej2me/Anbu.java`
- `src/org/recompile/freej2me/SDLConfig.java`
- `KEYMAP_ENG.md`

### Default physical mapping

The Miyoo frontend first maps physical controls to SDL keys, then `Anbu.getMobileKey()` maps those keys to the existing Mobile/MIDP boundary.

| Miyoo physical control | Frontend role / SDL output | Default `Mobile` key at Java boundary |
| --- | --- | --- |
| D-pad Up | SDL Up | `KEY_NUM2` |
| D-pad Down | SDL Down | `KEY_NUM8` |
| D-pad Left | SDL Left | `KEY_NUM4` |
| D-pad Right | SDL Right | `KEY_NUM6` |
| Y | left phone button / `q` | `NOKIA_SOFT1` |
| A | right phone button / `w` | `NOKIA_SOFT2` |
| X | OK / Enter | `KEY_NUM5` |
| B | `0` | `KEY_NUM0` |
| Select | `*` / `e` | `KEY_STAR` |
| Start | `#` / `r` | `KEY_POUND` |
| L1 | `1` | `KEY_NUM1` |
| R1 | `3` | `KEY_NUM3` |
| L2 | `7` | `KEY_NUM7` |
| R2 | `9` | `KEY_NUM9` |

This is the pinned Miyoo physical default mapping. It is distinct from merely choosing a useful P-phone mapping at the Java boundary.

### Keymap policy

Pinned Miyoo supports `keymap.cfg` remapping of the physical roles:

```text
left phone button
right phone button
OK
*
#
0
1
3
7
9
```

The default roles above are restored if custom parsing fails.

### Phone-mode policy

Pinned Miyoo supports five cyclic phone modes:

```text
p -> n -> e -> s -> m -> p
```

Default is `p`. The mode is persisted in the per-app config and changes the `Anbu.getMobileKey()` translation at the Java boundary. The frontend hotkey is Select + Start.

P2C must not reimplement vendor Canvas semantics. A ported phone-mode policy, if implemented, may only choose which already-canonical `Mobile` keycode is dispatched into `MobilePlatform`.

### Pointer/touch policy

Pinned Miyoo has no requirement for a physical touchscreen. It implements a virtual pointer mode in the frontend:

- Select + Y toggles pointer mode;
- D-pad moves a logical pointer in steps of 6 pixels while in the supported orientation path;
- X acts as pointer confirm;
- the Java side receives `pointerPressed(x,y)` and `pointerReleased(x,y)` through `MobilePlatform`;
- the pinned flow does not emit pointerDragged from this frontend;
- `Canvas.hasPointerEvents()` remains canonical and is not rewritten by the adapter.

Therefore lack of a physical touchscreen is not by itself evidence that pointer emulation is unsupported on RG35XX.

### Rotation policy

Pinned Miyoo frontend supports a rotation hotkey (Select + B) and maintains frontend rotation state. It rotates presentation and remaps D-pad directions to the corresponding logical direction. Rotation is a frontend/presenter policy; it does not redefine MIDP Graphics transforms.

P2C must determine an RG35XX owner-scoped implementation that does not alter the protected native video binary unless exact evidence proves that native change is required.

### Logical resolution policy

Pinned `Anbu` receives logical width and height at process launch and creates `MobilePlatform(width,height)`. The SDL frontend receives the same logical source dimensions and aspect-fits them into a 640x480 physical display.

`SDLConfig` persists width/height fields, but the audited pinned path does not establish that those persisted fields dynamically resize an already-created platform. Dynamic resize is therefore not imported into P2C; it remains P3.

The active P2 logical-resolution contract is launch-time configuration.

## Current RG35XX boundary

### Raw input acquisition

`adapter/native/rg35xx_input.c` is the sole `/dev/input/js0` owner and emits a semantic bitmap. It currently owns hardware acquisition only and contains no MIDP Canvas semantics.

Classification:

```text
adapter/native/rg35xx_input.c=RG35XX_NATIVE_BOUNDARY_PROTECTED
P2C_NATIVE_INPUT_CHANGE_EXPECTED=NO
```

### Java dispatcher

Current `RG35XXKeyDispatcher` terminates correctly at `MobilePlatform`, but its fixed mapping is:

| RG35XX semantic control | Current Java key |
| --- | --- |
| Up | `KEY_NUM2` |
| Down | `KEY_NUM8` |
| Left | `KEY_NUM4` |
| Right | `KEY_NUM6` |
| A | `KEY_NUM5` |
| B | `NOKIA_SOFT2` |
| X | `KEY_NUM7` |
| Y | `KEY_NUM9` |
| L1 | `KEY_STAR` |
| R1 | `KEY_POUND` |
| Start | `NOKIA_SOFT1` |
| Select | `KEY_NUM0` |

This mapping has accepted historical RG35XX input evidence and must not be changed because of a game. However, it is not the same mapping as the pinned Miyoo physical default contract above. P2C therefore classifies the mismatch as a platform-contract gap to resolve by canonical + hardware evidence, not as a game failure.

### Launcher / resolution

`RG35XXLauncher` already accepts arbitrary positive launch-time logical width and height and constructs `MobilePlatform(width,height)`. The older A8 production shell hardcodes `240 320`.

Classification:

```text
RG35XXLauncher launch-time width/height=CANONICAL_COMPATIBLE_BOUNDARY
A8 production hardcoded 240x320=FRONTEND_CAPABILITY_GAP
DYNAMIC_RESIZE=P3_NOT_P2C
```

### Presenter

Protected `librg35xx_video.so` accepts source width/height and aspect-fits generically into 640x480. It has no rotation parameter.

An RG35XX P2C rotation implementation should first attempt an owner-scoped Java/frontend buffer/orientation policy while preserving the native video hash. Native video changes are forbidden unless that approach is proven insufficient.

## Gap table

| P2C contract | Current evidence | Classification | Required next action |
| --- | --- | --- | --- |
| D-pad / basic key delivery | accepted RG35XX physical evidence; dispatcher ends at MobilePlatform | `RG35XX_NATIVE_BOUNDARY` | protect parent behavior |
| Miyoo-default physical key roles | current fixed RG35XX mapping differs from pinned Miyoo frontend | `FRONTEND_CAPABILITY_GAP` | host mapping contract after hardware inventory |
| L2/R2 | original RG35XX diagnostic measured L2=`axis 2`, R2=`axis 5`, baseline `-32767`, press `32767`, release `-32767` | `HARDWARE_EVIDENCE_PASS` | include in complete frontend mapping contract |
| `keymap.cfg` configurable physical roles | absent in current RG35XX frontend | `FRONTEND_CAPABILITY_GAP` | design smallest Java/frontend owner |
| p/n/e/s/m phone-mode switching | absent in current RG35XX frontend | `FRONTEND_CAPABILITY_GAP` | reproduce boundary keycode selection only; do not modify Canvas |
| pointer emulation | canonical Miyoo virtual-pointer path exists; RG35XX producer absent | `MISSING_RG35XX_BACKING` | owner-scoped frontend producer using measured controls |
| rotation | canonical Miyoo frontend supports it; RG35XX production path absent | `MISSING_RG35XX_BACKING` | owner-scoped Java/frontend presentation policy; protect video native |
| launch-time logical resolution | Java launcher already generic; production shell hardcodes 240x320 | `FRONTEND_CAPABILITY_GAP` | remove hardcoded-only production policy in later generic package path |
| dynamic resize | canonical method exists, but locked phase assigns resize to P3 | `DEFERRED_CAPABILITY` | P3 runtime-services/resize module |

## Original-RG35XX hardware evidence closure

```text
DEVICE=ORIGINAL_RG35XX
DIAGNOSTIC_PACKAGE_RUN=37137415150
DIAGNOSTIC_ARTIFACT_ID=11279100414
DIAGNOSTIC_PROBE_SHA256=b37a0e79f58795e90e75261c161697c9e150f6a59bba0f3ffa861d56404f3bf1
DEVICE_RESULT_SHA256=2bf0de5660431bc144e29ab531fa7614ce764e29517b397fe865d88f3134fdf5
KEYMAP_COUNT=14
P2C_INPUT_CAPABILITY_RESULT=PASS
PROBE_EXIT_CODE=0
L2_TYPE=axis
L2_INDEX=2
L2_BASELINE=-32767
L2_PRESS=32767
L2_RELEASE=-32767
R2_TYPE=axis
R2_INDEX=5
R2_BASELINE=-32767
R2_PRESS=32767
R2_RELEASE=-32767
PROTECTED_JAMVM_BEFORE_AFTER=IDENTICAL
PROTECTED_GLIBJ_BEFORE_AFTER=IDENTICAL
HARDWARE_EVIDENCE=PASS
```

This closes only the hardware identity prerequisite. It is not P2C module acceptance.

## Pre-change checklist

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
HARDWARE_EVIDENCE=PASS_14_CONTROL_ORIGINAL_RG35XX
MISSING_CONTRACT=KEYMAP_POLICY+PHONE_MODE+POINTER+ROTATION+GENERIC_LAUNCH_RESOLUTION_POLICY
OWNER=RG35XX_INPUT_FRONTEND_BOUNDARY
FILES_ALLOWED_TO_CHANGE=OWNER_SCOPED_JAVA_FRONTEND+PACKAGING+TESTS_ONLY
FILES_FORBIDDEN_TO_CHANGE=CANVAS+GAMECANVAS+MOBILEPLATFORM_SEMANTICS+JAMVM+GLIBJ+PROTECTED_INPUT_NATIVE+PROTECTED_VIDEO_NATIVE+PROTECTED_AUDIO_NATIVE+P1/P2A/P2B_ACCEPTED_OWNERS
HOST_GATE=NOT_TESTED
PHYSICAL_GATE=NOT_TESTED
GENERIC_PLATFORM_IMPACT=REQUIRED_P2_PLATFORM_COMPLETION
RUNTIME_PATCH=ALLOWED_ONLY_AFTER_MINIMUM_OWNER_SCOPE_IS_DEFINED
```

## Minimum owner-scoped candidate requirement

The candidate must preserve the protected native input/video/audio binaries and canonical MIDP classes. The first legal implementation must be limited to the RG35XX Java/frontend boundary and must:

1. consume the measured 14-control hardware inventory, including L2/R2 axes;
2. reproduce pinned Miyoo default physical roles at the `MobilePlatform` keycode boundary;
3. provide platform-level remapping/config policy without game-specific branches;
4. implement phone-mode switching as boundary keycode selection only;
5. implement virtual pointer production through existing `MobilePlatform.pointerPressed/Released`;
6. implement rotation in Java/frontend presentation first, preserving `librg35xx_video.so`;
7. retain launch-time logical resolution as the P2 contract and defer dynamic resize to P3;
8. preserve P1/P2A/P2B parent regressions and all protected hashes.

No module-level physical test is legal until host/module gates prove this scope.

## Next legal action

```text
NEXT_LEGAL_ACTION=P2C_DEFINE_AND_BUILD_MINIMUM_OWNER_SCOPED_CANDIDATE
RUNTIME_SEMANTIC_DELTA=NONE_AT_AUDIT_CHECKPOINT
P2C_PHYSICAL_TEST=NOT_TESTED
P2=PARTIAL
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```
