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

## Platform 1.0 Beta 2 — current work

### RGJ-B2-001 — Real-game JAR compatibility corpus
- Action: AUDIT
- Status: IMPLEMENTED
- Rule: user-supplied game JARs are compatibility evidence; binaries/assets are not committed.
- Output: package/API/resource matrices and non-content metadata.

### RGJ-B2-002 — Unified font semantic audit
- Action: AUDIT
- Status: PLANNED
- Scope: Font metrics + Graphics text calls across the JAR reference set.
- Goal: ensure measurement and rasterization use one engine.

### RGJ-B2-003 — RG35XXFontEngine
- Action: ADD
- Status: PLANNED
- Requirement: charWidth/charsWidth/stringWidth/substringWidth/getHeight/baseline and renderer share one metric source.
- Risk: changing Font semantics can alter menu/layout geometry.
- Rollback: retain prior Unicode resource renderer and old Font metrics as a matched pair.
