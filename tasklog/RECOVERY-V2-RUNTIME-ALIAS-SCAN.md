# Recovery v2 — Runtime/Core Alias Scan

Status: TOOLING-FIX
Date: 2026-09-08

## Problem

The first Pre-M1 recovery PC package assumed that every per-device backup contained exactly `BIOS/freej2me-lr.jar`. Device feedback showed that recovery could fail with `runtime jar missing` even though historical installers/platform layouts used more than one runtime/core alias.

## Correction

Recovery v2 must not assume one filename/path. It must scan known device and backup locations for:

- `freej2me-lr.jar`
- `freej2me_plus-lr.jar`
- Java/runtime copies under BIOS/CFW Java trees
- `freej2me_plus_libretro.so`
- `freej2me_libretro.so`

It records SHA-256 for every candidate, rejects the known M1 regression pair, prefers known device-tested fingerprints, and emits a scan report if no safe candidate can be selected.

## Known preferred baseline

- CN core: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`
- CQ runtime: `45853d13376fd17d176a8296c247adcf2e14065cd44f171b1aaacf2387ec14a8`

Historical Golden fingerprints are also recognized:

- Golden core: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- Golden runtime: `de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8`

## Rejected M1 regression

- Core: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`
- Runtime: `cae779a1ac2dfd7cd65e8893b30fee8196c1c6107f693c335701fe34fea4d322`

The rejected runtime throws `IllegalArgumentException: Wrong major version number:4` through GNU Classpath PNG ICC parsing on KDTT and leaves the device showing only the green background.

## Safety

Recovery v2 snapshots current JamVM/core/runtime candidates before writing, always installs the proven JamVM L Production payload, never modifies game JARs/RMS/config, and never silently chooses a known rejected M1 binary.
