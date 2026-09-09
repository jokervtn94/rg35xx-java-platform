# B6 — Atomic Installer + Recovery + Evidence Collector

Status: `PACKAGE-BUILT — DEVICE ACCEPTANCE PENDING`

## Purpose

B6 is the first installable acceptance package for the verified-clean foundation. It consumes the B5 canonical SD tree and adds fail-closed payload verification, per-device backup, synchronized alias installation, post-copy SHA verification, rollback, log rotation, and evidence collection.

This checkpoint is not `STABLE` and not `DEVICE-PASS` until real RG35XX acceptance succeeds.

## Locked foundation payloads

- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath `glibj.zip`: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- B4 runtime JAR: `e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed`
- B4 core: `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`
- B3 deterministic runtime content identity: `52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783`

## Install behavior

The installer verifies every payload SHA before touching the SD card. It then backs up every existing canonical target to a timestamped directory under:

`RG35XX_VERIFIED_CLEAN_B6_Backup/<timestamp>/`

It installs all nine canonical targets and verifies each destination SHA after copy. Existing early/core/Java logs are backed up with the snapshot and then removed so the next hardware test starts with fresh evidence.

The installer writes:

`RG35XX-VERIFIED-CLEAN-B6-INSTALL-RESULT.txt`

with before/after hashes and the exact backup path.

## Recovery behavior

`b6_restore_previous.ps1` restores the newest B6 backup snapshot without relying on any binary embedded from another RG35XX device.

## Verification behavior

`b6_verify.ps1` checks all nine installed targets against the locked foundation hashes. Any missing or mismatching alias is a hard failure.

## Evidence collection

`b6_collect_result.ps1` collects at least:

- `RG35XX-VERIFIED-CLEAN-B6-INSTALL-RESULT.txt`
- `/mnt/mmc/freej2me-vc3-early.log`
- `/mnt/mmc/freej2me-core.log`
- `/mnt/mmc/freej2me-java-error.log`
- `/mnt/mmc/freej2me-java-control.log` when present.

## Acceptance sequence

1. Run B6 installer on the SD card.
2. Require `VERIFY: PASS` before booting the device.
3. Reboot RG35XX.
4. Run one known-working Java game.
5. Run one game that previously produced a blue/black screen or no Java log.
6. Confirm the device remains responsive, can exit the game, and can launch another game.
7. If available, exercise representative 240x320, 320x240, 352x416, and 360x640 games.
8. Collect the B6 evidence folder.

The early log interpretation remains the B4 contract: no B4 log means the selected core likely did not reach `retro_init`; a log stopping before `JAVA_READY` indicates native/JamVM startup; `IPC_RUN_SENT` with no valid frame moves the boundary to Java/MIDlet compatibility.

## Foundation exclusions

B6 still does not admit PNG ICC compatibility, CK font scaling, CV/CW resolution experiments, audio rework, old RC/CJ stacks, JamVM diagnostic variants, or patched GNU Classpath.

## Archive policy

Installer, verifier, restore, collector source, locked hashes, upstream pin, toolchain digest, and checkpoint documentation are committed to GitHub. The generated acceptance ZIP is additionally hashed and must be preserved as a recovery asset after device acceptance; Actions artifacts alone are not considered archival.
