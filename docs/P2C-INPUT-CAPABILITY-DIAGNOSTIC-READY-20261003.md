# P2C Input Capability Diagnostic Ready — 2026-10-03

## Classification

This checkpoint records a **diagnostic-only** original-RG35XX hardware capability package. It is not a P2C runtime candidate, not a P2C physical acceptance result, and does not authorize any production runtime change.

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
AUDIT_STATUS=PARTIAL
P2C_DIAGNOSTIC_PACKAGE_GATE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
RUNTIME_PATCH=FORBIDDEN
RUNTIME_SEMANTIC_DELTA=NONE
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

## Exact lineage

```text
CANONICAL_SOURCE=aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_PARENT_IDENTITY=aa7f84dac5ff24b5fd30fc6158ca3be0327675a0
P2B_ACCEPTED_RUNTIME=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
P2C_DIAGNOSTIC_BRANCH=audit/p2c-input-frontend-contract-20261003
P2C_DIAGNOSTIC_SOURCE_HEAD=8cb9a194500a075e8188e2941353d6d63b5b488a
HISTORICAL_DEVICE_PASS_SOURCE_COMMIT=faa49f9b941db5394265d9b13413e4576ef4694f
HISTORICAL_M1_3C_SOURCE_BLOB=4e6d42f499f85db242fd0f8db09d97077c48aa33
```

The diagnostic build materializes the exact historical M1.3C source from Git history and fails closed unless the resolved blob equals the locked blob above. The only derived semantic change is the calibration inventory: historical 12-control calibration becomes a 14-control diagnostic so L1/L2/R1/R2 are measured instead of inferred.

## CI result

```text
WORKFLOW=P2C Original RG35XX Input Capability Diagnostic
WORKFLOW_RUN=37137415150
WORKFLOW_JOB=111244650846
WORKFLOW_HEAD=8cb9a194500a075e8188e2941353d6d63b5b488a
WORKFLOW_RESULT=PASS
P2C_DIAGNOSTIC_SCOPE=PASS
P2C_DIAGNOSTIC_BUILD=PASS
P2C_DIAGNOSTIC_PACKAGE_GATE=PASS
RUNTIME_SEMANTIC_DELTA=NONE
P2C_PHYSICAL_TEST=NOT_TESTED
```

CI passed:

- audit-only changed-file scope gate;
- exact audit-state gate;
- pinned ARMv5TE / ARM926EJ-S / soft-float uClibC toolchain;
- exact historical M1.3C blob gate;
- derived 14-control compile;
- ARM ELF32 / EABI5 / soft-float / `/lib/ld-uClibc.so.0` gate;
- diagnostic isolation gate;
- flat GarlicOS Apps package gate;
- artifact upload.

## Exact build hashes

```text
M1_3C_MATERIALIZED_SOURCE_SHA256=2b608fb21c826f30cf88c015b6e6c63441718a20844d6171ee503fb8e8700e59
P2C_DERIVED_SOURCE_SHA256=55f448c88e8fd9b123575ac2b4456abea7aacf974699f52b15265c35b4ee2c3d
P2C_PROBE_SHA256=b37a0e79f58795e90e75261c161697c9e150f6a59bba0f3ffa861d56404f3bf1
P2C_WRAPPER_SHA256=e79390bb407f3b48353387e51d88c8b904a05ac585f50c082dc25da83f8aa463
P2C_README_SHA256=c1642bd43366fc08ae5a232fed15d7d2fd75b0e10620c4bb74988d45b9624410
P2C_TAR_GZ_SHA256=81bc34e41a766f3d2125edc637206988717e81601d025c45dbb2be1ac6824511
```

## GitHub Actions artifact

```text
ARTIFACT_NAME=RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC
ARTIFACT_ID=11279100414
ARTIFACT_SIZE_BYTES=15556
ARTIFACT_ZIP_SHA256=6f282f2d9b9360cae3dac9e822437e1e3d5333e0fa1e01ac302f9d657bd0f314
ARTIFACT_EXPIRES_AT=2027-01-01T16:35:31Z
ARTIFACT_DOWNLOAD=https://github.com/jokervtn94/rg35xx-java-platform/actions/runs/37137415150/artifacts/11279100414
```

The artifact contains five uploaded files including the flat `Roms/APPS` diagnostic layout and `RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC.tar.gz`.

## Original RG35XX procedure

1. Download artifact `RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC` from workflow run `37137415150`.
2. Copy the artifact `Roms/APPS` contents into the matching `Roms/APPS` directory on the GarlicOS SD card.
3. Launch `P2C-INPUT-CAPABILITY-DIAGNOSTIC.sh` from Apps.
4. Follow only the control name displayed on LCD and wait for `CONFIRMED` before the next control.
5. Use this exact order:

```text
UP DOWN LEFT RIGHT A B X Y START SELECT L1 L2 R1 R2
```

Text-safe LCD labels are:

```text
LONE=L1
LTWO=L2
RONE=R1
RTWO=R2
```

6. On complete calibration the probe displays `DONE` and exits normally.
7. Return the exact report:

```text
/mnt/mmc/RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC-RESULT.txt
```

## Evidence interpretation

A successful diagnostic may close only the exact hardware identity/capability question for L2/R2 and the complete 14-control inventory. It must not be recorded as `P2C_PHYSICAL_TEST=PASS`.

After the exact report is reviewed, the next legal step is to fill the P2C pre-change owner/gap fields and define the minimum owner-scoped runtime candidate. Only after host/module gates pass may an INPUT-FRONTEND-MODULE physical acceptance package be created.

```text
NEXT_LEGAL_ACTION=RUN_DIAGNOSTIC_ON_ORIGINAL_RG35XX_AND_RETURN_EXACT_REPORT
P2=PARTIAL
P2C_PHYSICAL_TEST=NOT_TESTED
RUNTIME_SEMANTIC_DELTA=NONE
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```
