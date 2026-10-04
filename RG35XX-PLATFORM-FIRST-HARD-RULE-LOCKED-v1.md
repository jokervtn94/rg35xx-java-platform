# RG35XX FreeJ2ME Port — PLATFORM-FIRST HARD RULE v1

**Status:** LOCKED  
**Project:** Port FreeJ2ME to original RG35XX / GarlicOS  
**Repository:** `jokervtn94/rg35xx-java-platform`  
**Purpose:** Prevent regression into game-driven micro-fixes, method-by-method physical testing, speculative reconstruction, and partial platform packaging.

This document is a **hard process addendum** to:

- `RG35XX-PORT-RULER-LOCKED-v1.md`
- `RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md`

It does **not** replace either document.  
It tightens how the port must be completed.

If an implementation plan is technically possible but violates this document, **STOP THE IMPLEMENTATION** and return to the platform-first workflow.

---

# 0. NON-NEGOTIABLE PROJECT TARGET

The target is **one generic, installable FreeJ2ME platform for original RG35XX**, derived from the pinned Aweigit Miyoo implementation.

The target is NOT:

```text
game A fails -> patch
game B fails -> patch
API X fails -> physical package
API Y fails -> physical package
repeat forever
```

The target IS:

```text
PINNED AWEIGIT SOURCE
        ↓
WHOLE-PLATFORM SOURCE / METHOD AUDIT
        ↓
ORIGINAL RG35XX HARDWARE CONTRACT
        ↓
COMPLETE RG35XX ADAPTER/BACKING BY MODULE
        ↓
MODULE-LEVEL AUTOMATED DIFFERENTIAL TESTS
        ↓
MODULE-LEVEL PHYSICAL DEVICE TESTS
        ↓
ONE GENERIC INSTALL PACKAGE
        ↓
FULL PLATFORM EXERCISER
        ↓
TIER-0 PHYSICAL REGRESSION
        ↓
PLATFORM BASELINE LOCK
        ↓
ONLY THEN COMPATIBILITY UPDATES
```

The final baseline must allow JARs to be launched through the RG35XX platform **without game-specific runtime code**.

---

# 1. AUTHORITY ORDER REMAINS LOCKED

Use this order and never reverse it:

1. Pinned Aweigit source/behavior.
2. Measured original-RG35XX hardware/runtime behavior.
3. Previously accepted original-RG35XX DEVICE-PASS evidence.
4. Exact controlled module test evidence.
5. Exact commercial-game evidence.
6. Diagnostic experiment.
7. New implementation idea.

A commercial game is therefore **not an earlier authority than the platform source contract**.

---

# 2. CANONICAL / GOLDEN IDENTITIES

Canonical Aweigit:

```text
repository:
aweigit/freej2me-miyoomini

commit:
ca11dfe8ea1cc273d92460f9a83bbf192023fa63
```

Protected runtime:

```text
JamVM:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Exact accepted A8 physical platform identity:

```text
freej2me-rg35xx.jar:
057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c

librg35xx_input.so:
69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d

librg35xx_video.so:
c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d

libaudio.so:
4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644

audio-prime PCM:
8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

A rebuilt semantic-equivalent artifact is **not allowed to replace an exact physical Golden identity**.

---

# 3. REQUIRED PORT MODEL

Every RG35XX change must fit this model:

```text
CANONICAL J2ME / AWEIGIT SEMANTICS
        ↓
RG35XX-SPECIFIC BOUNDARY ONLY
```

Canonical-owned behavior includes, unless exact evidence proves otherwise:

- MIDlet lifecycle semantics
- Canvas / GameCanvas semantics
- Graphics API semantics
- Image semantics
- key event semantics after hardware dispatch
- RMS semantics
- MMAPI Player state/control semantics
- vendor API semantics already present in Aweigit

RG35XX-owned behavior includes:

