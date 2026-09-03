# RC1 Graphics / Input / Lifecycle Consolidation Audit

Status: STATIC-AUDIT-PASS for RGJ-RC1-011B. This is not BUILD-PASS or DEVICE-TEST-PASS.

Upstream source pin: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.

## Reload and duplicate gate

Before this stage, `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current RG35XX helper sources, and exact pinned upstream owners were reloaded. No new renderer, framebuffer, key mapper, protocol reader, image decoder, transform engine, or lifecycle class was added.

## 1. PlatformImage

Pinned `PlatformImage` remains the authoritative byte/resource/InputStream decoder and mutable/immutable facade. Its byte-array constructor currently decodes with ImageIO, normalizes non-INT images into TYPE_INT_ARGB and finally sets `isMutable = mutable`. Existing `patches/0011-platformimage-rg35xx-cache.patch` remains compatible with this exact constructor shape: only immutable byte-array inputs are cache eligible; hits reconstruct a fresh ARGB backing image; mutable DoJa inputs bypass the cache.

No duplicate image/cache owner is required. The RC integration must preserve any final PNG/tRNS repair before cache insertion.

## 2. PlatformGraphics

The pinned PlatformGraphics blob remains the same upstream owner family previously audited by RC1-007: MIDP/DoJa/DirectGraphics/Mascot drawing semantics stay in the upstream class. Existing 0007/0008 contracts remain surgical. `processAlpha=false` must force opaque pixels, not preserve source alpha via an indiscriminate array copy. Transform cache state remains geometry-only and bounded.

No second renderer or transformed-pixel cache is introduced.

## 3. Exact frontbuffer producer point

Pinned `MobilePlatform.flushGraphics()` performs the authoritative frontbuffer flush under `synchronized(lcdFrontbuffer)`, then executes `postDraw`, then `painter.run()`, then FPS limiting. Because `postDraw` can produce the visible command-bar/overlay state, a dirty-generation producer mark is valid only after `postDraw` completes. A mark before that point can announce an incomplete visible frame.

Pinned `resizeLCD()` replaces both LCD buffers and updates MIDP/DoJa display references. A resize dirty mark is valid only after those references are fully installed.

## 4. Dirty-frame consumer correction

The earlier patch 0012 required a consumer to call `RG35XXFrameScheduler.waitForChange(lastSeen)`. Exact pinned Libretro proves that the Java side has one `LibretroIO` thread whose loop blocks on `System.in.read()` and owns all 5-byte core control parsing. Case 15 itself performs pause bookkeeping, held-key repeat dispatch and synchronous frame serialization.

Therefore a blocking dirty wait inside that thread is unsafe: while waiting for Java painting, the same thread cannot consume the future core packet that may be needed to continue protocol progress. In addition, the current core/Java case-15 contract requests a frame and has no explicit no-change response packet.

RC1 therefore replaces only the 0012 consumer rule: keep current case-15 frame request/response behavior, do not block the protocol thread on `waitForChange()`, and do not create a second Java presentation thread merely to make the helper consumable. `RG35XXFrameScheduler` may remain a producer/lifecycle generation signal for later protocol work.

This correction favors deterministic protocol ownership over an optimization whose transport acknowledgement is not yet defined.

## 5. Exact input tick and slot boundary

Pinned Libretro directly handles DOWN/UP by indexing `MobilePlatform.pressedKeys[code]` and immediately dispatching `MobilePlatform.keyPressed/keyReleased(Mobile.getMobileKey(code))`. Case 15 then loops over every pressed-key slot and emits `keyRepeated` every frontend tick.

This exactly identifies the replacement sites for `RG35XXInputEngine`:

- DOWN/UP must validate the RG35XX input-engine slot before indexing/dispatching.
- A single reusable sink converts the slot through `Mobile.getMobileKey(slot)` exactly once.
- Direct transition dispatch beside the engine must be removed to prevent duplicate MIDP transitions.
- The case-15 raw repeat loop must be replaced by one `RG35XXInputEngine.update(nowMs, sink)` call.

Pinned `MobilePlatform.pressedKeys` has length 23, while the registered RG35XX input engine deliberately owns 20 gameplay slots. Index 20 is explicitly used by upstream as the fast-forward/FPS-limit state. It must remain outside RG35XXInputEngine. No numeric remapping is added; `Mobile.getMobileKey` remains authoritative.

## 6. Lifecycle load transaction correction

Pinned Libretro case 10 calls `MobilePlatform.load(...)` directly. That call constructs/replaces `MIDletLoader` and initializes suite configuration. RMS state from the previous game therefore must be flushed before case 10 invokes `load`, not afterward.

The prior `RG35XXLifecycle.beforeGameLoad()` correctly flushed/reset old state but incorrectly set `gameActive=true` before the new `MobilePlatform.load()` had succeeded. That could make a failed load look active and complicate a following replacement.

RC1-011B modifies the existing lifecycle owner in place:

- `beforeGameLoad()` performs old-game unload/reset and records only a prepared load.
- `afterGameLoad()` is the success commit point and sets `gameActive=true`.
- `gameLoadFailed()` clears the prepared state without fabricating an active game.

No new lifecycle class or second subsystem-order owner is introduced.

## 7. Pause, shutdown and preservation

Pause/destroy RMS barriers remain owned by `RG35XXLifecycle`. Final Java EOF/shutdown remains governed by the previously locked media process-boundary contract: attempt platform shutdown/RMS flush before native hard-kill fallback.

Preserved invariants:

- stdout remains binary video IPC only;
- frontbuffer serialization remains synchronized;
- existing upstream FPS limiting remains authoritative;
- no additional Java Timer/executor/frame thread is created;
- DoJa/Vodafone key state remains in MobilePlatform;
- image/graphics facade ownership remains upstream;
- lifecycle resets input/image/transform/frame state between games.

## 8. Remaining build gates

Before BUILD-PASS, the consolidated source must apply 0007/0008/0011 plus the corrected 0020 contract to the pinned upstream tree, compile the exact case-10/case-15 changes, verify JamVM support for upstream `LockSupport`, and verify that all lifecycle/media/RMS calls resolve to the current helper APIs.

Font source reconciliation and the newer multi-file RMS transaction problem remain independent source-consolidation gates. They are not hidden by this audit.

Result: RGJ-RC1-011B STATIC-AUDIT-PASS.