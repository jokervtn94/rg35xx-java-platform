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
- Reason: advertised capabilities must not cause a game to select an unsupported codec on RG35XX.

### RGJ-B3-002 — Truthful RG35XX MMAPI capability reporting
- Action: MODIFY
- Status: PLANNED
- Target source: javax.microedition.media.Manager.getSupportedContentTypes/getSupportedProtocols.
- Source of truth: RG35XXMediaProfile.
- Initial target truth: MIDI, WAV/PCM/IMA/A-law/mu-law and tone; AMR/MPEG remain unadvertised until a target decoder is proven.
- Regression focus: Zombie Infection format negotiation.

### RGJ-B3-003 — RG35XXMediaRegistry
- Action: ADD
- Status: PLANNED
- Responsibility: stable player IDs, type, lifecycle, loop count, volume, media time and native registration state.
- Rule: Player semantics stay in Java; decode/mix timing truth for native-backed formats stays native.

### RGJ-B3-004 — Dedicated Java-to-native audio transport
- Action: REPLACE
- Status: PLANNED
- Before: media blobs/commands staged through files under /mnt/mmc/BIOS.
- After target: separate audio command/blob channel that cannot corrupt stdout video IPC.
- Constraint: do not multiplex large audio payloads into binary video stdout.
- Rollback: preserve current SD bridge until the new channel passes static/protocol audit.

### RGJ-B3-005 — Native media blob cache
- Action: ADD
- Status: PLANNED
- Purpose: register immutable MIDI/PCM media once by player ID and reuse it for PLAY/STOP/SEEK/VOLUME commands.
- Benefit: eliminate repeated SD reads/staging during gameplay.

### RGJ-B3-006 — CPU-bounded native mixer/player model
- Action: ADD
- Status: PLANNED
- Target: one BGM MIDI context plus bounded SFX MIDI/PCM voices appropriate for ARM926-class target cost.
- Preserve: asynchronous libretro audio callback/ring architecture and native END_OF_MEDIA truth.

### RGJ-B3-007 — Media Engine real-JAR regression audit
- Action: AUDIT
- Status: PLANNED
- Diamond Rush: PCM WAV + MMAPI.
- Asphalt 4: MIDI + PCM + IMA ADPCM + VolumeControl.
- Zombie Infection: capability negotiation with multiple advertised media variants.
- Prince of Persia: packed MIDI/PCM and Player lifecycle.
- God of War: multi-MIDI behavior.
- Vua Cướp Biển: no invented audio for a binary without actual audio implementation/assets.
