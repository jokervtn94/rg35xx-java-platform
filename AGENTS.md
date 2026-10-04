# Codex / Agent Bootstrap — RG35XX FreeJ2ME Port

This repository is a locked, evidence-driven port of the pinned Miyoo/Aweigit FreeJ2ME platform to the **original Anbernic RG35XX / GarlicOS**.

## Mandatory read order

Before editing code, changing status, selecting a parent commit, or proposing a next task, read these files in order:

1. `RG35XX-PORT-RULER-LOCKED-v1.md`
2. `RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md`
3. `RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md`
4. `RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md`
5. `CURRENT-CHECKPOINT.md`
6. `CHECK-TASK.md`
7. `MASTER-TASKLOG.md`
8. `docs/ACCEPTED-BASELINE.md`

`CURRENT-CHECKPOINT.md` is the authoritative current work position. `MASTER-TASKLOG.md` records chronology and phase state. Locked rule files override any stale branch, old build, historical task note, or newer-but-unaccepted artifact.

## Current truth — do not infer from newest commit

```text
OFFICIAL_BRANCH=main
OFFICIAL_ACCEPTED_RUNTIME_SCOPE=P2B_FONT_TEXT
OFFICIAL_ACCEPTED_RUNTIME_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830

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
```

**Important:** P2C has not been physically accepted and has not been promoted to `main`. R3 CI/package PASS does not make P2C an accepted runtime.

## Only legal next gate at this handoff

The exact P2C R3 physical package must be run on an **original RG35XX**, then its generated evidence must be reviewed.

```text
NEXT_LEGAL_ACTION=P2C_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST_AND_EVIDENCE_REVIEW
RAW_PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
ACTIONS_ARTIFACT_ID=11281889195
ACTIONS_ARTIFACT_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
EVIDENCE_DIR=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
```

Without physical evidence, do **not**:

- set `P2C_PHYSICAL_TEST=PASS`;
- promote P2C to `main`;
- start P3;
- run P7 game regression as a substitute for P2C module acceptance;
- perform Tier-1/game-specific fixes;
- use A9 or diagnostic branches as production parents.

## Status vocabulary

Use only:

```text
PASS
FAIL
PARTIAL
NOT_TESTED
NEEDS_REPRO
REJECTED
ARCHIVED_DIAGNOSTIC
```

A CI success is not a device pass. A package-ready checkpoint is not a physical acceptance.

## Canonical pin and protected baseline

```text
CANONICAL_AWEIGIT=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
P2B_ACCEPTED_INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

P2C deliberately changes the input owner after measured hardware evidence proved L2/R2 ownership; exact candidate identities are in `CURRENT-CHECKPOINT.md`.

## Rule-file integrity at this handoff

```text
RG35XX-PORT-RULER-LOCKED-v1.md=ffaf5d9e05be92ad41ad0acdfdf188f0495bbd999a34b3b16b27206802ec4b8c
RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md=8135dfb11f87ebecb7ddde86a53c40908604e86541463c740246f558f5450477
RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md=c42f852ebab78781c5e1084e2b194f20ff1a578a7b683ed98d627d83245e5bcb
RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md=1b77ee21e7023c62d7b265a66ae83973cee14b5c4dd072bbcdf59b360aca5aa2
```

If repository evidence conflicts with a locked rule, stop and classify the conflict before modifying runtime code.
