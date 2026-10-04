# RG35XX FreeJ2ME Platform Port — TASKLOG / New-Chat Handoff

Last updated: **2026-10-04**

Purpose: this is the first checkpoint to read when a new ChatGPT conversation starts. It records exact accepted ancestry, protected identities, current phase status, and the only legal next work unit.

## 0. Locked project rules

Read and obey:

```text
RG35XX-PORT-RULER-LOCKED-v1.md
RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md
RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md
RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md
```

Permanent direction:

```text
MIYOO BUILD FIRST
        ↓
FREEJ2ME / CANONICAL SOURCE FOR SEMANTIC REFERENCE
        ↓
RG35XX BOUNDARY ONLY WHERE REQUIRED
        ↓
HOST DIFFERENTIAL / PARENT REGRESSION
        ↓
ONE MODULE GATE
        ↓
ORIGINAL RG35XX PHYSICAL ACCEPTANCE
```

Locked vocabulary:

```text
PASS
FAIL
PARTIAL
NOT_TESTED
NEEDS_REPRO
REJECTED
ARCHIVED_DIAGNOSTIC
```

---

## 1. New-chat bootstrap — current truth

```text
PROJECT=FreeJ2ME_R35XX_PLATFORM_PORT
TARGET=ORIGINAL_ANBERNIC_RG35XX
CANONICAL_SOURCE=aweigit/freej2me-miyoomini
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63

OFFICIAL_REPOSITORY_BRANCH=main
OFFICIAL_MAIN_PROMOTION_MERGE=3087b9ca28d4fddd70406b7058abaeb708419215
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
P2B_ACCEPTED_BRANCH_HEAD=6cc7461897dedeafa3d71848854341d41c533b5d

CURRENT_PHASE=P4
CURRENT_MODULE=P4_3D_CAPABILITY_DECISION
CURRENT_PHYSICAL_ACCEPTED_SCOPE=P2C_INPUT_FRONTEND
CURRENT_PHYSICAL_ACCEPTED_BRANCH_HEAD=8cd4f6b

P0=PASS
P1=PASS
P2=PASS
P3=PASS
P4=NOT_TESTED
P5=NOT_TESTED
P6=NOT_TESTED
P7=NOT_TESTED
P8=NOT_TESTED
P9=NOT_TESTED

RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

### NEXT_LEGAL_ACTION

```text
NEXT_LEGAL_ACTION=P4_EGL_GLES_HARDWARE_CAPABILITY_PROBE
EXACT_ACCEPTED_RUNTIME_PARENT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
PHYSICAL_ACCEPTED_PREDECESSOR=P2C_INPUT_FRONTEND
EXPECTED_PHYSICAL_MODULE=RUNTIME-SERVICE-MODULES
P3_AUDIT_DEFINITION=docs/P3-RUNTIME-SERVICE-MODULE-AUDIT-20261004.md
P3_AUDIT_WORKFLOW=.github/workflows/p3-runtime-service-audit.yml
P3_EXERCISER_WORKFLOW=.github/workflows/p3-runtime-service-exerciser.yml
P3_EXERCISER_WORKFLOW_RUN=37211752518
P3_EXERCISER_ARTIFACT=RG35XX-P3-RUNTIME-SERVICE-EXERCISER-4fe82701dc98f29b96585e85deb146093ac14cc3
P3_PLATFORM_SHA256=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
P3_PHYSICAL_TEST=PASS
P3_AUDIO_AUDIBLE_DEVICE=CONFIRMED_BY_USER
P3_DEVICE_PROGRAMMATIC_RESULT=PASS
P4=NOT_TESTED
DEVICE_PASS=P3_SCOPED_ONLY
P4_PROBE_WORKFLOW_RUN=37214748433
P4_PROBE_ARTIFACT=RG35XX-P4-CAPABILITY-PROBE-cc29ad2f92666f26256a8c4a6850a4ec19b92276
P4_PROBE_ARTIFACT_SHA256=f877a9214accd4d328d59c0944a61a4f209fdeb54164d99766c08332791b099b
```

P2C is physically accepted by the original-RG35XX three-phase device run. P3 is now physically accepted as a scoped runtime-service module: lifecycle, RMS, FileConnection, WAV/MIDI API paths, audible output, shutdown and protected hashes all passed. The read-only P4 EGL/GLES capability probe is built and installed on the SD; the next action is to run it on the original RG35XX and review its evidence. Do not re-enable M3G, MascotCapsule/Micro3D or LWJGL/OpenGL until the device probe and source-call mapping provide evidence.

---

## 2. Official accepted ancestry

### Golden / A-series authority

```text
A8_GOLDEN_AUTHORITY=PASS
A8_AS_CURRENT_PLATFORM_PHASE=P0_REFERENCE_ONLY
A9_EXPERIMENTAL_LINEAGE=ARCHIVED_DIAGNOSTIC
A9_PARENT=NO
```

A8 remains protected evidence. A9 never becomes a production parent.

### P1A — Core 2D Graphics

```text
P1A_CANDIDATE_HEAD=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P1A_ACCEPTANCE_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c
P1A_GRAPHICS_HOST_MODULE_GATE=PASS
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P1A_GRAPHICS_PROTECTED_HASHES=PASS
P1A_GRAPHICS_NORMAL_EXIT=PASS
```

Evidence: `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`.

### P2A — Image Decode

```text
P2A_EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_CANDIDATE_HEAD=77a36526e0f6d875c57c7e9a973e0c1a05573721
P2A_ACCEPTANCE_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2A_IMAGE_DECODE_HOST_MODULE_GATE=PASS
P2A_IMAGE_DECODE_PHYSICAL_MODULE_GATE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2A_FIXTURES=150
P2A_PUBLIC_FRONTENDS=3
P2A_DEVICE_DECODE_CASES=450
P2A_DEVICE_FAILURES=0
P2A_NORMAL_EXIT=PASS
```

Evidence: `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`.

### P2B — Font/Text

Runtime / evidence chain:

```text
P2B_EXACT_RUNTIME_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2B_RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_HOST_MODULE_CHECKPOINT=121ca5904b7d442161ed4639f30c5fe9f1c5772d
P2B_PHYSICAL_PACKAGE_SOURCE_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
P2B_ACCEPTED_BRANCH_HEAD=6cc7461897dedeafa3d71848854341d41c533b5d
```

Required host/module gates all passed:

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
P2B_HOST_MODULE_GATE=PASS
```

