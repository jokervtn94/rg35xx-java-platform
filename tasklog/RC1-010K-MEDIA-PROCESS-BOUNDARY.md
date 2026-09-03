# RGJ-RC1-010K — Media process-boundary completion

- Action: ADD / MODIFY / AUDIT
- Status: STATIC-AUDIT-PASS
- Scope: one completed RC1 stage covering native media callback handoff, opcode-14 serialization, Java case-14/case-15 dispatch, and graceful final shutdown/RMS barrier.
- Pre-change control: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current native tree and exact upstream libretro owners were reloaded before mutation.
- Duplicate check: repository search found no existing `media_event_queue` owner and no existing graceful shutdown/event-writer owner outside the registered core/Libretro integration contracts.
- New source: `native/rg35xx_media_event_queue.h/.c` — fixed 32-event primitive handoff; no heap allocation; mutex only on rare media events/pop/reset; no per-frame audio lock.
- Integration: `patches/0017-libretro-media-process-boundary.patch`.
- Audit: `docs/RC1-MEDIA-PROCESS-BOUNDARY-AUDIT.md`.
- Reconciled older contract: patch 0014 no longer claims native MIDI LOOPED production is unresolved; shared callback/worker production exists and cross-thread core handoff is now owned by 0017.
- Compile-risk correction during audit: proposed core callback signature changed from `uint8_t event_type` to `int event_type` to exactly match `rg35xx_media_event_cb`.
- Shutdown decision: do not allocate another protocol opcode. Parent closes the existing core→Java control write end to deliver EOF; Java `LibretroIO` finally calls `RG35XXLifecycle.platformShutdown()` and exits; Linux core retains bounded deinit wait plus upstream hard-kill fallback.
- Invariants: stdout remains video-only; no second reverse pipe; no Java timer/executor; no direct audio-thread write to the shared control stream; no event survives game reset.
- Rollback: remove queue + patch 0017 together if consolidated core integration proves incompatible; retain patch 0014 wire semantics and existing upstream hard-kill fallback until the replacement shutdown path is BUILD-PASS.
- BUILD-PASS: not claimed.
- DEVICE-TEST-PASS: not claimed.
