# RG35XX Java Platform Tasklog

Tasklog history is immutable. If a decision is reverted, create a new REVERT/REPLACE task; do not erase the original engineering decision.

Actions: `ADD`, `MODIFY`, `REMOVE`, `DISABLE`, `REPLACE`, `KEEP`, `REVERT`, `AUDIT`.

Statuses: `PLANNED`, `IMPLEMENTED`, `STATIC-AUDIT-PASS`, `BUILD-PASS`, `DEVICE-TEST-PASS`, `DEVICE-TEST-FAIL`, `ROLLED-BACK`, `SUPERSEDED`.

## Proven legacy baseline

### RGJ-LEGACY-001 — uClibc/JamVM runtime
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Reason: target is ARM32 EABI5/uClibc/soft-float GarlicOS userspace.
- Decision: JamVM + GNU Classpath; do not silently switch to glibc/OpenJDK.

### RGJ-LEGACY-002 — Headless AWT
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Reason: GarlicOS target has no desktop GTK/X11 runtime.

### RGJ-LEGACY-003 — PNG indexed tRNS repair
- Action: KEEP
- Status: DEVICE-TEST-PASS
- File: PlatformImage
- Reason: GNU Classpath PNG decoding lost palette alpha and produced white sprite rectangles.
- Rollback: only after replacing the affected image decoder semantics.

### RGJ-LEGACY-004 — RGB565 IPC
- Action: KEEP
- Status: DEVICE-TEST-PASS
- Files: Libretro.java / freej2me_libretro.c
- Reason: reduce Java/native frame payload by one third versus RGB888.

### RGJ-LEGACY-005 — Native receiver pthread/double buffer
- Action: KEEP
- Status: DEVICE-TEST-PASS
- Reason: drain Java frame pipe independently of retro_run().

### RGJ-LEGACY-006 — Asynchronous native audio
- Action: KEEP
- Status: DEVICE-TEST-PASS
- Reason: audio must not depend on frontend frame cadence.

### RGJ-LEGACY-007 — prepareMediaEngine disabled
- Action: DISABLE
- Status: DEVICE-TEST-PASS
- Reason: GNU Classpath JavaSound/MIDI incompatibility caused unstable initialization/SIGABRT.
- Rollback: only with a replacement media backend.

### RGJ-LEGACY-008 — stdout reserved for IPC
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Reason: Java stdout carries the binary FreeJ2ME/libretro protocol.

### RGJ-LEGACY-009 — Direct numeric keypad mapping
- Action: KEEP
- Status: DEVICE-TEST-PASS
- Reason: standard numeric J2ME keycodes must not depend on vendor profile remapping.

### RGJ-LEGACY-010 — Native MIDI END_OF_MEDIA
- Action: KEEP
- Status: DEVICE-TEST-PASS
- Reason: native synthesizer owns playback truth; command 16 reports real finite MIDI completion to Java Player state/listeners.

## Platform 1.0 Alpha 1

### RGJ-A1-001 — RG35XXPlatformProfile
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Reason: centralize target policy/constants instead of spreading magic numbers.

### RGJ-A1-002 — RG35XXFrameScheduler
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Reason: track LCD generation and avoid serializing duplicate frames.
- Risk: a render path missing markDirty can hold an old frontend frame.
- Rollback: return to request-driven frame serialization.

### RGJ-A1-003 — Dirty hooks in MobilePlatform
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Symbols: resizeLCD, flushGraphics, drawAppTerminated
- Reason: completed LCD flush is the authoritative fresh-frame signal.

### RGJ-A1-004 — Dirty-aware Java frame worker
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- File: Libretro.java
- Preserved: short LCD lock, RGB565 LUT, low-priority frame worker.

## Platform 1.0 Beta 1

### RGJ-B1-001 — RG35XXImageCache
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Design: immutable decoded ARGB LRU; 12 MiB / 192 entries.
- Reason: reduce repeated resource decode during scene transitions.

### RGJ-B1-002 — PlatformImage resource cache hook
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Preserved: PNG tRNS repair.

### RGJ-B1-003 — PlatformImage byte-slice cache hook
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Key: length + CRC32 for immutable byte-backed images.

