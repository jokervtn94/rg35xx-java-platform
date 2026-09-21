# B4-DRAGON-MEDIA-TRACE-R1-AB

Status: BUILD-PASS / DEVICE-TRACE-PENDING / STABLE=NO
Primary variable: BOUNDED_MEDIA_LIFECYCLE_OBSERVABILITY_ONLY

## CURRENT_SYMPTOM

With the two proven zero-length Dragon Mania RMS stores quarantined:
- the previous RecordStore StringIndexOutOfBoundsException storm disappears;
- Dragon Mania still freezes at the Gameloft logo on the physical RG35XX LCD;
- no RG35XX-VIDEO JAVA error is emitted;
- current Java error log contains only bounded startup/lazy-media markers.

## HISTORY_FOUND

Historical real-device evidence for the same dragon-mania-s40v6.jar shows a prior platform session that:
- received 2493 video frames;
- played multiple native audio streams;
- emitted native END/STOP media lifecycle events;
- remained active far beyond the Gameloft splash.

Historical audio tasklogs also show that the device-proven media architecture used a native worker/ring and did not depend on JavaSound startup probes.

Current clean B4 intentionally includes:
- eager Manager.prepareMediaEngine() disabled at MIDlet boot;
- no admitted native media implementation.

Pinned upstream Manager/PlatformPlayer reality:
- Manager.exclusiveSynths[] is populated by prepareMediaEngine();
- B4 skips prepareMediaEngine() at boot;
- midiPlayer.prefetch() later calls prepareMidiSubsystem(), which expects Manager.exclusiveSynths[synthIdx];
- JavaSound MidiSystem.getSequencer() / AudioSystem.getClip() remain in the lazy request path.

This makes media lifecycle a high-priority regression candidate, but it is not yet proven as the current freeze cause.

## PREVIOUS_FIX

Historical worker-ring/native media restored independent media progression and END_OF_MEDIA handling, but the exact device-proven binary is not being reintroduced blindly.

## PREVIOUS_EVIDENCE_LEVEL

- historical same-game successful long frame/media session: DEVICE-EVIDENCE
- B4 RMS exception storm removal: DEVICE-PASS for that symptom
- current Gameloft-logo freeze cause: UNRESOLVED
- exact Golden/CN audio binary recovery: unavailable in current retained artifacts

## REGRESSION_RISK

Do not change media behavior yet.

Preserve:
- B4-VIDEO-MASK-R2 DEVICE-PASS behavior
- B4-HOTPATH-R2 DEVICE-PASS behavior
- current protected B4 native core
- quarantined corrupt RMS state
- JamVM L
- GNU Classpath
- input
- screenshot baseline state
- audio/media behavior exactly as current runtime

Trace logging must be bounded and only occur on media lifecycle transitions, never per frame.

## MINIMAL_PROPOSED_CHANGE

Runtime-only trace:
- Manager.createPlayer stream/locator begin/done
- PlatformPlayer realize/prefetch/start state transitions
- MIDI getSequencer and prepareMidiSubsystem boundaries
- current exclusiveSynths[0] null/ready state
- WAV AudioSystem.getClip boundary
- Player listener events, including END_OF_MEDIA

No behavior change is allowed.

## EXPECTED_DEVICE_TEST

Keep the two corrupt Dragon Mania RMS stores quarantined.

Install trace runtime and run Dragon Mania until the Gameloft-logo freeze is visible.

Diagnostic acceptance:
1. installer only accepts exact current B4-HOTPATH-R2 runtime and protected B4 core/JamVM/glibj;
2. trace identifies whether Dragon Mania reaches media creation/prefetch/start;
3. if MIDI/WAV path is entered, trace identifies the last completed media boundary;
4. if no media path is entered, media is deprioritized and the next trace moves to Display/Canvas/game-loop state;
5. no hard hang/reset introduced by trace;
6. no per-frame log flood.

BUILD-PASS does not imply DEVICE-PASS.
STABLE remains NO.


## Build result — 2026-09-21

- source commit: 1734e73ca220ba2aa6a93cf512034e48a4c22950
- workflow/run ID: 35568159431
- job ID: 106234015560
- artifact ID: 10625430940
- artifact digest / ZIP SHA256: e43fea8475b21761d1dcc9e01f50401f0246fd1c7964b6cccd557f0f57ea2033
- runtime SHA256: fb719a9b841c7314c963b7f99959edf16f83b351f2c0272f1106046f67b9d462
- required protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java class count: 1334
- Java major 50 gate: PASS
- bounded media trace source gate: PASS
- media trace inner-class bytecode gate: PASS
- current Video Mask R2 source: reproduced/preserved
- current Hotpath R2 source: reproduced/preserved
- media behavior change: NONE
- RMS behavior change: NONE
- native core packaged: NO
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TRACE-PENDING
- STABLE: NO


## Installer v1 quarantine-marker failure and v2 fix — 2026-09-21

Observed failure:
B4-DRAGON-MEDIA-TRACE-R1 INSTALL FAIL: RMS R2 quarantine result missing.

Evidence reconciliation:
The previously collected B4-RMS-R2-QUARANTINE-EVIDENCE-20260921-131214.zip contains:
- RG35XX-B4-RMS-R2-QUARANTINE-RESULT.txt
- RESULT=PASS
- quarantine folder: H:\RG35XX-JAVA-BACKUP\b4-rms-r2-quarantine-20260921-131022
- quarantined metadata count: 2
- quarantined payload count: 2
- remaining Dragon Mania metadata count: 6
- protected platform hashes unchanged

Therefore the v1 install refusal was caused by depending on a single root marker file that is no longer present, not by evidence that quarantine was undone.

v2 installer quarantine verification:
1. use root RESULT=PASS marker when present;
2. otherwise locate the single active Dragon Mania RMS directory;
3. require both known zero-length metadata stores to be absent;
4. require exactly six Dragon Mania metadata stores to remain;
5. locate newest b4-rms-r2-quarantine-* backup with MANIFEST.csv;
6. require manifest to contain exactly 2 META + 2 PAYLOAD rows for the known store basenames;
7. hash-verify all four backup files before allowing trace runtime installation.

v2 package:
- commit: 2804c0605637e712c254ef130f0b6f4a2511e939
- workflow/run: 35569712213
- artifact: 10625318983
- artifact SHA256: 8c97bf5dce4ae8874dd8447663bd2b005f062639e9722435259d6bf84c9c6078

No media/core/RMS behavior change is introduced by this installer-tooling fix.
