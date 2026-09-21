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


## Installer v2 quarantine-state failure and v3 precondition design — 2026-09-21

Observed v2 failure:
RMS R2 quarantine cannot be verified: expected both corrupt Dragon Mania stores absent, six metadata stores remaining, and a valid 4-file quarantine manifest.

Interpretation:
The v2 message conflated active RMS state and historical backup discoverability. It did not identify which condition failed. Because Dragon Mania had been launched after the original quarantine, the proven zero-length stores may have been recreated; however this was not yet directly observed, so no assumption is promoted to fact.

v3 separates concerns:

ENSURE-B4-DRAGON-RMS-PRECONDITION:
- validates protected baseline hashes;
- locates only the active Dragon Mania freej2me/rms directory, excluding RG35XX-JAVA-BACKUP;
- if the two known store basenames are already absent and exactly six metadata files remain: PASS with no mutation;
- if known store files have reappeared, only zero-length metadata with the exact empty-file SHA256 may be re-quarantined;
- any non-zero metadata at the known basenames causes fail-closed refusal;
- all active files selected for requarantine are copied and hash-verified before removal;
- final state requires zero active files for the two known basenames and exactly six Dragon Mania metadata files.

Media Trace installer v3:
- never mutates RMS;
- validates only the exact active RMS state after ENSURE;
- no longer depends on a historical marker or manifest to install the trace runtime.

v3 build:
- source commit: c4ede37820de262666d9f7249bf3d449c4106320
- workflow/run: 35570953754
- job: 106242287269
- artifact: 10624929780
- artifact SHA256: 84a9432082ca24916333ba2f670a23b69ad55b72c0f938015c46cfdd6f80075d
- runtime SHA256: 44d6bbf894c6f83476f8ff89403ab3f5c205fc1f221dcc174d4f5a7039f91733
- required core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- BUILD-PASS: YES
- DEVICE-TRACE: PENDING
- STABLE: NO


## Active-store reappearance evidence — 2026-09-21

Observed installer v3 refusal:
Known corrupt Dragon Mania store files are active again:
ffffffff9c61314e09vhjlzvf1zxn0.rms

Interpretation:
- the known Dragon Mania RMS store basename has reappeared in the active freej2me/rms directory after the earlier quarantine/device run;
- this is useful evidence that Dragon Mania can recreate at least one of the previously quarantined store paths;
- the installer correctly refused to proceed because it is read-only with respect to RMS state;
- the current evidence does NOT yet establish the recreated file length/content.

Required next step:
Run ENSURE-B4-DRAGON-RMS-PRECONDITION.cmd before the media-trace installer.

ENSURE semantics:
- if the recreated metadata is exactly the previously proven zero-length/empty-SHA state, it is backed up and re-quarantined;
- if it is non-zero or otherwise different, ENSURE fails closed and preserves it for analysis;
- only after ENSURE PASS may INSTALL-B4-DRAGON-MEDIA-TRACE-R1.cmd be run.

No new platform code checkpoint is opened for this event.


## Recreated RMS metadata evidence — 387 bytes — 2026-09-21

User-provided ENSURE log:
- basename: ffffffff9c61314e09vhjlzvf1zxn0.rms
- current length: 387 bytes
- ENSURE refused quarantine because the metadata is no longer zero-length.

Interpretation correction:
The basename itself is not permanently corrupt.
What was proven corrupt earlier was the zero-byte instance of this basename.
Dragon Mania has now recreated the same store path with non-zero metadata, so automatic quarantine by basename would risk deleting newly valid save state.

v4 precondition model:
- ZERO-LENGTH current metadata at the previously corrupt basename => fail closed and require reversible ENSURE/quarantine;
- ABSENT store => allowed;
- NON-ZERO recreated store => parse as JSON, require pinned FreeJ2ME metadata keys, require baseName to match filename, require every ids[] entry to have its payload file and tag:<id> metadata;
- structurally valid recreated metadata => preserve it and allow media trace installation;
- installer never mutates RMS data.

