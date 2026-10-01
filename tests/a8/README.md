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
- `PREPARE-A8-CANDIDATE.ps1` — PC-side helper. Computes exact JAR SHA256 and creates a candidate identity/observation record before device testing.

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

## Suggested workflow

### 1. Prepare the candidate on PC

```powershell
powershell -ExecutionPolicy Bypass -File .\PREPARE-A8-CANDIDATE.ps1 -JarPath "C:\Games\game.jar" -GameName "Game Name" -Source "source description"
```

This produces an identity record. The JAR itself is never added to the repository.

### 2. Copy the JAR and wrapper to the RG35XX SD card

Keep commercial/copyrighted JARs outside the production runtime package.

For example:

```text
Roms/JAVA/game.jar
Roms/APPS/A8-COMPAT-RUN.sh
```

Copy `tests/a8/A8-COMPAT-RUN.sh` from this repository to `Roms/APPS/A8-COMPAT-RUN.sh` on the SD card. The accepted production launcher remains unchanged at `Roms/APPS/RG35XX-AWEIGIT-R1.sh`.

### 3. Run on the original RG35XX

Example:

```sh
/mnt/mmc/Roms/APPS/A8-COMPAT-RUN.sh \
  "/mnt/mmc/Roms/JAVA/game.jar" \
  "A8-COMP-01"
```

The wrapper calls the accepted production launcher rather than duplicating runtime launch logic.

### 4. Review the evidence

Evidence is written under:

```text
/mnt/mmc/A8-COMPAT-EVIDENCE/<candidate-id>-<timestamp>/
```

Expected files:

```text
IDENTITY.txt
RUNTIME-RESULT.txt
OBSERVATION.txt
```

Complete `OBSERVATION.txt` after the real-device run.

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
