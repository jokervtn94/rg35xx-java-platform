# RG35XX Java Platform — RC1 Consolidation Tasklog

This file extends the immutable project task history for the Platform 1.0 consolidated RC stage. It does not replace `TASKLOG.md`.

## Mandatory tasklog/source-registry reload rule
Before every future ADD/REMOVE/REPLACE/MODIFY of RG35XX platform code, reload:
1. `tasklog/TASKLOG.md`
2. this `tasklog/RC1-TASKLOG.md`
3. `docs/PLATFORM-SOURCE-REGISTRY.md`
4. current repository tree/target files

No class/package/native module may be added merely from memory or an older overlay. ADD requires a non-overlap check; REMOVE/REPLACE requires an immutable task entry identifying the old symbol and replacement/rollback. KEEP also requires current-tree presence verification; a registry entry alone is not proof that its source exists.

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
- Facts retained for RC design: JamVM/GNU Classpath target; native TML/TSF + PCM media foundation; stdout remains binary video IPC.
- Limitation: historical logs are compatibility evidence, not RC device-test results.

## RGJ-RC1-003 — Exact-source assembly
- Action: AUDIT
- Status: IMPLEMENTED
- Scope: assemble upstream FreeJ2ME source plus project RG35XX classes and patches into one reproducible RC tree.
- Required checks: PlatformImage, PlatformGraphics, MobilePlatform, PlatformPlayer, Manager, RecordStore, Libretro.java, freej2me_libretro.c, native media modules.
- Control added: `docs/PLATFORM-SOURCE-REGISTRY.md` is the authoritative duplicate/missing-class gate.
- Remaining: exact upstream call-site application/audit before BUILD-PASS.

## RGJ-RC1-004 — First host/cross build
- Action: AUDIT
- Status: PLANNED
- Java acceptance: `rm -rf build && ant` succeeds.
- Native acceptance: ARMv5TE/uClibc libretro core links with no undefined RG35XX symbols.
- Rule: host/cross BUILD-PASS still does not imply DEVICE-TEST-PASS.

## RGJ-RC1-005 — Authoritative source registry / duplicate prevention
- Action: ADD
- Status: STATIC-AUDIT-PASS
- File: `docs/PLATFORM-SOURCE-REGISTRY.md`
- Purpose: maintain one authoritative inventory of RG35XX Java classes, native modules, upstream integration owners and patch responsibilities.
- Required behavior: reload tasklogs + registry before every code mutation.

## RGJ-RC1-006 — PlatformImage + immutable image-cache exact-source gate
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Sources checked: upstream `org.recompile.mobile.PlatformImage` on FreeJ2ME-Plus devel; registered `RG35XXImageCache`.
- Integration spec: `patches/0011-platformimage-rg35xx-cache.patch`.
- Duplicate result: no new class/package; upstream PlatformImage remains decoder/facade owner and RG35XXImageCache remains the only RG35XX decoded-image cache.
- Cache API modified in-place: entries retain width + height + defensive ARGB pixel copy.
- Exact cache-hit contract: immutable byte-array images reconstruct a fresh TYPE_INT_ARGB BufferedImage and copy cached pixels; mutable DoJa images bypass cache.
- PNG/tRNS invariant: final compatibility repair occurs before insertion.
- Gate result: STATIC-AUDIT-PASS; BUILD-PASS not claimed until consolidated call-site is compiled.

## RGJ-RC1-007 — PlatformGraphics exact-source gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Reload performed: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY before inspection/mutation.
- Exact upstream owner: `org.recompile.mobile.PlatformGraphics`; no parallel graphics class/package added.
- Reconciled sources: upstream FreeJ2ME-Plus devel PlatformGraphics + patches `0007-platformgraphics-rg35xx-fast-drawrgb.patch` and `0008-platformgraphics-transform-cache.patch` + registered `RG35XXTransformCache`.
- drawRGB contract: resolve translation/clip once; processAlpha=false forces opaque source; processAlpha=true skips alpha=0, direct-copies alpha=255 and blends only 1..254; no allocation in inner pixel loop.
- Important correction: do NOT replace processAlpha=false with raw `System.arraycopy`, because MIDP requires source alpha to be ignored/forced opaque.
- Transform contract: TRANS_NONE retains direct drawRGB path; transformed drawRegion uses geometry-only `RG35XXTransformCache`; mutable pixels are never cached; source bounds/anchor/translation/clip/alpha semantics remain upstream-owned.
- Exact-source finding: current upstream PlatformGraphics is already heavily hand-rasterized and carries DoJa/DirectGraphics/Mascot compatibility state. RG35XX optimization must be surgical; replacing the class or routing generic drawing through AWT would regress compatibility.
- Allocation gate: RG35XX additions introduce no per-pixel/per-frame allocation on drawRGB; transform map allocation occurs only on bounded cache miss (24 entries), then maps are reused and reset between games.
- Gate result: architecture and exact-source integration contract STATIC-AUDIT-PASS. BUILD-PASS is not claimed until patches are applied to the consolidated source and compiled.