### RGJ-B1-004 — RG35XXInputEngine
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Repeat: 340 ms initial delay / 75 ms interval.
- Repeatable: directions and keypad.
- Non-repeatable: Fire and softkeys.

### RGJ-B1-005 — Remove release-triggered global repeat scan
- Action: REMOVE
- Status: STATIC-AUDIT-PASS
- Old behavior: releasing one key scanned all held keys and generated keyRepeated events.
- Replacement: RG35XXInputEngine.
- Reason: incorrect J2ME semantics and possible double/unrelated actions.
- Rollback: restore legacy block in Libretro.java.

### RGJ-B1-006 — RG35XXWavDecoder
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Formats: PCM 8/16, Microsoft IMA ADPCM, G.711 A-law, G.711 mu-law.
- Output: signed PCM16 little-endian.

### RGJ-B1-007 — Unified WAV path
- Action: REPLACE
- Status: STATIC-AUDIT-PASS
- New path: resource stream -> RG35XXWavDecoder -> PCM16 -> native PCM bridge.

### RGJ-B1-008 — RG35XXMediaProfile
- Action: ADD
- Status: IMPLEMENTED
- Purpose: central source of truth for codec capability reporting.

### RGJ-B1-009 — RG35XXRuntimeStats
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Reason: aggregate diagnostics without per-frame SD logging.

## Platform 1.0 Beta 2 — Unified Font Engine

### RGJ-B2-001 — Real-game JAR compatibility corpus
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Rule: user-supplied game JARs are compatibility evidence; binaries/assets are not committed.
- Output: package/API/resource matrices and non-content metadata.

### RGJ-B2-002 — Unified font semantic audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Scope: MIDP/DoJa Font metrics, Graphics text calls, anchors, baseline and Unicode resource renderer.
- Finding: upstream PlatformFont measurement is AWT FontMetrics-based while RG35XX raster is bitmap/direct, creating a metric divergence risk.

### RGJ-B2-003 — RG35XXFontEngine
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Requirement: charWidth/charsWidth/stringWidth/substringWidth/getHeight/baseline and renderer share one metric source.
- Preserved: 22,719-glyph embedded Unicode resource, Vietnamese/CJK coverage.
- Risk: changing metrics can alter menu/layout geometry.

### RGJ-B2-004 — PlatformFont RG35XX measurement backend
- Action: REPLACE
- Status: STATIC-AUDIT-PASS
- Before: java.awt.FontMetrics was authoritative for measurement.
- After: RG35XX target uses RG35XXFontEngine metrics matching raster advances.
- Rollback: restore AWT metrics together with matching AWT renderer; do not mix metric sources.

### RGJ-B2-005 — PlatformGraphics unified text raster backend
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Reason: text rendering and Font measurement must use identical glyph advances, height and baseline.

### RGJ-B2-006 — LCDUI/PlatformFont validation correctness
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Finding: grouped invalid face/style/size checks could allow a single invalid group through.
- Decision: validate each contract correctly without changing valid MIDP behavior.

### RGJ-B2-007 — DoJa font compatibility
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Requirement: SIZE_TINY, BOLDITALIC and DoJa measurement helpers continue through the shared font facade/engine.

### RGJ-B2-008 — Embedded font resource path
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Reason: keep glyph data in JAR resources; no game-loop filesystem font lookup.

### RGJ-B2-009 — Six-JAR static regression audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Result: font/text API surface remains covered by the shared measurement/raster architecture.

### RGJ-B2-010 — Beta 2 final source audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Result: 13/13 structural checks passed; no Java/native IPC change.
- Device build/test: intentionally deferred until Platform 1.0 consolidated RC.

## Platform 1.0 Beta 3 — Media Engine 2.0

### RGJ-B3-001 — Upstream Manager/PlatformPlayer semantic audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Finding: upstream Manager advertises MIDI, WAV, MLD, AMR, MPEG, tone, MMF, iMelody and audio/basic unconditionally.
- Finding: upstream PlatformPlayer contains desktop JavaSound/MIDI/MP3 and multiple decoder paths not equivalent to the proven RG35XX native backend.

