# RG35XX Java Platform — RC1-011AB Native Runtime Lifecycle Wiring Repair

## Trigger
Consolidated build run `33863861824` completed Java Ant build and ARMv5TE/uClibc compile/link successfully, producing `freej2me_plus-lr.jar` and an ARM EABI5 shared object with no unresolved `rg35xx_*` symbols. Evidence review nevertheless found GCC `-Wunused-function` warnings for `rg35xx_core_media_event`, `rg35xx_load_soundfont_bytes`, `rg35xx_audio_drain_start`, and `rg35xx_native_media_shutdown`. Inspection of the produced ELF confirmed those static runtime helpers were optimized out and no call references remained. Therefore the green compile/link run is not accepted as BUILD-PASS yet.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, task `RC1-011AA`, exact pinned upstream `freej2me_libretro.c`, and current active patches 0015/0016/0017.

## Decision
- Action: MODIFY active integration patches 0015, 0016, and 0017 only; no new native module/class.
- Preserve 0015 as the implementation owner of native media runtime startup/shutdown and the audio-drain worker.
- Preserve 0016 as the sole audio-pipe creation, inherited child-FD, and JVM argv owner; after successful parent-side fork handoff it invokes the already-defined 0015 drain-start hook.
- Preserve 0017 as the graceful Java EOF/process-boundary owner; after Java exits or the bounded SIGKILL fallback completes, it invokes the already-defined 0015 native-media shutdown hook.
- Move 0015 runtime initialization to an unambiguous `retro_init()` entry call-site so mixer callback registration, SoundFont loading, and media runtime initialization are syntactically live.
- Do not change stdout video IPC, 640x480 RGB565, receiver pthread, async audio callback, dedicated audio pipe lifetime, native END_OF_MEDIA behavior, or watchdog policy.

## Acceptance
1. All 11 active patches still dry-run/apply sequentially on exact FreeJ2ME pin.
2. Java Ant build remains successful.
3. ARMv5TE/uClibc native compile/link remains successful with `-Wl,--no-undefined` and no unresolved `rg35xx_*` symbols.
4. GCC no longer reports the four native runtime hooks as defined-but-unused.
5. Produced ELF contains live references/calls for media runtime initialization, audio drain startup, mixer callback ownership, and final native media shutdown.
6. Only after evidence review of 1-5 may the first consolidated BUILD-PASS be recorded; DEVICE-TEST-PASS remains separate.
