# RG35XX MIYOO-FIRST PORT RULE — LOCKED v1

**Project:** Port FreeJ2ME Miyoo/Aweigit to original RG35XX / GarlicOS  
**Status:** LOCKED ADDENDUM  
**Date:** 2026-10-02  
**Role:** Binding engineering rule for all future port work  
**Replaces existing rules:** NO  
**Applies together with:**
- `RG35XX-PORT-RULER-LOCKED-v1.md`
- `RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md`
- `RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md`

---

# 0. PURPOSE OF THIS ADDENDUM

This rule exists to prevent the RG35XX port from drifting into a second, independently invented FreeJ2ME implementation.

The project is specifically:

```text
FREEJ2ME / J2ME SOURCE SEMANTICS
            ↓
AWEIGIT / MIYOO PORT AS THE MAIN BUILD BASE
            ↓
RG35XX-SPECIFIC PORTING ONLY WHERE REQUIRED
            ↓
ORIGINAL RG35XX / GARLICOS
```

The **Miyoo/Aweigit port remains the main build lineage**.

FreeJ2ME, J2ME/OpenJDK source, and other canonical implementation sources are used to understand, verify, or reconstruct behavior when a Miyoo implementation depends on facilities that the RG35XX runtime cannot provide directly.

They are NOT permission to replace the Miyoo build wholesale or independently rewrite the platform.

---

# 1. PRIMARY BUILD RULE — MIYOO FIRST

The main source/build base is locked to:

```text
repository:
aweigit/freej2me-miyoomini

pinned commit:
ca11dfe8ea1cc273d92460f9a83bbf192023fa63
```

Unless a later user-approved rule explicitly changes this pin:

```text
MIYOO_AWEIGIT_BUILD_BASE=MANDATORY
```

For every class or module:

1. Start from the pinned Miyoo/Aweigit implementation.
2. Preserve it unchanged when it already works correctly on RG35XX.
3. Do not replace it merely because another implementation appears cleaner, newer, faster, or easier to code.
4. Do not port a generic FreeJ2ME class over the Miyoo class without first proving that the Miyoo implementation cannot satisfy the RG35XX platform contract.
5. Do not create a parallel J2ME behavior layer inside the RG35XX adapter.

---

# 2. SOURCE AUTHORITY MODEL

The existing project authority order remains valid.

This addendum clarifies the engineering role of each source.

## 2.1 Miyoo/Aweigit

Role:

```text
MAIN_BUILD_BASE
PRIMARY_PORT_LINEAGE
PRIMARY_IMPLEMENTATION_REFERENCE
```

Use it first for:

- class structure;
- module structure;
- MIDP/J2ME integration;
- lifecycle;
- graphics API ownership;
- image ownership;
- RMS ownership;
- MMAPI ownership;
- launcher/platform integration inherited from the Miyoo port.

## 2.2 FreeJ2ME / canonical J2ME source

Role:

```text
SEMANTIC_REFERENCE
MISSING_IMPLEMENTATION_REFERENCE
CROSS_CHECK_SOURCE
NOT_WHOLESALE_BUILD_REPLACEMENT
```

Use FreeJ2ME source when needed to answer questions such as:

- What behavior is this J2ME method intended to expose?
- What logic exists upstream that Miyoo currently delegates to an unavailable desktop/runtime service?
- Is an RG35XX replacement preserving the same class/module contract?
- Is a missing Miyoo raw/headless path already represented elsewhere in canonical source?

FreeJ2ME source may guide a port.

It must not silently become a new independent platform lineage.

## 2.3 OpenJDK / JDK implementation source

Role:

```text
BACKEND_SEMANTIC_REFERENCE_WHEN_MIYOO_DELEGATES_TO_JDK/AWT
```

OpenJDK/JDK source may be used when the pinned Miyoo path delegates to Java2D/AWT or another JDK implementation that is unavailable on original RG35XX.

Example:

```text
Miyoo PlatformGraphics API
        ↓
desktop/AWT implementation unavailable on RG35XX
        ↓
trace exact JDK/OpenJDK canonical backend
        ↓
port only required raster/backend semantics
        ↓
RG35XX Raw2D boundary
```

This is permitted only when the exact backend path has been identified by source or differential evidence.

## 2.4 Original RG35XX evidence

Role:

```text
FINAL_HARDWARE_AUTHORITY
RG35XX_BOUNDARY_AUTHORITY
```

Measured original-RG35XX behavior determines what hardware/runtime adaptation is actually necessary.

Do not infer hardware constraints from another handheld.

---

# 3. REQUIRED PORT MODEL

All production changes must fit:

```text
PINNED MIYOO / AWEIGIT CLASS OR MODULE
                ↓
DOES IT WORK AS-IS ON RG35XX?
        ┌───────┴────────┐
       YES               NO
        │                 │
    KEEP IT          IDENTIFY EXACT
    UNCHANGED        RG35XX GAP
                          ↓
                 IDENTIFY FAILURE OWNER
                          ↓
             CHECK FREEJ2ME / CANONICAL SOURCE
                          ↓
              CHECK JDK/OPENJDK IF REQUIRED
                          ↓
             PORT MINIMUM REQUIRED SEMANTICS
                          ↓
                RG35XX BOUNDARY ONLY
                          ↓
                 HOST DIFFERENTIAL GATE
                          ↓
                  MODULE INTEGRATION
                          ↓
               ORIGINAL RG35XX TEST
```

The default answer to:

```text
"Should this Miyoo class be replaced?"
```

is:

```text
NO
```

until exact evidence proves replacement/adaptation is necessary.

---

# 4. RG35XX-SPECIFIC CHANGES THAT ARE LEGITIMATE

RG35XX-specific ownership may include:

- `/dev/input/js0` hardware acquisition;
- RG35XX physical key mapping;
- SDL1/fbcon initialization;
- physical 640×480 surface handling;
- scaling/presentation required by the RG35XX display;
- headless/Raw2D backing because desktop AWT is unavailable;
- Java 6 compatibility required by protected JamVM/glibj;
- SDL1_mixer hardware backend;
- original-RG35XX audio-route initialization;
- launcher and GarlicOS filesystem paths;
- native loading;
- device configuration;
- device-specific storage boundary;
- measured hardware capability differences.

These are boundary adaptations.

They do NOT transfer ownership of J2ME semantics into the adapter.

---

# 5. BEHAVIOR THAT MUST REMAIN CANONICAL/Miyoo-OWNED

Unless exact evidence proves otherwise, do not independently redefine:

- MIDlet lifecycle semantics;
- `Canvas` / `GameCanvas` semantics;
- repaint / flush semantics;
- key event semantics after hardware dispatch;
- GameCanvas key-state semantics;
- MIDP `Graphics` API behavior;
- image transform semantics;
- `drawRegion` semantics;
- RMS logical semantics;
- MMAPI Player state/control semantics;
- canonical vendor APIs already present in Miyoo;
- application timing semantics;
- game lifecycle semantics.

The RG35XX adapter must not become a second implementation of these contracts.

---

# 6. CLASS / MODULE PORT DECISION RULE

Before modifying or replacing any class or module, all fields below must be filled:

