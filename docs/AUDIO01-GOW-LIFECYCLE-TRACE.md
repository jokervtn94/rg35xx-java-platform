# AUDIO-01 — God of War lifecycle trace only

## Evidence basis

- A8 Golden and COMP-02 both reproduce the same physical behavior: menu audio is audible, an initial gameplay audio segment is audible, then audio becomes silent.
- Therefore the loss of audio is not attributable to the COMP-02 `PlatformGraphics.fillTriangle` patch.
- The graphics owner remains closed. AUDIO-01 is a separate owner.

## Diagnostic hypothesis

Aweigit's canonical SDL_mixer JNI and the RG35XX SDL1 adapter both use the single SDL_mixer music channel for MIDI. Each new MIDI play halts the current music first. Multiple MMAPI Players may therefore interact through one global music channel. This is a hypothesis only until lifecycle trace proves the sequence.

## Scope

This branch is diagnostic-only.

Allowed delta:
- `libaudio.so`: logging only around MIDI/WAV load/play/pause/resume/stop/isPlaying/free/callback/quit.

Protected and unchanged:
- COMP-02 Java platform JAR.
- `PlatformGraphics.class` and all graphics logic.
- input native owner.
- video/presenter native owner.
- JamVM.
- glibj.
- A1P5 audio prime boundary.
- game code and game-specific behavior.

The trace must not change playback control flow intentionally. No AUDIO-01 fix is accepted from this branch.

## Target physical test

Exact corpus:

`God-of-War-Betrayal_J2ME_EN_v148.jar`

SHA256:

`e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98`

Run until well after the point where audio becomes silent, then exit normally and preserve the complete runtime evidence.

## Acceptance of this diagnostic

The diagnostic is useful only if:

- the game behavior remains comparable to the non-trace run,
- the runtime log contains ordered `RG35XX_AUDIO01_TRACE` events,
- protected identities remain unchanged,
- root cause is not declared until the trace sequence supports it.
