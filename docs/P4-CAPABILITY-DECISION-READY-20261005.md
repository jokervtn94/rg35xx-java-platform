# P4 — Deferred capability decision checkpoint

**Date:** 2026-10-05  
**Status:** `PARTIAL`  
**Branch:** `physical-test/p4-capability-decision-20261005`  
**Parent:** `23a79d5d8bdf024382890f8d347cf50c85c91203`  
**Canonical Aweigit:** `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

## Why this is the current checkpoint

The accepted project lineage has already completed the module-level P2C
input/frontend physical acceptance and P3 runtime-service physical acceptance.
P3 includes user-confirmed audible WAV/MIDI output on the original RG35XX.
The next phase required by the locked platform-first rule is P4: decide the
measured hardware/runtime capability for deferred M3G, MascotCapsule/Micro3D
and LWJGL/OpenGL support before P5 installer work begins.

The P4 parent already contains three read-only diagnostics:

1. visible EGL/GLES/OpenGL provider inventory;
2. EGL/GLES context creation probe;
3. EGL platform/device/display probe.

All three explicitly keep the deferred 3D stacks disabled.

## Process correction

The three diagnostics were packaged separately. Running them as three separate
physical prerequisites would add unnecessary original-RG35XX test cycles even
though they answer one module question. The platform-first rule requires
physical testing to be module-level where possible.

This branch therefore adds one consolidation package only. It does not change
any production Java/native runtime code and it does not alter the three probe
implementations.

```text
CURRENT_PHASE=P4
CURRENT_MODULE=P4_3D_CAPABILITY_DECISION
P4_STATUS=PARTIAL
P4_PARENT_COMMIT=23a79d5d8bdf024382890f8d347cf50c85c91203
MIYOO_BUILD_BASE=aweigit/freej2me-miyoomini
MIYOO_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RUNTIME_SEMANTIC_DELTA=NONE
PHYSICAL_TEST_LEVEL=MODULE
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
SPECULATIVE_CODE=NO
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

## Pre-change ownership lock

```text
EXACT_EVIDENCE_REQUIRING_ACTION=
  P4 deferred capabilities cannot be classified from host/CI alone;
  original-RG35XX EGL/GLES/provider behavior remains physically unmeasured
  in the available project evidence.

CANONICAL_BEHAVIOR=
  keep the pinned Miyoo/Aweigit 3D stack as the reference; do not replace it
  and do not re-enable it until its required backend is proven available.

EXACT_RG35XX_BOUNDARY=
  physical EGL/GLES provider, ABI, display/platform and context capability.

OWNER=
  RG35XX_HARDWARE_CAPABILITY_BOUNDARY / DEFERRED_CAPABILITY.

FILES_ALLOWED_TO_CHANGE=
  P4 diagnostic scripts, P4 native probes, CI workflow, P4 documentation.

FILES_FORBIDDEN_TO_CHANGE=
  production FreeJ2ME/J2ME semantics, accepted P1/P2/P3 runtime owners,
  JamVM/glibj, input/video/audio production natives, game-specific code.

HOST_GATE=
  all three existing P4 probe builders + consolidated package build under the
  pinned Miyoo uClibc toolchain.

PHYSICAL_GATE=
  one original-RG35XX P4 module run producing one consolidated evidence
  directory, followed by source/hardware review.

GENERIC_PLATFORM_IMPACT=
  capability classification only; no automatic runtime enablement.
```

## Consolidated package contract

Builder:

```text
scripts/build-p4-capability-decision-package.sh
```

One device launcher:

```text
/mnt/mmc/Roms/APPS/RG35XX-P4-CAPABILITY-DECISION.sh
```

One evidence directory to return:

```text
/mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE
```

Expected files:

```text
P4-CAPABILITY-DECISION.log
P4-EGL-GLES-PROBE.log
P4-EGL-GLES-CONTEXT.log
P4-EGL-PLATFORM.log
```

Expected pre-review marker:

```text
P4_CAPABILITY_DECISION=REVIEW_REQUIRED
```

That marker is intentional. Even if EGL/GLES initialization succeeds, the
result must first be mapped to the exact pinned Miyoo native 3D requirements.
A probe success does not itself authorize enabling M3G, Micro3D or LWJGL.

## Only legal continuation after CI

If the consolidated build gate is `PASS`, run this one P4 module package on the
original RG35XX and review the returned evidence. Do not begin P5 and do not
modify production runtime semantics before the P4 capability decision is
recorded.

After evidence review, each deferred capability must be explicitly classified
according to the locked project vocabulary/scope. Unsupported or unproven
capabilities remain deferred; there is no blind re-enable path.
