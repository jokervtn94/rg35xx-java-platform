# Beta 6 Consolidated Integration Audit

## Scope
Audit the project-owned RG35XX helper APIs before assembling the consolidated FreeJ2ME source tree.

## Findings and corrections

### 1. Missing project sources
The repository documented Alpha/Beta helper classes that were present in earlier overlay packages but were not yet committed into the project source tree. Beta 6 restores source-controlled versions of:

- `RG35XXFrameScheduler`
- `RG35XXInputEngine`
- `RG35XXImageCache`

This prevents the lifecycle coordinator from depending on undocumented ZIP-only classes.

### 2. Transform cache reset API mismatch
`RG35XXTransformCache` exposes `reset()`, not `clear()`. `RG35XXLifecycle` was corrected to call `reset()`.

### 3. Audio transport reset API mismatch
`RG35XXAudioTransport` exposes `resetNative()`, not `reset()`. `RG35XXLifecycle` now calls `resetNative()`.

### 4. Media reset ordering
On game unload, native media RESET occurs before clearing the Java registry. This preserves the player-ID namespace until the native command that destroys all blobs/voices has been issued.

### 5. Persistent vs disposable state
- persistent: RMS files and immutable platform/font resources
- disposable per-game: image cache, transform cache, held input/repeat timers, Java media registry, native media blobs/voices, frame generation

### 6. Audio bridge startup omission
The first lifecycle implementation started the RMS worker but did not attach the inherited dedicated audio FD. `platformStart()` now calls `RG35XXAudioBootstrap.initialize()` fail-safe. Failure to attach does not redirect audio to stdout and does not abort platform startup; the legacy media route remains the rollback path until RC device validation.

### 7. Defensive pre-load media reset
`beforeGameLoad()` now performs a native RESET when the dedicated audio transport is available, even when no Java game is marked active. This prevents stale native blobs/voices from a failed/partial previous load from leaking into the next MIDlet.

### 8. RMS background failure deadlock risk
The original coalescing writer re-enqueued a failed store immediately. A persistent SD/write error could therefore keep `forceFlush()` waiting forever while the worker retried indefinitely.

Correction:
- background failures move the store to a separate failed set rather than the active queue;
- a force-flush barrier gives failed stores exactly one retry;
- a second failure is surfaced to the caller instead of spinning;
- a later mutation re-queues the store normally;
- `shutdown()` stops/joins the worker even when forceFlush reports an error.

This preserves data-safety signaling while avoiding a platform-shutdown hang.

## Runtime evidence carried into consolidation

Historical RG35XX logs show the actual target is JamVM 2.0.0 reporting Java 1.5 and GNU Classpath boot libraries. Separate probes show desktop MIDI is not a valid dependency (`MidiSystem.getSequencer` unavailable and ALSA sequencer device absent). Existing native TML/TSF playback, audio worker/ring and RGB565 receiver behavior therefore remain the correct target foundations.

These are compatibility facts, not RC BUILD-PASS or DEVICE-TEST-PASS.

## Remaining consolidated-source gates

The following cannot honestly be marked BUILD-PASS until the exact FreeJ2ME tree is assembled with the patches:

1. `PlatformImage` cache hook signatures versus restored `RG35XXImageCache` API.
2. `Libretro.java` input engine adapter signatures.
3. `MobilePlatform` dirty-frame hooks versus `RG35XXFrameScheduler` API.
4. `PlatformGraphics` transform-cache patch call signatures.
5. RecordStore patch application and removal of RG35XX-target `java.nio.file` dependencies.
6. TML/TSF native hook symbol resolution.
7. dedicated audio pipe integration in `freej2me_libretro.c`.
8. lifecycle call sites for load/unload/pause/destroy/deinit.
9. Java/native audio protocol parity in the assembled tree.
10. no duplicate reset/release path capable of producing repeated END_OF_MEDIA or use-after-free.

## Transition to RC1

`docs/RC1-INTEGRATION-MANIFEST.md` is now the authoritative pre-build gate list. Beta 6 remains STATIC-AUDIT stage until every RC1 G1-G12 source gate is resolved against one consolidated source tree.
