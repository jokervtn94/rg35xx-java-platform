# RG35XX FreeJ2ME Port — Accepted Baseline Ledger

Lock date: **2026-10-03**

This ledger records the latest **physically accepted runtime lineage** and separates it from audit/candidate work that is not yet accepted.

## Official accepted runtime baseline

```text
OFFICIAL_REPOSITORY_BRANCH=main
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2A_IMAGE_DECODE
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P1A_ACCEPTED_CHECKPOINT=f502ea692518fa1e3b529718f44aaf459f90f49c
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

`main` is the official repository/tracking branch after promotion of the accepted P2A lineage. This does **not** mean P8 full-platform promotion has occurred.

The locked platform-first rule permits full baseline promotion only after P0–P7 have passed.

## Authority and ancestry

The accepted authority chain remains:

```text
PINNED MIYOO/AWEIGIT SOURCE
        ↓
A8 / GOLDEN PHYSICAL EVIDENCE AND PROTECTED IDENTITIES
        ↓
PLATFORM-FIRST RECONSTRUCTION
        ↓
P1A GRAPHICS PHYSICAL MODULE ACCEPTANCE
        ↓
P2A IMAGE DECODE PHYSICAL MODULE ACCEPTANCE
        ↓
P2B FONT/TEXT — CURRENT WORK
```

Hard ancestry locks:

```text
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

A9 and game-specific experimental branches remain diagnostic/history only.

## P0 — Golden authority

```text
P0_GOLDEN_AUTHORITY=PASS
```

Historical A8 physical acceptance, protected component identities, Tier-0 evidence and exact Golden reconstruction records remain authoritative. Platform-first work must preserve them unless exact evidence formally reassigns an owner.

## P1 / P1A — Core 2D Graphics

Accepted original-RG35XX checkpoint:

```text
P1A_ACCEPTANCE_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c
P1A_CANDIDATE_HEAD=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P1A_PACKAGE=RG35XX-P1A-GRAPHICS-PHYSICAL-R2
P1A_GRAPHICS_HOST_MODULE_GATE=PASS
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P1A_GRAPHICS_PROTECTED_HASHES=PASS
P1A_GRAPHICS_NORMAL_EXIT=PASS
```

Physical evidence included the one P1A graphics exerciser on original RG35XX, all declared programmatic graphics checks, protected-hash preservation, the visible `P1A GRAPHICS PASS` result and normal return to GarlicOS.

Evidence record:

- `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`

## P2A — Image Decode

Accepted original-RG35XX checkpoint:

```text
P2A_ACCEPTANCE_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2A_CANDIDATE_HEAD=77a36526e0f6d875c57c7e9a973e0c1a05573721
P2A_EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_IMAGE_DECODE_HOST_MODULE_GATE=PASS
P2A_IMAGE_DECODE_PHYSICAL_MODULE_GATE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

Device evidence:

```text
P2A_EXERCISER_FIXTURE_COUNT=150
P2A_EXERCISER_FRONTEND_COUNT=3
P2A_EXERCISER_DECODE_COUNT=450
P2A_EXERCISER_FAILURE_COUNT=0
P2A_EXERCISER_RESULT=PASS
P2A_NORMAL_EXIT=PASS
```

The three public decode frontends were byte-array, input-stream and resource-name. Human observation confirmed the visible PASS result and normal GarlicOS return.

Accepted P2A candidate platform JAR:

```text
P2A_PLATFORM_JAR_SHA256=11a524c67edc631c2391573add4bcc21ea0e4d95d187fb4b34bffde01cf46b9b
```

Evidence record:

- `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`

## Protected runtime identities

The accepted device lineage preserves:

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

These owners must not be changed during P2B unless separate evidence explicitly proves one of them owns a P2B failure.

## P2B — Font/Text current handoff

P2B is **not part of the accepted runtime baseline yet**.

Latest audit/design checkpoint:

```text
P2B_AUDIT_BRANCH=audit/p2b-font-text-post-layout-r2
P2B_AUDIT_HEAD=8d3dc24f847380c699e18b6efd4bd9183884ac2c
```

Current implementation-candidate branch:

```text
P2B_CANDIDATE_BRANCH=module/p2b-font-text-candidate-r1
P2B_CANDIDATE_HEAD=3fad06899232b7307fc6249f1a4dfe35c830ec3b
P2B_CANDIDATE_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2B_RUNTIME_CANDIDATE=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
```

Audit/design evidence already closed for its declared scopes:

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=PASS
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PASS
P2B_FILES_ALLOWED_TO_CHANGE=PASS
P2B_MINIMUM_REQUIRED_DELTA=PASS
P2B_FONT_PROVISIONING_PACKAGING_CONTRACT=PASS
```

Scope details matter:

- exhaustive `charWidth` / `canDisplay`: exact 196,608/196,608 BMP code-unit cases;
- simple raster: existing 144-case simple-string corpus;
- complex layout: existing 192-case non-simple corpus;
- font asset: exact Aweigit 2.0 MiSans runtime identity, embedded-software provisioning only, with required attribution/license handling.

These are audit/design gates, not runtime/device acceptance.

### P2B minimum owner scope

The authorized design keeps Miyoo/MIDP semantics in their existing owners and replaces only the unavailable provisional RG35XX Raw2D backing.

Allowed future runtime scope is limited to the documented P2B owner boundary, including:

- `adapter/java/org/recompile/rg35xx/RG35XXCore2D.java` font/text backing section;
- owner-scoped P2B staging/build files;
- a new owner-scoped font native backend/glue if required;
- Raw2D-only staged deltas in `Font.java` and `PlatformGraphics.java` while preserving their public/Miyoo semantics.

Forbidden P2B changes include the canonical gitlink/pin, JamVM, glibj, protected input/video/audio natives, P1A non-text graphics semantics, P2A image semantics, RMS, MMAPI, lifecycle and game-specific logic.

## Required P2B acceptance sequence

Before any P2B physical package may be considered accepted, the runtime candidate must pass in order:

```text
P2B_CANONICAL_DIFF_VERIFIED=PASS
P2B_OWNER_SCOPE_VERIFIED=PASS
P2B_JAVA6_GATE=PASS
P2B_HOST_FONT_METRICS_GATE=PASS
P2B_HOST_SIMPLE_RASTER_GATE=PASS
P2B_HOST_COMPLEX_LAYOUT_GATE=PASS
P1A_GRAPHICS_PARENT_REGRESSION=PASS
P2A_IMAGE_PARENT_REGRESSION=PASS
P2B_MODULE_GATE=PASS
```

Only after those gates may one original-RG35XX P2B physical module package be built and tested.

## Remaining platform phases

Current platform state:

```text
P0=PASS
P1=PASS
P2=PARTIAL
P3=NOT_TESTED
P4=NOT_TESTED
P5=NOT_TESTED
P6=NOT_TESTED
P7=NOT_TESTED
P8=NOT_TESTED
P9=NOT_TESTED
```

P2 remains `PARTIAL` because P2B and the remaining frontend/input/resolution contract have not received their required runtime/module/physical acceptance.

P9 work is not authorized before P8.

## Human + ChatGPT collaboration record

The repository owner/operator is completing this project with **ChatGPT by OpenAI as an engineering assistant**. ChatGPT assists with source/ancestry auditing, contract reconstruction, differential-test design, evidence review, GitHub/documentation work and checkpoint/tasklog continuity.

Original-RG35XX physical observations and project decisions remain human-controlled. No ChatGPT analysis substitutes for a required physical device gate.

## New-chat rule

For every new chat:

1. Read `TASKLOG.md` first.
2. Treat this ledger and the locked rule files as authority.
3. Verify exact parent/branch identity before changing runtime code.
4. Continue the recorded `NEXT_LEGAL_ACTION` rather than reopening accepted owners.
5. Never parent production work from A9 or from a game-specific experimental branch.
