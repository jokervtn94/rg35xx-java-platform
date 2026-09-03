# RC1 Native Media Consolidation Audit

Task: RGJ-RC1-010O
Status: STATIC-AUDIT-PASS (native media source/link contract); BUILD-PASS pending.

## Scope
This stage closes the native media dependency and symbol-ownership design as one subsystem before any consolidated build. It does not claim that missing third-party inputs or an authoritative SF2 asset have appeared.

## Reload/source basis
Mandatory TASKLOG, RC1-TASKLOG and PLATFORM-SOURCE-REGISTRY were reloaded before this stage. Current native owners inspected include rg35xx_media_runtime.c, rg35xx_tsf_worker.h/.c, rg35xx_tsf_impl.c, rg35xx_midi_backend.c, rg35xx_mixer.c and verify_tinysoundfont_vendor.sh. Repository search found no project Makefile/CMake source list owning the consolidated RG35XX native link yet.

## Single ownership graph
Java audio protocol -> audio pipe/dispatch -> media cache -> mixer -> MIDI backend -> TML/TSF worker -> TinyMidiLoader/TinySoundFont.

SoundFont bytes are owned outside the synth and enter exactly once through rg35xx_media_runtime_init(soundfont,size), which calls soundfont_source_set then worker_init. Final teardown is worker_shutdown then soundfont_source_clear. Mixer/audio-pipe lifetime remains a consolidated-core responsibility.

rg35xx_tsf_impl.c is the only permitted translation unit defining TSF_IMPLEMENTATION and TML_IMPLEMENTATION. It disables third-party stdio; MIDI and SF2 enter through memory APIs.

## Dependency identity gate
RC1 pins schellingb/TinySoundFont commit 853a0a171759f1ddba0de1442133a75912bbeffa.
Required Git blob identities:
- tml.h: 6b3b6cdd1a212115787d7f32fc63a9e1f680814a
- tsf.h: 7c64a18a73d43bb0d4878c2e729b7e259b985cd4

native/verify_tinysoundfont_vendor.sh is the mandatory offline integrity check. The repository does not currently contain byte-proven vendored copies, therefore BUILD-PASS is intentionally blocked rather than accepting truncated/reconstructed headers.

## Required native build inputs
The consolidated native core must compile/link exactly one copy of each project media implementation:
- rg35xx_media_cache.c
- rg35xx_audio_dispatch.c
- rg35xx_audio_pipe.c
- rg35xx_media_event_queue.c
- rg35xx_mixer.c
- rg35xx_midi_backend.c
- rg35xx_tsf_worker.c
- rg35xx_tsf_impl.c
- rg35xx_soundfont_source.c
- rg35xx_media_runtime.c
plus the existing freej2me_libretro.c integration owner.

The compiler include path must expose native/ and the verified TinySoundFont vendor directory. Native link must include the math library required by TinySoundFont. No second synth, second mixer or second core entrypoint may be introduced.

## Runtime invariants
- output/mixer rate is 44100 Hz stereo;
- MIDI worker owns loop counting; backend only emits typed LOOPED/END callbacks;
- PCM mixer and MIDI worker do not intentionally allocate in the render hot path;
- stdout remains Java->libretro binary video IPC;
- Java->native audio uses the dedicated inherited FD;
- native->Java media events use the bounded queue and existing control writer;
- game switch resets player/mixer/cache state without reloading the process-lifetime SoundFont foundation;
- final shutdown tears down media before releasing SF2 bytes.

## Static findings
The worker declaration and MIDI adapter call surface match: open/start/pause/stop/seek/close/mix/finished/time/take_looped. The mixer delegates MIDI lifecycle to that adapter and PCM remains in the same mixer. The runtime coordinator has a clean failure rollback: if worker init fails it clears the registered SoundFont source.

No authoritative SF2 filename/path is present in the project evidence. No path is invented in this stage.

## Build blockers intentionally retained
1. Exact pinned tml.h and tsf.h must be present and pass verify_tinysoundfont_vendor.sh.
2. An authoritative SoundFont asset/provider must be established by source/device evidence or an explicit configuration contract; arbitrary bundled SF2 is forbidden.
3. Exact consolidated freej2me_libretro.c must apply the already-recorded runtime/audio-FD/event/shutdown contracts.
4. A real ARMv5TE/uClibc compile/link must succeed with no undefined RG35XX/TML/TSF symbols.

Until all four are satisfied, status stays STATIC-AUDIT-PASS and not BUILD-PASS.

## Stage result
The native media subsystem now has one frozen ownership/link manifest and no unresolved architectural choice. Remaining items are concrete build inputs/integration evidence, not reasons to redesign the media engine.