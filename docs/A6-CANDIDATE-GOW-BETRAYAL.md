# A6 candidate inventory — God of War: Betrayal

Date: 2026-09-24
Stage: A6 REAL_GAME_REGRESSION candidate evaluation
Runtime base: PERF-A1

## Binary identity

File: `God-of-War-Betrayal_J2ME_EN_v148.jar`
SHA256: `e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98`
Size: `414932` bytes

Manifest:
- MIDlet-Name: `God Of War`
- MIDlet-1 entry class: `GOWMIDlet`
- MIDlet-Version: `1.4.8`
- MIDlet-Vendor: `Glu Mobile LTD`
- MicroEdition-Configuration: `CLDC-1.0`
- MicroEdition-Profile: `MIDP-2.0`

Static startup code in class `e` configures logical display `240x320`, matching the proven PERF-A1 async path.

## Core coverage

Static bytecode inventory confirms:
- Canvas / Display startup;
- Graphics/Image including `drawRegion`;
- RMS `RecordStore` operations;
- keyboard-driven gameplay path.

Not found in the screened class references:
- `javax.microedition.io.Connector` / HttpConnection;
- `javax.wireless.messaging` / MessageConnection / TextMessage;
- Bluetooth APIs;
- IMEI/device-ID APIs;
- `MIDlet.platformRequest`.

## Media inventory

MMAPI is present in class `d`.

Startup behavior differs materially from the blocked Bolacthoitiensu corpus:
- `GOWMIDlet.startApp()` constructs class `e` and sets it current;
- class `e` constructs media controller `d`, but this constructor only allocates state/Player arrays;
- the actual `Manager.createPlayer(...)`, `Player.realize()` and `Player.prefetch()` calls live in `d.a(int,int,int,int)`;
- the complete create/realize/prefetch region is guarded by `catch (java.lang.Throwable)`.

Therefore MMAPI failure has a plausible fail-soft path rather than necessarily terminating the game thread. Audio/Media remain excluded from the A6 verdict.

## A6 decision

`A6_CANDIDATE_GOW_BETRAYAL=SECONDARY_CANDIDATE`

Reasons:
- exact 240x320 portrait path suitable for cross-game validation of PERF-A1 async;
- no screened SMS/network/Bluetooth/device-ID/external-link dependency;
- useful Graphics/RMS coverage;
- active MMAPI exists, but createPlayer/realize/prefetch is Throwable-guarded.

Acceptance scope:
`BOOT,PERF_A1_ASYNC_ENABLED,RENDER,INPUT,BASIC_GAMEPLAY,RMS_IF_EXERCISED,NORMAL_EXIT`

Excluded:
`AUDIO,MEDIA`

If MMAPI fails but gameplay continues, do not count that as an A6 core failure. If the title cannot proceed because Media still escapes the guard, classify it as `BLOCKED_BY_MEDIA_OUT_OF_SCOPE` and do not patch Media under A6.

Runtime candidate package:
`RG35XX-AWEIGIT-R1-A6-GOW-BETRAYAL-PERF-A1-CORPUS3.zip`

Runtime locks:
- Java: `8ecbcb1964967e55994ba2401471c19fb23f9efdc285a568c2c303b0fb54cafd`
- input native: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- PERF-A1 video: `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`

Status:
`BUILD-PASS=YES`
`DEVICE-PASS=NO_PENDING_ORIGINAL_RG35XX_TEST`
`STABLE=NO`
