# RG35XX Golden Full-Platform Rebuild Tasklog

Status: SOURCE-REBUILD / DEVICE-TEST-PENDING

## Purpose

Rebuild the RG35XX Java platform as one coherent set from the last device-proven Golden architecture. Do not continue per-file rollback/testing.

## Immutable device-proven references

- Golden runtime `freej2me-lr.jar`: `de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8`
- Golden core `freej2me_plus_libretro.so`: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- Golden embedded font resource: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- JamVM L production/device-pass: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- FreeJ2ME upstream pin: `13ec186903087156c145268f8706eecfaf9f1e50`
- ARM toolchain image: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

## Excluded as baseline

M1/N1/N3 binaries are diagnostic/development states and MUST NOT be used as the baseline for this rebuild. RC1 patch history is evidence only; it is subordinate to Golden real-device behavior.

## Rebuild set

The device package is atomic and must contain/verify together:

1. `CFW/java/bin/jamvm` — JamVM L.
2. `CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so` plus required core alias.
3. `BIOS/freej2me-lr.jar` plus only aliases proven necessary by runtime resolution.
4. Required Java/ClassPath files from the known-good baseline; no byte-patched N3 archive.
5. Runtime configuration and required BIOS media assets, without overwriting user game data.
6. Manifest with SHA-256 for every installed platform file.

## Golden contracts that must survive rebuild

- ARMv5TE / ARM EABI5 / soft-float / uClibc compatible core.
- One Java launch owner, after game path is known.
- Async Java frame worker -> RGB565 LUT -> native exact-length receiver thread -> front/back generation -> smart-fit presentation.
- MIDlet logical LCD remains authoritative.
- Embedded Unicode bitmap font is the normal text path.
- Async native audio worker/ring; MIDI/PCM lifecycle must not be tied to one frame cadence.
- JamVM L ALOAD_0/GETFIELD_THIS fix remains intact.
- Game JAR is never modified.

## PNG ICC policy

Do not patch `glibj.zip` in-place and do not modify the game JAR. PNG ICC-v4 compatibility may only be introduced as a source-level change after the clean Golden boot chain is restored and independently verified. The first full rebuild package therefore prioritizes restoring Golden boot/runtime behavior before layering PNG compatibility.

## Build gates

- pinned upstream checkout
- deterministic assembly scripts
- Java class major version 50
- ARM ELF32 EABI5 soft-float verification
- required Golden ownership symbols/paths
- undefined-symbol/dependency audit
- package manifest/hash verification
- no M1/N1/N3 payload hashes in the atomic package

## Device acceptance order

`core load -> Java launch -> JamVM L -> MIDlet load -> PNG assets -> text -> KDTT past historical JamVM crash -> video/input -> MIDI/audio -> sustained gameplay`

A build is not called stable until this chain passes on a real RG35XX with a real game JAR.
