# RG35XX Media Engine 2.0 — Beta 3 Architecture

## Why Beta 3 exists

The generic FreeJ2ME media implementation is broader than the RG35XX target runtime. Upstream `Manager.getSupportedContentTypes()` advertises formats such as AMR and MPEG even though the proven RG35XX/JamVM/native path does not currently provide equivalent target decoders for all of them. Real JAR analysis shows that this is not cosmetic: games can query capabilities and choose one of several packaged formats.

Media Engine 2.0 therefore separates **MMAPI semantic compatibility** from **target decode/mix capability**.

## Rules

1. Never advertise a target codec solely because desktop FreeJ2ME can instantiate it.
2. Never use JavaSound Clip/Synthesizer as the required RG35XX backend.
3. Keep `Manager.prepareMediaEngine()` disabled on the libretro target.
4. Preserve native asynchronous audio callback/ring architecture.
5. Preserve native MIDI END_OF_MEDIA truth.
6. Do not contaminate Java stdout; it remains video/control binary IPC.
7. Eliminate SD media staging only after a separate transport is structurally safe.
8. Do not invent audio for a JAR that contains no playable audio path/assets.

## Capability model

`RG35XXMediaProfile` becomes the authoritative RG35XX capability table.

Initial Platform 1.0 target:

| Family | Advertise | Backend |
|---|---:|---|
| MIDI | yes | native TinyMidiLoader/TinySoundFont path |
| WAV PCM 8/16 | yes | RG35XXWavDecoder -> native PCM |
| WAV IMA ADPCM | yes | RG35XXWavDecoder -> PCM16 -> native PCM |
| WAV A-law | yes | RG35XXWavDecoder -> PCM16 -> native PCM |
| WAV mu-law | yes | RG35XXWavDecoder -> PCM16 -> native PCM |
| Tone | yes | target tone/native-compatible path |
| AMR | no | no proven RG35XX decoder yet |
| MPEG/MP3 | no | generic desktop implementation is not target proof |
| 3GP/video | no | outside current audio backend |

MLD/MMF/iMelody require a separate distinction: a container may be convertible into MIDI/PCM by Java-side decoders, but it must not be advertised as natively supported until its conversion path is audited on JamVM and the real-game corpus demonstrates a need.

## Player architecture

```text
javax.microedition.media.Manager
          |
          v
   PlatformPlayer facade
          |
          v
   RG35XXMediaRegistry
     |      |      |
     |      |      +-- lifecycle / media time / loop / volume
     |      +--------- stable player ID
     +---------------- target type/capability
          |
          v
  RG35XX audio transport
     | registration: immutable media blob once
     | command: PLAY / STOP / PAUSE / SEEK / VOLUME / RELEASE
          |
          v
 native media registry/cache
     |                    |
     +-- MIDI contexts    +-- PCM voices
             \              /
              native mixer
                   |
              audio ring
                   |
        libretro audio callback
```

## Transport design constraint

The current Java stdout channel already carries binary frame/control protocol. Large audio blobs must not be inserted into that stream opportunistically.

Preferred Beta 3 direction is a dedicated inherited pipe/file descriptor created by the native core before `execvp(jamvm, ...)`. Java receives the descriptor number as a system property and writes a small framed binary audio protocol to that descriptor. If GNU Classpath/JamVM cannot safely expose an inherited descriptor without extra JNI, the fallback is a tiny target JNI bridge rather than SD-file staging.

No existing SD bridge is removed until this channel has a complete lifecycle and rollback path.

## Proposed audio protocol

The protocol is versioned independently from video IPC.

```text
header:
  magic        4 bytes
  version      1 byte
  opcode       1 byte
  playerId     4 bytes
  payloadSize  4 bytes

opcodes:
  REGISTER_MIDI
  REGISTER_PCM16
  PLAY
  PAUSE
  STOP
  SEEK_US
  SET_VOLUME
  SET_LOOP_COUNT
  RELEASE
```

Registration is immutable. A game that repeatedly starts the same Player should not repeatedly copy the media blob or reread it from SD.

## Native registry/mixer limits

The RG35XX Original is CPU constrained. Media Engine 2.0 will not instantiate an unlimited synthesizer per Java Player.

Initial design target:

- one primary MIDI/BGM context
- one bounded MIDI SFX context where corpus evidence requires simultaneous MIDI
- bounded PCM SFX voices
- per-player volume/state
- deterministic voice stealing if the bound is exceeded
- existing asynchronous worker/ring remains the only final audio producer

The exact voice count is not frozen until static cost analysis is complete.

## Real-JAR acceptance matrix

### Diamond Rush
- PCM WAV path must play without JavaSound Clip.
- MMAPI lifecycle and RMS/game timing must not be blocked by decode.

### Asphalt 4
- MIDI must remain stable.
- PCM WAV and IMA ADPCM WAV must normalize to PCM16.
- VolumeControl must map to the correct player/voice.
- packed media must not require permanent extracted files.

### Zombie Infection
- truthful capability reporting is mandatory so the game does not prefer AMR/MMF merely because Manager claims support.
- available MIDI/WAV alternatives must remain selectable.

### Prince of Persia — The Two Thrones
- packed MIDI/PCM resources and Player lifecycle are regression targets.

### God of War — Betrayal
- multiple MIDI resources/player transitions are a registry/lifecycle regression target.

### Vua Cướp Biển
- no platform change may fabricate audio where the audited JAR contains no actual audio implementation/assets.

## Beta 3 completion gate

Beta 3 is not complete until:

- Manager capability reporting is target-specific
- Player registry semantics are defined and integrated
- dedicated audio transport is implemented or a documented target-safe equivalent exists
- native immutable media cache exists
- PCM/MIDI mixer lifecycle is bounded
- END_OF_MEDIA remains correct
- no hot-path SD media staging remains in the new path
- six-JAR static regression matrix passes
- protocol/tasklog/rollback documentation is complete

No real-device build is requested before the consolidated Platform 1.0 stage is ready.