## RGJ-RC1-008 — MobilePlatform dirty-frame integration gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Reload performed: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY before inspection/mutation.
- Sources: upstream FreeJ2ME-Plus devel `MobilePlatform` + registered `RG35XXFrameScheduler`.
- Integration spec: `patches/0012-mobileplatform-dirty-frame.patch`.
- Ownership: MobilePlatform remains sole LCD/frontbuffer/repaint owner; RG35XXFrameScheduler remains generation-based dirty/wakeup helper only. No second renderer, frame queue, Timer, executor or Java frame thread is introduced.
- Producer contract: mark dirty only after an existing upstream render/backbuffer-to-frontbuffer operation has produced a coherent presentable frame; never mark per primitive or before paint/copy completion.
- Resize contract: after replacement LCD buffers/graphics references are fully installed, force a dirty generation so native presentation cannot retain stale geometry.
- Consumer contract: remember last-seen generation and wait for change; multiple producer marks may coalesce intentionally rather than queue obsolete frames.
- Lifecycle: game reset uses `RG35XXFrameScheduler.reset()`; final shutdown may call `wake()` only to release a waiter and must not treat wake as a rendered frame.
- FPS ownership: existing upstream MobilePlatform frame-limit timing remains authoritative; dirty scheduling must not become a second FPS limiter.
- Runtime audit note: current upstream MobilePlatform imports `java.util.concurrent.locks.LockSupport`; this pre-existing dependency must be verified against the target JamVM/GNU Classpath during consolidated build. RC1-008 adds no new concurrent API dependency.
- Gate result: STATIC-AUDIT-PASS for architecture/integration contract. BUILD-PASS is not claimed until the exact presentation call-site is applied and compiled.

## RGJ-RC1-009 — Libretro input adapter exact-source gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Reload performed: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY before inspection/mutation.
- Sources checked: upstream FreeJ2ME-Plus devel `org.recompile.freej2me.Libretro`, upstream `MobilePlatform`, registered `RG35XXInputEngine`.
- Integration spec: `patches/0013-libretro-rg35xx-input-engine.patch`.
- Ownership: Libretro remains stdin protocol/parser owner; MobilePlatform remains MIDP/vendor dispatch owner; Mobile.getMobileKey remains frontend-slot -> J2ME mapping owner; RG35XXInputEngine is the sole RG35XX held/repeat state machine.
- Exact-source finding: upstream Libretro directly mutates `MobilePlatform.pressedKeys[code]` and immediately calls MobilePlatform keyPressed/keyReleased. RC integration must replace that transition dispatch, not run RG35XXInputEngine beside it, otherwise duplicate MIDP transitions occur.
- Repeat policy: no Timer/repeat thread/executor. `RG35XXInputEngine.update()` must be driven by an existing bounded libretro/core update cadence; the engine itself prevents catch-up repeat storms after stalls.
- Numeric keypad policy: do not remap in RG35XXInputEngine. Preserve the already-working mapping by converting through `Mobile.getMobileKey(slot)` exactly once at the reusable sink boundary.
- Safety correction: validate frontend slot before indexing `pressedKeys`/input state so malformed protocol input cannot kill the Libretro IO thread with ArrayIndexOutOfBoundsException.
- Compatibility mirror: `MobilePlatform.pressedKeys` may remain synchronized for upstream behavior, but cannot own a second repeat generator.
- Lifecycle: `RG35XXLifecycle` resets RG35XXInputEngine between games so no held key leaks into the next JAR.
- Gate result: STATIC-AUDIT-PASS for exact-source ownership/integration contract. BUILD-PASS remains blocked on applying the consolidated call site and verifying the actual update/tick hook.

## RGJ-RC1-010 — Manager + PlatformPlayer media facade gate
- Action: AUDIT
- Status: PLANNED
- Reload performed before audit start: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY.
- Sources inspected so far: upstream `javax.microedition.media.Manager`, upstream `org.recompile.mobile.PlatformPlayer`, `RG35XXMediaProfile`, `RG35XXMediaRegistry`, `RG35XXNativePlayer`, patches 0003/0006.
- Exact-source finding: upstream Manager still advertises AMR/MPEG/MMF/MLD/iMelody broadly and directly depends on desktop `javax.sound.midi`; upstream PlatformPlayer also imports JavaSound, ScheduledExecutorService and desktop MPEG playback. These cannot become mandatory RG35XX runtime dependencies.
- Integration requirement retained: Manager capability reporting must route through `RG35XXMediaProfile`; PlatformPlayer remains the public/vendor-compatible facade and delegates supported RG35XX media to `RG35XXNativePlayer` rather than replacing the facade.
- Tone caveat: `RG35XXMediaRegistry.TYPE_TONE` is not directly registerable by current RG35XXNativePlayer prefetch; tone must be converted to MIDI first and registered as MIDI, as the earlier integration spec states.
- Previous blocker: `RG35XXWavDecoder.java` was missing. It is restored and source-hardened under RC1-010B/010C. Native PCM rate conversion is corrected under RC1-010D. This facade gate remains open until exact PlatformPlayer WAV/tone call sites are reconciled.
- BUILD-PASS and STATIC-AUDIT-PASS for RC1-010 are not claimed yet.

