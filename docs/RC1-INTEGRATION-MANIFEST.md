# RG35XX Java Platform 1.0 — Consolidated RC1 Integration Manifest

Status: PRE-RC / source-integration gate. This document does not claim BUILD-PASS or DEVICE-TEST-PASS.

## Runtime facts carried into RC1

- Target runtime is JamVM/GNU Classpath on RG35XX Original / GarlicOS.
- Desktop JavaSound/ALSA MIDI is not a valid target backend; RG35XX media uses the native TML/TSF + PCM path.
- stdout remains binary Java↔libretro video IPC and must never carry diagnostics or audio payloads.
- Native audio/video worker threads remain independent of retro_run hot-path blocking.

## Consolidated Java source set

Required RG35XX classes:

- RG35XXPlatformProfile
- RG35XXFrameScheduler
- RG35XXImageCache
- RG35XXInputEngine
- RG35XXWavDecoder
- RG35XXMediaProfile
- RG35XXMediaRegistry
- RG35XXAudioProtocol
- RG35XXAudioTransport
- RG35XXAudioBootstrap
- RG35XXNativePlayer
- RG35XXFontEngine
- RG35XXTransformCache
- RG35XXRmsCoordinator
- RG35XXRmsAtomicFile
- RG35XXLifecycle

Integration targets that must be checked against exact FreeJ2ME source before first build:

- javax.microedition.lcdui.Font / PlatformFont
- PlatformGraphics
- PlatformImage
- MobilePlatform
- PlatformPlayer
- javax.microedition.media.Manager
- javax.microedition.rms.RecordStore
- org.recompile.freej2me.Libretro

## Consolidated native source set

- rg35xx_audio_protocol.h
- rg35xx_media_cache.h/.c
- rg35xx_audio_dispatch.h/.c
- rg35xx_audio_pipe.h/.c
- rg35xx_mixer.h/.c
- rg35xx_midi_backend.h/.c
- existing freej2me_libretro.c audio worker/ring/video receiver/RGB565 paths

## Mandatory source gates

### G1 — Java compatibility

All new classes must compile with the project Java language level and avoid APIs unavailable on GNU Classpath target. No java.nio.file dependency may be introduced by RG35XX-specific persistence code.

### G2 — Font metric/raster unity

Font measurement and PlatformGraphics text rasterization must share RG35XXFontEngine metrics. DoJa inheritance must remain valid. Font resource loading must be classpath-based, not per-frame filesystem I/O.

### G3 — Graphics hot path

Validate drawRGB clipping/alpha specialization, Sprite transform-cache indexing, drawRegion fallback semantics and zero allocations in repeated transformed drawing after cache warm-up.

### G4 — Image compatibility

PlatformImage must preserve indexed PNG tRNS repair and immutable cache-copy semantics. Mutable MIDP images must never share cached mutable backing arrays.

### G5 — Input semantics

Libretro button mapping must feed RG35XXInputEngine press/release/update deterministically. Numeric keypad direct J2ME codes, star and pound remain available. No release-triggered legacy repeat scan may remain active in parallel.

### G6 — Media capability truth

Manager must advertise RG35XXMediaProfile capabilities on target. PlatformPlayer keeps vendor/MMAPI facade compatibility but native-backed formats route through RG35XXNativePlayer/MediaRegistry.

### G7 — Dedicated audio transport

Native pipe is created before fork/exec. JamVM child receives the write FD via -Dfreej2me.rg35xx.audio.fd=N. Java opens only /proc/self/fd/N; fd 0/1/2 are rejected. Parent read side is non-blocking and framed by RG35XXAudioProtocol.

### G8 — Native mixer/link contract

All TML/TSF adapter symbols must resolve exactly once. Mixer has no per-render heap allocation. PCM and MIDI share bounded accumulation/output. RELEASE/RESET cannot leave voices referencing freed media blobs.

### G9 — END_OF_MEDIA

Native playback completion is authoritative. One finite player completion must produce exactly one Java END_OF_MEDIA event; loop restart must not produce premature completion. Java timers must not synthesize native completion.

### G10 — RMS persistence

RecordStore semantic state remains authoritative in RAM. Dirty writes are coalesced. Background failure must not spin forever; forceFlush retries failed stores once and surfaces persistent failure. Shutdown must stop the RMS worker even when flush fails.

### G11 — Lifecycle ordering

platformStart:
1. RMS coordinator start
2. inherited audio bridge attach (fail-safe)

beforeGameLoad:
1. unload active game if needed
2. defensive native media RESET
3. Java media registry reset
4. image/transform/input/frame per-game reset

unloadGame:
1. RMS forceFlush
2. native media RESET
3. Java media registry reset
4. input/image/transform/frame reset

platformShutdown:
1. unloadGame
2. audio bridge shutdown
3. RMS worker shutdown
4. propagate first captured failure only after teardown attempts

### G12 — Native shutdown ownership

Audio callback must be disabled/stopped before ring/cache destruction. Video receiver and audio worker are joined before freeing their state. Pipe descriptors are closed exactly once in the owning process.

## Real-device evidence already available, but not RC1 PASS

Historical device logs show JamVM successfully fork/execs and accepts READY, native audio workers start and stop, RGB565 video receiver threads run, and TML/TSF playback can prime the native ring. These logs are compatibility evidence only; RC1 still requires a new build and fresh device regression after consolidation.

## RC1 first-build acceptance

The first build is allowed only after G1–G12 are source-audited against the assembled tree. BUILD-PASS requires both:

1. `rm -rf build && ant` succeeds for Java, and
2. the ARMv5TE/uClibc libretro core links with no undefined RG35XX media/lifecycle symbols.

No device performance conclusion is allowed from host compilation alone.