- `/dev/input/js0`
- physical control mapping
- SDL1/fbcon presentation
- 640×480 hardware surface handling
- Raw2D backing needed because AWT is unavailable
- Java 6 compatibility glue
- SDL1_mixer device backend
- audio route prime
- installer/launcher paths
- device-specific filesystem boundary
- device configuration

The adapter must not become a second independent implementation of J2ME behavior.

---

# 4. WHOLE-SOURCE AUDIT BEFORE COMPATIBILITY PATCHING

Before Tier-1 compatibility work resumes, the assistant must complete a source coverage audit for the declared platform scope.

The audit must classify every relevant class/method as one of:

```text
CANONICAL_UNCHANGED
RG35XX_JAVA6_COMPAT
RG35XX_RAW_BACKING
RG35XX_NATIVE_BOUNDARY
CANONICAL_LIMITATION
DEFERRED_CAPABILITY
MISSING_RG35XX_BACKING
UNVERIFIED
```

For Raw2D specifically:

```text
if canonical method can dereference gc/canvas
and Raw2D sets gc/canvas to null
then the method MUST be audited before platform completion
```

Do not wait for a commercial game to call the method.

---

# 5. NO MORE GAME-DRIVEN PORT ARCHITECTURE

A game may reveal a missing platform path.

A game may NOT decide:

- the rendering algorithm;
- the media architecture;
- the input model;
- the lifecycle model;
- the RMS model;
- the class ownership;
- whether canonical behavior should be replaced.

Correct workflow:

```text
game reveals symptom
        ↓
identify source-level platform gap
        ↓
add gap to platform coverage matrix
        ↓
fix the complete module contract
        ↓
module acceptance
        ↓
later re-run game
```

Forbidden workflow:

```text
game reveals fillTriangle
-> patch fillTriangle
game reveals drawArc
-> patch drawArc
game reveals DirectGraphics
-> patch DirectGraphics
...
```

---

# 6. HOST TESTS MAY BE METHOD-LEVEL; PHYSICAL TESTS MUST BE MODULE-LEVEL

This rule is mandatory.

## 6.1 Host / CI tests

Host differential tests MAY be granular.

Examples:

```text
clearRect
copyArea
fillTriangle
drawArc
fillArc
drawRoundRect
DirectGraphics.drawPixels
```

This is allowed because method-level differential testing is cheap and useful for proving equivalence to pinned Aweigit/JDK behavior.

## 6.2 Physical RG35XX tests

Physical tests MUST normally be grouped by platform module.

Examples:

```text
GRAPHICS-CORE-2D-MODULE
IMAGE-DECODE-MODULE
FONT-TEXT-MODULE
INPUT-FRONTEND-MODULE
RMS-FILESYSTEM-MODULE
MMAPI-AUDIO-MODULE
GENERIC-LAUNCHER-MODULE
```

Do NOT create a new SD package and ask the user to physically test every individual method.

### Exception

A single-method physical test is permitted only when ALL are true:

1. host behavior cannot represent the hardware boundary;
2. the method touches device-specific native/hardware behavior;
3. risk cannot be grouped with the module test;
4. the reason is documented before package creation.

Pure Java Raw2D methods normally do **not** qualify for this exception.

---

# 7. CURRENT CORRECTION — G1 / G2

The recent P1A work is interpreted as follows.

## G1

`clearRect + copyArea`

Useful evidence:

```text
HOST DIFFERENTIAL = PASS
PHYSICAL MODULE SAMPLE = PASS
```

This validates the Raw2D differential/testing mechanism.

It does NOT establish a requirement to physically test each remaining primitive separately.

## G2A / G2B / G2C / G2D

These may continue as **host differential implementation units**, but they must converge into ONE physical graphics-module candidate.

Therefore:

```text
G2A fillRoundRect
G2B fillTriangle
G2C drawRoundRect
G2D drawArc/fillArc
```

MAY each have CI gates.

They MUST NOT each require a separate user/device test unless the exception in Section 6.2 is proven.

### Immediate lock

The already-created standalone G2A physical package is:

```text
STATUS=NOT_REQUIRED_FOR_PLATFORM_WORKFLOW
```