### RGJ-B3-002 — Truthful RG35XX MMAPI capability reporting
- Action: MODIFY
- Status: IMPLEMENTED
- Source: RG35XXMediaProfile + patches/0003-manager-rg35xx-media-profile.patch.
- Initial truth: MIDI, WAV/PCM/IMA/A-law/mu-law and tone; AMR/MPEG remain unadvertised.
- Regression focus: Zombie Infection format negotiation.

### RGJ-B3-003 — RG35XXMediaRegistry / native Player lifecycle adapter
- Action: ADD
- Status: IMPLEMENTED
- Sources: RG35XXMediaRegistry.java, RG35XXNativePlayer.java, docs/MMAPI-LIFECYCLE.md.
- Responsibility: stable player IDs, lifecycle, loop count, volume, media time and native registration state.
- Rule: PlatformPlayer remains public/vendor compatibility facade.

### RGJ-B3-004 — Dedicated Java-to-native audio transport
- Action: REPLACE
- Status: IMPLEMENTED
- Sources: RG35XXAudioProtocol.java, RG35XXAudioTransport.java, RG35XXAudioBootstrap.java, native/rg35xx_audio_pipe.*.
- Before: media blobs/commands staged through files under /mnt/mmc/BIOS.
- New path: separate inherited FD pipe; stdout remains video IPC only.
- Rollback: legacy SD bridge is retained until consolidated audit/build/device validation.

### RGJ-B3-005 — Native media blob cache
- Action: ADD
- Status: IMPLEMENTED
- Sources: native/rg35xx_media_cache.* and native/rg35xx_audio_dispatch.c.
- Purpose: immutable MIDI/PCM registration once by player ID; later commands reuse RAM media.

### RGJ-B3-006 — CPU-bounded native mixer/player model
- Action: ADD
- Status: IMPLEMENTED
- Sources: native/rg35xx_mixer.*, native/rg35xx_midi_backend.*.
- Bound: 8 PCM voices, 2 MIDI contexts; slot 0 retained as primary/BGM, slot 1 deterministic SFX replacement.
- Preserve: asynchronous libretro audio callback/ring and native END_OF_MEDIA truth.

### RGJ-B3-STAB-001 — Remove allocation from audio render hot path
- Action: MODIFY
- Status: STATIC-AUDIT-PASS
- Before: rg35xx_mixer_render used calloc/free on every render call.
- After: static 1024-frame stereo int32 accumulator reused in bounded chunks.
- Reason: avoid allocator churn/latency on ARM926 and reduce frame/audio instability risk.
- Rollback: none recommended; allocation-free render is behavior-equivalent.

### RGJ-B3-007 — Media Engine real-JAR regression audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Evidence corpus: Diamond Rush, Asphalt 4, Zombie Infection, Prince of Persia Two Thrones, God of War Betrayal, Vua Cướp Biển.
- Diamond Rush: PCM WAV/MMAPI path maps to WAV decoder -> PCM16 registration -> bounded PCM mixer; RMS remains a later storage subsystem task.
- Asphalt 4: MIDI + PCM + Microsoft IMA ADPCM + VolumeControl are represented by truthful capability/decode/mixer paths.
- Zombie Infection: AMR/MMF/MPEG are intentionally not advertised by RG35XXMediaProfile; MIDI/WAV remain selectable supported paths.
- Prince of Persia: packed MIDI/PCM resources are registered from memory; Player lifecycle is delegated through RG35XXNativePlayer.
- God of War: multiple MIDI Players map to bounded 2-context MIDI policy; deterministic SFX replacement prevents unbounded synth growth.
- Vua Cướp Biển: no media backend is invented for a JAR with no actual audio implementation/assets.
- Limitation: static audit proves architecture/API coverage, not device timing or game-specific runtime correctness.

