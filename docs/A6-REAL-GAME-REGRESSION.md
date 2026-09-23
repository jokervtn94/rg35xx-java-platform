# A6 — REAL GAME REGRESSION (NON-AUDIO)

Date: 2026-09-23
Project: RG35XX-AWEIGIT-R1
Production baseline: `ffff492c0f2f0ccc1e0c1548addcec99c73fff09`
Canonical Aweigit commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

## Purpose

A6 is the first Level-3 real-game regression phase after A5 Core2D DEVICE-PASS and same-build confirmation. It validates the accepted production core on the original RG35XX without introducing speculative J2ME semantic patches.

Audio/Media remain HOLD.

## Primary locked corpus — recovered

File: `Vua-Cuop-Bien-240x320.jar`

Exact identity verified from the user-supplied binary:
- SHA256: `220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578`
- size: `894847` bytes
- MIDlet: `Vua Cuop Bien`
- vendor: `HaySo1.Vn`
- version: `1.0.0`
- MIDP-1.0 / CLDC-1.0
- 83 class files
- 61 non-class resources
- 21 BIN resources
- 39 PNG resources
- class major versions 45 and 48

This exactly matches the historical corpus identity previously recorded in the compatibility matrix.

Useful A6 coverage confirmed directly from bytecode:
- Graphics/Image: `drawImage`, `drawRegion`, `drawString`, `setClip`
- Font: J2ME Font APIs
- RMS: `openRecordStore`, `addRecord`, `setRecord`, `getRecord`, `deleteRecordStore`
- Nokia UI: `com.nokia.mid.ui.DirectGraphics`, `DirectUtils`
- no `javax.microedition.media` / Manager / Player references

Additional closed-boundary modules also exist in the binary:
- SMS MessageConnection/TextMessage code
- direct SMS send code in one class
- HTTP Connector/HttpConnection request code
- payment/network support modules

The compatibility matrix did not inventory network/SMS columns; therefore `Media = none` must not be interpreted as `network/SMS = none`.

Startup path inspection shows `CMIDlet.startApp()` creates the main Canvas and sets it current; no direct SMS/HTTP invocation is present in that MIDlet startup method. A6 therefore locks a constrained user path and deliberately excludes payment/network/SMS actions.

Status:
`A6_CORPUS_VUACUOPBIEN=PRIMARY_LOCKED`

## Device test path

Required path only:
1. boot to visible game UI;
2. verify background/images/transparency and text rendering;
3. verify D-pad, A/B and softkey behavior;
4. enter basic gameplay and move/interact;
5. exercise save/load/RMS only if naturally available on this path;
6. exit normally when possible.

Do NOT enter payment, SMS or network menus.

A6 scope:
`BOOT,RENDER,INPUT,BASIC_GAMEPLAY,RMS,NORMAL_EXIT`

Excluded from A6 verdict:
`SMS,HTTP,PAYMENT,NETWORK,AUDIO,MEDIA`

## Other evaluated candidates

- `NinjaSchool1.jar`: `REJECTED_OUT_OF_SCOPE` — Media + SMS + Bluetooth/device identity.
- `Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`: `CONDITIONAL_FALLBACK` — clean core coverage but active MMAPI MIDI.
- `KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`: `REJECTED_OUT_OF_SCOPE` — Media + HTTP payment + SMS/payment stack.

## Evidence required

Capture production/adapter and canonical identities, platform/native hashes, protected JamVM/glibj hashes before/after, locked game SHA256, runtime log, and human observations for boot/render/input/basic gameplay/RMS/normal exit.

`BUILD-PASS != DEVICE-PASS != STABLE`.
Only original RG35XX evidence can promote the A6 real-game gate.

## Failure handling

If the game fails, identify the first meaningful boundary and compare it against pinned Aweigit and A5 device-proven contracts. Do not replay DP patches. Do not patch SMS/network/media behavior under A6. Use a micro diagnostic only if evidence cannot isolate an already-open boundary, then rerun the same locked JAR.

## Current status

A4_LEVEL1_DEVICE_PASS=YES
A5_R2_DEVICE_PASS=YES
A5_REGRESSION_CONFIRMATION=PASS
A5_PRODUCTION_MERGE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
A6_CORPUS_VUACUOPBIEN=PRIMARY_LOCKED
A6_REAL_GAME_REGRESSION=READY_FOR_DEVICE_TEST
AUDIO=HOLD
MEDIA=HOLD
STABLE=NO
FULL_PLATFORM_STABLE=NO
