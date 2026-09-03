# RG35XX MMAPI Lifecycle — Platform 1.0 Beta 3

## Ownership

`PlatformPlayer` remains the public compatibility facade. It owns MIDP/vendor listener semantics and Control exposure. `RG35XXNativePlayer` owns only target transport/lifecycle delegation. `RG35XXMediaRegistry` owns Java-side identity/state. Native cache/mixer owns playback timing truth.

## State path

```text
UNREALIZED
   | realize
   v
REALIZED
   | prefetch/register immutable blob once
   v
PREFETCHED <----------+
   | start            | stop/pause/native end
   v                  |
STARTED --------------+
   |
   | close
   v
CLOSED
```

Registration is idempotent at the Player level. Repeated `start()` does not resend the full media blob once native registration has succeeded.

## Stop vs pause

`STOP` resets target media time to zero in the current protocol/cache semantics. `PAUSE` preserves media time. PlatformPlayer must choose the operation according to its public MMAPI semantics rather than using them interchangeably.

## Loop count

- `0` is invalid.
- positive N means finite playback count as defined by MMAPI facade semantics.
- `-1` is reserved for infinite looping.
- native mixer is responsible for decrement/restart timing because it owns playback completion truth.

## Volume and mute

Requested level is clamped to 0..100. Mute is facade state: effective native volume is 0 while muted, then previous requested level is restored when unmuted. Volume is per player/voice, not a global synthesizer side effect.

## END_OF_MEDIA

No Java timer may guess completion for native-backed media. Native MIDI/PCM playback reports completion. The Java facade converts that completion into exactly one `PlayerListener.END_OF_MEDIA` notification and transitions from STARTED to PREFETCHED/stopped semantic state as appropriate.

The previously proven native MIDI END command remains the compatibility anchor until the versioned Media Engine event channel explicitly replaces it.

## Failure/rollback

If dedicated audio transport is unavailable before registration, the Platform 1.0 integration may fall back to the legacy bridge while that bridge still exists. A partially registered native Player must never be silently split across both backends. Backend choice is fixed for a Player once prefetch succeeds.

## Game-change cleanup

1. stop/close live PlatformPlayers
2. release their native player IDs
3. clear Java media registry
4. send native RESET
5. detach/close Java audio transport
6. close native pipe/cache during core deinit

This order prevents stale voices/media blobs from surviving into the next MIDlet.
