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
On game unload, native media RESET now occurs before clearing the Java registry. This preserves the player-ID namespace until the native command that destroys all blobs/voices has been issued.

### 5. Persistent vs disposable state
- persistent: RMS files and immutable platform/font resources
- disposable per-game: image cache, transform cache, held input/repeat timers, Java media registry, native media blobs/voices, frame generation

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

Beta 6 remains a static integration stage until those exact call sites are assembled and checked.
