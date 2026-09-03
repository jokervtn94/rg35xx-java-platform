# RC1 ToneControl / Manager.playTone Audit

Status: **STATIC-AUDIT-PASS for the JavaSound-free tone stage only.** Not BUILD-PASS and not DEVICE-TEST-PASS.

Task: `RGJ-RC1-010M`.

## Exact responsibility

This stage adds one new RG35XX responsibility only: deterministic MIDP ToneControl A-BNF to Standard MIDI File conversion. Repository search found no existing RG35XX tone-sequence encoder. The public ToneControl interface and PlatformPlayer control/listener ownership remain upstream.

Source: `src/org/recompile/mobile/RG35XXToneSequenceEncoder.java`.

## Specification basis

The encoder follows MIDP 2.0 ToneControl rules:

- VERSION 1 first;
- optional TEMPO 5..127, default 30 (120 BPM);
- optional RESOLUTION 1..127, default 64;
- block ids 0..127;
- PLAY_BLOCK references a previously defined block;
- SET_VOLUME 0..100;
- REPEAT multiplier 2..127 followed by one tone event;
- note 0..127 or SILENCE;
- duration 1..127.

Block definitions are definitions only. Playback occurs through main sequence events/PLAY_BLOCK expansion. Earlier-block-only references make the expansion dependency acyclic; an explicit expanded-event ceiling prevents hostile expansion.

## Timing proof

The generated SMF uses:

- PPQ = ToneControl resolution;
- four MIDI ticks per ToneControl duration unit;
- BPM = tempo modifier × 4.

MIDI duration therefore becomes:

`duration × 4 / resolution × 60 / tempo` seconds,

which is algebraically identical to the MIDP duration rule.

No wall clock or Java timer participates in ToneControl sequence playback.

## SMF output

The output is Standard MIDI File format 0 with one track. It uses channel 0 NOTE_ON/NOTE_OFF, controller 7 for SET_VOLUME, tempo meta event, and end-of-track. SILENCE advances MIDI time without creating a sounding note.

The target file is consumed by the same native TML/TSF backend already used for direct MIDI; no second synth is introduced.

## Validation / failure policy

Malformed attributes, parameter ranges, block pairing, invalid forward/undefined block references, invalid notes/durations and expansion overflow raise `IllegalArgumentException`. `setSequence()` remains responsible for the MIDP state rule that PREFETCHED/STARTED players reject sequence replacement with `IllegalStateException`.

The encoder is Java 6 style and imports only `java.io.ByteArrayOutputStream` plus the existing MIDP ToneControl constants. It has no javax.sound.midi/javax.sound.sampled/java.util.concurrent dependency.

## Manager.playTone

A separate `encodeSingleTone()` path creates an SMF with exact millisecond ticks. Platform integration preserves the current upstream compatibility choice that requested durations below 50 ms use 50 ms effective duration before encoding. Manager keeps one transient native player and replaces/releases the prior transient tone, preserving the existing single-current-tone behavior without a Java sleep thread.

## PlatformPlayer integration

Patch `0019-platformplayer-tonecontrol-rg35xx.patch` keeps the existing PlatformPlayer nested ToneControl as the public Control owner. On RG35XX it converts A-BNF using this encoder or accepts an already-converted MThd sequence, then calls `RG35XXNativePlayer.setMidi()` before prefetch.

The RG35XX `device://tone` constructor must branch before upstream desktop `midiPlayer` construction. `device://midi` live MIDI control is explicitly not promoted by this stage because current native protocol owns complete MIDI blobs rather than arbitrary live short messages.

## Capability result

After this stage `RG35XXMediaProfile` may truthfully advertise `audio/x-tone-seq` in addition to direct MIDI/WAV aliases. This promotion does not imply AMR/MPEG/MMF/MLD/iMelody direct support or live `device://midi` control.

## Hot-path result

All tone parsing/SMF allocation occurs during setSequence/playTone setup. No allocation, parser, timer, or Java callback is added to the native render loop.

## Remaining media facade work

The next coherent media stage is vendor/container conversion: audit and route upstream MLD/MMF/SMAF/iMelody-style Java decoders only where they produce a proven MIDI/WAV target representation without requiring desktop audio. Live MIDI-device control remains a separate capability gate if needed by the compatibility matrix.

## Gate result

`RGJ-RC1-010M`: **STATIC-AUDIT-PASS** for JavaSound-free ToneControl/Manager.playTone architecture and the project-owned encoder source.

No whole-media `STATIC-AUDIT-PASS`, BUILD-PASS, or DEVICE-TEST-PASS is implied.