Original RG35XX result:

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

Human observation: green `PASS` screen and normal return to GarlicOS.

Evidence: `docs/P2B-FONT-TEXT-PHYSICAL-ACCEPTANCE-20261003.md`.

### P2B Windows installer R2 hygiene

The Windows helper fix is packaging-only. R2 was reconstructed from the exact physically accepted R1 package and the complete SD trees were independently compared.

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

Evidence: `docs/P2B-WINDOWS-INSTALLER-R2-HYGIENE-CHECKPOINT-20261003.md`.

---

## 3. Protected accepted identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
P2A_PLATFORM_JAR_SHA256=11a524c67edc631c2391573add4bcc21ea0e4d95d187fb4b34bffde01cf46b9b
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
```

P2C must not casually replace any accepted owner. Input/video/lifecycle changes require evidence that the missing contract belongs there.

---

## 4. Platform phase ledger

| Phase | Status | Current evidence / remaining gate |
|---|---|---|
| **P0 — Exact Golden authority** | `PASS` | Exact Golden/protected lineage retained. |
| **P1 — Core 2D platform completion** | `PASS` | P1A physical module acceptance completed. |
| **P2 — Image / font / frontend contract** | `PASS` | P2A Image Decode, P2B Font/Text and P2C Input/Frontend module are physically accepted on the original RG35XX. |
| **P3 — Runtime service modules** | `NOT_TESTED` | Audit and CI package build PASS; original-RG35XX module test and audible review remain. |
| **P4 — Deferred capability decision** | `NOT_TESTED` | M3G/Mascot/LWJGL/OpenGL/hardware capability inventory required. |
| **P5 — Generic installer/platform** | `NOT_TESTED` | One generic installer/launcher required. |
| **P6 — Full platform exerciser** | `NOT_TESTED` | Full declared platform contract suite required. |
| **P7 — Tier-0 physical regression** | `NOT_TESTED` | Vua Cướp Biển + God of War; audible GoW audio remains protected expectation. |
| **P8 — Baseline promotion** | `NOT_TESTED` | Only after P0–P7 pass. |
| **P9 — Compatibility updates** | `NOT_TESTED` | Not authorized before P8. |

---

## 5. P2C Input/Frontend accepted checkpoint

The locked P2 rule defines the remaining scope as one physical module:

```text
INPUT-FRONTEND-MODULE
```

It includes:

```text
complete physical input mapping
keymap/frontend policy
logical resolution configuration
pointer/touch policy
rotation policy if supported
```

Current state:

```text
P2C_INPUT_FRONTEND_AUDIT=PASS
P2C_CANONICAL_DIFF_VERIFIED=PASS
P2C_OWNER_SCOPE_VERIFIED=PASS
P2C_RUNTIME_CANDIDATE=PASS
P2C_PARENT_REGRESSION=PASS
P2C_MODULE_GATE=PASS
P2C_PHYSICAL_TEST=PASS
```

### Required audit questions

The completed audit established from pinned Miyoo and accepted RG35XX sources:

1. Which layer owns raw hardware acquisition (`/dev/input/js0`) versus MIDP logical key semantics?
2. Exact keycode/game-action mapping expected by canonical Miyoo behavior.
3. Frontend ownership for Canvas/GameCanvas dimensions and logical resolution selection.
4. Whether pointer/touch is unsupported, mapped, or exposed by policy on original RG35XX.
5. Whether rotation is unsupported or has an explicit frontend/config contract.
6. Current accepted resize/display behavior and whether it belongs to P2 frontend policy or later P3 resize service.
7. Exact protected native/input/video hashes and whether any source/runtime divergence exists.
8. The minimum owner-scoped delta, if any, and the host/module tests that can prove it before device work.

### Required P2C sequence

```text
canonical Miyoo/frontend/input inventory
-> accepted RG35XX input/frontend inventory
-> contract gap table
-> owner classification
-> minimum allowed file scope
-> host differential tests
-> parent P1/P2A/P2B regressions
-> one INPUT-FRONTEND-MODULE integration gate
-> one original-RG35XX physical module package
-> human physical acceptance
```

The accepted P2C module records:

```text
P2C_RUNTIME_EDIT_AUTHORIZED=YES_FOR_P2C_MODULE_ONLY
P2C_DEVICE_PACKAGE=PASS
P2C_PHYSICAL_TEST=PASS
```

---

## 6. Historical diagnostics that must not become production parents

```text
A9=ARCHIVED_DIAGNOSTIC
RAW_DEFAULT_FREETYPE_AS_JDK8_DROPIN=REJECTED
PINNED_MIYOO_FREETYPE_2_11_1_AS_EXACT_JDK8_ENGINE=REJECTED
HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
SYNTHETIC_5X7_FONT_AS_FINAL_P2B_BACKEND=REJECTED
```

Game-specific branches and historical diagnostics remain evidence only.

---

## 7. New-chat anti-drift checklist

Before runtime edits verify:

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P3_RUNTIME_SERVICE_MODULES
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_ACCEPTED_RUNTIME_PARENT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
HARDWARE_EVIDENCE=P1A_PASS_PLUS_P2A_PASS_PLUS_P2B_PASS_ON_ORIGINAL_RG35XX
NEXT_LEGAL_ACTION=P3_RUNTIME_SERVICE_MODULE_PHYSICAL_TEST
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

If a future chat sees a newer branch/SHA, first establish whether it is a formally accepted checkpoint. Do not assume the newest commit is accepted runtime semantics.

---

## 8. Definition of completion

The project is not complete at P2C.

```text
P0 PASS
-> P1 PASS
-> P2 PASS
-> P3 PASS
-> P4 PASS
-> P5 PASS
-> P6 PASS
-> P7 PASS
-> P8 BASELINE PROMOTION
```

Only after P8 may P9 compatibility work resume under the normal failure-owner workflow.