Do not ask the user to run it as a prerequisite.

Continue host/platform integration instead.

---

# 8. GRAPHICS COMPLETION MUST BE A MODULE, NOT A CHAIN OF MICRO-PROMOTIONS

The Graphics/Raw2D workstream must produce one candidate covering the declared 2D graphics matrix.

At minimum audit/implement as applicable:

### MIDP Graphics

- clearRect
- copyArea
- drawLine
- drawRect
- fillRect
- drawArc
- fillArc
- drawRoundRect
- fillRoundRect
- fillTriangle
- drawImage
- drawRegion
- drawRGB
- text operations
- clip
- translate
- anchors

### Nokia DirectGraphics

- drawImage manipulation
- drawPixels(byte[])
- drawPixels(int[])
- drawPixels(short[])
- drawPolygon
- drawTriangle
- fillPolygon
- fillTriangle
- getPixels(int[])
- getPixels(short[])

Canonical stubs must remain canonical stubs unless separately justified.

The required output is:

```text
P1A-COMPLETE-GRAPHICS-CANDIDATE
```

not a long-lived collection of production parents named by individual methods.

---

# 9. MODULE COMPLETION GATE

Before a module is sent to physical test:

1. canonical source coverage matrix updated;
2. all module methods classified;
3. every missing path either implemented or explicitly deferred;
4. all new implementations have canonical differential tests where possible;
5. existing accepted gates PASS;
6. only owner-scoped classes changed;
7. non-owner hashes unchanged;
8. Java 6 bytecode gate PASS;
9. no game names in runtime;
10. no trace-only code;
11. no A9 parent;
12. one module exerciser exists.

Only then build one physical package for that module.

---

# 10. PHYSICAL MODULE ACCEPTANCE

Physical test packages should answer a module question, not a method question.

Example:

```text
QUESTION:
Does the completed Raw2D/DirectGraphics 2D module behave correctly
on original RG35XX?

NOT:
Does fillRoundRect work?
NOT:
Does drawArc work?
NOT:
Does copyArea work?
```

A physical module exerciser should:

- execute all covered APIs;
- display an obvious PASS/FAIL pattern;
- log each case;
- log exact runtime hashes;
- preserve protected artifacts;
- return normally to GarlicOS;
- write one evidence directory.

Human physical observation remains final authority.

---

# 11. COMPLETE PLATFORM PHASE ORDER

The assistant must follow this order unless the user explicitly changes it.

## P0 — Exact Golden authority

```text
STATUS: REQUIRED / PROTECTED
```

Recover and preserve exact accepted identities.

## P1 — Core 2D platform completion

Includes:

- PlatformGraphics Raw2D coverage
- DirectGraphics coverage
- PlatformImage required raw operations
- Core2D helpers only where necessary

Physical acceptance occurs at the **graphics module level**, not each method.

## P2 — Image / font / frontend contract

Includes:

- declared image decode formats
- alpha/transform
- font/text coverage
- complete physical input mapping
- keymap/frontend policy
- logical resolution configuration
- pointer/touch policy
- rotation policy if supported

## P3 — Runtime service modules

Includes:

- RMS/filesystem
- IO/network declared support
- MMAPI/audio
- lifecycle/shutdown
- resize behavior

Each is tested by module.

## P4 — Deferred capability decision

Includes:

- M3G
- MascotCapsule/Micro3D
- LWJGL/OpenGL
- hardware capability inventory

No blind re-enable.

## P5 — One generic installer/platform

Deliver:

```text
/mnt/mmc/
├── CFW/java/...
├── Roms/JAVA/
│   └── *.jar
└── Roms/APPS/
    ├── FreeJ2ME-RG35XX.sh
    └── FreeJ2ME-RG35XX/
        ├── freej2me-rg35xx.jar
        ├── librg35xx_input.so
        ├── librg35xx_video.so
        ├── libaudio.so
        ├── platform config
        └── data/
```

The launcher must be generic.

Commercial game names must not exist in production runtime logic.