```text
PORT_UNIT=
MIYOO_SOURCE=
MIYOO_CURRENT_BEHAVIOR=
FREEJ2ME_REFERENCE=
JDK_OPENJDK_REFERENCE_IF_REQUIRED=
RG35XX_MEASURED_LIMITATION=
EXACT_FAILURE_OR_MISSING_CONTRACT=
FAILURE_OWNER=
WHY_MIYOO_AS_IS_CANNOT_WORK=
MINIMUM_REQUIRED_DELTA=
FILES_ALLOWED_TO_CHANGE=
FILES_FORBIDDEN_TO_CHANGE=
PARENT_REGRESSION_GATES=
HOST_DIFFERENTIAL_GATE=
MODULE_INTEGRATION_GATE=
PHYSICAL_GATE=
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

If any required field is unresolved:

```text
RUNTIME_PATCH=FORBIDDEN
ACTION=DIAGNOSTIC_OR_DOCUMENTATION_ONLY
```

---

# 7. NO SPECULATIVE CODE RULE

The following are forbidden as production reasoning:

```text
"this algorithm should be close enough"
"this is probably faster"
"this game seems to need it"
"the pixels look similar"
"this implementation is simpler"
"we can rewrite the whole class"
"we can optimize this while we are here"
```

No runtime implementation may be accepted because it merely looks plausible.

Required evidence is one or more of:

- exact pinned Miyoo source behavior;
- exact FreeJ2ME/canonical source behavior;
- exact JDK/OpenJDK backend behavior where Miyoo delegates to it;
- reproducible host differential;
- measured original-RG35XX hardware behavior;
- accepted original-RG35XX DEVICE-PASS evidence.

---

# 8. MINIMUM DELTA RULE

When RG35XX needs a different implementation:

```text
CHANGE_THE_SMALLEST_OWNER_SCOPED_BOUNDARY
```

Do not:

- rewrite neighboring methods without evidence;
- change multiple subsystems in one candidate;
- alter input while fixing graphics;
- alter graphics while fixing audio;
- alter lifecycle to hide a game exit;
- alter timing to hide rendering bugs;
- modify JamVM/glibj unless a separately approved runtime phase requires it;
- add per-game conditions;
- add game-name detection;
- import A9 experimental code as a parent.

A correct RG35XX port should contain fewer independent semantics, not more.

---

# 9. EXAMPLE — GRAPHICS / RAW2D

If Miyoo uses:

```text
PlatformGraphics method
        ↓
java.awt.Graphics2D / Java2D
```

and original RG35XX cannot use AWT:

Do NOT invent a new raster algorithm immediately.

Required process:

```text
1. Identify exact Miyoo public/class behavior.
2. Identify exact Java2D/JDK backend path.
3. Confirm failure or missing Raw2D boundary.
4. Determine canonical raster/geometry behavior.
5. Port only that behavior into the RG35XX Raw2D boundary.
6. Run strict differential tests.
7. Protect already accepted neighboring methods.
8. Integrate into the complete graphics module.
```

This rule is the reason approximate implementations must be rejected when they diverge from the canonical backend.

---

# 10. EXAMPLE — INPUT

The RG35XX adapter may own:

```text
/dev/input/js0
physical button acquisition
hardware polling
physical-to-semantic mapping
```

It must terminate at the existing Miyoo/FreeJ2ME key boundary.

It must not:

- call `Displayable` directly;
- invent alternate Canvas event semantics;
- change repeat behavior for one game without evidence;
- move GameCanvas state ownership into native code.

---

# 11. EXAMPLE — VIDEO / PRESENTER

RG35XX may replace the physical presentation backend because the device uses SDL1/fbcon.

It may own:

- physical framebuffer initialization;
- aspect fit;
- scale;
- pixel-format packing;
- `SDL_Flip`;
- measured presenter performance optimization.

It must not change:

- MIDP coordinate semantics;
- Graphics primitive meaning;
- clipping semantics;
- application logical resolution semantics without an explicit configuration contract.

Presenter optimization is not permission to rewrite J2ME drawing.

---

# 12. EXAMPLE — AUDIO

The RG35XX port may adapt:

- Java 6 compatibility glue;
- SDL1_mixer backend;
- native device initialization;
- audio route prime.

It must preserve Miyoo/FreeJ2ME MMAPI Player state/control behavior unless exact canonical evidence proves a required semantic correction.

API success alone is not audible-device evidence.

---

# 13. OPTIMIZATION RULE

Optimization is allowed only after ownership and correctness are established.

Required order:

```text
CORRECTNESS
    ↓
CANONICAL DIFFERENTIAL
    ↓
