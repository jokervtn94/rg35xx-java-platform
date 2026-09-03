# RGJ-RC1-010N — Vendor/container media capability gate

- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Audit: `docs/RC1-VENDOR-MEDIA-CONTAINER-AUDIT.md`
- Pre-change control reload: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`.
- Exact upstream sources inspected: `SMAFDecoder`, `MLDDecoder`, `EMSMelodyDecoder`, plus existing PlatformPlayer routing evidence.
- Finding: all three upstream conversion families still construct/use `javax.sound.midi` objects and/or `MidiSystem.write`; they are not safe to promote as RG35XX JamVM/GNU Classpath backends merely because upstream desktop FreeJ2ME supports them.
- Decision: preserve all upstream vendor facades/decoders; advertise none of MMF/SMAF, MLD/MFi or iMelody/eMelody on RG35XX at this gate.
- Existing truthful target capability remains MIDI + WAV + ToneControl. AMR/MPEG and live device://midi remain false/unclaimed.
- No new decoder class, vendor package, thread, synth, native ring or transport was added.
- Future JavaSound-free container conversion requires an explicit task and must retain mixed sequence/PCM timing semantics where applicable.
- BUILD-PASS and DEVICE-TEST-PASS not claimed.