## P6 — Full platform exerciser

One platform test suite verifies:

- launch/resource loading
- Canvas/GameCanvas
- full declared graphics matrix
- image
- text/font
- input
- RMS
- filesystem/IO declared support
- MMAPI/audio
- lifecycle
- clean exit
- generic resolution/config behavior

## P7 — Tier-0 physical regression

Required:

```text
Vua Cướp Biển
God of War
```

God of War audible audio remains a protected Golden expectation unless exact Golden evidence is formally revised.

## P8 — Baseline promotion

Only after P0-P7 pass:

```text
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES
```

## P9 — Compatibility updates

Only now resume:

- Asphalt
- other Tier-1 games
- additional vendor/profile compatibility

At P9, a failure must still go through the original RULER failure workflow.

---

# 12. NO NEW COMPATIBILITY GAME UNTIL PLATFORM BASELINE EXISTS

This is a hard stop.

Until P8:

```text
NO_NEW_TIER1_GAME_FIX=YES
NO_GAME_SPECIFIC_RUNTIME_PATCH=YES
NO_GAME_SPECIFIC_PRODUCTION_BRANCH=YES
```

Existing compatibility evidence may be retained as audit evidence.

It must not drive the platform architecture.

---

# 13. INSTALLER IS A REQUIRED DELIVERABLE, NOT AN AFTERTHOUGHT

The port is not considered structurally complete merely because classes compile or test JARs run.

A generic install package must exist and must:

- use the actual GarlicOS APPS layout;
- hash-gate protected runtime;
- discover/accept JAR input generically;
- provide persistent data/RMS paths;
- preserve JamVM/glibj;
- configure required native library path;
- avoid manual shell-only workflows for normal use;
- contain no per-game runtime behavior.

Testing isolated development launchers must not replace the installer deliverable.

---

# 14. NO SILENT SCOPE REDUCTION

If the port cannot support a canonical Miyoo feature because of RG35XX hardware/runtime limitations, explicitly classify it:

```text
DEFERRED_CAPABILITY
UNSUPPORTED_BY_MEASURED_HARDWARE
CANONICAL_LIMITATION
NOT_TESTED
```

Do not silently remove a source tree and later describe the platform as fully equivalent.

Examples requiring explicit status:

- M3G
- Micro3D
- non-PNG image formats
- touch/pointer emulation
- L2/R2
- rotation
- network protocols
- haptic

---

# 15. REQUIRED PRE-CHANGE CHECKLIST FOR THE ASSISTANT

Before any runtime code change, the assistant must state internally and verify:

```text
CURRENT_PHASE=
CURRENT_MODULE=
CANONICAL_SOURCE=
EXACT_PARENT_IDENTITY=
HARDWARE_EVIDENCE=
MISSING_CONTRACT=
OWNER=
FILES_ALLOWED_TO_CHANGE=
FILES_FORBIDDEN_TO_CHANGE=
HOST_GATE=
PHYSICAL_GATE=
GENERIC_PLATFORM_IMPACT=
```

If any of these are unresolved, do not write the runtime patch.

---

# 16. REQUIRED POST-CHANGE CHECKLIST

Before presenting a candidate:

```text
CANONICAL_DIFF_VERIFIED=YES/NO
OWNER_SCOPE_VERIFIED=YES/NO
UNRELATED_CLASS_DIFF=NONE/...
PROTECTED_HASHES=PASS/FAIL
JAVA6_GATE=PASS/FAIL
HOST_MODULE_GATE=PASS/FAIL
PHYSICAL_TEST_REQUIRED=YES/NO
PHYSICAL_TEST_LEVEL=MODULE/SPECIAL_EXCEPTION
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
STABLE=NO
```

Build success alone never changes `DEVICE-PASS`.

---

# 17. BRANCH / ARTIFACT DISCIPLINE

Do not create endless production ancestry from diagnostics.

Allowed conceptual branch roles:

```text
audit/*
module/*
platform-integration/*
physical-test/*
stable
```

