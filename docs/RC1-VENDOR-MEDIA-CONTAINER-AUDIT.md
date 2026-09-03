# RC1 Vendor/Container Media Audit — RGJ-RC1-010N

Status: STATIC-AUDIT-PASS (capability boundary only)

## Scope
This stage audits upstream container/vendor decoders before allowing any RG35XX capability promotion. It does not rewrite vendor APIs and does not create a second decoder family.

## Exact-source findings

### SMAF/MMF
Upstream `javax.microedition.media.decoders.SMAFDecoder` parses SMAF/MMF and can expose sequence and PCM streams, but its sequence construction/output path imports `javax.sound.midi` and serializes a `Sequence` with `MidiSystem.write`. Therefore the decoder is not a valid JamVM/GNU Classpath RG35XX conversion backend as-is. Native TML/TSF cannot consume the upstream JavaSound `Sequence` object directly.

Decision: preserve upstream decoder for desktop compatibility, but DO NOT advertise `audio/mmf`/SMAF on RG35XX until the conversion owner can emit SMF bytes without JavaSound. Existing PCM substreams do not justify advertising the whole container because mixed sequence+PCM timing/trigger semantics must remain coherent.

### MLD/MFi
Upstream `MLDDecoder` similarly builds `javax.sound.midi.Sequence`/Track state and serializes it through `MidiSystem.write`; it also carries PCM trigger maps. This is not a JavaSound-free RG35XX backend.

Decision: preserve upstream MLD/MFi decoder and vendor facade, but DO NOT advertise `audio/x-mld`/MFi on RG35XX until a byte-level SMF emitter or equivalent native event conversion is implemented and its PCM trigger timing is retained.

### EMS iMelody/eMelody
Upstream `EMSMelodyDecoder` imports and constructs JavaSound MIDI objects (`Sequence`, `Track`, `MidiEvent`, `ShortMessage`, `MidiSystem`). It therefore cannot be treated as an RG35XX-safe converter merely because PlatformPlayer ultimately receives an InputStream.

Decision: do not advertise `audio/x-imy`/EMS melody on RG35XX at this gate. A later replacement conversion may reuse the already audited pure-Java SMF writer approach used by `RG35XXToneSequenceEncoder`, but no silent reconstruction is allowed in this stage.

## Vendor facade policy
Nokia, Siemens, KDDI, DoJa and JBlend facade/listener ownership remains upstream. RG35XX must adapt only the backend after a format has a JavaSound-free conversion path. No vendor API package is replaced or disabled by this stage.

## Capability truth table after 010N
RG35XX advertised: MIDI, WAV/PCM-normalized formats, ToneControl.
RG35XX not advertised: MMF/SMAF, MLD/MFi, iMelody/eMelody, AMR, MPEG/MP3, live `device://midi` short-message control.

This conservative boundary is intentional: upstream support/release notes are evidence that these decoders are useful on full desktop Java, not proof that their current implementation can run on the RG35XX JamVM/GNU Classpath target without JavaSound.

## Performance/lifecycle invariants
- No new audio thread, synth, ring or decoder is introduced.
- stdout remains video-only.
- Existing dedicated audio transport remains the only Java->native audio command path.
- Existing native event return path remains the only native completion path.
- No capability is promoted from file signature alone.
- Container decode may allocate during load/prefetch; native render callback remains allocation-free.

## Gate result
RGJ-RC1-010N is STATIC-AUDIT-PASS for the vendor/container capability boundary. It deliberately closes this stage by refusing unsupported promotion rather than introducing a large unverified decoder rewrite. A future explicit REPLACE/ADD task is required for each JavaSound-free container conversion implementation.

BUILD-PASS and DEVICE-TEST-PASS are not claimed.