MODULE INTEGRATION
    ↓
MEASURED PERFORMANCE OWNER
    ↓
OWNER-SCOPED OPTIMIZATION
```

Never use:

```text
PERFORMANCE_PROBLEM
    ↓
RANDOM_PLATFORM_REWRITE
```

For any optimization candidate:

```text
MEASURED_BOTTLENECK_REQUIRED=YES
OWNER_REQUIRED=YES
SEMANTIC_DELTA_ALLOWED=NO_UNLESS_SEPARATELY_JUSTIFIED
PARENT_REGRESSION_REQUIRED=YES
```

---

# 14. BUILD LINEAGE RULE

The final RG35XX platform must remain recognizable as:

```text
PINNED MIYOO/AWEIGIT BUILD
    +
EXPLICIT RG35XX ADAPTER/BACKING DELTAS
```

It must NOT become:

```text
MIXED RANDOM FREEJ2ME CLASSES
    +
MIXED A9 EXPERIMENTS
    +
NEW HAND-WRITTEN PLATFORM SEMANTICS
```

Temporary diagnostic branches are allowed.

They are not automatically production parents.

Method-level branches must converge into module-level candidates.

---

# 15. PROTECTED RUNTIME RULE

Unless a separately approved phase explicitly changes them:

```text
JamVM:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj.zip:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Remain protected.

Current accepted A8 native/platform identities also remain protected evidence and may not be silently replaced merely because rebuilt artifacts are semantically similar.

---

# 16. MODULE-FIRST PROMOTION RULE

Method-level work is permitted for diagnostics and CI.

Production acceptance is module-level.

For Graphics:

```text
G1 + G2A + G2B + G2C + G2D + remaining declared graphics matrix
        ↓
P1A-COMPLETE-GRAPHICS-CANDIDATE
        ↓
ONE GRAPHICS MODULE EXERCISER
        ↓
ONE ORIGINAL-RG35XX PHYSICAL MODULE TEST
```

Do not request physical tests for every pure-Java primitive.

This addendum inherits:

```text
PLATFORM FIRST.
MODULE SECOND.
GAME COMPATIBILITY LAST.
```

---

# 17. GAME COMPATIBILITY RULE

A commercial game may reveal a platform gap.

It does not own platform architecture.

Until the platform baseline is promoted:

- no game-specific runtime code;
- no game-name conditions;
- no Tier-1 optimization-driven platform redesign;
- no using one game to justify unrelated subsystem changes.

Game evidence must first be translated into:

```text
EXACT_FAILURE
        ↓
PLATFORM_CONTRACT_GAP?
        ↓
OWNER
        ↓
GENERIC_FIX_IF_JUSTIFIED
```

If no generic platform contract gap is proven:

```text
PLATFORM_CHANGE=NOT_JUSTIFIED
```

---

# 18. REQUIRED PRE-CHANGE CHECKLIST — MIYOO-FIRST VERSION

Before every future runtime change:

```text
CURRENT_PHASE=
CURRENT_MODULE=

MIYOO_BUILD_BASE=
MIYOO_PIN=
MIYOO_SOURCE_PATH=
MIYOO_CURRENT_BEHAVIOR=

FREEJ2ME_REFERENCE=
JDK_OPENJDK_REFERENCE_IF_REQUIRED=

EXACT_RG35XX_GAP=
HARDWARE_EVIDENCE=
FAILURE_OWNER=
WHY_CHANGE_REQUIRED=

MINIMUM_DELTA=
FILES_ALLOWED_TO_CHANGE=
FILES_FORBIDDEN_TO_CHANGE=

PROTECTED_IDENTITIES=
HOST_GATE=
MODULE_GATE=
PHYSICAL_GATE=

GENERIC_PLATFORM_IMPACT=
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
SPECULATIVE_CODE=NO
```

If these cannot be answered:

```text
DO_NOT_PATCH
```

---

# 19. REQUIRED POST-CHANGE CHECKLIST — MIYOO-FIRST VERSION

