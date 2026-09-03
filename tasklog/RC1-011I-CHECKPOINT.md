# RGJ-RC1-011I — Native Build Manifest & Consolidated Core Assembly

- Action: AUDIT / ADD BUILD MANIFEST
- Status: STATIC-AUDIT-PASS
- Governance reload: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `native/` tree.
- New authoritative document: `docs/RC1-NATIVE-BUILD-MANIFEST.md`.
- Ownership decision: KEEP all registered native modules; ADD no duplicate runtime module; existing pinned upstream `src/libretro/freej2me_libretro.c` remains the sole libretro core entrypoint.
- Build graph: compile/link `rg35xx_media_cache.c`, `rg35xx_media_event_queue.c`, `rg35xx_audio_dispatch.c`, `rg35xx_audio_pipe.c`, `rg35xx_mixer.c`, `rg35xx_midi_backend.c`, `rg35xx_tsf_worker.c`, `rg35xx_tsf_impl.c`, `rg35xx_soundfont_source.c`, `rg35xx_media_runtime.c` exactly once.
- TML/TSF rule: `rg35xx_tsf_impl.c` remains the sole `TSF_IMPLEMENTATION` / `TML_IMPLEMENTATION` owner; exact vendored headers must pass the existing verifier.
- SoundFont rule: pinned GeneralUser-GS remains an external stable byte input; no C-array duplication and no second filesystem loader.
- Link rule: target pthread/math requirements must be supplied by the real RG35XX ARMv5TE/uClibc toolchain Makefile; host linker behavior is not accepted as target proof.
- Prototype/order regression gate: no `pWrite`, `write_to_pipe` or `check_fast_forwarding` use before declaration; native media callback event type remains `int`; worker threads do not write Java control packets directly.
- Lifecycle rule: process-lifetime SF2/TML/TSF ownership survives game unload and is released only at final native runtime shutdown.
- External-source basis: upstream FreeJ2ME documents `src/libretro/make` as the native core build path; current upstream source still defines `check_fast_forwarding` in `freej2me_libretro.c`. RC1 integrates against its separately pinned source rather than moving devel.
- BUILD-READY: NOT CLAIMED. Requires physical TML/TSF, SoundFont, GNU Classpath/font and pinned source assembly gates.
- BUILD-PASS: NOT CLAIMED.
- DEVICE-TEST-PASS: NOT CLAIMED.
- Next whole stage: reproducible source assembly/build overlay, followed by first consolidated Java/native build only after its input gate passes.
