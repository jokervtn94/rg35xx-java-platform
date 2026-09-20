# RG35XX Java Installable Baseline v1

Status before build: BUILD-PENDING / DEVICE-TEST-PENDING  
Full platform STABLE: NO  
Release branch: `rg35xx-installable-baseline-v1`  
Base commit: `fcba44c2688e65a3f537c8e9884cfa1ba4a630d3` (M1.16-r1.4 workflow commit)

## Purpose

Create the first practical standalone Java baseline that can be installed on a real RG35XX, remove known legacy/diagnostic platform aliases after backup, launch real JARs from `Roms/JAVA`, and collect evidence from game compatibility tests.

This is an integration/package checkpoint. It does not promote the full platform to STABLE and does not convert untested APIs into DEVICE-PASS.

## Preflight

- CURRENT_SYMPTOM: Proven M1 subsystems exist as separate device-test checkpoints, but there is no single clean installable baseline for real Java-game testing. Old platform aliases and diagnostic files can also create ambiguity/conflicts.
- HISTORY_FOUND: B6 and From-Zero installers established fail-closed SHA verification, backup-before-write, atomic staging/rollback and evidence collection.
- PREVIOUS_FIX: Keep device-proven JamVM L and pinned glibj immutable; assemble from fresh pinned FreeJ2ME; restore only independently proven runtime patches.
- PREVIOUS_EVIDENCE_LEVEL: Individual subsystems below are DEVICE-PASS scoped. Full platform remains NOT STABLE.
- REGRESSION_RISK: HIGH if unverified r1.5, audio, vendor APIs, or broad filesystem deletion is bundled. Packaging-only composition is lower risk but still requires a new real-device acceptance pass.
- MINIMAL_PROPOSED_CHANGE: No new runtime semantics beyond the r1.4 device-proven stack. Add only a generic launcher, installer cleanup/backup/rollback, JAR wrappers and evidence collector.
- EXPECTED_DEVICE_TEST: Clean install -> verify hashes -> launch real JARs -> verify input/render/exit/save behavior and collect logs without hard reset.

## Included DEVICE-PASS scoped boundaries

1. M1.6 display.
2. M1.7 raw `/dev/input/js0`.
3. M1.8 js0 -> JNI -> MobilePlatform input dispatch.
4. M1.9E SDL1/fbcon -> physical LCD.
5. M1.9F Canvas input -> render -> LCD.
6. M1.10 GameCanvas input -> render -> flush -> LCD.
7. M1.14 font semantics/regression matrix, scoped; font resource remains EXPERIMENTAL_NOT_GOLDEN.
8. M1.15-r1 RMS lifecycle.
9. M1.15-r1.1 RMS persistence across separate process/reboot.
10. M1.16-r1.2 blank mutable PlatformImage dimensions/Graphics acquisition.
11. M1.16-r1.4 LCDUI Image-copy -> Sprite constructor boundary (A_MUTABLE + B_COPY).

Protected binaries:
- JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Font resource:
- SHA256: `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`
- Classification: EXPERIMENTAL_NOT_GOLDEN
- Required Golden SHA remains `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`.

## Deliberately excluded / deferred

- M1.16-r1.5 `createRGBImage` headless patch: UNVERIFIED and not present on this release branch.
- Full Sprite rendering/collision and TiledLayer coverage.
- Dynamic standalone logical resolution / Smart-Fit integration beyond the locked 640x480 presenter.
- Audio/media changes or eager media preparation.
- Nokia/vendor compatibility.
- Arbitrary commercial JAR compatibility.
- Full-platform STABLE status.

## Integration delta

New integration glue only:
- `M1InstallableBaselineLauncher.java`
- common `run-java.sh`
- Windows atomic installer / cleanup
- restore script
- evidence collector
- generated per-JAR wrappers under `Roms/APPS`.

The launcher deliberately calls `platform.loader.start()` directly rather than upstream `runJar()`, so this release does not reintroduce eager media preparation.

Logging is bounded. Presentation heartbeat is emitted once every 300 present events.

## Cleanup policy

Before deletion, the installer creates a timestamped backup under:

`RG35XX-JAVA-BACKUP/installable-baseline-v1-<timestamp>/`

Known old runtime/core aliases and M1/VC7 diagnostic launch files are backed up before removal. Old diagnostic logs are also backed up before cleanup.

The installer MUST NOT delete:
- `Roms/JAVA` game JARs,
- JamVM L,
- glibj.zip,
- unknown game save/RMS directories,
- unrelated files outside the explicit cleanup allowlist.

The previous installation can be restored with the bundled restore script.

## Acceptance policy

Until a real RG35XX installs this exact artifact and launches representative real games:

- BUILD-PASS: pending CI
- DEVICE-PASS for the new integration/package: NO
- STABLE: NO

After installation, collect at minimum:
- install result
- runtime/input/presenter hashes
- Java log
- tested game name
- render result
- audio result
- hang/reset result
- exit behavior
- save/load behavior when applicable
- regression observations.
