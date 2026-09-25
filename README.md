# FreeJ2ME for Original RG35XX — Aweigit Canonical Port

This repository ports the proven `aweigit/freej2me-miyoomini` FreeJ2ME implementation to the **original Anbernic RG35XX / GarlicOS-class environment** while preserving device-proven RG35XX hardware/runtime contracts.

## Current accepted baseline

The branch `rg35xx-aweigit-r1-stable` is the protected reference baseline for future RG35XX development.

Accepted source checkpoint:

```text
SOURCE_BRANCH=rg35xx-aweigit-r1-a7-audio-media
SOURCE_COMMIT=5b7a8e88bd32a735a1342715e718eecf8cf10fad
STATUS=DEVICE-PASS_SELECTED_SCOPE
FULL_PLATFORM_STABLE=NO
```

This means the currently selected core integration and real-game regression scope has passed on original RG35XX hardware. It does **not** claim universal compatibility with every J2ME game, codec or optional API.

## Canonical upstream

```text
Repository: aweigit/freej2me-miyoomini
Pinned commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Role: CANONICAL_J2ME_IMPLEMENTATION
```

The upstream pin is deliberate. Do not automatically follow newer upstream commits without an explicit audit/migration decision.

## Architecture

```text
AWEIGIT CANONICAL J2ME CORE
        |
        v
RG35XX ADAPTER
        |
        v
RG35XX PACKAGE / LAUNCHER
        |
        v
Original RG35XX hardware
```

Device-specific implementation targets the original RG35XX rather than redesigning generic J2ME semantics.

## Accepted RG35XX runtime

The accepted chain currently includes:

- original RG35XX SDL1.2/fbcon video path
- physical RG35XX input adapter and MIDP input lifecycle
- Canvas/GameCanvas and core 2D rendering
- PNG alpha and `drawRegion`
- Sprite/TiledLayer/LayerManager paths exercised by the accepted integration chain
- raw drawing primitives required by tested games
- PERF-A1 asynchronous latest-frame native presenter
- corrected `PlatformGraphics.translate()` device-space clip behavior
- RMS where exercised by the selected corpus
- Java 6 media compatibility overlay required by protected JamVM/glibj
- RG35XX SDL1_mixer native audio backend
- launcher-boundary cold-start audio-route prime before Java/SDL media playback
- WAV playback, volume and pause/resume in the accepted A7 integration test
- MIDI playback and END_OF_MEDIA callback in the accepted A7 integration test
- normal application exit without hard reset in accepted tests

## Real-device milestones

### A4 — Smoke
Established the basic original-RG35XX execution chain: runtime boot, LCD presentation, physical input and normal exit.

### A5 — Core integration
Integrated the canonical Aweigit J2ME implementation with the RG35XX adapter and exercised the core graphics/game-layer functionality required for the production path.

### A6 — Real-game regression
The selected A6 corpus reached DEVICE-PASS. Important accepted fixes include classloader duplicate-definition handling, Adam7 PNG support, rendering primitive compatibility, input lifecycle integration, PERF-A1 and the ClipTranslate correction.

Confirmed parent games include:

- `Vua-Cuop-Bien-240x320.jar`
- `God-of-War-Betrayal_J2ME_EN_v148.jar`

Commercial game JARs are test inputs only and are never bundled in this repository or release packages.

### A7 — Audio / Media
A7 added the RG35XX-native SDL1/SDL_mixer audio bridge while retaining the canonical MMAPI/PlatformPlayer behavior as far as the accepted adapter boundary permits.

Cold-start device testing isolated an RG35XX audio-route initialization requirement. The accepted device-boundary solution primes `hw:0,0` before Java playback using approximately 350 ms of zero PCM (`S32_LE`, 44100 Hz, stereo), then starts the unchanged accepted Java/SDL1_mixer runtime.

Accepted A7 testing demonstrated audible WAV and MIDI playback, WAV pause/resume, MIDI END_OF_MEDIA, protected runtime hashes, normal return and no hard reset. Vua Cướp Biển and God of War then passed parent regression on the A7 candidate.

## Protected components

The following accepted areas are treated as locked unless a new reproducible parent integration/regression failure directly identifies them as the owner:

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
```

Micro-tests are diagnostic tools only after a parent integration or real-game regression exposes a reproducible failure. Do not resume the historical DP/VC/Golden patch chains as production development; those builds remain evidence/reference only.

## Runtime protection

```text
JamVM SHA256:
eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34

glibj SHA256:
d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Do not replace these components merely to simplify development or compilation.

## Initialize the canonical source

```sh
git submodule update --init --recursive
./scripts/verify-canonical.sh
```

## Status vocabulary

- `BUILD-PASS` — compilation/package gates passed; no hardware claim.
- `DEVICE-PASS` — tested successfully on original RG35XX within the stated scope.
- `ACCEPTED` — retained as the reference implementation for that tested scope.
- `STABLE` — reserved for broader repeated integration/regression confidence.
- `FAIL` — includes hang or hard reset during the tested scenario.

## Current direction

The accepted A7+A1P5 implementation is now the reference code baseline. Future development should branch from `rg35xx-aweigit-r1-stable`, preserve accepted identities/contracts, consolidate production packaging/launcher behavior, and expand compatibility through evidence-driven real-game regression.

The project intentionally does **not** claim `FULL_PLATFORM_STABLE` yet. Networking, SMS/payment, 3D/M3G/Mascot and untested MMAPI formats remain outside the currently accepted scope.