Method-level work branches may exist temporarily for CI/differential development.

They must converge into the module branch before physical acceptance.

A method branch must not become a new long-term production parent merely because its isolated test passed.

---

# 18. TEST COUNT / USER BURDEN RULE

The user owns physical device time.

Minimize unnecessary physical cycles.

Before asking for a new device test, the assistant must prove that:

1. all feasible host/differential tests are already complete;
2. the package answers a meaningful module/platform question;
3. the result will change the next engineering decision;
4. the same information cannot be obtained from existing evidence;
5. the test is not merely confirming one small pure-Java method.

If not, do not ask for the device test.

---

# 19. ERROR CORRECTION RULE

If the assistant discovers that its previous artifact, identity, conclusion, or test protocol violated a locked rule:

1. state the exact error;
2. withdraw only the invalid conclusion;
3. preserve valid evidence;
4. do not ask the user to repeat unaffected tests;
5. update the process rule if the error class could recur;
6. return to the last valid platform checkpoint.

Do not continue forward merely because work has already been invested.

---

# 20. CURRENT LOCKED PROJECT INTERPRETATION

As of this rule:

```text
A8_EXACT_GOLDEN=AUTHORITY

G1_CLEAR_COPY:
  HOST_DIFFERENTIAL=PASS
  ORIGINAL_RG35XX_PHYSICAL=PASS
  ROLE=VALIDATION_OF_PLATFORM_METHOD_AND_TEST_MECHANISM
  LONG_TERM_PARENT=NO_BY_ITSELF

G2A_FILLROUNDRECT:
  HOST_DIFFERENTIAL=PASS
  STANDALONE_PHYSICAL_TEST=NOT_REQUIRED
  ROLE=HOST_IMPLEMENTATION_UNIT_FOR_GRAPHICS_MODULE

G2B/G2C/G2D:
  ROLE=HOST_IMPLEMENTATION_UNITS
  PHYSICAL_TEST_EACH=NO

AUDIO01:
  ARCHIVED_DIAGNOSTIC

COMP02_FILLTRIANGLE:
  PLATFORM_GAP_EVIDENCE
  NOT_PLATFORM_ARCHITECTURE_DRIVER

NEXT_REQUIRED_DELIVERABLE:
  P1A_COMPLETE_GRAPHICS_CANDIDATE
  + ONE_GRAPHICS_MODULE_EXERCISER

NEW_TIER1_FIX:
  FORBIDDEN_UNTIL_PLATFORM_BASELINE
```

---

# 21. DEFINITION OF A VALID PORT BASELINE

A baseline may only be called a valid RG35XX FreeJ2ME platform baseline when:

```text
CANONICAL_PIN=PRESERVED
PROTECTED_RUNTIME=PRESERVED
DECLARED_SOURCE_SCOPE=AUDITED
RG35XX_BOUNDARY_COMPLETE_FOR_DECLARED_SCOPE=YES
GENERIC_INSTALLER=YES
GENERIC_JAR_LAUNCH=YES
FULL_PLATFORM_EXERCISER=PASS_ON_DEVICE
VUA_TIER0=PASS_ON_DEVICE
GOW_TIER0=PASS_ON_DEVICE
GOW_AUDIO_AUDIBLE=PASS_ON_DEVICE
GAME_SPECIFIC_RUNTIME_CODE=NO
DEVICE-PASS=YES
```

Anything before this is:

```text
MODULE_CANDIDATE
DIAGNOSTIC
PARTIAL_PLATFORM
```

—not a completed platform.

---

# 22. FINAL HARD STOP

Whenever there is uncertainty, use this decision:

```text
Does this action move us toward completing
the generic Aweigit -> RG35XX platform?

YES:
    continue if owner/scope/evidence are locked.

NO:
    stop.

Is this merely another game-specific or method-specific
physical validation that can be covered by a module test?

YES:
    do not do it.
```

**PLATFORM FIRST. MODULE SECOND. GAME COMPATIBILITY LAST.**