Before accepting any candidate:

```text
MIYOO_BASE_PRESERVED=YES/NO
CANONICAL_BEHAVIOR_VERIFIED=YES/NO
FREEJ2ME_REFERENCE_USED_ONLY_AS_REQUIRED=YES/NO
RG35XX_BOUNDARY_ONLY=YES/NO

OWNER_SCOPE_VERIFIED=YES/NO
UNRELATED_CLASS_DIFF=NONE/...
PROTECTED_HASHES=PASS/FAIL
JAVA6_GATE=PASS/FAIL
HOST_DIFFERENTIAL=PASS/FAIL
MODULE_GATE=PASS/FAIL

GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO

PHYSICAL_TEST_REQUIRED=YES/NO
PHYSICAL_TEST_LEVEL=MODULE/SPECIAL_EXCEPTION
DEVICE_PASS=NO_UNTIL_PHYSICAL_ACCEPTANCE
STABLE=NO_UNTIL_PROMOTION
```

---

# 20. STOP CONDITIONS

Stop coding and return to diagnostics if any of the following occurs:

- the Miyoo behavior is not yet understood;
- the FreeJ2ME/JDK reference path is uncertain;
- the RG35XX boundary owner is uncertain;
- more than one subsystem appears to require simultaneous change;
- a patch is justified only by one game's behavior;
- a replacement class would duplicate canonical J2ME behavior;
- a test failure may be a generator/build/staging problem rather than runtime semantics;
- current evidence does not distinguish geometry, raster, device, lifecycle, input, audio, or timing ownership.

The correct response to uncertainty is:

```text
DIAGNOSE FIRST
PATCH SECOND
```

---

# 21. CURRENT PROJECT INTERPRETATION

As of 2026-10-02:

```text
P0_GOLDEN_AUTHORITY=COMPLETE

CURRENT_PHASE=P1_CORE_2D
CURRENT_WORKSTREAM=P1A_GRAPHICS

G1_CLEAR_COPY=ACCEPTED
G2A_FILLROUNDRECT=HOST_ACCEPTED
G2B_FILLTRIANGLE=HOST_ACCEPTED
G2C_DRAWROUNDRECT=HOST_ACCEPTED
G2D_DRAWARC=HOST_ACCEPTED
G2D_FILLARC=ACTIVE

NEXT_MAJOR_OUTPUT=
P1A-COMPLETE-GRAPHICS-CANDIDATE
+ ONE_GRAPHICS_MODULE_EXERCISER
+ ONE_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST

P2_TO_P9=NOT_YET_PROMOTED
```

The current `fillArc` work remains a host implementation unit and must converge into the Graphics module rather than becoming a permanent standalone production lineage.

---

# 22. FINAL LOCK

For every future technical decision, ask:

```text
1. What does the pinned Miyoo build already provide?
2. Can RG35XX use it unchanged?
3. If not, what exact RG35XX limitation prevents that?
4. What does FreeJ2ME/canonical source say?
5. If Miyoo delegates to JDK/AWT, what exact backend behavior must be reproduced?
6. What is the smallest RG35XX-owned boundary change?
7. Can it be proven by differential/module/device evidence?
```

If the answer to #2 is YES:

```text
KEEP_MIYOO_CODE
```

If #3–#6 are not proven:

```text
DO_NOT_INVENT_CODE
```

The permanent project principle is:

```text
MIYOO BUILD FIRST
        ↓
FREEJ2ME / CANONICAL SOURCE FOR SEMANTIC REFERENCE
        ↓
RG35XX BOUNDARY ONLY WHERE REQUIRED
        ↓
EVIDENCE-DRIVEN DIFFERENTIAL
        ↓
MODULE-LEVEL INTEGRATION
        ↓
ORIGINAL RG35XX PHYSICAL ACCEPTANCE
```

And the existing hard rule remains:

```text
PLATFORM FIRST.
MODULE SECOND.
GAME COMPATIBILITY LAST.
```