## RGJ-RC1-010A — Current-tree source reconciliation
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Document: `docs/RC1-SOURCE-RECONCILIATION.md`.
- Purpose: verify that registry KEEP entries actually exist before dependent gates proceed.
- Confirmed missing Java sources at audit time: `RG35XXWavDecoder.java`, `RG35XXFontEngine.java`.
- Confirmed native registry mismatch: `native/rg35xx_audio_dispatch.h` is absent while `rg35xx_audio_dispatch.c` exists; need/ownership must be resolved rather than assuming the header exists.
- Prior-source search: Library/conversation search did not locate authoritative copies of the two missing Java classes; a prior combined patch did not contain their exact class names.
- Registry correction: missing entries were explicitly marked `MISSING — RESTORE REQUIRED`; future KEEP checks require current-tree presence verification.
- Rule: do not reconstruct missing classes from memory and do not silently substitute unrelated upstream code without a REPLACE task.

## RGJ-RC1-010B — Restore RG35XXWavDecoder from audited upstream format basis
- Action: ADD / RESTORE
- Status: IMPLEMENTED
- File: `src/org/recompile/mobile/RG35XXWavDecoder.java`.
- Pre-change reload: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY completed; current-tree search reconfirmed the registered source was absent, so this restores an existing registered responsibility rather than adding a new responsibility/class family.
- Source basis audited: upstream `WAVTools`, `WAVImaADPCMDecoder`, `WAVLawDecoder` format behavior plus the existing RG35XXNativePlayer contract. No historical missing implementation was found, so no old code was silently resurrected.
- Target policy: java.io-only RIFF/WAVE parser; no JavaSound, AudioSystem, host sample-rate probing, executor, or host-device resampling.
- Output contract: always PCM16 little-endian plus original source sampleRate/channels for native registration.
- Formats implemented: PCM 8-bit unsigned -> PCM16, PCM 16-bit LE pass/copy, Microsoft IMA ADPCM 0x11 mono/stereo block decode, A-law 0x06, mu-law 0x07.
- Parser behavior: scans RIFF chunks, accepts fmt/data with intervening chunks and RIFF even-byte padding, rejects truncated/invalid chunks and unsupported >2-channel/format cases.
- Allocation note: decode is a load/prefetch path, not the audio render hot path. No allocations are introduced into native mixing/audio callback paths.
- Follow-up: hardened under RC1-010C; native rate ownership corrected under RC1-010D.

## RGJ-RC1-010C — WAV normalization source/fixture hardening
- Action: MODIFY / AUDIT
- Status: STATIC-AUDIT-PASS
- File: `src/org/recompile/mobile/RG35XXWavDecoder.java`.
- Document: `docs/RC1-WAV-PCM-AUDIT.md`.
- Pre-change reload: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY completed.
- PCM invariant: reject incomplete PCM8/PCM16 channel frames rather than silently truncating one sample/channel.
- Law invariant: reject incomplete multi-channel A-law/mu-law frames.
- IMA invariant: require 4-bit IMA; decode low nibble first; stereo consumes 4 left bytes + 4 right bytes per group and emits eight interleaved L/R frames.
- Allocation correction: removed per-stereo-group `byte[][]` and `int[]` allocations from the decoder loop.
- Malformed-tail policy: a full stereo IMA block with non-8-byte body alignment is rejected; a short final block decodes only complete L/R groups and never emits an unmatched channel tail.
- Basis: upstream decoder behavior plus IMA-WAV block packing specification and synthetic format fixtures documented in RC1-WAV-PCM-AUDIT.
- BUILD-PASS is not claimed; consolidated Java compilation remains pending.

## RGJ-RC1-010D — Native PCM source-rate correction
- Action: MODIFY / AUDIT
- Status: STATIC-AUDIT-PASS
- File: `native/rg35xx_mixer.c`.
- Discovery: prior PCM render consumed one source frame per 44.1 kHz output frame. `sample_rate` affected media-time only, so non-44.1 kHz WAV had incorrect duration/pitch.
- Correction: each PCM voice now owns Q15 source position + rate step (`sourceRate * 32768 / 44100`) and performs linear interpolation between adjacent PCM16 frames.
- Hot-path constraint: no malloc/calloc/free added; interpolation uses bounded signed 32-bit multiply, with uint64_t only for persistent position/time arithmetic.
- Sanity rates documented: one second at 8k/11.025k/14.7k/22.05k/32k/44.1k/48k maps to approximately one second of 44.1 kHz output, with only bounded Q15 rounding.
- Preserved: mono duplicates to stereo, volume/loop/media-time semantics, native END_OF_MEDIA callback, fixed `RG35XX_MIXER_RATE=44100`.
- BUILD-PASS and device audio-quality validation remain pending.
