# A8 Compatibility Harness

This directory contains test tooling for extending the A8 compatibility corpus with real external J2ME game JARs.

The harness does **not** modify the A8 runtime. It wraps the accepted production launcher and archives identity/runtime evidence per candidate.

## Production baseline

Use only the accepted A8 production launcher:

```text
Roms/APPS/RG35XX-AWEIGIT-R1.sh
```

The launcher remains responsible for:

- protected JamVM/glibj identity checks
- A8 runtime/native identity checks
- A1P5 audio-route prime
- launching the exact external game JAR
- recording runtime exit and protected hash state

## Files

- `A8-COMPAT-RUN.sh` — RG35XX-side wrapper. Runs one external JAR through the accepted A8 launcher and archives the result under a unique evidence directory.
- `PREPARE-A8-CANDIDATE.ps1` — optional PC-side helper for exact JAR SHA256 and candidate record creation.
- `testpack/INSTALL-A8-COMPAT-HARNESS.cmd` — installs only the wrapper to the SD card after verifying the accepted A8 launcher exists.
- `testpack/REGISTER-A8-COMPAT-GAME.cmd` — registers one external JAR, records SHA256, and creates a menu-launchable `<CandidateId>-TEST.sh` entry under `Roms/APPS`.
- `testpack/COLLECT-A8-COMPAT-EVIDENCE.cmd` — collects the device evidence into one ZIP after testing.

## Required rule

A candidate is not a valid compatibility record unless all of these are known:

```text
exact JAR filename
exact JAR SHA256
source
original RG35XX device context
runtime evidence
manual display/input/gameplay observation
```

A game failure does not justify modifying A8 by itself.

## Recommended menu-driven workflow

### 1. Install the compatibility harness

Use the files under `tests/a8/testpack` and run:

```text
INSTALL-A8-COMPAT-HARNESS.cmd
```

This copies only `A8-COMPAT-RUN.sh` to `Roms/APPS`. The accepted A8 runtime is not modified.

### 2. Copy and register an external game JAR

Copy the JAR to the SD card, for example:

```text
Roms/JAVA/game.jar
```

Then run:

```text
REGISTER-A8-COMPAT-GAME.cmd
```

Supply the SD drive, JAR path, and a unique candidate ID such as `A8-COMP-01`.

The registration helper:

- verifies the JAR is on the selected SD card,
- computes the exact SHA256,
- writes a candidate identity record,
- creates an APPS launcher such as `A8-COMP-01-TEST.sh`.

Commercial/copyrighted JARs remain external inputs and are never added to the repository or production package.

### 3. Run from the original RG35XX APPS menu

Launch the generated `<CandidateId>-TEST` entry. It invokes the accepted production A8 launcher through the compatibility wrapper, so no shell command needs to be typed manually.

Evidence is written under:

```text
/mnt/mmc/A8-COMPAT-EVIDENCE/<candidate-id>-<timestamp>/
```

Expected files include:

```text
IDENTITY.txt
RUNTIME-RESULT.txt
OBSERVATION.txt
```

### 4. Collect evidence on PC

Run:

```text
COLLECT-A8-COMPAT-EVIDENCE.cmd
```

The collector creates an `A8-COMPAT-EVIDENCE-<timestamp>.zip` suitable for analysis.

## Direct shell workflow

The lower-level wrapper can still be invoked directly when needed:

```sh
sh /mnt/mmc/Roms/APPS/A8-COMPAT-RUN.sh \
  "/mnt/mmc/Roms/JAVA/game.jar" \
  "A8-COMP-01"
```

## Observation result vocabulary

Use only:

```text
PASS
FAIL
PARTIAL
NOT_TESTED
NEEDS_REPRO
```

## Failure ownership order

```text
game/JAR identity
-> launcher/package
-> canonical J2ME behavior
-> RG35XX adapter boundary
-> graphics/input/audio/media subsystem
-> protected runtime component
```

## Promotion boundary

Do not create an A9 runtime change until there is:

1. a reproducible failure tied to an exact JAR SHA256,
2. evidence from the original RG35XX,
3. a clearly identified failure owner,
4. a smallest-required adapter/runtime delta,
5. proof that the accepted A8 parent regression remains intact.
