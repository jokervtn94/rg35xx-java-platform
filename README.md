# FreeJ2ME for Original RG35XX — Miyoo/Aweigit Platform Port

This repository ports the pinned Miyoo/Aweigit FreeJ2ME implementation to the **original Anbernic RG35XX / GarlicOS** using the smallest evidence-driven RG35XX boundary adaptations possible.

## Codex / new-agent entrypoint

If you opened this repository from a link and need to continue the current work, start here:

1. [`CODEX-START-HERE.md`](CODEX-START-HERE.md)
2. [`AGENTS.md`](AGENTS.md)
3. [`CURRENT-CHECKPOINT.md`](CURRENT-CHECKPOINT.md)
4. [`CHECK-TASK.md`](CHECK-TASK.md)
5. [`MASTER-TASKLOG.md`](MASTER-TASKLOG.md)

Do not infer accepted runtime state from the newest SHA or newest branch.

## Locked engineering authority

Read and obey all four:

- [`RG35XX-PORT-RULER-LOCKED-v1.md`](RG35XX-PORT-RULER-LOCKED-v1.md)
- [`RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md`](RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md)
- [`RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md`](RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md)
- [`RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md`](RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md)

Permanent direction:

```text
MIYOO BUILD FIRST
        ↓
FREEJ2ME / CANONICAL SOURCE FOR SEMANTIC REFERENCE
        ↓
RG35XX BOUNDARY ONLY WHERE REQUIRED
        ↓
HOST DIFFERENTIAL / MODULE GATE
        ↓
ORIGINAL RG35XX PHYSICAL ACCEPTANCE
        ↓
PLATFORM FIRST — GAME COMPATIBILITY LAST
```

## Official accepted baseline vs active work

The latest **physically accepted official runtime** remains P2B Font/Text:

```text
OFFICIAL_BRANCH=main
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2B_PHYSICAL_ACCEPTANCE_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
```

The active work is P2C Input/Frontend, which is **not yet physically accepted**:

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
P2=PARTIAL

P2C_RUNTIME_CANDIDATE_COMMIT=0738281012b83d748cfb88ba063d21248a3f9c97
P2C_HOST_MODULE_GATE=PASS
P2C_PHYSICAL_PACKAGE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED

P2C_PHYSICAL_BRANCH=physical-test/p2c-input-frontend-20261003-r3
P2C_PHYSICAL_R3_SOURCE_HEAD=ceca509b39f95f2d172c4b20119ab644522be55b
P2C_READY_DOC_COMMIT=286e4ebbea850a56db27165aec3e40d1ddf97380

RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

## Current legal next action

```text
NEXT_LEGAL_ACTION=P2C_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST_AND_EVIDENCE_REVIEW
```

Exact physical package waiting for test:

```text
ACTIONS_ARTIFACT_ID=11281889195
ACTIONS_ARTIFACT_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
RAW_PACKAGE_FILENAME=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
EVIDENCE_DIR=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
```

Detailed checkpoints:

- [`docs/P2C-INPUT-FRONTEND-HOST-MODULE-CHECKPOINT-20261003.md`](docs/P2C-INPUT-FRONTEND-HOST-MODULE-CHECKPOINT-20261003.md)
- [`docs/P2C-INPUT-FRONTEND-PHYSICAL-R3-READY-20261004.md`](docs/P2C-INPUT-FRONTEND-PHYSICAL-R3-READY-20261004.md)

CI/package PASS is not device acceptance. P2C may only become physically accepted after exact device evidence is reviewed and the operator independently confirms visible rotation `0 -> 1 -> 2 -> 0` and normal return to GarlicOS.

## Phase ledger

| Phase / module | Status | Current meaning |
|---|---|---|
| P0 — Exact Golden authority | `PASS` | Golden/protected evidence retained. |
| P1 / P1A — Core 2D Graphics | `PASS` | Original-RG35XX module acceptance completed. |
| P2A — Image Decode | `PASS` | 450/450 physical cases PASS. |
| P2B — Font/Text | `PASS` | 360/360 physical cases PASS; normal GarlicOS return. |
| P2C — Input/Frontend | `PARTIAL` | Host/module PASS + physical package PASS; device physical gate `NOT_TESTED`. |
| P3 — Runtime services | `NOT_TESTED` | Do not begin until P2 closes. |
| P4 — Deferred capabilities | `NOT_TESTED` | Explicit capability decisions required. |
| P5 — Generic installer/platform | `NOT_TESTED` | Generic, no game-specific production logic. |
| P6 — Full platform exerciser | `NOT_TESTED` | Full declared platform contract. |
| P7 — Tier-0 regression | `NOT_TESTED` | Vua Cướp Biển + God of War including audible GoW audio. |
| P8 — Baseline promotion | `NOT_TESTED` | Only after P0–P7 PASS. |
| P9 — Compatibility updates | `NOT_TESTED` | Forbidden before P8. |

## Accepted physical records

- `docs/P1A-GRAPHICS-PHYSICAL-ACCEPTANCE-20261002.md`
- `docs/P2A-IMAGE-DECODE-PHYSICAL-ACCEPTANCE-20261003.md`
- `docs/P2B-FONT-TEXT-PHYSICAL-ACCEPTANCE-20261003.md`
- `docs/P2B-WINDOWS-INSTALLER-R2-HYGIENE-CHECKPOINT-20261003.md`
- `docs/ACCEPTED-BASELINE.md`

## Protected baseline identities

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
P2B_ACCEPTED_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

P2C intentionally has a candidate input-native delta after measured original-RG35XX L2/R2 evidence; that candidate hash must not be retroactively described as the accepted P2B input identity until P2C physical acceptance.

## Hard stops

Until the current P2C physical gate closes:

- no P2C promotion to accepted runtime;
- no P3 start;
- no P7 game regression as a substitute for module acceptance;
- no P9/Tier-1 compatibility work;
- no game-name-specific production logic;
- no A9/diagnostic parent;
- no physical PASS claim from CI alone;
- no `STABLE=YES` before P8.

Status vocabulary is limited to `PASS`, `FAIL`, `PARTIAL`, `NOT_TESTED`, `NEEDS_REPRO`, `REJECTED`, `ARCHIVED_DIAGNOSTIC`.
