# RG35XX-SD-PRECLEAN-R1 — Full-SD old platform cleanup

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r1`
Purpose: prepare the real RG35XX SD card before installing Clean Consolidated R1.
Status: TOOL / NO DEVICE ACTION YET / STABLE=NO

## Goal

Scan the entire selected RG35XX SD root and remove old/stray Java platform files from active paths before the new R1 runtime is installed.

"Remove" means:
- move active old platform files into a rollback quarantine under `RG35XX-JAVA-PRECLEAN`;
- verify each moved file by SHA256;
- rescan the entire SD and require zero remaining known old/stray active platform files;
- preserve a manifest and a restore tool.

This deliberately does **not** permanently erase the quarantine. Old files inside the quarantine/backups cannot participate in runtime lookup and therefore cannot conflict with the new platform. Permanent purge should only happen after R1 passes device testing.

## Protected foundation — never delete

The tool fails before mutation unless these exact production components exist:

- JamVM L:
  `CFW\java\bin\jamvm`
  SHA256 `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

- GNU Classpath:
  `CFW\java\share\classpath\glibj.zip`
  SHA256 `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

- protected B4 native core:
  `CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so`
  SHA256 `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`

## User data — never delete

Entire trees excluded from cleanup:
- `Roms\JAVA\` — real game JARs;
- `Saves\` — RMS/save data;
- `RG35XX-JAVA-BACKUP\` — historical rollback backups;
- `RG35XX-JAVA-PRECLEAN\` — this tool's own reports/quarantine;
- the tool's own directory if it is copied onto the SD.

## Active files removed

The scanner targets:

1. Known runtime aliases:
   - `BIOS\freej2me-lr.jar`
   - `BIOS\freej2me_plus-lr.jar`
   - `BIOS\freej2me_plus_lr.jar`
   - `CFW\java\share\freej2me\freej2me-lr.jar`
   - `CFW\java\share\freej2me\freej2me_plus-lr.jar`
   - `CFW\retroarch\.retroarch\system\freej2me-lr.jar`
   - `CFW\retroarch\.retroarch\system\freej2me_plus-lr.jar`
   - `CFW\retroarch\system\freej2me-lr.jar`
   - `CFW\retroarch\system\freej2me_plus-lr.jar`

2. Other active files anywhere outside protected/excluded trees whose filename clearly identifies FreeJ2ME runtime/native payload:
   - `freej2me*.jar`
   - `freej2me*libretro*.so`
   - `libfreej2me*.so`
   - stale FreeJ2ME runtime temp files.

3. Historical experimental APP payloads under `Roms\APPS` only:
   - M1 experiment packages;
   - `libm1_*presenter.so`;
   - old RG35XX VC/B4/M1 experiment wrappers.

4. Root-level stale evidence pointers/logs:
   - `freej2me-*.log`
   - `RG35XX-*-INSTALL-RESULT.txt`
   - `RG35XX-*-CURRENT-BACKUP.txt`

These root evidence files are moved only to prevent old logs/results from being mistaken for the next test session.

## Safety model

- drive-root path required; arbitrary folder paths are rejected;
- protected hashes checked before scan cleanup;
- no wildcard recursive deletion;
- no `Remove-Item -Recurse`;
- every candidate is inventoried and hashed before move;
- files are moved one-by-one to a same-card quarantine preserving relative paths;
- destination SHA must equal source SHA;
- post-clean full-SD rescan must report zero active candidates;
- if any move/postcondition fails, files moved during that run are restored automatically;
- dedicated restore script is included.

## R1 installer compatibility change

Clean Consolidated R1 installer previously required the old canonical `BIOS\freej2me-lr.jar` to exist.

Because pre-clean intentionally removes old runtime aliases, installer R1 is updated to accept:
`OLD_RUNTIME_STATE=ABSENT_PRE_CLEAN`.

Protected JamVM/glibj/core hash checks remain mandatory.

The installer still installs the new runtime into all five canonical aliases and records ABSENT/EXISTED state for rollback.

## Usage order

1. `01-SCAN-RG35XX-OLD-PLATFORM.cmd`
   - read-only with respect to platform files;
   - writes inventory/report only.

2. `02-CLEAN-RG35XX-OLD-PLATFORM.cmd`
   - rescans;
   - shows candidates;
   - requires typing `CLEAN`;
   - moves candidates into quarantine;
   - verifies protected hashes and zero active residual candidates.

3. Run the updated `INSTALL-RG35XX-CLEAN-R1.cmd`.

4. Only after R1 device acceptance should quarantine be permanently purged.

Rollback if needed:
`03-RESTORE-PRECLEAN.cmd`.

## Expected clean result

- `ACTIVE_OLD_PLATFORM_SCAN=ZERO`
- `READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES`
- JamVM/glibj/protected core hashes unchanged
- game JARs unchanged
- saves/RMS unchanged

STABLE=NO.


---

## Incident 2026-09-22 — drive-root rollback failure

User executed the original R1 cleaner on SD drive `H:\`.

The scan correctly detected 14 old/stray active platform files while all protected hashes matched.

During CLEAN, a failure triggered rollback. The rollback then failed at the root-level restore path:

```
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)
```

For root files such as:
- `H:\freej2me-java-error.log`
- `H:\freej2me-vc3-early.log`
- root install-result / backup-pointer files

`Split-Path -Parent` resolves to the drive root. Recreating an already existing drive root with `New-Item -ItemType Directory` is not a valid/safe operation on the user's Windows PowerShell environment.

### Impact

- protected JamVM/glibj/B4-core hashes were verified before mutation;
- game and save trees were excluded;
- rollback itself may have stopped before restoring every file moved in that run;
- any files left in the previous quarantine are isolated and cannot participate in runtime lookup;
- R1 must NOT be installed until a fixed cleaner completes with `ACTIVE_OLD_PLATFORM_SCAN=ZERO`.

### R1.1 fix

- new `Ensure-ParentDirectory(path)` helper:
  - if parent is empty: return;
  - if parent already exists (including drive root): return;
  - create only genuinely missing parent directories.
- all clean/rollback/restore parent creation uses the helper.
- rollback preserves the original clean exception instead of masking it.
- rollback validates restored SHA256.
- previous incomplete `quarantine-*` folders are detected and reported, but remain isolated.
- rerunning R1.1 safely continues cleanup from the current active SD state; files already isolated in an earlier partial quarantine do not need to be reactivated first.
- Windows PowerShell drive-root self-test added to CI.

Classification:
- original R1 cleaner: SUPERSEDED / DO NOT USE
- fixed cleaner: R1.1
- device cleanup status: pending successful R1.1 rerun
- R1 platform install: BLOCKED until R1.1 reports READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES


---

## Incident 2026-09-22 — StrictMode singleton scan failure

After R1.1 fixed the drive-root rollback bug, the user's next SCAN run reported:

```
WARNING: Detected 1 previous partial quarantine folder(s).
The property 'Count' cannot be found on this object.
PropertyNotFoundStrict
```

### Root cause

Under Windows PowerShell, function output is pipeline-unrolled.

When `Scan-Candidates` returned exactly one object, assignment:

```
$candidates=Scan-Candidates
```

produced a scalar `PSCustomObject`, not an array.

With `Set-StrictMode -Version Latest`, accessing:

```
$candidates.Count
```

failed because the scalar object has no Count property.

The same latent bug existed in the post-clean residual rescan.

### Impact

- failure occurred in SCAN ONLY;
- no additional platform files were moved by this run;
- protected JamVM/glibj/B4 core hashes were still valid;
- previous partial quarantine remained isolated.

### R1.2 fix

Normalize all scanner results at the call site:

```
$candidates=@(Scan-Candidates)
$residual=@(Scan-Candidates)
```

This guarantees:
- zero result -> array Count 0;
- one result -> array Count 1;
- many results -> array Count N.

CI self-test now requires:
- `SELFTEST_ROOT_PARENT=PASS`
- `SELFTEST_NESTED_PARENT=PASS`
- `SELFTEST_SINGLETON_ARRAY=PASS`
- `SELFTEST_EMPTY_ARRAY=PASS`

Classification:
- R1: SUPERSEDED
- R1.1: SUPERSEDED
- R1.2: current cleaner candidate
- R1 platform install remains BLOCKED until R1.2 returns READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES
