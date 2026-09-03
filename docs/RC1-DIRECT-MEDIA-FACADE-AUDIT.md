# RC1 Direct MIDI/WAV Facade Audit

Status: **STATIC-AUDIT-PASS for the direct MIDI/WAV Java facade stage only.** Not BUILD-PASS and not DEVICE-TEST-PASS.

Task: `RGJ-RC1-010L`.

## Scope

This stage closes target selection, truthful direct capability reporting, direct MIDI/WAV backend routing contract, and native LOOPED/END facade state semantics. ToneControl and Java vendor-container conversion are deliberately the next stage.

## Upstream ownership retained

`javax.microedition.media.Manager` remains the API entry owner. `JavaxPlatformPlayer` remains the javax-facing concrete facade and continues to extend `PlatformPlayer`. `PlatformPlayer` remains the Player state/control/listener/vendor-fanout owner.

RG35XX does not replace these classes with parallel javax packages.

## Target selector

`RG35XXPlatformProfile.isActive()` now reads the explicit JVM property `freej2me.rg35xx`. The RG35XX core must pass `-Dfreej2me.rg35xx=true` before `-jar` independently of whether the dedicated audio FD was created successfully.

This closes the prior ambiguity where Manager capability replacement could affect desktop/AWT. Desktop launches without the property retain upstream behavior.

## Capability truth

The current direct target capability list contains only MIDI and WAV aliases:

- `audio/midi`
- `audio/x-midi`
- `audio/wav`
- `audio/x-wav`

`audio/x-tone-seq` was removed from advertised direct support until the JavaSound-free ToneControl conversion stage is complete. AMR/MPEG also remain false. WAV subformats such as IMA ADPCM, A-law and mu-law are capabilities inside the WAV decoder, not separate direct MIME advertisements.

This is stricter than upstream desktop Manager, which advertises formats tied to desktop JavaSound/JLayer/vendor decoders.

## Constructor ordering

Exact upstream PlatformPlayer currently constructs desktop midiPlayer/wavPlayer/MP3Player from the constructor path. On RG35XX, the direct-format branch must execute before those objects are created.

Patch 0018 locks this ordering. Direct MIDI routes to `RG35XXNativePlayer`. Direct WAV routes through `RG35XXWavDecoder` and then `RG35XXNativePlayer.setPcm16()`.

Unsupported RG35XX direct formats may use the existing facade stub/error semantics, but must never fall through to a desktop backend merely because those classes exist at compile time.

## WAV contract

`RG35XXWavDecoder.decode(InputStream)` exists and returns PCM16 bytes plus source sample rate and channels. Native mixer rate conversion remains authoritative. This stage does not add a second resampler.

## Native event semantic correction

A static mismatch was found in current project sources: both registry dispatch and RG35XXNativePlayer previously treated every native event as playback completion.

That was corrected:

- LOOPED keeps `started=true` / player `STARTED`;
- END_OF_MEDIA alone clears started state and moves the backend to `PREFETCHED`.

This matches native ownership: LOOPED is emitted only after an actual intermediate restart, while END is final completion.

## Tone preparation without false advertising

`RG35XXNativePlayer` now has a pre-prefetch `setMidi(byte[])` replacement path, and TYPE_TONE may register converted Standard MIDI File bytes through the native MIDI transport. This prepares the next stage without claiming that ToneControl A-BNF conversion itself is complete.

The direct capability list therefore remains truthful until that converter/facade control is source-audited.

## Desktop compatibility

No desktop capability or JavaSound behavior is removed. Patch 0018 explicitly branches only when `RG35XXPlatformProfile.isActive()` is true. `JavaxPlatformPlayer` remains the Manager return facade.

## Remaining work before full media-facade pass

The full `RGJ-RC1-010` media facade is still open because the next stage must reconcile:

- `Manager.playTone()` without JavaSound on RG35XX;
- `device://tone` and ToneControl `setSequence()`;
- MLD/MMF/iMelody/vendor conversion paths that can produce MIDI/WAV;
- exact PlatformPlayer Control exposure for the native backend;
- application of the integration patch to the assembled upstream source tree.

## Gate result

`RGJ-RC1-010L`: **STATIC-AUDIT-PASS for direct MIDI/WAV facade architecture and project-owned helper semantics.**

No BUILD-PASS is claimed until exact Java source assembly and `rm -rf build && ant` succeed.
