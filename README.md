# FreeJ2ME for Original RG35XX — Aweigit Canonical Port

This repository ports the proven `aweigit/freej2me-miyoomini` FreeJ2ME implementation to the **original Anbernic RG35XX / GarlicOS-class environment** while preserving device-proven RG35XX hardware/runtime contracts.

## Current accepted baseline

The branch `rg35xx-aweigit-r1-stable` is now the **A8 production reference baseline** for future RG35XX development.

```text
BASELINE=A8
BRANCH=rg35xx-aweigit-r1-stable
A8_CI_COMMIT=80113f50e5db59e372f02722e3ff362263490b2c
A8_DEVICE_ACCEPTANCE=PASS
STATUS=DEVICE-PASS
```

The A8 baseline is the accepted A7+A1P5 runtime boundary consolidated into the production launcher/package path. The original RG35XX device test confirmed the selected parent regression scope with Vua Cướp Biển and God of War.

This does **not** claim universal compatibility with every J2ME game, codec or optional API.

## What A8 achieved

A8 is a **packaging/launcher consolidation**, not a runtime-semantic rewrite.

It preserves:

- canonical Aweigit J2ME implementation
- protected JamVM/glibj
- accepted A6 graphics/input/PERF-A1/ClipTranslate behavior
- A7 Java 6 media compatibility
- SDL1_mixer native audio backend
- accepted A1P5 cold-start audio-route prime
- accepted runtime/native identity hashes

The production launcher accepts the selected external JAR as argument 1 and performs the established identity/audio gates before launching the game.

Production layout:

```text
Roms/APPS/RG35XX-AWEIGIT-R1.sh
Roms/APPS/RG35XX-AWEIGIT-R1/
  freej2me-rg35xx.jar
  librg35xx_input.so
  librg35xx_video.so
  libaudio.so
  a7-a1p5-rw-silence-prime.s32le
  data/
```

Commercial game JARs remain external test inputs and are not part of the production runtime package.

## Real-device acceptance

A8 passed the required original-RG35XX acceptance scope.

### Automated / CI

- A8 production package: PASS
- package manifest verification: PASS
- runtime identity verification: PASS
- protected JamVM/glibj: PASS
- A1P5 zero-PCM pre-Java prime: PASS
- Vua Cướp Biển regression: PASS
- God of War regression: PASS
- PERF-A1/runtime execution: PASS
- normal exit: PASS

### Physical RG35XX confirmation

The operator confirmed:

- Vua Cướp Biển displays correctly.
- Vua Cướp Biển controls work.
- Vua Cướp Biển gameplay is normal.
- Vua Cướp Biển does not hang.
- God of War displays correctly.
- God of War controls work.
- God of War gameplay is normal.
- God of War does not hang.
- God of War audio is audible and normal.

Therefore:

```text
A8_BUILD=PASS
A8_DEVICE=PASS
A8_PRODUCTION_BASELINE=YES
FULL_PLATFORM_STABLE=NO
```

## Milestones

### A4 — Smoke
Established the basic original-RG35XX execution chain: runtime boot, LCD presentation, physical input and normal exit.

### A5 — Core integration
Integrated the canonical Aweigit J2ME implementation with the RG35XX adapter and exercised the core graphics/game-layer functionality required for the production path.

### A6 — Real-game regression
Reached DEVICE-PASS for the selected parent corpus and established the graphics/input/PERF-A1/ClipTranslate baseline.

### A7 — Audio / Media
Established the RG35XX-native SDL1_mixer path, Java 6 media compatibility and the accepted cold-start audio-route prime. WAV and MIDI parent regression passed.

### A8 — Production Consolidation
Converted the accepted A7+A1P5 device-proven boundary into the production launcher/package layout without changing accepted runtime semantics. CI passed and the consolidated build passed physical RG35XX testing.

Detailed A8 notes and preserved A1P5 references are in `packaging/a8/README.md` and `packaging/a8/reference/`.

## Protected components

The following remain locked unless a new reproducible parent integration/regression failure directly identifies them as the owner:

- canonical Aweigit pin
- protected JamVM/glibj runtime
- A6 graphics/rendering chain
- input mapping/lifecycle
- PERF-A1 presenter
- PNG/alpha/drawRegion
- ClipTranslate
- A7 Java 6 media compatibility path
- SDL1_mixer backend
- accepted RG35XX audio-route prime

Do not reopen a protected subsystem merely because a new game fails. First reproduce the failure, compare against canonical Aweigit behavior, identify the RG35XX boundary and make the smallest evidence-driven adapter change.

## Development rules

Development is **integration-first**. A successful build is not a device pass. Only evidence from an original RG35XX can promote a candidate to DEVICE-PASS.

Required workflow:

```text
canonical behavior
-> RG35XX device contract
-> integration evidence
-> failure owner
-> smallest adapter delta
-> parent integration/regression test
-> physical RG35XX acceptance
-> stable promotion
```

Micro-tests are diagnostic tools only after a parent integration or real-game regression exposes a reproducible failure. Do not resume historical DP/VC/Golden patch chains as production development; those builds remain evidence/reference only.

## Runtime protection

```text
JamVM SHA256:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj SHA256:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Do not replace these components merely to simplify development or compilation.

## Canonical source

```text
Repository: aweigit/freej2me-miyoomini
Pinned commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Role: CANONICAL_J2ME_IMPLEMENTATION
```

Do not automatically follow newer upstream commits without an explicit audit/migration decision.

## Status vocabulary

- `BUILD-PASS` — compilation/package gates passed; no hardware claim.
- `DEVICE-PASS` — tested successfully on original RG35XX within the stated scope.
- `ACCEPTED` — retained as the reference implementation for that tested scope.
- `STABLE` — the branch used as the production development baseline.
- `FAIL` — includes hang or hard reset during the tested scenario.

## Current direction

**A8 is now the production reference baseline.**

Future work should branch from `rg35xx-aweigit-r1-stable`, preserve accepted identities/contracts, and add compatibility only through evidence-driven real-game regression.

The project intentionally does **not** claim `FULL_PLATFORM_STABLE` yet. Networking, SMS/payment, 3D/M3G/Mascot and untested MMAPI formats remain outside the currently accepted scope.
