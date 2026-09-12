# VC7R23 — Audio Worker-Ring Reconstruction

Status: FORENSIC-LOCKED / IMPLEMENTATION-PENDING / HARDWARE-TEST-REQUIRED
Date: 2026-09-12

## Why this checkpoint exists

VC7R22 is CI-PASS for Java hot-path cleanup, but the retained Actions history does not contain an exact device-proven Golden/CN native core that can be accepted by SHA256.

Accepted identities remain:

- Golden: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- CN short-prime: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`

Rejected retained builds include:

- Golden G1 ARM source-build: `ad67a349652985daac342843867c2343c176940c173a0439a0eda34d566de5e5`
- CN commit source-build: `9f154a096d52745406621e5ab0365eaa1768712305c4b9deb38723dfe2369523`

The exact CN commit `7b7e91516d16a1988bae7bd907bacaecdf2fa972` has only one retained Actions artifact and it is the rejected source-build above.

## Historical worker ownership recovered from source history

The repository still contains the historical independent audio drain worker design in `patches/0015-libretro-native-media-runtime.patch`.

Relevant history:

- `fc14d1dd6b83011a37e3c054e464fc9160fa6595` — materialize native media runtime and audio drain worker
- `c965930de752f945f59c28dd6d1a7eed8f8c4f54` — parent audio drain ownership repair
- `544be0a6f815bc4ca7b857987e309ec25c3cf704` — start audio drain only in parent after handoff
- `086d4987c0d60b5eb9abc3887e73638b24a1b964` — anchor parent drain inside audio-ready block

At `544be0a`, the retained consolidated ARM workflow failed before core compilation and uploaded only a tiny build-evidence artifact, so it cannot supply the device-proven core binary.

## Confirmed regression in current VC7R3 overlay

`scripts/vc7r3_apply_native_audio.py` currently:

- defines `RG35XX_AUDIO_FRAMES_PER_RUN 735u`
- calls `rg35xx_pump_media_audio()` directly from `retro_run()`
- drains Java audio commands, renders mixer audio and invokes `AudioBatch()` from game/render cadence

This violates the device-proven architecture where audio lifecycle is independent from frame cadence.

## Confirmed TSF source mismatch

`native/rg35xx_tsf_worker.c` currently uses:

- `RG35XX_TSF_RATE 44100u`
- stereo interleaved TSF output
- `RG35XX_TSF_RENDER_FRAMES 1024u`

The device-proven contract is instead:

- async libretro audio callback
- dedicated worker
- ring buffer `16384` frames
- MIDI prime target `3072`
- worker chunk `1470`
- TSF synth `14700 Hz`
- final output `44100 Hz`
- mono-x3 staging/conversion
- PCM prime approximately `2940`
- PCM underrun -> re-prime
- native END_OF_MEDIA / BGM resume
- no `retro_run()` audio pumping

## Media startup contract remains locked

Do not regress the stable boot policy:

- Lazy Media ON
- eager `prepareMediaEngine()` OFF
- MediaWarmup OFF
- `/dev/snd/seq` startup probe OFF
- JavaSound `MidiSystem.getSequencer()` must be bypassed on RG35XX

## Reconstruction rules

1. This phase is a reconstruction from device evidence + historical source ownership, not a Golden binary recovery.
2. Any produced `.so` must be labeled `RECONSTRUCTED / HARDWARE-TEST-REQUIRED` unless its SHA256 unexpectedly matches an accepted exact Golden/CN identity.
3. The implementation must first remove `retro_run()` pumping and restore independent parent-side command drain ownership.
4. Audio generation/output must then be moved to the async callback + worker-ring path using the locked constants above.
5. Native media events and PCM re-prime behavior must be preserved.
6. VC7R21 graphics/transparency and VC7R22 Java hot-path cleanup are outside this checkpoint and must remain unchanged.

## CI acceptance gates for the reconstructed build

The future VC7R23 build must fail if any of these are true:

- `rg35xx_pump_media_audio()` remains called by `retro_run()`
- no independent parent drain worker is present
- ring size differs from 16384
- MIDI prime differs from 3072
- worker chunk differs from 1470
- TSF synth rate differs from 14700
- output contract differs from 44100 / mono-x3
- Lazy Media startup is lost
- RG35XX Java path can reach `MidiSystem.getSequencer()`

## Device acceptance (not yet claimed)

- short `playTone` audible
- long MIDI audible and stable
- PCM audible; underrun re-primes
- ToneControl audible
- native END_OF_MEDIA observed
- BGM resumes correctly
- no load stall caused by audio startup
- no `/dev/snd/seq` boot probe
- no `NoSuchMethodError: getSequencer`
- `freej2me-core.log` shows callback/worker/ring/prime markers matching the locked contract

Do not mark GOLDEN, STABLE, or DEVICE-TEST-PASS before hardware evidence.
