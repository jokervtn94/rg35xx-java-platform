# RG35XX Java Platform — Verified Clean Manifest v1

This document is the source-of-truth for the clean rebuild. Nothing is admitted because it merely compiled. Device evidence has priority.

## Canonical execution flow

RetroArch -> FreeJ2ME libretro core -> inherited IPC pipes -> JamVM L -> GNU Classpath baseline -> freej2me-lr.jar -> Libretro command loop -> MobilePlatform -> MIDlet.

Video: Java ARGB framebuffer -> RG35XXGoldenFrameTransport worker -> RGB565 exact-length framed IPC -> native receiver thread -> validated back buffer -> atomic front/back publish -> Smart-Fit -> RG35XX output.

Boot: JAR LOAD -> RUN -> MobilePlatform.runJar() -> loader.start(). Boot-time Manager.prepareMediaEngine() is forbidden. Media initialization is lazy.

## Admitted components

### A. JamVM L Production — ADMITTED / DEVICE-PASS
SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

Verified fix: disable the invalid direct-interpreter `ALOAD_0 + GETFIELD -> GETFIELD_THIS` folding. `ASTORE_0` may replace local slot 0, so GETFIELD must use the current local-0 value. Diagnostics/low-pointer guards/test exits are not part of production.

### B. GNU Classpath baseline — ADMITTED / IMMUTABLE
SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Do not byte-patch glibj. N3/N3.1 are rejected.

### C. Lazy media boot — ADMITTED / DEVICE-PASS
`MobilePlatform.runJar()` starts the MIDlet without eager or background `Manager.prepareMediaEngine()`. `RG35XX-MediaWarmup` is forbidden. Device evidence showed ALSA `/dev/snd/seq` probing destabilized Java during boot, while lazy-only boot reached and sustained frame IPC.

### D. Golden asynchronous video transport — ADMITTED / DEVICE-PASS
Required source concepts/classes:
- `org.recompile.freej2me.RG35XXGoldenFrameTransport` (added class)
- `Libretro` integration that requests frames asynchronously
- native `rg35xx_golden_video.c/.h`
- receiver thread, exact-length reads, RGB565, front/back buffers, generation publish, Smart-Fit

The frame worker must not make `retro_run()` block on Java.

### E. Core/runtime VC3 binaries — BUILD-PASS, DEVICE COMPATIBILITY NOT YET FROZEN
Runtime SHA256: `eeb08e6b325b032c84776e2374b665c73461ca0d97f796907d3817691046f1e6`
Core SHA256: `3d7b9daac6be2058b8a669d943cf996984ba9a01127964067cda1c74fb1278a2`

Some real games run, while others show a blue screen without logs. Therefore these exact binaries are a clean checkpoint, not the final stable platform.

## Proven platform capabilities from device exerciser/comprehensive evidence

- MIDlet boot / Canvas 240x320
- PNG tRNS
- Sprite and mutable/offscreen graphics
- 36 font metric configurations without API failure
- Unicode path executes; visual quality remains a separate visual acceptance item
- input press/release/repeat
- RMS close/reopen persistence
- frame liveness
- playTone
- WAV END_OF_MEDIA
- MIDI END_OF_MEDIA
- ToneControl platform path passed in comprehensive test; Exerciser v1 getControl failure was a harness/API mismatch
- native RGB565 receiver + Smart-Fit

## Not admitted into the clean baseline

- PNG ICC v1/v2 source experiments: compatibility problem is real, but current fixes are not device-proven as a clean final solution.
- N3/N3.1 glibj byte patches.
- CV/CW boot/dynamic-resolution experiments.
- CK font metric scaling regression.
- boot-time or daemon media prewarm.
- diagnostic JamVM variants A-K as production binaries; only L production is admitted.
- any RC/CJ/CV/CW stack whose behavior contradicts Golden/device evidence.

## Classes/features that may be rebuilt only after the clean foundation is frozen

`RG35XXLifecycle.java` and other Beta lifecycle helpers are documented design work, not automatically admitted production code. They must be revalidated against the clean source tree and real-device acceptance before inclusion.

Golden Unicode font resource/path and Golden async audio ring/worker + native MIDI/PCM are desired restoration targets, but they must be added in separate checkpoints after boot/video/logging are frozen.

## Clean rebuild order

1. Audit device and source tree; produce hashes and path map.
2. Rebuild JamVM L independently and verify exact production semantics.
3. Rebuild GNU Classpath baseline unchanged.
4. Rebuild FreeJ2ME Java runtime from pinned upstream with only admitted boot/video changes.
5. Rebuild ARM libretro core with Golden video and mandatory early native logging.
6. Stage canonical aliases from one runtime and one core artifact.
7. Install atomically with backup and SHA verification.
8. Acceptance on multiple real games; no patching between games.
9. Freeze foundation.
10. Add font, audio, then compatibility fixes one checkpoint at a time.

## Mandatory logging contract for the new platform

The final clean core must open an early native session log before Java launch and record at least:
`retro_init`, `retro_load_game`, JAR path, core/runtime/JamVM hashes or build IDs, pipe creation, fork PID, exec attempt/result, Java READY, LOAD, RUN, first frame header, first frame publish, shutdown reason.

A blue/black screen with no log is unacceptable observability and blocks a stable designation.
