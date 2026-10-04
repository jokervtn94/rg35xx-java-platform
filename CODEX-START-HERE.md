# CODEX START HERE — RG35XX FreeJ2ME Port

Use this file when opening the repository from a fresh Codex/agent session.

## 1. Read order

Read these files before doing anything else:

1. `AGENTS.md`
2. `RG35XX-PORT-RULER-LOCKED-v1.md`
3. `RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md`
4. `RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md`
5. `RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md`
6. `CURRENT-CHECKPOINT.md`
7. `CHECK-TASK.md`
8. `MASTER-TASKLOG.md`
9. `docs/ACCEPTED-BASELINE.md`
10. `docs/P2C-INPUT-FRONTEND-HOST-MODULE-CHECKPOINT-20261003.md`
11. `docs/P2C-INPUT-FRONTEND-PHYSICAL-R3-READY-20261004.md`

## 2. Current truth

```text
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
P2C_PHYSICAL_SOURCE_HEAD=ceca509b39f95f2d172c4b20119ab644522be55b
P2C_READY_DOC_CHECKPOINT=286e4ebbea850a56db27165aec3e40d1ddf97380

NEXT_LEGAL_ACTION=P2C_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST_AND_EVIDENCE_REVIEW
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
NEW_TIER1_FIX_BEFORE_P8=NO
```

## 3. Do not mix build identities

There are four different identities with different meanings:

1. **Official accepted runtime** — P2B runtime commit `2f18b78e...`.
2. **P2C runtime candidate** — `07382810...`; host/module PASS, not device accepted.
3. **P2C physical package source** — `ceca509b...`; package/exerciser CI PASS, not device accepted.
4. **P2C READY docs checkpoint** — `286e4ebb...`; documentation-only child, no runtime delta.

Never select a production parent just because its SHA is newer.

## 4. Exact physical package waiting for test

```text
ACTIONS_ARTIFACT_ID=11281889195
ACTIONS_ARTIFACT_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
RAW_PACKAGE_FILENAME=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
EVIDENCE_DIR=/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
```

Physical acceptance requires programmatic evidence plus human observation of visible rotation `0 -> 1 -> 2 -> 0` and normal return to GarlicOS.

## 5. Hard stop

Until exact P2C physical evidence is reviewed:

- do not set `P2C_PHYSICAL_TEST=PASS`;
- do not promote P2C to accepted `main` runtime;
- do not begin P3;
- do not begin P7 as a substitute for P2C module acceptance;
- do not begin P9/Tier-1 compatibility work;
- do not add game-specific production logic;
- do not use A9 or diagnostic branches as production parents.

If the user says **"tiếp tục"**, continue only the `NEXT_LEGAL_ACTION` from `CURRENT-CHECKPOINT.md`.
