# FreeJ2ME for Original RG35XX — Miyoo/Aweigit Platform Port

This repository ports the proven `aweigit/freej2me-miyoomini` FreeJ2ME implementation to the **original Anbernic RG35XX / GarlicOS-class environment** while preserving accepted RG35XX hardware/runtime contracts and pinned Miyoo/Aweigit J2ME behavior.

The project follows a strict **Miyoo-first, platform-first** reconstruction process:

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

## Official repository baseline

As of **2026-10-04**, P2C Input/Frontend has passed its original-RG35XX physical module gate. The official `main` promotion remains separate from this physical-test branch.

```text
OFFICIAL_REPOSITORY_BRANCH=main
OFFICIAL_MAIN_PROMOTION_MERGE=3087b9ca28d4fddd70406b7058abaeb708419215
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
P2B_ACCEPTED_BRANCH_HEAD=6cc7461897dedeafa3d71848854341d41c533b5d
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
CURRENT_PHASE=P4
CURRENT_MODULE=P4_3D_CAPABILITY_DECISION
CURRENT_PHYSICAL_ACCEPTED_SCOPE=P2C_INPUT_FRONTEND
CURRENT_PHYSICAL_ACCEPTED_BRANCH_HEAD=8cd4f6b
P2=PASS
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

`main` is the official repository/tracking branch for accepted work. **Official does not mean full-platform stable.** The locked phase order requires P0–P7 to pass before P8 may set `RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES`.

Accepted physical records:

- `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`
- `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`
- `docs/P2B-FONT-TEXT-PHYSICAL-ACCEPTANCE-20261003.md`
- `docs/P2B-WINDOWS-INSTALLER-R2-HYGIENE-CHECKPOINT-20261003.md`
- `docs/P2C-INPUT-FRONTEND-PHYSICAL-ACCEPTANCE-20261004.md`
- `docs/P3-RUNTIME-SERVICE-MODULE-AUDIT-20261004.md`

## Current progress

| Phase / module | Status | Accepted scope / next requirement |
|---|---|---|
| P0 — Exact Golden authority | `PASS` | Accepted A8/Golden identities and physical evidence retained as authority. A9 is not a production parent. |
| P1 / P1A — Core 2D Graphics | `PASS` | Host/module gates and original-RG35XX graphics physical acceptance completed. |
| P2A — Image Decode | `PASS` | 150 fixtures × 3 public frontends = 450/450 device decode cases PASS; protected hashes preserved. |
| P2B — Font/Text | `PASS` | Host/module gates PASS; original RG35XX 360/360 cases PASS, protected hashes PASS, green PASS screen, normal GarlicOS return. |
| P2C — Input / Frontend contract | `PASS` | Original RG35XX programmatic run passed all three phases, including custom keymap, pointer 6,6 and rotation 1→2→0. |
| P3 — Runtime service modules | `PASS (scoped)` | Original RG35XX passed lifecycle, RMS, FileConnection, WAV/MIDI API paths, audible output, shutdown and protected hashes. |
| P4 — Deferred capabilities | `NOT_TESTED` | Next: read-only EGL/GLES hardware probe and source-call mapping; no blind M3G/Mascot/LWJGL/OpenGL re-enable. |
| P5 — Generic installer/platform | `NOT_TESTED` | One generic FreeJ2ME-RG35XX installer/launcher, no game-name runtime logic. |
| P6 — Full platform exerciser | `NOT_TESTED` | Full declared platform contract suite. |
| P7 — Tier-0 physical regression | `NOT_TESTED` | Vua Cướp Biển + God of War, including protected audible GoW audio expectation. |
| P8 — Baseline promotion | `NOT_TESTED` | Only after P0–P7 pass. |
| P9 — Compatibility updates | `NOT_TESTED` | Not authorized before P8. |

For exact handoff state and per-stage history, read **`TASKLOG.md` first**.

## P2B Font/Text accepted scope

P2B replaced only the unavailable provisional RG35XX Raw2D font/text backing while retaining canonical Miyoo/MIDP ownership.

Key accepted identities:

```text
P2B_RUNTIME_CANDIDATE=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_FONT_SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
P2B_FONT_SIZE=8092724
P2B_DEVICE_CASES=360
P2B_DEVICE_FAILURES=0
P2B_PHYSICAL_TEST=PASS
P2B_NORMAL_EXIT=PASS
```

The Windows installer R2 hygiene revision is packaging-only. CI independently proved the full `SD/` tree byte-identical to the physically accepted R1 package:

```text
P2B_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE
P2B_R2_RUNTIME_SEMANTIC_DELTA=NONE
P2B_R2_PACKAGE_SHA256=7df059c07a3867eef5e6a00348b19b18ee6901cffd4bf7b53caefbbebb34de38
```

No second physical run is required for that helper-only revision because the tested SD runtime payload is unchanged byte-for-byte.

## Next legal work unit — P4 EGL/GLES capability decision

P3 is now physically accepted as a scoped runtime-service module without changing the accepted input/frontend owner. The next module is **P4 EGL/GLES CAPABILITY DECISION**:

- inventory actual EGL/GLES libraries, symbols and device providers on original RG35XX/GarlicOS;
- map the canonical Aweigit M3G/MascotCapsule/LWJGL native call surface to those measured providers;
- record a capability decision before any 3D source is staged or re-enabled.

The P3 source audit, CI build and original-RG35XX physical run are complete. The P3 package used the accepted P2C payload plus an RG35XXLauncher-only audio-loader overlay; the candidate JamVM/glibj runtime and accepted input/video/font/audio native owners remain protected. No 3D implementation is authorized yet.

The P3 audit and physical acceptance are recorded in
`docs/P3-RUNTIME-SERVICE-MODULE-AUDIT-20261004.md`. The next evidence package
must be a read-only P4 hardware capability probe; it must not modify the
production runtime or re-enable deferred 3D classes.

The latest CI package is available from GitHub Actions Run #3:

```text
RUN=https://github.com/jokervtn94/rg35xx-java-platform/actions/runs/37211752518
ARTIFACT=RG35XX-P3-RUNTIME-SERVICE-EXERCISER-4fe82701dc98f29b96585e85deb146093ac14cc3
P3_PLATFORM_SHA256=a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00
P3_PHYSICAL_TEST=PASS
P3_AUDIO_AUDIBLE_DEVICE=CONFIRMED_BY_USER
P3_DEVICE_PROGRAMMATIC_RESULT=PASS
```

## Protected RG35XX runtime identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

Do not reopen a protected subsystem merely because a new game fails. Reproduce the failure, compare with pinned Miyoo/canonical behavior, identify the RG35XX boundary owner, and apply only the smallest evidence-driven delta.

## Historical A8 / A9 interpretation

```text
A8_GOLDEN_EVIDENCE=PRESERVED
A9_PARENT=NO
GAME_SPECIFIC_PRODUCTION_PATCH=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

A9 experiments remain diagnostic/history only and must not become a production parent.

## Development and acceptance rules

A successful build or CI run is not a device pass. Physical claims require evidence from an **original RG35XX** at the defined module/platform gate.

Required workflow:

```text
pinned Miyoo behavior
-> canonical/JDK semantic reference where required
-> original RG35XX hardware contract
-> exact missing contract / failure owner
-> smallest owner-scoped adapter delta
-> host differential + parent regression
-> one module integration gate
-> original-RG35XX physical module acceptance
-> later full-platform promotion only after P0-P7
```

Commercial game JARs remain external test inputs and are never bundled into production runtime logic or used as game-name-specific switches.

## Canonical source

```text
Repository: aweigit/freej2me-miyoomini
Pinned commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Role: CANONICAL_MIYOO_J2ME_IMPLEMENTATION
```

Do not automatically follow newer upstream commits without an explicit audit/migration decision.

## Status vocabulary

`PASS`, `FAIL`, `PARTIAL`, `NOT_TESTED`, `NEEDS_REPRO`, `REJECTED`, `ARCHIVED_DIAGNOSTIC`.

Any use of “stable” or “device pass” must identify its exact scope.
