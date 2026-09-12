# VC7R22-R1 — Golden Worker-Ring Source Reconstruction

Status: **SOURCE + CI HARNESS ADDED / CI + DEVICE TEST PENDING**

## Why this checkpoint exists

VC7R22 recovery scanning proved that neither immutable device-proven audio core is present on the current SD/PC scan:

- Golden core SHA256: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- CN short-prime core SHA256: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`

The current SD aliases resolve to another core and therefore cannot be promoted as a Golden recovery.

## Evidence recovered from repository history

The immutable Golden binary audit and baseline document recover these native owners/contracts:

- `rg35xx_audio_callback`
- `rg35xx_audio_worker`
- `rg35xx_audio_ring`
- `rg35xx_audio_mutex`
- `rg35xx_audio_cond`
- `rg35xx_async_audio_registered`
- asynchronous libretro audio callback
- underrun/re-prime behavior
- native media END/BGM lifecycle

Golden/CN device history records:

- ring capacity: `16384` frames
- worker chunk: `1470` frames
- Golden MIDI prime: `12288` frames
- CN device-proven short-media prime: `3072` frames
- Golden synthesis staging: `14700 Hz` mono then x3 to `44100 Hz`

Commit `7b7e91516d16a1988bae7bd907bacaecdf2fa972` proves the CN binary differs from audited Golden only at the three guarded ARM immediate instructions used to lower the prime threshold from 12288 to 3072.

## Regression identified in source reconstruction stack

The historical source implementation used by VC7R3 is not the Golden worker-ring:

- `native/rg35xx_tsf_worker.c` renders TSF at 44100 Hz stereo.
- `patches/0027-libretro-rg35xx-media-pump.patch` disables the old background drain thread.
- VC7R3 inserts `rg35xx_pump_media_audio()` at `retro_run()` entry.
- it renders exactly `735` frames per run (`44100 / 60`) and calls `AudioBatch` there.

That makes media progress depend on libretro frame cadence and contradicts the Golden architecture baseline.

## R1 scope

R1 restores **audio ownership/lifecycle only**:

1. Remove all audio drain/render ownership from `retro_run()`.
2. Register `RETRO_ENVIRONMENT_SET_AUDIO_CALLBACK`.
3. Run a dedicated pthread audio producer.
4. Make that worker the sole owner of Java media FD draining and `rg35xx_mixer_render()`.
5. Feed a `16384`-frame stereo ring.
6. Use CN prime `3072` and worker chunk `1470`.
7. Async callback consumes ring data and submits via `AudioBatch`.
8. On complete underrun, return to unprimed state and require re-prime.
9. Bound underrun logging.
10. Start worker only after the parent owns the Java media read FD; stop/join worker before media teardown.

## Deliberately NOT changed in R1

R1 does **not** claim byte-identical Golden/CN audio.

The historical source mixer/TSF implementation remains 44100 Hz stereo. The recovered Golden `14700 Hz mono x3` synthesis staging is deferred to R2 because source provenance for an exact reconstruction is not yet sufficient.

R1 also does not modify:

- VC7R21 Java graphics/transparency behavior;
- RGB565 Golden-style native video owner;
- dynamic resolution / Smart-Fit;
- PNG compatibility;
- font rendering;
- input/RMS/lifecycle outside audio ownership.

## Fail-closed source gate

`scripts/vc7r22r1_apply_worker_ring.py` requires the exact VC7R3 generated source shape. It aborts if the fixed frame pump cannot be identified exactly.

Required postconditions:

- `RG35XX-VC7R22R1-WORKER-RING`
- ring `16384`
- prime `3072`
- chunk `1470`
- async callback registration
- worker start/stop markers
- underrun/re-prime marker
- Golden-style RGB565 video owner still present

Forbidden postconditions:

- `RG35XX_AUDIO_FRAMES_PER_RUN 735`
- `rg35xx_pump_media_audio();`
- old run-buffer `AudioBatch` path

## CI artifact policy

Workflow: `.github/workflows/verified-clean-vc7r22r1-worker-ring.yml`

The workflow builds an ARMv5TE/uClibc ELF32 EABI5 soft-float core and packages **only the experimental core**.

It must not replace the accepted VC7R21/VC7R22 Java runtime during this checkpoint.

Artifact name:

`rg35xx-vc7r22r1-worker-ring-core`

Status remains `DEVICE-TEST-PENDING` even after a successful CI build.

## Device acceptance gate

Do not promote R1 until hardware evidence proves all of the following:

1. Core logs `RG35XX-AUDIO: async callback registered=1`.
2. Core logs `worker START ring=16384 target=3072 chunk=1470`.
3. No fixed 735-frame `retro_run` audio ownership is active.
4. `Manager.playTone()` is audible and does not hang the game.
5. MIDI is audible.
6. PCM/WAV is audible and can survive underrun/re-prime.
7. ToneControl follows the native MIDI route; no JavaSound `getSequencer` failure.
8. END_OF_MEDIA reaches Java correctly.
9. BGM restart/resume behavior remains correct.
10. Real games remain responsive while audio is active.
11. VC7R21 graphics/transparency/dynamic resolution/Smart-Fit remain unchanged.

## Next checkpoint

Only after R1 hardware evidence is clean should R2 reconstruct the recovered Golden synthesis staging (`14700 Hz`, mono x3 → 44100) and refine short-tail/draining semantics. No R2 DSP change should be mixed into the R1 ownership test.
