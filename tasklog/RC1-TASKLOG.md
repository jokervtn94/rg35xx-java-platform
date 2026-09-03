# RG35XX Java Platform — RC1 Consolidation Tasklog

This file extends the immutable project task history for the Platform 1.0 consolidated RC stage. It does not replace `TASKLOG.md`.

## RGJ-B6-009 — RMS failure-path hardening
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- File: `src/org/recompile/mobile/RG35XXRmsCoordinator.java`
- Before: a failed background flush was immediately re-enqueued; persistent storage failure could keep `forceFlush()` waiting forever.
- After: failed stores are parked separately, receive one barrier retry, and persistent failure is surfaced. `shutdown()` stops/joins the writer even when the flush barrier fails.
- Reason: prevent save-error shutdown hangs while preserving failure visibility.
- Rollback: restore immediate requeue only if a later proven bounded retry mechanism replaces this policy.

## RGJ-B6-010 — Audio bootstrap lifecycle ownership
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- File: `src/org/recompile/mobile/RG35XXLifecycle.java`
- Before: platformStart started RMS but did not attach the inherited audio descriptor.
- After: `RG35XXAudioBootstrap.initialize()` is invoked during platform start; failure is fail-safe and stdout is never used for audio.
- Additional protection: `beforeGameLoad()` issues defensive native media RESET when transport is available.
- Rollback: remove bootstrap ownership from lifecycle only if another single authoritative Java bootstrap point replaces it.

## RGJ-RC1-001 — Consolidated RC1 integration manifest
- Action: ADD
- Status: IMPLEMENTED
- File: `docs/RC1-INTEGRATION-MANIFEST.md`
- Purpose: define G1-G12 source gates before the first consolidated build.
- Rule: BUILD-PASS is forbidden until all exact-source gates are resolved in one source tree.

## RGJ-RC1-002 — Runtime evidence freeze
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Evidence: historical RG35XX logs supplied during development.
- Facts retained for RC design:
  - JamVM 2.0.0 / GNU Classpath target runtime.
  - desktop JavaSound/ALSA MIDI cannot be a required backend.
  - native TML/TSF + PCM worker/ring is the target media foundation.
  - Java↔native stdout remains binary video IPC.
- Limitation: historical logs are compatibility evidence, not RC device-test results.

## RGJ-RC1-003 — Exact-source assembly
- Action: AUDIT
- Status: PLANNED
- Scope: assemble upstream FreeJ2ME source plus project RG35XX classes and patches into one reproducible RC tree.
- Required checks: PlatformImage, PlatformGraphics, MobilePlatform, PlatformPlayer, Manager, RecordStore, Libretro.java, freej2me_libretro.c, native media modules.

## RGJ-RC1-004 — First host/cross build
- Action: AUDIT
- Status: PLANNED
- Java acceptance: `rm -rf build && ant` succeeds.
- Native acceptance: ARMv5TE/uClibc libretro core links with no undefined RG35XX symbols.
- Rule: host/cross BUILD-PASS still does not imply DEVICE-TEST-PASS.
