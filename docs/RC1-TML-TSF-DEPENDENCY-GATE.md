# RC1 TML/TSF Dependency Gate

Status: STATIC-AUDIT-PASS for dependency/source policy only. Worker and single implementation translation-unit ownership are now present; this is not BUILD-PASS.

Task basis: `RGJ-RC1-010F` in `tasklog/RC1-TASKLOG.md` authorizes RESTORE-BY-REIMPLEMENTATION of the historical native TML/TSF worker while preserving `native/rg35xx_midi_backend.c` as the bounded two-context adapter.

## 1. Current-tree finding

The current `native/` tree contains the RG35XX audio protocol, pipe, dispatcher, media cache, mixer, MIDI adapter, replacement `rg35xx_tsf_worker.h/.c`, and `rg35xx_tsf_impl.c` as the single TML/TSF implementation translation unit.

Repository search before adding `rg35xx_tsf_impl.c` found no existing `TSF_IMPLEMENTATION`/`TML_IMPLEMENTATION` owner, so this ADD does not duplicate an existing implementation responsibility.

The repository still does not contain the pinned `tml.h` and `tsf.h` source inputs or an authoritative SoundFont asset/source contract. Native build therefore remains dependency-blocked until those inputs are assembled.

## 2. Authoritative third-party source pin

Upstream: `schellingb/TinySoundFont`.

Pinned source commit for RC1 dependency review:

`853a0a171759f1ddba0de1442133a75912bbeffa`

Required upstream files at that pin:

- `tml.h` — TinyMidiLoader v0.7, zlib license.
- `tsf.h` — TinySoundFont v0.9, MIT license.

RC1 must vendor exact files from the pinned commit (including upstream license text) or otherwise provide byte-identical sources to the native build. Do not follow moving `main` during a release build.

`native/rg35xx_tsf_impl.c` is the sole project translation unit permitted to define `TML_IMPLEMENTATION` and `TSF_IMPLEMENTATION`. It also defines `TML_NO_STDIO` and `TSF_NO_STDIO`: MIDI and SoundFont data enter through memory APIs, so the third-party layer does not own filesystem paths.

## 3. Implementation ownership

Do not create a second MIDI backend. The existing ownership remains:

`Java media protocol -> rg35xx_media_cache -> rg35xx_mixer -> rg35xx_midi_backend -> rg35xx_tsf_* worker -> TML/TSF`

`rg35xx_midi_backend.c` remains responsible for mapping player IDs to the bounded two-slot adapter and for exposing play/pause/stop/seek/release/mix behavior to the mixer.

The replacement worker is responsible only for the existing `rg35xx_tsf_*` hook contract plus the minimal explicit loop-boundary primitive required by RC1-010E.

## 4. SoundFont ownership gate

Historical runtime logs prove that a SoundFont was loaded and that the stable target configuration used a 14700-Hz synth basis, 44100-Hz platform output and 16 voices. The recovered logs do not identify an authoritative `.sf2` filename/path or provide the SoundFont bytes.

Therefore RC1 must not hard-code a guessed `/mnt/mmc/BIOS/*.sf2` path and must not silently bundle an unrelated SoundFont.

Before the worker can become BUILD-PASS, consolidated `freej2me_libretro.c` must provide one explicit SoundFont initialization owner. The accepted source must be one of:

1. an exact project-owned SoundFont file/path established by recovered source or device layout evidence; or
2. an explicit core configuration/input contract recorded in Tasklog before implementation.

Until one is proven, worker code exposes `rg35xx_tsf_worker_init(soundfont, size)` and fails cleanly when no SoundFont is supplied.

## 5. TML timeline contract

`tml_load_memory()` is the load-time parser for each registered MIDI blob. TML allocations are allowed during register/open/setup, not in the audio render hot path.

Each worker slot retains the TML first-message pointer, current cursor, total duration, absolute 44.1-kHz frame position, loop state and lifecycle state. MIDI timestamps are milliseconds and are converted to absolute output-frame boundaries, avoiding per-segment microsecond rounding drift.

## 6. TSF context contract

One SoundFont foundation is loaded once. Each active MIDI slot uses an independent playback TSF context derived with `tsf_copy()`.

Before normal rendering, setup configures 44.1-kHz stereo output, pre-allocates 16 voices and initializes all 16 MIDI channels. This prevents intentional first-use channel/voice allocation from being introduced by the RG35XX render path.

## 7. Render hot-path rule

After `open/start` setup, `rg35xx_tsf_mix_slot()` does not call `malloc`, `calloc`, `realloc` or `free` directly. MIDI is rendered in event-boundary segments into fixed scratch storage and accumulated into the existing mixer.

No second RG35XX worker ring is introduced. Historical worker-ring logs remain compatibility/performance evidence, not an instruction to duplicate current mixer ownership.

## 8. MIDI event mapping

The replacement worker handles NOTE_ON / NOTE_OFF, PROGRAM_CHANGE, CONTROL_CHANGE and PITCH_BEND through TinySoundFont channel APIs. Unsupported/non-rendering metadata advances the TML timeline without selecting another backend. Channel 10 (zero-based channel 9) uses TinySoundFont MIDI-drum preset semantics.

## 9. Seek/reset contract

Seek resets TSF state, resets the TML cursor and deterministically replays state-changing MIDI messages through the requested absolute frame. STOP returns the frame clock to zero; PAUSE preserves it. RELEASE frees only the slot's TML list and copied TSF context.

## 10. Loop/event ownership

Exactly one native layer owns MIDI looping: the replacement worker. `loop_count == -1` is infinite; positive loop counts are decremented only at actual timeline restart. Each intermediate restart sets one pending LOOPED indication; final completion is exposed once to the existing adapter.

## 11. Remaining build gates

`RGJ-RC1-010F` cannot become BUILD-PASS until all of these are exact-source resolved:

- pinned `tml.h` and `tsf.h` are present in the assembled native tree;
- `native/rg35xx_tsf_impl.c` remains the only translation unit defining `TML_IMPLEMENTATION` and `TSF_IMPLEMENTATION`;
- SoundFont initialization ownership is explicit and not guessed;
- consolidated core initializes/shuts down the worker and transports native media events;
- ARMv5TE/uClibc link includes worker, implementation unit and required math linkage;
- actual native cross-build succeeds.

No BUILD-PASS or DEVICE-TEST-PASS is claimed by this document.