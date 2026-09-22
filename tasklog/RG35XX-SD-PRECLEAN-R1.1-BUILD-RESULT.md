# RG35XX-SD-PRECLEAN-R1.1 — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`
Source commit: `20b0b82e45b507a764d06d956e6bf83b1277cd70`

## Incident fixed

Original R1 cleaner failed during rollback when restoring a root-level file because it attempted:

```
New-Item -ItemType Directory -Force -Path H:\
```

through `Split-Path -Parent`.

R1.1 replaces direct parent creation with `Ensure-ParentDirectory()`, which:
- returns if parent is empty;
- returns if parent already exists, including drive root;
- creates only genuinely missing directories.

Rollback now:
- preserves original clean exception;
- validates restored SHA256;
- reports rollback errors without masking root cause.

R1.1 also recognizes previous incomplete quarantine folders and safely continues from the current active SD state.

If previous R1 already isolated all old files, CLEAN mode now explicitly reports:
- `ACTIVE_OLD_PLATFORM_SCAN=ZERO`
- `READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES`

without reactivating old files.

## CI

- Workflow: `RG35XX SD Preclean R1.1 Tool`
- Run: `35682648075`
- Job: `106602712473`
- Result: **SUCCESS**
- Windows PowerShell parse: PASS
- `SELFTEST_ROOT_PARENT=PASS`
- `SELFTEST_NESTED_PARENT=PASS`
- Static safety gate: PASS
- Artifact ID: `10675471054`
- Artifact name: `rg35xx-sd-preclean-r1-1`
- Artifact / downloaded ZIP SHA256:
  `6adadb93812ad0c4f275022557da5ea34e2a88bb7ebdc84e47d436caa46adfa3`
- Internal SHA256SUMS verification: PASS

## Classification

- original SD Preclean R1: **SUPERSEDED / DO NOT USE**
- SD Preclean R1.1: **TOOL-BUILD-PASS**
- real SD cleanup: pending user rerun
- R1 platform install: blocked until cleaner reports `READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES`
- STABLE: NO
