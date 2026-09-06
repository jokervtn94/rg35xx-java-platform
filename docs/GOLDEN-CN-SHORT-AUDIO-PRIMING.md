# Golden CN — Short Audio Priming / Audible playTone

## Device evidence

On CM, `Manager.playTone()` returns successfully and the native MIDI path parses the generated one-note SMF. Device log repeatedly reports e.g.:

- `PLAY id=7 loops=0 len=177ms notes=1 ...`
- `native END id=7`
- `STOP id=7`

but the user hears no tone.

Longer MIDI/ToneControl material logs `PRIMED queued=13230 target=12288` before playback, while the 177 ms `playTone` events never log `PRIMED`.

At 44.1 kHz, 12288 frames is about 278.6 ms. A 177 ms one-shot can only synthesize about 7806 output frames, so it cannot ever reach the normal ring prime target before END_OF_MEDIA. The current state machine can therefore complete and stop a short one-shot before the frontend consumes any audible samples.

## CN fix contract

Do not lengthen or alter the MIDP tone itself. Fix native playback ownership instead.

1. Keep the normal large prime target for long BGM/MIDI.
2. For finite one-shot media whose total rendered frame count is smaller than the normal prime target, use a short-media prime target bounded by the media's available/estimated output frames.
3. A one-shot that reaches logical END must not be destroyed while its audio ring still contains queued samples. Transition to DRAINING, continue feeding the libretro audio callback, and emit native END_OF_MEDIA only after the queued tail has been consumed (or an explicit stop/close occurs).
4. Never clear the ring merely because the synthesizer reached the MIDI end marker.
5. Explicit STOP/CLOSE may flush immediately.
6. Add diagnostics: `SHORT-PRIME`, `DRAIN start`, `DRAIN end`, and queued-frame counts.

## Acceptance

- 177 ms `Manager.playTone()` must be audibly heard on RG35XX.
- Repeated playTone calls must not leave stale tails or overlap after explicit replacement.
- MIDI and ToneControl must keep their current PASS/END_OF_MEDIA behavior.
- Long game BGM must retain the normal high prime target.
- PCM/WAV should use the same drain semantics so short samples can reach audible output and END_OF_MEDIA reliably.

The comprehensive test's current `MEDIA_PLAYTONE PASS` means only that `Manager.playTone()` returned without exception; it is not an audible-output assertion and must not be treated as device audio PASS.