### RGJ-B3-008 — Consolidated source/protocol gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Java language gate: target additions use Java-6-compatible syntax; upstream build.xml compiles source/target 1.6.
- Protocol parity: Java/native magic 0x41354A52, version 1, 14-byte header, 4 MiB payload cap and opcodes 1..10 match exactly.
- stdout isolation: dedicated inherited audio FD remains separate from binary video stdout IPC.
- Pipe lifecycle: create before fork; parent owns nonblocking read end; JamVM child inherits write end; partial header/payload state retained across reads.
- Reset/release: mixer voice/context release precedes media blob free; RESET clears mixer before media cache.
- Hot path: mixer render uses preallocated bounded accumulator; no per-render heap allocation and no SD media staging in new transport path.
- END_OF_MEDIA: native playback remains authoritative; Java timer synthesis is prohibited. Existing proven native completion path remains compatibility anchor until event-channel replacement.
- C-link caveat: TML/TSF hook functions are an explicit integration contract with the existing core worker and must be resolved when the consolidated source tree is assembled; therefore BUILD-PASS is intentionally not claimed here.
- Result: Beta 3 source/protocol architecture is statically lockable; build/device gates remain deferred to consolidated RC as planned.

### RGJ-B3-009 — Beta 3 lock
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Decision: Media Engine 2.0 architecture is frozen for Platform 1.0 unless a later audit/build/device test creates an explicit REVERT/REPLACE task.
- Preserved rollback: legacy SD bridge remains present but non-preferred until consolidated build/device validation proves the dedicated transport end-to-end.
- Next subsystem: Beta 4 Graphics Engine optimization and compatibility audit.

## Platform 1.0 Beta 4 — Graphics Engine

### RGJ-B4-001 — Upstream PlatformGraphics hot-path audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Finding: drawRegion TRANS_NONE already reaches direct drawRGB; transformed sprites use a separate transformed-image path.
- Finding: drawRGB is direct framebuffer work, so optimization must preserve MIDP alpha, scanlength, translation and clip semantics rather than replace the renderer.

### RGJ-B4-002 — drawRGB clipped fast path
- Action: MODIFY
- Status: IMPLEMENTED
- Source: patches/0007-platformgraphics-rg35xx-fast-drawrgb.patch.
- Design: resolve destination clip once before the inner loop; processAlpha=false forces opaque alpha; processAlpha=true skips alpha 0, directly copies alpha 255 and blends only partial alpha.
- Constraint: no allocation or Graphics2D fallback in the pixel loop.

### RGJ-B4-003 — Preserve PNG transparency/image cache pipeline
- Action: KEEP
- Status: STATIC-AUDIT-PASS
- Reason: graphics optimization consumes already-decoded ARGB and must not bypass indexed PNG tRNS repair or immutable RG35XXImageCache semantics.

### RGJ-B4-004 — Bounded Sprite transform geometry cache
- Action: ADD
- Status: IMPLEMENTED
- Sources: src/org/recompile/mobile/RG35XXTransformCache.java and patches/0008-platformgraphics-transform-cache.patch.
- Design: cache destination-to-source index maps for the eight MIDP Sprite transforms, keyed by source width/height/transform.
- Bound: 24 maps with deterministic LRU replacement.
- Rule: cache geometry only; never cache mutable image pixels.

### RGJ-B4-005 — Transform-cache lifecycle
- Action: MODIFY
- Status: IMPLEMENTED
- Requirement: reset RG35XXTransformCache between games together with RG35XXImageCache during consolidated Libretro integration.
- Reason: bounded memory and deterministic per-game state.

### RGJ-B4-006 — Graphics compatibility gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Diamond Rush / Asphalt 4 / God of War: drawRGB path benefits directly while retaining alpha semantics.
- Prince of Persia: TiledLayer/Sprite transformed regions retain all eight MIDP transform geometries.
- Zombie Infection: packed decoded image data remains behind the same ARGB/tRNS pipeline.
- Limitation: exact integration against the consolidated modified PlatformGraphics source remains an RC assembly gate; BUILD-PASS is intentionally not claimed.

### RGJ-B4-007 — Beta 4 lock
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Decision: Graphics Engine optimization architecture is frozen unless consolidated-source audit reveals a semantic mismatch.
- No Java/native video protocol change; fixed 640x480 RGB565 frontend, dirty-frame scheduler and receiver thread remain unchanged.
- Next subsystem: Beta 5 RMS/storage engine and lifecycle audit.
