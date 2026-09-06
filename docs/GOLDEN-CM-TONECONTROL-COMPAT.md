# Golden CM — ToneControl Java 6 compatibility

Device evidence from CL shows:

- Golden Unicode font resource loads successfully.
- `MEDIA_PLAYTONE` and `MEDIA_MIDI` reach native END_OF_MEDIA.
- `MEDIA_TONECONTROL` fails with `java.lang.NoSuchMethodError: <init>` inside `PlatformPlayer$toneControl.setupSequence()`.
- The CL bytecode reaches parameterized `javax.sound.midi` constructors (`ShortMessage(int,int,int,int)` and `MetaMessage(int,byte[],int)`) that are not guaranteed by the RG35XX JamVM/GNU Classpath Java 6 runtime.

CM policy:

1. Do not build ToneControl playback through JavaSound `Sequence`, `Track`, `ShortMessage`, or `MetaMessage` objects on RG35XX.
2. Keep the device-proven MIDI native bridge as the playback owner.
3. Convert J2ME ToneControl ABNF to a Standard MIDI File byte array with `RG35XXToneSequenceEncoder.encode(byte[])`.
4. Feed that MIDI blob through the existing MIDI player/native bridge path.
5. Existing Standard MIDI (`MThd`) input may pass through unchanged.
6. Preserve the Golden font renderer and G1 RGB565/Smart-Fit video path.

This matches the intended source-level behavior already described by `0019-platformplayer-tonecontrol-rg35xx.patch`: the clean rebuild must route RG35XX ToneControl through `RG35XXToneSequenceEncoder` + native media instead of relying on desktop JavaSound constructors.

## WAV observation

CL device logs show PCM loaded as 8000 Hz mono 16-bit with 10290 frames, followed by one underrun/re-prime. The test then explicitly stopped/closed the WAV when the user moved to MIDI, so that run does not prove native PCM END_OF_MEDIA failure. Retest WAV for at least 3 seconds without changing media before changing the PCM engine.
