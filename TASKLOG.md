# RG35XX FreeJ2ME Platform Port — TASKLOG / New-Chat Handoff

Last updated: **2026-10-03**

Purpose: this file is the first checkpoint to read when a new ChatGPT conversation starts. It records the exact accepted runtime ancestry, the status of every platform phase, the current legal work unit, and the evidence that must not be reopened without cause.

## 0. Locked project rules

Before doing any new runtime work, read and obey the project-supplied locked documents:

```text
RG35XX-PORT-RULER-LOCKED-v1.md
RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md
RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md
RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md
```

Permanent engineering direction:

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

Locked status vocabulary:

```text
PASS
FAIL
PARTIAL
NOT_TESTED
NEEDS_REPRO
REJECTED
ARCHIVED_DIAGNOSTIC
```

Do not use “stable”, “fixed”, “working”, or “passed” without identifying the exact scope.

---

## 1. New-chat bootstrap — current truth

```text
PROJECT=FreeJ2ME_R35XX_PLATFORM_PORT
TARGET=ORIGINAL_ANBERNIC_RG35XX
CANONICAL_SOURCE=aweigit/freej2me-miyoomini
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63

OFFICIAL_REPOSITORY_BRANCH=main
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2A_IMAGE_DECODE
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P1A_ACCEPTED_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c

CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT

P2B_AUDIT_BRANCH=audit/p2b-font-text-post-layout-r2
P2B_AUDIT_HEAD=8d3dc24f847380c699e18b6efd4bd9183884ac2c
P2B_CANDIDATE_BRANCH=module/p2b-font-text-candidate-r1
P2B_CANDIDATE_HEAD=3fad06899232b7307fc6249f1a4dfe35c830ec3b
P2B_CANDIDATE_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441

P2B_RUNTIME_CANDIDATE=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO

A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

### NEXT_LEGAL_ACTION

```text
NEXT_LEGAL_ACTION=P2B_FONT_TEXT_MODULE_CANDIDATE_R1_IMPLEMENTATION
EXACT_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
WORK_BRANCH=module/p2b-font-text-candidate-r1
```

Implement only the already-audited owner-scoped P2B Font/Text backing. Do not modify accepted input/video/audio/image/non-text graphics owners. Do not build a physical P2B package until all required host/parent/module gates pass.

---

## 2. Official accepted ancestry

### Historical Golden / A-series lineage

The earlier A4–A8 work remains accepted Golden evidence for the scopes physically demonstrated there. It established the original-RG35XX boot/presentation/input chain, accepted graphics/input behavior, selected Tier-0 regression, Java 6 media compatibility, SDL1_mixer audio and the accepted audio-route prime.

```text
A8_GOLDEN_AUTHORITY=PASS
A8_AS_CURRENT_PLATFORM_PHASE=P0_REFERENCE_ONLY
A9_EXPERIMENTAL_LINEAGE=ARCHIVED_DIAGNOSTIC
```

A8 is preserved as Golden authority; it is not a reason to skip the new platform-first P0–P8 reconstruction sequence. A9 must never become a production parent.

### P1A accepted ancestry

```text
P1A_CANDIDATE_HEAD=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P1A_ACCEPTANCE_COMMIT=f502ea692518fa1e3b529718f44aaf459f90f49c
P1A_PACKAGE=RG35XX-P1A-GRAPHICS-PHYSICAL-R2
P1A_GRAPHICS_HOST_MODULE_GATE=PASS
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P1A_GRAPHICS_PROTECTED_HASHES=PASS
P1A_GRAPHICS_NORMAL_EXIT=PASS
```

Physical result: original RG35XX displayed `P1A GRAPHICS PASS`, programmatic declared graphics checks passed, protected identities were unchanged, and the system returned normally to GarlicOS.

Evidence:

```text
docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md
```

### P2A accepted ancestry

```text
P2A_EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
P2A_CANDIDATE_HEAD=77a36526e0f6d875c57c7e9a973e0c1a05573721
P2A_ACCEPTANCE_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2A_IMAGE_DECODE_HOST_MODULE_GATE=PASS
P2A_IMAGE_DECODE_PHYSICAL_MODULE_GATE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

Device corpus:

```text
P2A_FIXTURES=150
P2A_PUBLIC_FRONTENDS=3
P2A_DEVICE_DECODE_CASES=450
P2A_DEVICE_FAILURES=0
P2A_NORMAL_EXIT=PASS
```

Evidence:

```text
docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md
```

P2A is the latest accepted runtime parent. P2B candidate work must descend from it.

---

