# FreeJ2ME for Original RG35XX — Miyoo/Aweigit Platform Port

This repository ports the proven `aweigit/freej2me-miyoomini` FreeJ2ME implementation to the **original Anbernic RG35XX / GarlicOS-class environment** while preserving the accepted RG35XX hardware/runtime contracts and the pinned Miyoo/Aweigit J2ME behavior.

The project follows a strict **Miyoo-first, platform-first** reconstruction process:

```text
MIYOO BUILD FIRST
        ↓
FREEJ2ME / CANONICAL SOURCE FOR SEMANTIC REFERENCE
        ↓
RG35XX BOUNDARY ONLY WHERE REQUIRED
        ↓
MODULE DIFFERENTIAL / REGRESSION GATES
        ↓
ORIGINAL RG35XX PHYSICAL ACCEPTANCE
```

## Official repository baseline

As of **2026-10-03**, the official accepted runtime lineage in this repository is the physically accepted **P2A Image Decode** checkpoint:

```text
OFFICIAL_REPOSITORY_BASELINE=P2A_IMAGE_DECODE_ACCEPTED
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
P1A_GRAPHICS_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2A_IMAGE_DECODE_MODULE_PHYSICAL_ACCEPTANCE=PASS
CURRENT_PHASE=P2
CURRENT_MODULE=P2B_FONT_TEXT
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```

`main` is the official repository/tracking branch for accepted work. **Official does not mean full-platform stable.** The locked phase order requires P0–P7 to pass before P8 baseline promotion may set `RG35XX_PLATFORM_BASELINE_DEVICE_PASS=YES`.

The exact accepted P2A device record is in:

- `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`

The accepted P1A graphics record is in:

- `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`

## Current progress

| Phase / module | Status | Accepted scope / next requirement |
|---|---|---|
| P0 — Exact Golden authority | `PASS` | Accepted A8/Golden identities and physical evidence retained as authority. A9 is not a production parent. |
| P1 / P1A — Core 2D Graphics | `PASS` | Host/module gates and one original-RG35XX graphics module physical acceptance completed. |
| P2A — Image Decode | `PASS` | 150 fixtures × 3 public frontends = 450/450 device decode cases PASS; protected hashes preserved. |
| P2B — Font/Text | `NOT_TESTED` runtime | Audit/design prerequisites are closed; owner-scoped runtime candidate R1 is the next engineering unit. No P2B physical acceptance yet. |
| Remaining P2 frontend/input/resolution contract | `NOT_TESTED` | Must be completed at the appropriate module boundary after P2B. |
| P3 — Runtime service modules | `NOT_TESTED` | Platform-first module acceptance still required even though historical Golden behavior remains protected evidence. |
| P4 — Deferred capabilities | `NOT_TESTED` | M3G/Mascot/LWJGL/OpenGL require explicit capability decisions; no blind re-enable. |
| P5 — Generic installer/platform | `NOT_TESTED` | One generic FreeJ2ME-RG35XX installer/launcher, no game-name runtime logic. |
| P6 — Full platform exerciser | `NOT_TESTED` | Full declared platform contract suite. |
| P7 — Tier-0 physical regression | `NOT_TESTED` | Vua Cướp Biển + God of War, including protected audible GoW audio expectation. |
| P8 — Baseline promotion | `NOT_TESTED` | Only after P0–P7 pass. |
| P9 — Compatibility updates | `NOT_TESTED` | Not authorized before P8. |

For the exact handoff state and per-stage history, read **`TASKLOG.md` first**.

## Current P2B Font/Text work

P2B is currently beyond the initial audit stage but has **not** been accepted as runtime code.

Current trace points:

