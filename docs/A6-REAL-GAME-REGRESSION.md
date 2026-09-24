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

## Original-RG35XX A6 failure evidence

The first parent A6 run passed all identity gates, created the MIDlet and 240x320 Canvas, opened `RMS_ROL` and `RMS_PUB`, then exited with SIGSEGV / code 139 after the game printed `CHANNEL_FLAG=======3`. Protected JamVM/glibj hashes remained unchanged.

A single PNG diagnostic then exercised the first two startup resources from the locked game itself:
- `/bin/move_logo.png` — PASS, 101x75;
- `/bin/process.png` — PASS, 125x7 with transparency;
- diagnostic exit code 0;
- protected hashes PASS.

The required parent rerun was then performed with trace-only image/decode markers. It decoded and returned `/bin/move_logo.png`, `/bin/process.png`, `/bin/logo_1.png` and `/bin/logo_2.png`; missing `/bin/logo_3.png` followed the expected IOException/null path. The first meaningful Java failure was instead:

```text
Exception in thread "Thread-1" java.lang.NoClassDefFoundError: w
Caused by: java.lang.LinkageError: duplicate class definition
    at java.lang.VMClassLoader.defineClass(Native Method)
    at java.lang.ClassLoader.defineClass(ClassLoader.java:186)
    at org.recompile.mobile.MIDletLoader.loadClass(MIDletLoader.java:594)
    ...
    at l.paint(Unknown Source)
```

Another game thread continued loading `/bin/firefly.png` after that exception, and the device then hung and required a hard reset. Per project policy, that tested build is `FAIL`.

Historical RG35XX logs contain the same `NoClassDefFoundError` + `LinkageError: duplicate class definition` pattern in Canvas/EventProcessing/showNotify paths, so this is treated as a recurring class-loader concurrency boundary rather than a game-specific workaround.

## Evidence-driven A6 adapter delta

Pinned Aweigit `MIDletLoader.loadClass(String)` delegates platform/vendor namespaces as before, but its custom MIDlet game-class path instruments and calls `defineClass(...)` without a `findLoadedClass(name)` guard and without serialization around that path.

The A6 disposable-source overlay therefore makes exactly two generic changes to that one-argument game-class loader entry:
1. serialize `loadClass(String)`;
2. return `findLoadedClass(name)` when another thread has already defined the class before the instrumentation/define path.

No game-specific class names are hard-coded. Canonical upstream gitlink remains pinned and unmodified. A5 Core2D semantics, JamVM, glibj, input native and video native are unchanged.

Prechange classification:

```text
CURRENT_INTEGRATION_FAILURE=A6 parent hard-hangs; first Java failure is NoClassDefFoundError:w caused by LinkageError duplicate class definition in MIDletLoader.loadClass.
AWEIGIT_CANONICAL_BEHAVIOR=Pinned MIDletLoader instruments/defineClass-es game classes directly; no findLoadedClass guard and no synchronization around define.
RG35XX_DEVICE_CONTRACT=A5 display/input/Core2D/RMS contracts remain protected; hard reset is FAIL.
HISTORY_FOUND=Same duplicate-class-definition pattern appeared in earlier RG35XX Canvas/EventProcessing/showNotify paths.
CURRENT_DIVERGENCE=Concurrent game and Canvas/EventProcessing threads can request the same obfuscated game class before either define completes.
PROPOSED_ADAPTER_DELTA=Disposable-source overlay: serialize game-class load and return findLoadedClass before instrument/defineClass; no game-specific names.
REGRESSION_RISK=Low-to-moderate; affects custom MIDlet game-class loader path only; platform/java/javax/vendor delegation remains unchanged.
PARENT_TEST_TO_RE-RUN=Exact locked Vua-Cuop-Bien-240x320.jar A6 real-game regression.
```

## A6 class-loader candidate build

A6 branch head used by CI: `edbeb926ffe0caf60a6dd7cc10e762f16592f2b1`

GitHub Actions run: `35876072666`

Result:
- A4 raw2D staging: PASS
- exact ARMv5/EABI5/soft-float native build: PASS
- accepted A5 Core2D staging: PASS
- A6 class-loader staging: PASS
- A6 Java6 class-major gate: PASS (`50`)
- synchronized/findLoadedClass bytecode gate: PASS
- canonical gitlink clean/scope lock: PASS
- accepted input/video native hash lock: PASS
- artifact upload: PASS

Fixed candidate hashes:
- platform JAR: `2bf2ff422156cb60f0fb46149c70468c2e72854207a3822ee4cd4361aefb9a94`
- input native: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- video native: `9094819d7c81576b63bd0cde9531404a3fb82b8d5b845dbae152152f2e1a2a7a`
- CI artifact ZIP: `59915cb282cd010190d8a5d10d2470f14f5fdfd801005ec14d69f5f4609cbf33`
- CI artifact ID: `10756728471`

This establishes `BUILD-PASS` only. The same locked Vua Cuop Bien parent test must be rerun on the original RG35XX before any DEVICE-PASS decision.

## Other evaluated candidates

- `NinjaSchool1.jar`: `REJECTED_OUT_OF_SCOPE` — Media + SMS + Bluetooth/device identity.
- `Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`: `CONDITIONAL_FALLBACK` — clean core coverage but active MMAPI MIDI.
- `KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`: `REJECTED_OUT_OF_SCOPE` — Media + HTTP payment + SMS/payment stack.

## Evidence required

Capture production/adapter and canonical identities, platform/native hashes, protected JamVM/glibj hashes before/after, locked game SHA256, runtime log, and human observations for boot/render/input/basic gameplay/RMS/normal exit.

`BUILD-PASS != DEVICE-PASS != STABLE`.
Only original RG35XX evidence can promote the A6 real-game gate.

## Failure handling

If the fixed parent still fails, identify the first meaningful boundary from that same parent run and compare it against pinned Aweigit plus A5 device-proven contracts. Do not replay DP patches. Do not patch SMS/network/media behavior under A6. Do not create an endless micro-checkpoint chain.

## Current status

A4_LEVEL1_DEVICE_PASS=YES
A5_R2_DEVICE_PASS=YES
A5_REGRESSION_CONFIRMATION=PASS
A5_PRODUCTION_MERGE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
A6_CORPUS_VUACUOPBIEN=PRIMARY_LOCKED
A6_PARENT_BASELINE_RESULT=FAIL_HARD_RESET
A6_FAILURE_OWNER=MIDLETLOADER_DUPLICATE_CLASS_DEFINITION_RACE
A6_CLASSLOADER_FIX_BUILD_PASS=YES
A6_CLASSLOADER_FIX_DEVICE_PASS=NO_PENDING_PARENT_RERUN
A6_REAL_GAME_REGRESSION=PENDING
AUDIO=HOLD
MEDIA=HOLD
STABLE=NO
FULL_PLATFORM_STABLE=NO
