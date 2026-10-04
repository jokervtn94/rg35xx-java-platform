# Check Task — Anti-Drift Checklist for Codex / Agents

Last updated: **2026-10-04**

Use this checklist before continuing this project from a fresh session.

## A. Bootstrap check

- [ ] Read `AGENTS.md`.
- [ ] Read all four locked rule / reconstruction-map files.
- [ ] Read `CURRENT-CHECKPOINT.md`.
- [ ] Read `MASTER-TASKLOG.md`.
- [ ] Read `docs/ACCEPTED-BASELINE.md`.
- [ ] Confirm canonical pin is `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`.
- [ ] Confirm `A9_PARENT=NO`.
- [ ] Confirm `GAME_SPECIFIC_CODE=NO`.
- [ ] Confirm status vocabulary is limited to `PASS/FAIL/PARTIAL/NOT_TESTED/NEEDS_REPRO/REJECTED/ARCHIVED_DIAGNOSTIC`.

## B. Distinguish the four important identities

Do not mix these:

```text
1. OFFICIAL_ACCEPTED_RUNTIME
   main accepted through P2B
   runtime commit = 2f18b78e9b0aa1660b7fd2f5904dd697fcef5830

2. P2C_RUNTIME_CANDIDATE
   candidate commit = 0738281012b83d748cfb88ba063d21248a3f9c97
   host/module gate = PASS
   NOT accepted on device yet

3. P2C_PHYSICAL_PACKAGE_SOURCE
   commit = ceca509b39f95f2d172c4b20119ab644522be55b
   branch = physical-test/p2c-input-frontend-20261003-r3
   package gate = PASS

4. P2C_READY_DOC_CHECKPOINT
   commit = 286e4ebbea850a56db27165aec3e40d1ddf97380
   docs-only child of physical source head
   no runtime delta
```

- [ ] Never call item 2, 3, or 4 an accepted official runtime before physical P2C evidence is reviewed.
- [ ] Never choose the newest SHA merely because it is newer.

## C. Verify current P2C package before any device conclusion

```text
ACTIONS_ARTIFACT_ID=11281889195
ACTIONS_ARTIFACT_SHA256=f6215e37a3c07bf218f7b3db1243f14ae37fb5146d860e2b6c9b675b238689df
RAW_PACKAGE=RG35XX-P2C-INPUT-FRONTEND-PHYSICAL-R1.zip
RAW_PACKAGE_SHA256=014c7f7b96f24aae62610fec7b1157c23a2c844777fb5b70b9b524a818962e36
```

- [ ] Do not accept evidence from an unverified package build.
- [ ] Do not replace the package with a freshly rebuilt "equivalent" package and call it the same physical identity.

## D. Current task gate

Current task is **not implementation**. It is:

```text
P2C_ORIGINAL_RG35XX_PHYSICAL_MODULE_TEST_AND_EVIDENCE_REVIEW
```

If device evidence has not been supplied:

- [ ] Keep `P2C_PHYSICAL_TEST=NOT_TESTED`.
- [ ] Keep `P2=PARTIAL`.
- [ ] Keep `DEVICE_PASS=NO`.
- [ ] Keep `RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO`.
- [ ] Keep `STABLE=NO`.
- [ ] Do not promote P2C to `main`.
- [ ] Do not begin P3.
- [ ] Do not begin P7 game regression.
- [ ] Do not begin Tier-1/P9 compatibility work.

## E. If P2C device evidence is supplied

First verify evidence came from:

```text
/mnt/mmc/RG35XX-P2C-INPUT-FRONTEND-EVIDENCE
```

Review at minimum:

```text
P2C-INPUT-FRONTEND-RUN.log
P2C-INPUT-FRONTEND-DEVICE-SUMMARY.txt
PHASE1.log
PHASE2.log
PHASE3.log
MANUAL-OBSERVATION.txt
P2C-INPUT-FRONTEND-IDENTITY.txt
P2C-INPUT-FRONTEND-EXERCISER-IDENTITY.txt
PHYSICAL-PACKAGE-IDENTITY.txt
PAYLOAD-SHA256SUMS.txt
```

Require programmatic markers:

- [ ] `P2C_PHASE1_EXIT_CODE=0`
- [ ] `P2C_PHASE2_EXIT_CODE=0`
- [ ] `P2C_PHASE3_EXIT_CODE=0`
- [ ] each phase has its required PASS markers
- [ ] pointer event at `6,6` is PASS
- [ ] protected before/after hashes are preserved
- [ ] `P2C_PROTECTED_HASHES=PASS`
- [ ] `P2C_DEVICE_PROGRAMMATIC_RESULT=PASS`

Require human observation from the original RG35XX operator:

- [ ] visible rotation sequence `0 -> 1 -> 2 -> 0` = PASS
- [ ] normal return to GarlicOS after phase 3 = PASS

Do not infer either human observation from a process exit code.

## F. Only after all P2C physical requirements pass

Then and only then:

- [ ] create a dedicated P2C physical-acceptance branch/record;
- [ ] record exact physical source head `ceca509b...`, runtime candidate `07382810...`, package SHA, evidence archive SHA, and human observations;
- [ ] keep `RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO` and `STABLE=NO` because P3-P7 remain incomplete;
- [ ] promote the accepted P2C lineage to `main` only through an auditable merge/PR or other user-approved accepted-history mechanism;
- [ ] update `CURRENT-CHECKPOINT.md`, `MASTER-TASKLOG.md`, `TASKLOG.md`, and README in the same docs handoff cycle.

## G. Required pre-change checklist for future runtime edits

Before any later runtime code change, fill and verify:

```text
CURRENT_PHASE=
CURRENT_MODULE=
CANONICAL_SOURCE=
EXACT_PARENT_IDENTITY=
HARDWARE_EVIDENCE=
MISSING_CONTRACT=
OWNER=
FILES_ALLOWED_TO_CHANGE=
FILES_FORBIDDEN_TO_CHANGE=
HOST_GATE=
PHYSICAL_GATE=
GENERIC_PLATFORM_IMPACT=
```

If any item is unresolved, do not write the runtime patch.

## H. Hard stops

- [ ] No A9 parent.
- [ ] No game-name-specific production logic.
- [ ] No new Tier-1 fixes before P8.
- [ ] No physical PASS claim from CI alone.
- [ ] No `stable` claim before P8.
- [ ] No silent replacement of protected identities.
- [ ] No method-by-method device-test loop when the rule requires module-level acceptance.
