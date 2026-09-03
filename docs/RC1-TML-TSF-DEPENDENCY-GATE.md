# RC1 TML/TSF Dependency Gate

Status: STATIC-AUDIT-PASS for dependency/source policy only. This is not BUILD-PASS and does not implement the missing worker.

Task basis: `RGJ-RC1-010F` in `tasklog/RC1-TASKLOG.md` authorizes RESTORE-BY-REIMPLEMENTATION of the historical native TML/TSF worker while preserving `native/rg35xx_midi_backend.c` as the bounded two-context adapter.

## 1. Current-tree finding

The current `native/` tree contains the RG35XX audio protocol, pipe, dispatcher, media cache, mixer and MIDI adapter. It does not contain `tml.h`, `tsf.h`, a TML/TSF implementation translation unit, a SoundFont asset, or an implementation of the `rg35xx_tsf_*` hooks declared by `rg35xx_midi_backend.c`.

Therefore the first native build with the current MIDI adapter would remain link-blocked until the worker implementation and its exact third-party source inputs are assembled.

## 2. Authoritative third-party source pin

Upstream: `schellingb/TinySoundFont`.

Pinned source commit for RC1 dependency review:

`853a0a171759f1ddba0de1442133a75912bbeffa`

Required upstream files at that pin:

- `tml.h` — TinyMidiLoader v0.7, zlib license.
- `tsf.h` — TinySoundFont v0.9, MIT license.

RC1 must vendor exact files from the pinned commit (including upstream license text) or otherwise provide byte-identical sources to the native build. Do not follow moving `main` during a release build.

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

Until one is proven, worker code may define the initialization API contract but must fail cleanly when no SoundFont is supplied.

## 5. TML timeline contract

`tml_load_memory()` is the load-time parser for each registered MIDI blob. TML allocations are allowed during register/open/setup, not in the audio render hot path.

Each worker slot retains:

- the TML first-message pointer for later `tml_free()`;
- the current message pointer;
- total MIDI length from `tml_get_info()`;
- current media time;
- requested loop count / remaining iterations;
- active, paused, finished and loop-boundary state.

MIDI event timestamps are milliseconds. Worker render scheduling must convert the rendered audio-frame position to the same timeline deterministically instead of using wall-clock timers.

## 6. TSF context contract

One SoundFont foundation is loaded once. Each active MIDI slot uses an independent playback TSF context derived from that foundation (`tsf_copy()` is the intended upstream mechanism when supported by the pinned source).

Before entering normal rendering, setup must:

- configure fixed output mode/sample rate;
- pre-allocate the chosen maximum voice count with `tsf_set_max_voices()`;
- initialize every MIDI channel that the worker can dispatch so channel creation cannot first occur inside the render callback;
- set initial bank/program/controller state deterministically.

The historical stable target is 16 voices. Changing this target requires a separately recorded replacement decision.

## 7. Render hot-path rule

After `open/start` setup, `rg35xx_tsf_mix_slot()` must not call `malloc`, `calloc`, `realloc` or `free` directly and must not intentionally trigger first-use TSF channel/voice allocation.

No second RG35XX worker ring is required by the current architecture. MIDI samples accumulate directly into the existing static mixer accumulator, then PCM voices are added and the existing mixer performs final PCM16 clamp/output.

Historical worker-ring logs remain compatibility/performance evidence, not an instruction to duplicate the current mixer ownership.

## 8. MIDI event mapping

The worker must handle at minimum the TML channel messages used by TinySoundFont's channel API:

- NOTE_ON / NOTE_OFF
- PROGRAM_CHANGE
- CONTROL_CHANGE
- PITCH_BEND

Unsupported/non-rendering metadata must advance the timeline without crashing or allocating an alternate backend.

Drum channel semantics must follow TinySoundFont's channel/preset API rather than a project-local synth implementation.

## 9. Seek/reset contract

Seek is deterministic replay, not wall-clock skipping:

1. reset TSF voice/channel state;
2. reset TML cursor to the first message;
3. replay state-changing MIDI events up to the requested media time without rendering obsolete audio;
4. set the current cursor/time to the first event after the seek point.

STOP returns media time to zero. PAUSE preserves media time. RESET/RELEASE frees the slot TML list and playback TSF context but does not destroy another slot's shared SoundFont foundation.

## 10. Loop/event ownership

Exactly one native layer owns MIDI looping: the replacement worker.

- `loop_count == -1`: infinite restart.
- positive loop count: worker decrements remaining iterations at actual end-of-timeline restart.
- intermediate restart produces one loop-boundary notification for RC1-010E.
- final iteration marks the slot finished exactly once; the existing MIDI adapter then emits the final END callback once.

The adapter must not independently decrement/restart the same loop count.

## 11. Build gates before implementation can be promoted

The worker cannot move beyond IMPLEMENTED until all of these are exact-source resolved:

- pinned `tml.h` and `tsf.h` are present in the assembled native tree;
- exactly one translation unit owns `TML_IMPLEMENTATION` and `TSF_IMPLEMENTATION`;
- SoundFont initialization ownership is explicit and not guessed;
- worker symbols exactly match the current `rg35xx_midi_backend.c` hook declarations;
- no second synth/ring/backend is introduced;
- ARMv5TE/uClibc link command includes the worker and required math linkage if the pinned TSF build requires it.

Only after those checks should `RGJ-RC1-010F` worker source be added and statically audited. BUILD-PASS still requires the actual cross-link.