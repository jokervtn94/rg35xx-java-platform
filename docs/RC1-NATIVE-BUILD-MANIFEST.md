# RC1 Native Build Manifest / Consolidated Core Assembly

Status: STATIC-AUDIT-PASS for build-graph ownership. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Purpose

RGJ-RC1-011I locks one native build graph before the first consolidated compile. It does not create a second libretro core and does not duplicate any registered native module.

## Single core entrypoint

The assembled upstream `src/libretro/freej2me_libretro.c` at the pinned FreeJ2ME source remains the only libretro entrypoint and owns libretro callbacks, Java process creation/control pipes and the integration call-sites specified by patches 0015-0017.

Project `native/*.c` files are support translation units only. None may define libretro entrypoints.

## Required project native translation units

Compile/link each exactly once:

- `native/rg35xx_media_cache.c`
- `native/rg35xx_media_event_queue.c`
- `native/rg35xx_audio_dispatch.c`
- `native/rg35xx_audio_pipe.c`
- `native/rg35xx_mixer.c`
- `native/rg35xx_midi_backend.c`
- `native/rg35xx_tsf_worker.c`
- `native/rg35xx_tsf_impl.c`
- `native/rg35xx_soundfont_source.c`
- `native/rg35xx_media_runtime.c`

Headers are declarations only and must never be separately compiled.

`native/rg35xx_tsf_impl.c` is the sole translation unit allowed to define `TSF_IMPLEMENTATION` and `TML_IMPLEMENTATION`. No amalgamated core source may define those macros again.

## Include graph

The native compiler must be able to resolve:

- project native headers from `native/`;
- exact vendored `native/vendor/TinySoundFont/tsf.h` and `tml.h`;
- the pinned upstream libretro headers already used by FreeJ2ME.

TML/TSF vendoring must pass `native/verify_tinysoundfont_vendor.sh` before compilation. Moving upstream headers are forbidden.

## External runtime inputs

Before a BUILD-READY claim the assembly must also pass `scripts/rc1_prebuild_gate.sh --build-ready`, including exact pinned FreeJ2ME, GNU Classpath/font input, GeneralUser-GS SoundFont identity and TML/TSF headers.

The SoundFont file is an assembly/runtime input. It is not compiled as a C array and no second filesystem loader is introduced. Consolidated core startup supplies stable caller-owned SF2 bytes to `rg35xx_media_runtime_init`; runtime shutdown occurs before those bytes are released.

## Link requirements

The native graph requires the actual target toolchain's POSIX thread support because the existing process/audio/event architecture uses pthreads. TinySoundFont worker math may require the target math library; the final target Makefile must carry the toolchain-equivalent pthread/math link flags exactly once. Do not hard-code host-only linker behavior as proof of the RG35XX ARMv5TE/uClibc link.

No JavaSound/ALSA/SDL audio backend is added to the RG35XX native media graph. Libretro audio output remains the mixer sink.

## Symbol/prototype order gate

The consolidated core must include declarations before first use. In particular, the previous failure classes are forbidden:

- no use of `pWrite` before its declaration/definition;
- no call to `write_to_pipe` before a visible prototype/definition;
- no call to `check_fast_forwarding` before a visible prototype/definition;
- native media callback event type is `int`, matching `rg35xx_media_events.h`;
- audio/event worker threads must not write Java control packets directly; the registered queue/control-writer ownership remains authoritative.

Integration patches must be applied/reconciled against the exact pinned core rather than concatenated blindly. A patch hunk that no longer matches is a source-assembly failure, not permission to paste duplicate helpers elsewhere.

## Lifecycle/link ownership

Startup order remains:

1. media cache / event queue / mixer callback state;
2. authoritative SoundFont bytes available;
3. `rg35xx_media_runtime_init` (SoundFont source -> TML/TSF worker);
4. dedicated audio pipe created;
5. fork/exec JamVM with inherited audio FD.

Shutdown order remains:

1. Java/RMS graceful barrier where available;
2. stop/block audio writer and close transport;
3. reset players/mixer/cache/event state;
4. `rg35xx_media_runtime_shutdown` (worker -> SoundFont source clear);
5. release external SF2 bytes;
6. hard-kill fallback only after graceful path fails/expires according to the existing integration contract.

Game unload resets player/mixer/cache state but does not tear down process-lifetime TML/TSF/SF2 ownership.

## First-build acceptance

011I does not claim compilation. The first native BUILD-PASS requires the assembled pinned source tree to compile and link the single libretro shared object with:

- every required project `.c` exactly once;
- zero duplicate TML/TSF implementation owners;
- zero implicit-function declarations caused by integration ordering;
- zero undefined `rg35xx_*` symbols;
- no second `freej2me_libretro.c`/libretro entrypoint;
- target-compatible pthread/math linkage.

Host compilation may be used as an early syntax/prototype check, but RC1 target BUILD-PASS remains the ARMv5TE/uClibc build defined by the tasklog.

## Result

Native source/link ownership is now deterministic at manifest level. Remaining work before BUILD-READY is physical external-input materialization and exact pinned source assembly/application of the integration contracts. The next stage may implement the reproducible assembly driver/Makefile overlay and then attempt the first build; no device-test claim is authorized yet.
