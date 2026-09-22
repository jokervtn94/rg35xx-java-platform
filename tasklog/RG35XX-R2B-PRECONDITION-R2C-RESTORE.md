# R2B Audio — Device Precondition Failure on R2C-FONT

Date: 2026-09-22

## Observed failure

R2B installer correctly refused to install because the first runtime alias was still the R2C-FONT runtime:

- expected exact R2A: `5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`
- actual R2C-FONT: `0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34`

This is a **fail-closed precondition PASS**, not an R2B runtime/device failure.

## Classification

- CURRENT_SYMPTOM: R2B installer blocked before write.
- HISTORY_FOUND: independent R2A-based A/B checkpoints require restoring exact R2A between tests.
- PREVIOUS_FIX: R2C installer created an exact R2A backup and ships a restore script.
- PREVIOUS_EVIDENCE_LEVEL: R2A = DEVICE-EVIDENCE; R2C-FONT = DEVICE-EVIDENCE for text crash removal; R2B = BUILD-PASS only.
- REGRESSION_RISK: installing R2B on top of R2C would combine Font + Audio and invalidate the A/B test.
- MINIMAL_PROPOSED_CHANGE: baseline recovery only, R2C -> exact R2A; preserve JamVM/glibj/B4 core.
- EXPECTED_DEVICE_TEST: after exact R2A verification, run R2B precheck and only then install/test audio.

## Recovery artifact

A self-contained recovery kit was generated from the exact R2A GitHub Actions artifact:

- R2A artifact ID: `10676954350`
- R2A artifact SHA256: `10bebb7095d04ec6d3b0e16381f87ec9d7a1ecb79c796344a500d02b2087200e`
- exact R2A payload SHA256: `5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`
- recovery ZIP SHA256: `d9b3377a51e4b5472f60a99ce4bf5ad1d2270e6b0d5863f7f521e7dba64da4e8`

The recovery kit accepts only exact R2C-FONT on all five runtime aliases, checks protected JamVM/glibj/B4 core, creates a backup, replaces only the five runtime aliases with exact R2A, and verifies each write.

## Device recovery evidence

The user ran the recovery verification on the real SD and all five runtime aliases matched the exact R2A SHA256:

- `BIOS\freej2me-lr.jar` = `5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`
- `BIOS\freej2me_plus-lr.jar` = same exact R2A SHA
- `CFW\java\share\freej2me\freej2me-lr.jar` = same exact R2A SHA
- `CFW\retroarch\.retroarch\system\freej2me-lr.jar` = same exact R2A SHA
- `CFW\retroarch\system\freej2me-lr.jar` = same exact R2A SHA

Verifier result:
`R2A_EXACT=YES`

Classification:
- BASELINE_RECOVERY=DEVICE-EVIDENCE
- EXACT_R2A_RUNTIME_ALIASES=PASS
- R2B_PRECHECK=NEXT
- R2B_DEVICE_PASS=NO
- STABLE=NO

## Status

- R2B INSTALL ATTEMPT: FAIL-CLOSED BEFORE WRITE
- DEVICE STATE AFTER RECOVERY: exact R2A runtime restored and verified
- R2B BUILD-PASS: YES
- R2B DEVICE-TEST-PENDING: YES
- R2B DEVICE-PASS: NO
- STABLE: NO
