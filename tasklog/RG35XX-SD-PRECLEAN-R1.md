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
