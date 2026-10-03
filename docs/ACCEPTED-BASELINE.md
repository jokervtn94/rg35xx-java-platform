# RG35XX FreeJ2ME Port — Accepted Baseline Ledger

Lock date: **2026-10-03**

This ledger records the latest **physically accepted runtime lineage** and separates it from work that remains incomplete. A module-level physical acceptance does not imply full-platform stability.

## Official accepted runtime baseline

```text
OFFICIAL_REPOSITORY_BRANCH=main
OFFICIAL_MAIN_PROMOTION_MERGE=3087b9ca28d4fddd70406b7058abaeb708419215
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
P2B_ACCEPTED_BRANCH_HEAD=6cc7461897dedeafa3d71848854341d41c533b5d
P1A_ACCEPTED_CHECKPOINT=f502ea692518fa1e3b529718f44aaf459f90f49c
P2A_ACCEPTED_CHECKPOINT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
P2=PARTIAL
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

`main` tracks accepted work. P8 full-platform promotion has **not** occurred.

## Authority and ancestry

```text
PINNED MIYOO/AWEIGIT SOURCE
        ↓
A8 / GOLDEN PHYSICAL EVIDENCE AND PROTECTED IDENTITIES
        ↓
P1A GRAPHICS PHYSICAL MODULE ACCEPTANCE
        ↓
P2A IMAGE DECODE PHYSICAL MODULE ACCEPTANCE
        ↓
P2B FONT/TEXT PHYSICAL MODULE ACCEPTANCE
        ↓
P2C INPUT/FRONTEND CONTRACT — NEXT WORK UNIT
```

A9 and game-specific experimental branches remain diagnostic/history only.

## P0 — Golden authority

```text
P0_GOLDEN_AUTHORITY=PASS
```

Historical A8 physical acceptance and protected identities remain authoritative. Platform-first work must preserve them unless exact evidence formally reassigns an owner.

## P1 / P1A — Core 2D Graphics

```text
P1A_ACCEPTANCE_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c
P1A_CANDIDATE_HEAD=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P1A_PACKAGE=RG35XX-P1A-GRAPHICS-PHYSICAL-R2
P1A_GRAPHICS_HOST_MODULE_GATE=PASS
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P1A_GRAPHICS_PROTECTED_HASHES=PASS
P1A_GRAPHICS_NORMAL_EXIT=PASS
```

Evidence: `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`.

## P2A — Image Decode

```text
P2A_ACCEPTANCE_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2A_CANDIDATE_HEAD=77a36526e0f6d875c57c7e9a973e0c1a05573721
P2A_EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_IMAGE_DECODE_HOST_MODULE_GATE=PASS
P2A_IMAGE_DECODE_PHYSICAL_MODULE_GATE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2A_EXERCISER_FIXTURE_COUNT=150
P2A_EXERCISER_FRONTEND_COUNT=3
P2A_EXERCISER_DECODE_COUNT=450
P2A_EXERCISER_FAILURE_COUNT=0
P2A_EXERCISER_RESULT=PASS
P2A_NORMAL_EXIT=PASS
P2A_PLATFORM_JAR_SHA256=11a524c67edc631c2391573add4bcc21ea0e4d95d187fb4b34bffde01cf46b9b
```

Evidence: `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`.

## P2B — Font/Text

Runtime lineage:

```text
P2B_EXACT_RUNTIME_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2B_RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_HOST_MODULE_CHECKPOINT=121ca5904b7d442161ed4639f30c5fe9f1c5772d
P2B_PHYSICAL_PACKAGE_SOURCE_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
```

Host/module gates:

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

Original RG35XX physical evidence:

```text
P2B_EXERCISER_CASE_COUNT=360
P2B_EXERCISER_FAILURE_COUNT=0
P2B_EXERCISER_RESULT=PASS
P2B_RUNTIME_EXIT_CODE=0
P2B_PROTECTED_HASHES=PASS
P2B_NORMAL_EXIT=PASS
P2B_DEVICE_PROGRAMMATIC_RESULT=PASS
P2B_FONT_TEXT_MANUAL_OBSERVATION=PASS
P2B_PHYSICAL_TEST=PASS
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

Human observation confirmed a green `PASS` screen and normal return to the GarlicOS menu.

Font runtime asset:

```text
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_FONT_NAME=MiSans_Normal
P2B_FONT_PS_NAME=MiSans-Normal
```

Evidence: `docs/P2B-FONT-TEXT-PHYSICAL-ACCEPTANCE-20261003.md`.

### P2B Windows installer R2 hygiene

The user-visible Windows helper was corrected after the accepted R1 physical run. CI reconstructed R2 from the exact hash-locked R1 package and independently compared the entire `SD/` tree.

```text
P2B_R1_PACKAGE_SHA256=1e78c30c166f2ce4988478d44c476b0bfdf8c6795e433cf8f21ed934796037da
P2B_R2_HYGIENE_RUN=37133242055
P2B_R2_HYGIENE_JOB=111232412816
P2B_R2_HYGIENE_ARTIFACT_ID=11277463370
P2B_R2_PACKAGE_SHA256=7df059c07a3867eef5e6a00348b19b18ee6901cffd4bf7b53caefbbebb34de38
P2B_R2_SD_MANIFEST_SHA256=4ff2cd9b019c1b09147731ca690fa046d9fc361a8b715bda889a42c845d9d956
P2B_R2_INDEPENDENT_SD_TREE_IDENTITY=PASS
P2B_R2_WINDOWS_HELPER_GATE=PASS
P2B_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE
P2B_R2_RUNTIME_SEMANTIC_DELTA=NONE
```

This packaging-only revision does not require a second physical acceptance because the complete SD runtime payload is byte-identical to the physically accepted R1 package.

Evidence: `docs/P2B-WINDOWS-INSTALLER-R2-HYGIENE-CHECKPOINT-20261003.md`.

## Protected runtime identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

These owners remain protected during P2C unless evidence specifically identifies one as the owner of a missing P2 input/frontend contract.

## P2C — Input/Frontend next work unit

The locked P2 contract still requires one `INPUT-FRONTEND-MODULE` covering:

- complete physical input mapping;
- keymap/frontend policy;
- logical resolution configuration;
- pointer/touch policy;
- rotation policy if supported.

Current state:

```text
P2C_INPUT_FRONTEND_AUDIT=NOT_TESTED
P2C_RUNTIME_CANDIDATE=NOT_TESTED
P2C_HOST_MODULE_GATE=NOT_TESTED
P2C_PHYSICAL_TEST=NOT_TESTED
```

The next legal action is contract reconstruction/audit. No implementation is authorized until the exact canonical ownership, current RG35XX behavior, gap, owner and minimum delta are documented.

## Remaining platform phases

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

P2 remains `PARTIAL` only because the remaining Input/Frontend contract is not yet formally accepted. P9 work is not authorized before P8.

## New-chat rule

1. Read `TASKLOG.md` first.
2. Treat this ledger and the locked rule files as authority.
3. Verify exact accepted parent before changing runtime code.
4. Continue only the recorded `NEXT_LEGAL_ACTION` unless the user explicitly changes project direction.
5. Never use A9 or a game-specific experimental branch as a production parent.