```text
P2B_AUDIT_BRANCH=audit/p2b-font-text-post-layout-r2
P2B_AUDIT_HEAD=8d3dc24f847380c699e18b6efd4bd9183884ac2c
P2B_CANDIDATE_BRANCH=module/p2b-font-text-candidate-r1
P2B_CANDIDATE_HEAD=3fad06899232b7307fc6249f1a4dfe35c830ec3b
P2B_CANDIDATE_PARENT=5a8bfdf12d42e49d5d4aa8260601799c904e6441
P2B_RUNTIME_CANDIDATE=NOT_TESTED
P2B_PHYSICAL_TEST=NOT_TESTED
```

Audit evidence has already established, for the declared scopes:

- exact JDK8u504-compatible ARM `charWidth` / `canDisplay` behavior for all 196,608 BMP code-unit cases;
- simple-string metric behavior;
- simple `drawString` source path and the existing 144-case raster corpus;
- JDK8 bundled LayoutEngine behavior for the existing 192-case non-simple corpus;
- the minimum RG35XX owner-scoped interface/file boundary;
- the exact MiSans runtime asset identity and an embedded-software provisioning contract with attribution/license requirements.

These audit results authorize the **next candidate engineering unit**; they do not constitute runtime/module/device acceptance.

## Accepted RG35XX runtime contracts

The port preserves the pinned Miyoo/Aweigit implementation and applies the smallest RG35XX boundary changes required by evidence. Protected or accepted owners include, within their tested scopes:

- canonical Aweigit J2ME source pin;
- protected JamVM/glibj runtime;
- original RG35XX SDL1/fbcon presentation path;
- accepted Raw2D/Core2D graphics behavior;
- input mapping/lifecycle boundary;
- PERF-A1 presenter behavior;
- PNG/alpha/drawRegion and P2A image-decode behavior;
- Java 6 media compatibility path;
- SDL1_mixer audio backend and accepted audio-route prime.

Protected runtime identities include:

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

Do not reopen a protected subsystem merely because a new game fails. Reproduce the failure, compare with the pinned Miyoo/canonical behavior, identify the RG35XX boundary owner, and apply only the smallest evidence-driven delta.

## Historical A8 / A9 interpretation

The earlier A8 runtime remains important **Golden authority and protected physical evidence**. It is not discarded.

However, the current project has moved to the locked platform-first reconstruction sequence. Therefore:

```text
A8_GOLDEN_EVIDENCE=PRESERVED
A9_PARENT=NO
GAME_SPECIFIC_PRODUCTION_PATCH=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

A9 experiments remain diagnostic/history only and must not become a new production parent.

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

## Collaboration with ChatGPT

This port is being completed by the repository owner/operator **in collaboration with ChatGPT by OpenAI as an engineering assistant**.

ChatGPT is used to help with:

- source and ancestry audits;
- canonical/Miyoo/OpenJDK contract tracing;
- differential-test and module-gate design;
- evidence review and failure-owner classification;
- GitHub integration/documentation;
- checkpoint and tasklog maintenance for continuity across chats.

The human operator remains the authority for project decisions and performs/confirms physical-device observations on the original RG35XX. ChatGPT assistance does **not** replace the required physical acceptance gates.

## New-chat handoff

Before continuing this project in a new chat:

1. Read `TASKLOG.md`.
2. Read `docs/ACCEPTED-BASELINE.md`.
3. Apply the four locked project rule documents supplied with the project.
4. Verify the exact accepted parent before changing runtime code.
5. Continue only the `NEXT_LEGAL_ACTION` recorded in `TASKLOG.md` unless the user explicitly changes the plan.
6. Never use A9 or a game-specific experimental branch as a production parent.

## Canonical source

```text
Repository: aweigit/freej2me-miyoomini
Pinned commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Role: CANONICAL_MIYOO_J2ME_IMPLEMENTATION
```

Do not automatically follow newer upstream commits without an explicit audit/migration decision.

## Status vocabulary

Project status records use the locked vocabulary:

`PASS`, `FAIL`, `PARTIAL`, `NOT_TESTED`, `NEEDS_REPRO`, `REJECTED`, `ARCHIVED_DIAGNOSTIC`.

Any use of “stable” or “device pass” must identify its exact scope.
