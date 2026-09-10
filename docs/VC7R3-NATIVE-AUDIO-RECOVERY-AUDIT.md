# VC7R3 — Native Audio Recovery Audit

Date: 2026-09-10
Base: VC7R2 Proven View
Status: SOURCE-AUDIT / IMPLEMENTATION-PENDING

## Trigger from real RG35XX device

VC7R2 device evidence proves the restored 320x240 logical view and sustained RGB565 frame transport, but real games still hit:

`java.lang.NoSuchMethodError: getSequencer`

at `org.recompile.mobile.PlatformPlayer$midiPlayer.prefetch(...)`.

This is not a reason to modify GNU Classpath. Historical direct probing already established that the admitted GNU Classpath `MidiSystem` does not provide the `getSequencer` API expected by upstream FreeJ2ME's desktop JavaSound MIDI backend.

Therefore VC7R3 must bypass JavaSound MIDI on RG35XX and restore the target-specific native media route that was previously exercised on device.

## Device evidence that constrains the solution

Historical real-device logs from the project show a working target path with markers such as:

- `RG35XX-AUDIO MIDI detected; async native libretro synth bridge`
- `RG35XX-AUDIO BRIDGE async-start`
- `RG35XX-AUDIO BRIDGE PLAY queued`
- `RG35XX-AUDIO NATIVE END_OF_MEDIA`
- native `worker START ring=...`
- `SoundFont loaded`
- `PRIMED queued=...`
- `PCM loaded`
- `native END id=...`

Historical comprehensive-device evidence also reached MIDI END_OF_MEDIA and ToneControl END_OF_MEDIA. These observations establish the behavior to recover; they do not make every old RC1 source file automatically admitted.

## Historical source provenance

The old `golden-clean-rebuild` branch contains the source family designed for this path, including:

### Java side

- `RG35XXAudioBootstrap.java`
- `RG35XXAudioProtocol.java`
- `RG35XXAudioTransport.java`
- `RG35XXMediaProfile.java`
- `RG35XXMediaRegistry.java`
- `RG35XXNativePlayer.java`
- `RG35XXToneSequenceEncoder.java`
- `RG35XXWavDecoder.java`

`RG35XXNativePlayer.prefetch()` routes MIDI/Tone through `RG35XXAudioTransport.registerMidi(...)` and PCM through `registerPcm16(...)`; it does not use `MidiSystem.getSequencer()`.

The direct-media PlatformPlayer patch `0018-manager-platformplayer-rg35xx-direct-media.patch` branches to the RG35XX backend before desktop JavaSound/JLayer construction when the RG35XX platform selector is active.

### Native side

Historical source family includes the dedicated audio pipe/protocol, mixer, MIDI backend, TinySoundFont worker, SoundFont source holder, native media event queue/runtime and dispatch modules.

The old audio-FD patch records the required process contract:

- Java video remains on stdout binary IPC.
- Audio uses a dedicated inherited FD.
- JVM properties include `-Dfreej2me.rg35xx=true` and, only when successfully created, `-Dfreej2me.rg35xx.audio.fd=<fd>`.
- Audio must never share stdout/stderr with frame transport.

The native-media event contract sends END_OF_MEDIA/LOOPED back over the existing core-to-Java control channel and drains those events on the normal update cadence; it does not invent Java timers.

## Important provenance limitation

The old RC1 native-media consolidation checkpoint itself was only STATIC-AUDIT-PASS at that stage. Therefore VC7R3 MUST NOT wholesale merge `golden-clean-rebuild` or label those source files Golden merely because they exist there.

Admission requires rebuilding the smallest compatible subset on top of current VC7R2, then real-device validation.

## VC7R3 strict scope

VC7R3 may change only media plumbing required to restore the target-specific MIDI/PCM path:

1. Java media helper classes and the PlatformPlayer/Manager integration needed to select them on RG35XX.
2. Dedicated audio FD setup/ownership.
3. Native media protocol, mixer/MIDI/PCM worker and event return path.
4. Build-system entries strictly necessary to compile/link those modules.
5. Audio diagnostics needed to prove route, priming, drain and END_OF_MEDIA.

VC7R3 MUST preserve without modification:

- JamVM L SHA `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`.
- GNU Classpath/glibj SHA `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`.
- VC7R2 dynamic logical-size behavior and its `RG35XX-VC7R2-VIEW` markers.
- Golden-style async Java RGB565 FrameWorker transport.
- Native video receiver/double-buffer/Smart-Fit behavior.
- Lazy Media Boot; no eager media warmup or ALSA sequencer probe at boot.
- source-level PNG iCCP compatibility.
- safe bitmap text route.
- game JAR bytes.
- no CV/CW boot-time resolution architecture.

Because native audio restoration changes the libretro core, VC7R3 will necessarily have a NEW core SHA and must be device-tested as a pair with its runtime. The currently accepted VC6 core remains the rollback checkpoint and must not be overwritten in repository history.

## Short media / priming rule

Historical CN analysis found that very short one-shot media can reach logical end before the normal large prime threshold. The recovered implementation must keep long-media priming while allowing a bounded short-media target, drain queued samples before END_OF_MEDIA, and flush immediately only on explicit STOP/CLOSE. This must be validated by ear; a successful `Manager.playTone()` return is not enough.

## Build gates before any installer

A VC7R3 build must prove:

- pinned upstream `13ec186903087156c145268f8706eecfaf9f1e50`;
- all Java classes major 50;
- `PlatformPlayer` RG35XX branch occurs before desktop MIDI construction;
- RG35XX target path contains no call to `MidiSystem.getSequencer`;
- video stdout ownership remains unchanged;
- dedicated audio FD is >=3 and fail-closed when unavailable;
- native core remains ELF32 ARM EABI5 soft-float;
- RGB565 receiver/Smart-Fit symbols remain present;
- VC7R2 logical-view markers remain present;
- PNG iCCP marker remains present;
- eager media warmup remains absent;
- native media worker/event symbols are linked exactly once;
- SoundFont path is explicit `/mnt/mmc/BIOS/freej2me.sf2` or supplied by an already-proven byte-source contract; do not guess another path.

## Device acceptance

Do not call VC7R3 DEVICE-PASS until real RG35XX evidence shows all of:

1. KDTT still sends 320x240 and presents 640x480.
2. 240x320 games still present 360x480 centered.
3. No `NoSuchMethodError: getSequencer`.
4. MIDI is audibly heard.
5. MIDI reaches native END_OF_MEDIA.
6. WAV/PCM is audibly heard and reaches END_OF_MEDIA.
7. ToneControl works.
8. short playTone is audibly heard (not only API PASS).
9. frame transport remains sustained while audio is active.
10. no new font/PNG/JamVM regression.

## Current status

VC7R2 remains the rollback base. VC7R3 audio is now scoped and provenance-audited, but no VC7R3 binary is yet BUILD-PASS or DEVICE-PASS.