## 3. Protected accepted identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
P2A_PLATFORM_JAR_SHA256=11a524c67edc631c2391573add4bcc21ea0e4d95d187fb4b34bffde01cf46b9b
```

A P2B change is not allowed to casually replace any of these owners.

---

## 4. Platform phase ledger

| Phase | Status | Current evidence / remaining gate |
|---|---|---|
| **P0 — Exact Golden authority** | `PASS` | Exact Golden/protected lineage recovered and retained; A8 evidence remains authority; A9 parent rejected. |
| **P1 — Core 2D platform completion** | `PASS` | P1A graphics host/module gate and original-RG35XX physical module acceptance completed. |
| **P2 — Image / font / frontend contract** | `PARTIAL` | P2A Image Decode is PASS. P2B Font/Text runtime/module/device acceptance is not complete. Remaining frontend/input/resolution policy still requires its platform-first gate. |
| **P3 — Runtime service modules** | `NOT_TESTED` | Historical Golden RMS/media/audio/lifecycle evidence remains protected, but the current platform-first P3 module sequence has not been formally closed. |
| **P4 — Deferred capability decision** | `NOT_TESTED` | M3G/Mascot/LWJGL/OpenGL/hardware capability inventory must be explicitly classified; no blind re-enable. |
| **P5 — Generic installer/platform** | `NOT_TESTED` | Final generic FreeJ2ME-RG35XX installer/launcher required; no commercial-game-name runtime logic. |
| **P6 — Full platform exerciser** | `NOT_TESTED` | One suite must cover the full declared platform contract. |
| **P7 — Tier-0 physical regression** | `NOT_TESTED` | Vua Cướp Biển + God of War required for final baseline promotion; God of War audible audio is a protected expectation. |
| **P8 — Baseline promotion** | `NOT_TESTED` | May occur only after P0–P7 pass. |
| **P9 — Compatibility updates** | `NOT_TESTED` | Not authorized before P8. |

---

## 5. P2B Font/Text audit ledger

P2B audit work is advanced enough to authorize a narrowly scoped implementation candidate, but **no P2B runtime acceptance exists yet**.

### 5.1 Source and semantic reference

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_JDK8_SEMANTIC_REFERENCE=PASS
P2B_JDK8_CMAP_CONTROL_RULE=PASS
```

Exact font identity used by the pinned Miyoo release / P2B evidence:

```text
P2B_FONT_ENTRY=JAVA/font.ttf
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_FONT_NAME=MiSans_Normal
P2B_FONT_PS_NAME=MiSans-Normal
```

### 5.2 Metrics / displayability

Exact source-matched OpenJDK8u504 vendored FreeType was cross-built with the pinned ARMv5/uClibC toolchain.

```text
P2B_CHARWIDTH_CASES=196608
P2B_CHARWIDTH_WIDTH_MISMATCH_COUNT=0
P2B_CHARWIDTH_DISPLAY_MISMATCH_COUNT=0
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CHARWIDTH=PASS
P2B_JDK8U504_FREETYPE_ARM_EXHAUSTIVE_CANDISPLAY=PASS
P2B_JDK8_CHARWIDTH_STYLE_INVARIANCE=PASS
```

### 5.3 Simple string path

```text
P2B_SIMPLE_STRING_METRIC_PATH=PASS
P2B_SIMPLE_DRAWSTRING_SOURCE_PATH=PASS
P2B_SIMPLE_STRING_DRAW_RASTER=PASS
P2B_SIMPLE_RASTER_SCOPE=EXISTING_144_CASE_SIMPLE_RASTER_CORPUS
```

The simple raster PASS is scoped to the existing 144-case corpus; it is not a claim of universal text equivalence.

### 5.4 Complex string layout

Exact JDK8 bundled LayoutEngine semantics were reconstructed on ARM for the existing non-simple corpus:

```text
P2B_LAYOUTENGINE_CASES=192
P2B_LAYOUTENGINE_MISMATCH_COUNT=0
P2B_COMPLEX_LAYOUT_EXISTING_CORPUS=PASS
```

Raw/default HarfBuzz substitution is not authorized.

### 5.5 Owner/file boundary

```text
P2B_MINIMUM_OWNER_SCOPED_RUNTIME_INTERFACE=PASS
P2B_FILES_ALLOWED_TO_CHANGE=PASS
P2B_MINIMUM_REQUIRED_DELTA=PASS
```

Minimum delta:

```text
Replace only the provisional RG35XX Raw2D synthetic font metrics/raster backing
with source-matched JDK8u504 font backend semantics,
while preserving the pinned Miyoo Font/PlatformGraphics API and anchor ownership.
```

Allowed future runtime owner scope includes:

```text
adapter/java/org/recompile/rg35xx/RG35XXCore2D.java   [font/text backing section]
scripts/stage-p2b-font-text.py                        [new]
adapter/native/rg35xx_font_jdk8.*                     [new owner-scoped font backend/glue]
scripts/build-p2b-font-text-candidate.sh               [new]
```

Raw2D-only staging may touch:

```text
src/javax/microedition/lcdui/Font.java
src/org/recompile/mobile/PlatformGraphics.java
```

Forbidden owner changes for P2B:

```text
upstream/freej2me-miyoomini gitlink/pin
JamVM
glibj.zip
rg35xx_input.c / input dispatcher semantics
rg35xx_video_sdl1.c / presenter semantics
rg35xx_audio_sdl1_mixer.c / MMAPI/audio semantics
P1A non-text graphics semantics
P2A image-decode semantics
RMS/filesystem semantics
MIDlet lifecycle/shutdown semantics
commercial-game-specific runtime logic
```

