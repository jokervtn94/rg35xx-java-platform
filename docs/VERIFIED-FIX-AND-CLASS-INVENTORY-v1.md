# RG35XX Java Platform — Verified Fix and Class Inventory v1

This inventory is a rebuild input, not a wishlist. A change is admitted only when project tasklogs/device evidence support it.

## A. Admitted / device-proven foundation

### JamVM L Production
- Binary SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- Source fix commit: `6ae5cf3966b7b6b1f4fb81c0118dfc690b9736ca`
- Production workflow commit: `4c4641c0c9ddd263452287bf4873d64be716ff91`
- Fix: disable unsafe direct-interpreter `ALOAD_0 + GETFIELD -> GETFIELD_THIS` folding.
- Reason: local slot 0 is writable via `ASTORE_0`; the fold could read the stale method-entry receiver and produce an invalid object reference.
- Production excludes diagnostic tracing, low-pointer guards and test exit codes.

### GNU Classpath baseline
- `glibj.zip` SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Policy: immutable during foundation rebuild.
- N3/N3.1 PNGChunk byte patches are rejected.

### FreeJ2ME source baseline
- Pinned upstream commit: `13ec186903087156c145268f8706eecfaf9f1e50`
- Java target: class major 50 / Java 6 compatible.

### Lazy media boot
- `MobilePlatform.runJar()` starts the MIDlet without boot-time `Manager.prepareMediaEngine()`.
- No `RG35XX-MediaWarmup` thread.
- Media initialization remains lazy on actual media use.
- Device evidence showed boot-time ALSA sequencer probing could terminate/stall Java before normal game execution.

### Added Java class: `org.recompile.freej2me.RG35XXGoldenFrameTransport`
- Status: admitted foundation component.
- Owns asynchronous frame worker.
- Snapshots Java ARGB frontbuffer.
- Converts to RGB565.
- Writes framed binary transaction to preserved IPC stdout.
- Worker is non-daemon so the Java process remains alive after main construction.

### Added native Golden video component
- `native/golden/rg35xx_golden_video.c`
- `native/golden/rg35xx_golden_video.h`
- Native receiver reads exact framed payloads, validates dimensions, publishes via front/back buffers and generation counters.
- `retro_run()` presents the latest valid generation without blocking Java.
- Golden Smart-Fit owns physical 640x480 fitting; source MIDlet framebuffer dimensions remain authoritative.

## B. Required in the new clean rebuild, but not yet device-accepted

### Early native observability
The rebuilt core must open an early log before Java launch and record checkpoints for:
`retro_init -> retro_load_game -> game path -> IPC -> fork -> JamVM exec -> Java main -> LOAD -> RUN`.

Reason: current VC3 testing found some JARs can show a blue screen without producing normal Java/core logs. This is an observability defect. It must be fixed before compatibility work continues.

This logging addition must not alter resolution, frame semantics, media or lifecycle.

## C. Known compatibility defects — NOT foundation fixes yet

### PNG ICC v4
- Known failure: GNU Classpath ImageIO rejects some PNG iCCP profiles with `Wrong major version number:4`.
- A source-level PlatformImage compatibility approach has been explored.
- It is not admitted into the new foundation until the clean platform and early logging pass device acceptance.
- Never patch `glibj.zip` bytecode to solve it.

### Duplicate class definition / MIDletLoader
- Seen in Barman-family compatibility testing.
- Candidate fix: check already-loaded class before `defineClass()`.
- Not admitted until reproduced against the new clean foundation.

## D. Explicitly rejected from foundation
- JamVM diagnostic variants A through K.
- CHECKCAST low-pointer guards and diagnostic exit codes.
- N3/N3.1 `PNGChunk.class` binary patching.
- CV/CW boot-time resolution launcher changes.
- CK metric-scaled font experiment.
- RC/CD/CJ experimental presentation stacks.
- boot-time or daemon `prepareMediaEngine()` prewarm.
- any build labeled stable solely because CI passed.

## E. Deferred components

### Golden Unicode font
The historical Golden contract contains embedded `/org/recompile/mobile/rg35xx-font.bin` (size 727008, SHA256 `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`). Restore only after the clean boot/video foundation passes device acceptance.

### Golden audio
Restore the proven async audio/native MIDI/PCM architecture only after font checkpoint acceptance. Lazy media boot remains mandatory.

## F. Rebuild order
1. B0 architecture/source/device audit.
2. B1 exact JamVM L admission/reproduction gate.
3. B2 immutable GNU Classpath gate.
4. B3 pinned FreeJ2ME runtime + lazy boot + Golden frame transport.
5. B4 native Golden core + early native logging.
6. B5 canonical filesystem staging and aliases.
7. B6 atomic installer/backup/verify/collector.
8. One real-device acceptance pass.
9. Font, audio, then compatibility fixes as isolated admitted checkpoints.

No component becomes `STABLE` until real RG35XX acceptance.