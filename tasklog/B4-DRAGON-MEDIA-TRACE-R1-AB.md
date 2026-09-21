# B4-DRAGON-MEDIA-TRACE-R1-AB

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO
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
