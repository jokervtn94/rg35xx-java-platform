# RG35XX Reference Audio Architecture Audit — 2026-09-14

## Purpose

Before changing Audio R2 again, compare the current RG35XX Libretro worker-ring path against two Linux handheld FreeJ2ME implementations that run on constrained ARM devices.

This document is an audit only. It does **not** admit any new runtime behavior and does **not** change DEVICE-PASS/STABLE status.

## Mandatory project-rule preflight

Current symptom:
- Real Football 2015 produces audio on Audio R2 but hard-hangs after first present and requires hard reset.

History found:
- Historical RG35XX device logs show Real Football previously running with worker-ring `16384`, chunk `1470`, TSF `14700 -> 44100 mono-x3`, with a historical prime target `2048` in at least one successful run.
- Later Golden/CN policy standardized MIDI prime `3072` to make short playTone audible.
- Previous tasklogs already rejected frame-coupled `735 frames per retro_run` pumping and eager JavaSound/MediaWarmup paths.

Previous evidence level:
- NoMask green-tint symptom: DEVICE-PASS.
- Historical worker-ring/audio behavior: DEVICE-EVIDENCE / device-proven for specific media behaviors.
- Current R2 whole checkpoint: FAIL for Real Football due hard hang; not DEVICE-PASS.

Regression risk:
- High if video/font/transparency are modified together with audio.
- High if a new JavaSound or frame-coupled audio backend is introduced.
- Medium/high if JNI callbacks are called from native audio threads without strict lifecycle/ownership discipline.

## Reference 1 — aweigit/freej2me-miyoomini

Pinned source inspected:
- repository: https://github.com/aweigit/freej2me-miyoomini
- inspected head: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

Architecture:
- FreeJ2ME standalone Java process.
- SDL2 frontend.
- JNI native libraries for audio and 3D.
- Audio backend uses SDL2_mixer (`libaudio.so`).
- README states tested devices include Miyoo Mini, GKD Mini Plus, RG28XX, RG35XX Plus, RG35XX H, TrimUI Brick, Miyoo Flip, Miyoo A30 and Ubuntu 18.

Important audio details from source:
- `SdlMixerManager` opens SDL_mixer at 44100 Hz, S16LE, stereo, chunk 4096.
- MIDI uses `Mix_LoadMUS` + `Mix_PlayMusic`.
- WAV uses `Mix_LoadWAV` + `Mix_PlayChannel`.
- `Mix_HookMusicFinished` is used for completion callbacks.
- Native callback attaches the current native thread to the JVM before invoking Java completion callback.
- Playback ownership is delegated to SDL_mixer rather than being tied to a game-frame callback.

Strengths for reference:
- No Libretro audio callback dependency.
- No `retro_run`-coupled audio production.
- Native mixer owns playback cadence.
- MIDI and WAV lifecycle is much simpler than the RG35XX command-pipe -> mixer -> ring -> Libretro callback chain.

Risks / non-portable assumptions:
- Uses JDK 17-era JNI headers/runtime model, while RG35XX production runtime is JamVM + GNU Classpath.
- Depends on SDL2_mixer and codecs being present/compatible on the target rootfs.
- Source uses global music state (`currentMusic`) and native-thread JNI callbacks; this is not automatically safe to transplant into JamVM.
- It is reference evidence, not RG35XX DEVICE-PASS evidence for the original 256 MB model.

## Reference 2 — bqcuong/miyoo-j2me

Pinned source inspected:
- repository: https://github.com/bqcuong/miyoo-j2me
- inspected head: `75c79213d0a6472c801d86b8d9264abe02204c40`

README intent:
- Fork/rework of FreeJ2ME-MiyooMini aimed specifically at fixing existing issues, primarily sound effects.
- Targets Onion OS / Miyoo Mini Plus.
- Runtime recommendation is ARM32 JDK 17 (Azul Zulu example).

Audio implementation:
- `PlatformPlayer` routes MIDI to `SDLMixerPlayer(..., ".mid")`.
- WAV/MPEG to `SDLMixerPlayer(..., ".wav")`.
- AMR is routed through the same family.
- `prefetch()` only advances player state; it does not call JavaSound `MidiSystem.getSequencer()` or `AudioSystem.getClip()`.
- Native `PlatformPlayer.cpp` uses SDL_mixer directly.
- MIDI: stop previous music, free previous music, `Mix_LoadMUS`, hook completion, `Mix_PlayMusic`.
- WAV: stop channel 0, free previous chunk, `Mix_LoadWAV`, `Mix_PlayChannel`.
- `org_recompile_mobile_Audio.cpp` lazily initializes SDL audio and opens 44100 Hz stereo chunk 4096.

