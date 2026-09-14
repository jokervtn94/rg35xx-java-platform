# RG35XX From-Zero Foundation v1 — Device Acceptance Gate

## Locked build under test

This document locks the only artifact that may be used for the first real-device acceptance pass.

- Branch: `rg35xx-from-zero-rebuild-v1`
- Commit: `24ed32b3bc2114f184066b29a82e195085971117`
- Workflow run: `34794581294`
- Artifact ID: `10328848388`
- Artifact name: `rg35xx-from-zero-foundation-v1-atomic-installer`
- Artifact ZIP SHA256: `a2bc71d6ca59313b330bca4fc720d93bbdfa176c574d80614f407095dc413fe7`
- Artifact size: `1135238` bytes

## Build evidence

CI passed all required gates:

- pristine pinned upstream identity: PASS
- allowlist-only From-Zero assembly: PASS
- Java compile: PASS
- Java class count: 1334
- Java class major: 50 only
- ARMv5TE / arm926ej-s / soft-float core build: PASS
- strict production contract gate: PASS
- PowerShell installer parse: PASS
- payload checksum verification: PASS
- full package checksum verification: PASS
- artifact upload: PASS

Locked binary hashes from run `34794581294`:

- Runtime JAR SHA256: `a3c15f55088ee0940f9133c36d2df869edcc35dc0c60de2a2451c170b09acb22`
- Native core SHA256: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`
- Required JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- Required glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

## Status before device test

- BUILD-PASS: YES
- DEVICE-PASS: PENDING
- STABLE: NO

Do not call this checkpoint stable until all required device checks below pass on an actual RG35XX.

## Installation acceptance

Use only artifact ID `10328848388`.

On Windows, extract the artifact and run the bundled atomic installer against the SD card. Accepted SD root examples are `G`, `G:`, or `G:\`.

The installer must report PASS after:

1. verifying the pinned JamVM L already present on the SD,
2. verifying the pinned `glibj.zip` already present on the SD,
3. verifying every payload hash,
4. backing up replaced files,
5. staging the new runtime/core,
6. verifying staged hashes,
7. committing the staged files.

Any failure is a FAIL for this acceptance pass. Do not manually copy individual files around the installer.

## Mandatory RG35XX device tests

### Test A — normal portrait logical view

Run one previously known-working Java title that uses a normal 240x320 logical view.

PASS requires all of the following:

- game reaches actual gameplay or its normal interactive title/menu state,
- no permanent black screen,
- no immediate crash back to frontend,
- image is not rotated incorrectly,
- image is not cropped incorrectly,
- input responds,
- repeated frame updates continue,
- no persistent freeze during normal navigation.

### Test B — landscape / KDTT class case

Run KDTT or another previously proven 320x240 Java title.

PASS requires all of the following:

- title reaches actual interactive scene,
- dynamic logical view is correct,
- no CV/CW boot-resolution dependency is required,
- Smart-Fit output is usable,
- no permanent black screen,
- no stale/frozen frontbuffer,
- input responds,
- scene continues to update.

### Test C — startup/media regression check

For both Test A and Test B:

- game launch must not hang before first useful frame,
- there must be no eager media prewarm regression,
- exiting the title and launching again must still work.

## Logs to preserve if any test fails

Do not patch immediately. First preserve the exact failing checkpoint and collect, when present:

- `/mnt/mmc/freej2me-java-error.log`
- `/mnt/mmc/freej2me-vc3-early.log`
- exact game JAR name
- whether failure occurred before first frame, at first frame, or after gameplay began
- whether the display was black, frozen, rotated, cropped, or returned to frontend

Do not mix logs from a later experimental build with this acceptance run.

## Forbidden changes during Foundation acceptance

Until the Foundation receives DEVICE-PASS, do not add or restore:

- Golden Audio worker-ring
- reconstructed / replacement font
- transparency/tRNS extensions
- CV/CW boot-resolution layer
- MediaWarmup/eager media preparation
- VC7R diagnostic probes
- TransformCache experiment
- JavaSound `MidiSystem.getSequencer()` path
- unbounded per-frame logging

## Promotion rule

Promote this checkpoint from BUILD-PASS to DEVICE-PASS only when Test A, Test B and Test C all pass on the same locked artifact without source or binary changes.

Only after DEVICE-PASS may the next isolated restoration stage begin. The first restoration stage should be Golden Audio, with a separate branch/checkpoint and separate device acceptance gate.
