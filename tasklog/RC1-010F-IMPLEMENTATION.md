# RGJ-RC1-010F — Replacement TML/TSF worker implementation checkpoint

- Action: REPLACE / RESTORE-BY-REIMPLEMENTATION
- Status: IMPLEMENTED
- Source: `native/rg35xx_tsf_worker.c` behind the previously registered `native/rg35xx_tsf_worker.h` contract.
- Pre-change reload: `tasklog/TASKLOG.md`, relevant `tasklog/RC1-TASKLOG.md` range, `docs/PLATFORM-SOURCE-REGISTRY.md`, current worker declaration and current-tree search were inspected. Search reconfirmed no existing `rg35xx_tsf_worker.c`, so this does not create a second implementation owner.
- Source basis: pinned TinyMidiLoader/TinySoundFont API plus the historical RG35XX runtime evidence already recorded by the parent 010F task. No historical worker source was recovered or claimed.
- Ownership: one SoundFont foundation supplied as memory by consolidated core; at most `RG35XX_MEDIA_MAX_MIDI_CTX` TSF copies; existing `rg35xx_midi_backend.c` remains player/context adapter and worker owns MIDI timeline/loop count.
- MIDI mapping: TML NOTE_ON/OFF, PROGRAM_CHANGE, CONTROL_CHANGE and PITCH_BEND map to TSF channel APIs. MIDI channel 10 (zero-based channel 9) is initialized with drum semantics.
- Allocation policy: TML parse/TSF copy and max-voice/channel preparation occur in init/open/setup paths. Render uses a fixed stereo PCM scratch buffer and the existing mixer accumulator; no project malloc/calloc/free is introduced in `rg35xx_tsf_mix_slot()`.
- Voice policy: TSF max voices is preallocated/bounded at 16, matching the historical compatibility target. All 16 MIDI channels are created before playback so first-use channel allocation is not intentionally deferred into render.
- Loop policy: finite `loop_count` is total play count; `-1` is infinite. Worker alone decrements finite loop ownership and exposes one consumable `looped_pending` signal per actual restart. Adapter only forwards the signal.
- Seek policy: synth/channel state is reset then TML channel messages are replayed through the target timestamp without rendering elapsed audio. This reconstructs program/controller/pitch/note state without a render-time scan from zero.
- Sample-rate replacement decision: replacement worker currently renders TSF directly at the consolidated mixer rate 44100 Hz instead of reproducing the historical 14700-Hz mono-x3 worker-ring. Reason: the current RC mixer already owns fixed 44100-Hz output and static accumulation; recreating the historical worker-ring would introduce a second buffering/resampling owner. This is a recorded replacement, not a claim that the historical implementation behaved identically.
- Known static-audit item: the first implementation batches rendering around the fixed scratch buffer; exact MIDI event-to-sample boundary timing must be audited/hardened before STATIC-AUDIT-PASS. IMPLEMENTED therefore does not mean source-audit complete.
- Dependency gates still open: pinned `tsf.h`/`tml.h` must be vendored or otherwise made available to the native build; SoundFont bytes and their authoritative consolidated-core owner remain unresolved; `rg35xx_tsf_worker_init()` call site is not yet integrated; typed native media callback must be serialized by the consolidated core case-14 path.
- BUILD-PASS / DEVICE-TEST-PASS are not claimed.

This supplemental immutable checkpoint is kept separate because the main RC1 tasklog cannot be safely rewritten from a truncated connector response. It must be merged only when the complete main file is available without losing history.