Strengths for reference:
- Directly avoids the exact JavaSound failures previously seen on RG35XX (`getSequencer`, `getClip`).
- Playback is not coupled to rendering cadence.
- Lifecycle surface is small and easy to reason about.

Risks:
- Uses one global BGM object and one WAV channel in the inspected code; compatibility with games requiring many simultaneous effects is not proven.
- Completion callbacks attach native threads to JVM and keep global refs; lifecycle cleanup must be audited before any JamVM port.
- JDK17 + glibc/hard-float assumptions differ materially from RG35XX JamVM/uClibc ARMv5TE production environment.

## Current RG35XX R2 architecture

Current path:

`Java RG35XXNativePlayer -> inherited audio FD -> native command drain -> native mixer/TSF -> dedicated worker -> 16384-frame ring -> Libretro async audio callback -> frontend`

Current R2 properties:
- dedicated worker
- ring 16384
- MIDI prime 3072
- worker chunk 1470
- TSF 14700 Hz -> 44100 Hz mono-x3
- no 735-frame `retro_run` pumping
- worker lifecycle is tied to Java media FD/process lifecycle, not callback state

Historical project tasklogs already established:
- media events cross the process boundary through a bounded native event queue
- direct writes from audio thread to shared control stream were intentionally avoided
- no second reverse pipe was added
- previous source-consolidation deliberately maintained one native media backend rather than duplicates

## Comparison

| Area | RG35XX R2 | FreeJ2ME-MiyooMini / miyoo-j2me |
|---|---|---|
| JVM | JamVM + GNU Classpath | JDK 17 ARM32 |
| Frontend | Libretro | SDL2 standalone |
| Audio owner | RG35XX worker + ring + Libretro callback | SDL_mixer |
| Frame coupling | Removed | None |
| MIDI decode/playback | TinySoundFont/TML custom native path | SDL_mixer `Mix_LoadMUS` |
| WAV/PCM | custom native media runtime/mixer | SDL_mixer `Mix_LoadWAV` |
| Completion | native event queue -> Java | SDL_mixer native callback -> JNI -> Java |
| Extra buffering | explicit ring/prime policy | SDL_mixer internal buffering |
| Complexity | high | lower |
| Drop-in feasibility on RG35XX original | current production path | low without runtime/rootfs work |

## Audit conclusion

The external references confirm an important architectural principle already supported by RG35XX history:

> Audio must have its own native cadence and must not be driven by `retro_run()` / video cadence.

They **do not** justify immediately replacing the current RG35XX audio backend with SDL_mixer.

Reasons:
1. The reference projects rely on a different JVM generation and JNI environment.
2. The original RG35XX platform is already device-proven with JamVM L + GNU Classpath and should not be replaced casually.
3. Current R2 already follows the same key decoupling principle through a dedicated worker.
4. A full SDL_mixer transplant would change several primary variables at once and violate the project A/B policy.

## Decision before next implementation

Do **not** switch the production branch to standalone JDK17/SDL2 now.

Do **not** replace the current worker-ring with SDL_mixer inside the same checkpoint.

Next minimal checkpoint should remain inside the existing architecture and use historical RG35XX evidence first.

### Recommended next checkpoint

`R2.1-AUDIO-PRIME-AB`

Single primary variable:
- MIDI prime `3072 -> 2048`

Everything else must remain byte-for-byte/functionally unchanged where possible:
- ring 16384
- chunk 1470
- TSF 14700 -> 44100 mono-x3
- NoMask retained
- bitmap font bypass retained
- no video changes
- no drawRGB changes
- no transparency changes
- no PCM policy reconstruction in this checkpoint

Reason:
- historical RG35XX device evidence already exists for Real Football running under the 2048-prime worker-ring family.
- this is a much smaller and better-grounded experiment than replacing the backend.

### Parallel research track (not production)

After R2.1 result, create a separate `EXPERIMENTAL-STANDALONE-SDL-AUDIO` research branch only if needed.
That branch may test whether JamVM can safely load a small SDL2_mixer JNI shim on the RG35XX rootfs, but it must not modify the production baseline until independent DEVICE-EVIDENCE exists.

## Status

- AUDIT: PASS
- BUILD-PASS: not applicable (no runtime source change)
- DEVICE-PASS: NO CHANGE
- STABLE: NO CHANGE
- Production recommendation: continue minimal R2.1 historical-prime A/B first.