v4 build:
- workflow/run: 35572214074
- job: 106246034128
- artifact: 10626358195
- artifact SHA256: cd78b18d8c315f659585c989c0e8779370c84ef766ddf32b4c999dffc6e43d66
- runtime SHA256: 0c2f8658e7786cd3f97285c94c609623464cb8f04311b359bfd0a95a7109f11e
- protected core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java classes: 1334
- Java major: 50
- bytecode trace gate: PASS
- BUILD-PASS: YES
- DEVICE-TRACE: PENDING
- STABLE: NO


## Device trace result — 2026-09-21 14:50

Evidence package:
B4-DRAGON-MEDIA-TRACE-R1-EVIDENCE-20260921-145020.zip
SHA256: 60c1e845c6f6db61f62958d2ff421bfd4913993fbbac2815ed9430fb94eb45f7

Installed state:
- runtime SHA256: 0c2f8658e7786cd3f97285c94c609623464cb8f04311b359bfd0a95a7109f11e
- protected core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- JamVM L SHA256: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj SHA256: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

RMS state at install:
- RMS_PRECONDITION=PASS
- Dragon Mania metadata count: 7
- ffffffff9c61314e09vhjlzvf1zxn0.rms recreated as structurally valid non-zero metadata
  - length: 387
  - SHA256: b51f52e3639dfa6bfa09b550f4b281356d6b6b1a9c8a57885d36961160906c74
  - ids count: 0
- ffffffff9c61314e14u2hvcf9vbmxvy2tozxc_ absent
- installer RMS mutation: NONE

Device observation:
- dragon-mania-s40v6 remains visually frozen at the Gameloft startup screen.

Native early log contains three sequential test sessions:
1. dragon-mania-s40v6
2. NinjaSchool1
3. 240x320-zombie_infection-s60

Important session correlation:
- Dragon Mania is the first Java session. Its Java stderr contains only FrameTransport startup and the expected "eager prepare SKIPPED" marker.
- Dragon Mania emits ZERO B4 media lifecycle trace records before the user exits the frozen logo screen.
- Therefore Dragon Mania does not reach Manager.createPlayer / Player.realize / prefetch / start in the observed freeze window.

Later sessions must not be attributed to Dragon Mania:
- NinjaSchool1 is the second session and emits 23 repeated GNU java2d AbstractGraphics2D.renderScanline NullPointerExceptions while drawing text from a.paint -> Canvas.repaintRequest -> Display.processEvents.
- 240x320-zombie_infection-s60 is the third session and emits the seven B4 media trace records:
  - MANAGER_CREATE_STREAM_BEGIN audio/midi
  - MANAGER_CREATE_STREAM_DONE
  - PLAYER_REALIZE_BEGIN/DONE
  - PLAYER_PREFETCH_BEGIN
  - MIDI_PREFETCH_BEGIN exclusive0=null
  - MIDI_GETSEQUENCER_BEGIN
  followed by NoSuchMethodError: getSequencer on Thread-1.
- The getSequencer error is therefore a Zombie Infection compatibility blocker, not evidence for the Dragon Mania logo freeze.

Media trace conclusion for Dragon Mania:
- MEDIA-CANDIDATE-AS-LOGO-FREEZE-CAUSE: DEPRIORITIZED / NOT REACHED
- RMS StringIndexOutOfBounds storm: remains absent
- Dragon logo freeze: persists
- MEDIA TRACE checkpoint: DEVICE-EVIDENCE / DIAGNOSTIC PASS
- game compatibility DEVICE-PASS: NO
- STABLE: NO

Next checkpoint:
B4-DRAGON-DISPLAY-TRACE-R1-AB

Primary variable:
BOUNDED_DISPLAY_CANVAS_GAME_LOOP_OBSERVABILITY_ONLY

Rationale:
The next trace must localize whether Dragon Mania:
- enters Display.setCurrent;
- reaches Canvas showNotify;
- requests/dispatches repaints;
- enters/exits the game paint callback;
- flushes frames;
- blocks in serviceRepaints/paintLock;
- receives/delivers input while the logo is displayed.

No media/RMS/core behavior change is allowed.
