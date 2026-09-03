# RGJ-RC1-011B — Pinned Graphics / Input / Lifecycle Consolidation

Status: STATIC-AUDIT-PASS. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: AUDIT / MODIFY / REPLACE-INTEGRATION-CONTRACT.

Source pin: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.

Mandatory reload before this task: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current RG35XX helper sources, integration patches, and exact pinned upstream `MobilePlatform`, `Libretro`, and `PlatformImage` call sites.

Audit: `docs/RC1-GRAPHICS-INPUT-LIFECYCLE-AUDIT.md`.
Consolidated integration contract: `patches/0020-pinned-graphics-input-lifecycle-consolidation.patch`.

## Decisions

1. KEEP upstream `PlatformImage`, `PlatformGraphics`, `MobilePlatform`, and `Libretro` as the only facade/integration owners. No parallel renderer, framebuffer owner, input parser, or lifecycle class is added.
2. KEEP `RG35XXImageCache`, `RG35XXTransformCache`, `RG35XXInputEngine`, `RG35XXFrameScheduler`, and `RG35XXLifecycle` as the already-registered helpers.
3. REPLACE only the unsafe consumer portion of `patches/0012-mobileplatform-dirty-frame.patch`: the pinned upstream has one blocking `LibretroIO` thread that must continue consuming core control packets. Calling `RG35XXFrameScheduler.waitForChange()` from case 15 would block the protocol reader and can deadlock/stall pause, input, settings, media events, and shutdown. RC1 therefore does not use blocking dirty-frame waits in that thread.
4. KEEP dirty generation as producer/lifecycle state only for now. A future transport optimization may consume it only after an explicit non-blocking no-change frame protocol or an independently proven presentation worker exists. No second Java frame thread is introduced in RC1.
5. MODIFY lifecycle load semantics: `beforeGameLoad()` completes old-game flush/reset before `MobilePlatform.load()` replaces loader/suite context, but does not mark the new game active before load succeeds. `afterGameLoad()` is the explicit success commit point; `gameLoadFailed()` clears a prepared failed load.
6. REPLACE the current pinned Libretro case-15 raw held-key repeat loop with the registered `RG35XXInputEngine.update()` cadence. DOWN/UP route through the same reusable sink; `MobilePlatform.pressedKeys` is a mirror only. Slot 20 remains upstream fast-forward state and is not passed into the 0..19 RG35XX input engine.
7. KEEP stdout exclusively for video IPC and preserve the existing synchronized frontbuffer serialization.

## Rollback

- Lifecycle rollback: restore `beforeGameLoad()` setting `gameActive=true` only if the integration call is also moved to a proven post-load point that cannot replace the old suite before RMS flush.
- Input rollback: restore upstream direct transition/repeat handling if the consolidated RG35XX adapter fails build/device validation; do not run both handlers simultaneously.
- Dirty-frame rollback/current safe default: send frames using the existing case-15 request/response contract. Do not block the Libretro IO parser waiting for a dirty generation.

## Gate result

Exact pinned call sites have been identified for PlatformImage cache insertion, MobilePlatform frontbuffer dirty production, Libretro DOWN/UP and case-15 repeat replacement, and case-10 lifecycle load transaction. Unsafe blocking dirty-frame consumption is explicitly superseded. Remaining Font, multi-file RMS, media dependency/SoundFont, and consolidated build gates remain separate and open.