### 5.6 Font provisioning/packaging

Engineering packaging contract:

```text
P2B_MISANS_EMBEDDED_USE_EVIDENCE=PASS
P2B_FONT_PACKAGING_LICENSE_SCOPE=PASS
P2B_FONT_PROVISIONING_PACKAGING_CONTRACT=PASS
```

Locked behavior:

- repository does not commit MiSans font bytes;
- production build fetches/extracts the exact Aweigit release asset and hash-gates it;
- final FreeJ2ME-RG35XX software package may embed the exact font only with required attribution/license materials;
- standalone font distribution is `REJECTED`;
- font modification/subsetting/substitution is not allowed under this P2B contract;
- missing/hash-mismatched font must fail closed rather than silently falling back to synthetic 5x7 text.

### 5.7 Runtime candidate state

```text
P2B_PRECHANGE_DECISION_RECORD=PASS
P2B_RUNTIME_CANDIDATE=NOT_TESTED
P2B_CANONICAL_DIFF_VERIFIED=NOT_TESTED
P2B_OWNER_SCOPE_VERIFIED=NOT_TESTED
P2B_JAVA6_GATE=NOT_TESTED
P2B_HOST_FONT_METRICS_GATE=NOT_TESTED
P2B_HOST_SIMPLE_RASTER_GATE=NOT_TESTED
P2B_HOST_COMPLEX_LAYOUT_GATE=NOT_TESTED
P1A_GRAPHICS_PARENT_REGRESSION_FOR_P2B=NOT_TESTED
P2A_IMAGE_PARENT_REGRESSION_FOR_P2B=NOT_TESTED
P2B_MODULE_GATE=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
```

The candidate branch currently contains the pre-change scope/parent lock only. Do not describe P2B runtime as implemented or accepted yet.

---

## 6. P2B required execution order from here

On `module/p2b-font-text-candidate-r1`, parented from `5a8bfdf...`:

1. Implement the minimum owner-scoped Font/Text backend only.
2. Verify canonical/Miyoo delta and exact allowed-file scope.
3. Pass Java 6 compatibility/build gate.
4. Pass host metric differential gate.
5. Pass host simple raster differential gate.
6. Pass host complex-layout differential gate.
7. Run P1A graphics parent regression.
8. Run P2A image parent regression.
9. Pass one P2B module integration gate.
10. Only then build one original-RG35XX P2B physical module package.
11. Human operator runs/observes that package and returns evidence.
12. Only a successful scoped physical acceptance may move the accepted runtime lineage beyond P2A.

Required pre-physical state:

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

Until that state is true:

```text
P2B_DEVICE_PACKAGE=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
```

---

## 7. Historical diagnostics that must not become new parents

```text
A9=ARCHIVED_DIAGNOSTIC
RAW_DEFAULT_FREETYPE_AS_JDK8_DROPIN=REJECTED
PINNED_MIYOO_FREETYPE_2_11_1_AS_EXACT_JDK8_ENGINE=REJECTED
HARFBUZZ_DROPIN_COMPLEX_BACKEND=REJECTED
SYNTHETIC_5X7_FONT_AS_FINAL_P2B_BACKEND=REJECTED
```

Diagnostic branches and individual primitive/failure branches may contain useful evidence, but they are not production parents unless a locked rule/checkpoint explicitly promotes them.

---

## 8. New-chat anti-drift checklist

Before any runtime edit, verify:

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_PARENT_IDENTITY=5a8bfdf12d42e49d5d4aa8260601799c904e6441
HARDWARE_EVIDENCE=P1A_PASS_PLUS_P2A_PASS_ON_ORIGINAL_RG35XX
MISSING_CONTRACT=P2B_RAW2D_FONT_TEXT_BACKEND
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY_FONT_TEXT_BACKING
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

If a future chat sees a different branch/SHA, first establish whether it is a later formally accepted checkpoint. Do not silently assume that the most recent commit is accepted.

---

## 9. Human + ChatGPT collaboration log

This project is being completed by the repository owner/operator with **ChatGPT by OpenAI as an engineering assistant**.

ChatGPT assists with:

- source/branch/commit ancestry audits;
- Miyoo/FreeJ2ME/OpenJDK semantic tracing;
- failure-owner and minimum-delta classification;
- differential tests and module-gate design;
- evidence review;
- GitHub integration and documentation;
- maintaining this tasklog so a new conversation can resume without relying on chat memory.

The human operator:

- decides project direction and acceptance policy;
- owns the GitHub project and physical target;
- installs/runs physical packages on original RG35XX;
- reports physical screen/audio/input/exit observations;
- provides final human acceptance evidence where required.

ChatGPT analysis or CI output alone never substitutes for the original-RG35XX physical gate.

---

## 10. Definition of completion

The project is not complete at P2A or P2B. Platform completion requires the locked phase sequence through P8:

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
