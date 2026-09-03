# RG35XX Java Platform 1.0 — Consolidated RC1 Integration Manifest

Status: STATIC-AUDIT-PASS for the consolidated source policy. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Pinned FreeJ2ME-Plus base: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.

This manifest supersedes the older pre-pin assumptions in the first RC1 draft. In particular, the missing historical `RG35XXFontEngine` is no longer a required class, the pinned RecordStore baseline is synchronous/multi-file rather than the old single-target async design, and the native media source set now includes the complete RC1 mixer/MIDI/runtime/event modules.

## Runtime facts carried into RC1

- Target runtime is JamVM 2.0.0 / GNU Classpath 0.99 on RG35XX Original / GarlicOS.
- Desktop JavaSound/ALSA MIDI is not a valid target backend; RG35XX supported media uses the native TML/TSF + PCM path.
- stdout remains binary Java↔libretro video IPC and must never carry diagnostics or audio payloads.
- Audio uses a dedicated inherited descriptor/pipe; media completion returns through the typed native event path.
- Native audio/video work remains decoupled from blocking work inside `retro_run()`.
- Historical device logs are compatibility evidence only; every RC status after source assembly requires fresh build/device evidence.

## Consolidated project Java source set

Required project-owned classes under `org.recompile.mobile`:

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
- RG35XXToneSequenceEncoder
- RG35XXTransformCache
- RG35XXRmsCoordinator — present but dormant on pinned synchronous RMS baseline
- RG35XXRmsAtomicFile — present but unhooked on pinned multi-file RMS baseline
- RG35XXLifecycle

Explicitly NOT required / must not be silently resurrected:

- `org.recompile.mobile.RG35XXFontEngine` — historical implementation source/resource was not recovered; responsibility is superseded under RC1-011D by the GNU Classpath headless FontPeer backend while existing FreeJ2ME PlatformFont/PlatformGraphics remain facade/consumer owners.

Pinned upstream integration owners:

- `org.recompile.mobile.PlatformFont`
- `org.recompile.mobile.PlatformGraphics`
- `org.recompile.mobile.PlatformImage`
- `org.recompile.mobile.MobilePlatform`
- `org.recompile.mobile.PlatformPlayer`
- `javax.microedition.media.Manager`
- `javax.microedition.rms.RecordStore`
- `org.recompile.freej2me.Libretro`
- `src/libretro/freej2me_libretro.c`

Target-runtime integration owner outside the FreeJ2ME tree:

- GNU Classpath 0.99 `gnu.java.awt.peer.headless.HeadlessToolkit` plus one real cached `ClasspathFontPeer`/FontDelegate path, as defined by patch 0022.

## Consolidated native source set

Project native modules required exactly once:

- rg35xx_audio_protocol.h
- rg35xx_media_cache.h/.c
- rg35xx_media_events.h
- rg35xx_media_event_queue.h/.c
- rg35xx_audio_dispatch.h/.c
- rg35xx_audio_pipe.h/.c
- rg35xx_mixer.h/.c
- rg35xx_midi_backend.h/.c
- rg35xx_tsf_worker.h/.c
- rg35xx_tsf_impl.c — sole `TSF_IMPLEMENTATION` / `TML_IMPLEMENTATION` owner
- rg35xx_soundfont_source.h/.c
- rg35xx_media_runtime.h/.c
- existing pinned/consolidated `freej2me_libretro.c` as the sole core entrypoint/integration owner

Third-party native inputs:

- TinyMidiLoader `tml.h` from `schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa`, Git blob `333287377fa860fa7f3d8fe8096d3cf32bfbb6ea`.
- TinySoundFont `tsf.h` from the same pin, Git blob `a81f25d5ca2e210720d646dec2dbfaeb119acb09`.
- one authoritative SoundFont asset/provider, still unresolved and therefore a hard BUILD-READY gate.

## Mandatory source gates

### G1 — Pinned source identity

All integration work is applied against FreeJ2ME-Plus commit `13ec186903087156c145268f8706eecfaf9f1e50`. No moving `devel` source is silently substituted. Rebase to a newer upstream requires a new explicit task and full call-site re-audit.

### G2 — Java/GNU Classpath compatibility

Project Java code must compile at the project language level and avoid APIs unavailable on JamVM/GNU Classpath. RG35XX persistence code must not introduce `java.nio.file`. Desktop JavaSound, JLayer and ScheduledExecutorService paths may remain upstream for desktop targets but may not become mandatory RG35XX runtime dependencies.

### G3 — Headless font backend

FreeJ2ME PlatformFont remains LCDUI/DoJa font policy and metrics facade; PlatformGraphics remains the draw consumer. GNU Classpath headless AWT must return a real non-null FontPeer/FontDelegate for logical fonts. Do not patch `java.awt.Font` to tolerate a null peer and do not globally sanitize Unicode to ASCII. The authoritative font resource must be present at assembly time and must not be loaded per draw call.

Acceptance includes stable `Font.hashCode()`, `createGlyphVector()`, FontMetrics and deterministic Vietnamese/missing-glyph behavior on the target classpath build.

### G4 — Graphics hot path

Preserve surgical PlatformGraphics integration: drawRGB clipping/alpha specialization, Sprite transform-cache geometry, drawRegion fallback semantics and no allocation in repeated hot inner loops after cache warm-up. Do not replace the heavily compatibility-tuned upstream PlatformGraphics class.

### G5 — Image compatibility

PlatformImage remains decoder/facade owner. Preserve indexed PNG tRNS repair and immutable cache-copy semantics. Mutable MIDP/DoJa images must never share cached mutable backing arrays.

### G6 — Dirty-frame ownership

MobilePlatform remains LCD/frontbuffer/render owner. RG35XXFrameScheduler is a generation/wakeup helper only. Do not block the single LibretroIO command parser waiting for dirty generations and do not introduce a second FPS limiter/frame thread. Mark dirty only after coherent frontbuffer production.

### G7 — Input semantics

Libretro remains protocol owner; MobilePlatform remains MIDP/vendor dispatch owner; `Mobile.getMobileKey(slot)` remains slot mapping owner. RG35XXInputEngine owns only RG35XX held/repeat state. Replace the upstream direct transition dispatch rather than running both in parallel; preserve numeric/star/pound behavior and keep frontend fast-forward slot handling separate.

### G8 — Media capability truth

RG35XX target capabilities advertise only implemented native-backed formats: direct MIDI, WAV/PCM normalization and ToneControl converted to MIDI. Vendor containers whose current upstream decoders still require JavaSound are preserved but not advertised. `device://midi` live ShortMessage transport remains unclaimed.

### G9 — Dedicated audio/process boundary

Native audio pipe is created before fork/exec. JamVM child receives `-Dfreej2me.rg35xx.audio.fd=N` before `-jar`; fd 0/1/2 are rejected. Parent and child close the opposite ends exactly once. Audio is never multiplexed onto stdout video IPC.

### G10 — Native mixer, MIDI and dependency contract

PCM and MIDI share one bounded 44.1-kHz mixer. `rg35xx_tsf_impl.c` is the only TML/TSF implementation translation unit. Exact vendor headers must pass `native/verify_tinysoundfont_vendor.sh`. The audio render hot path performs no project-introduced heap allocation/blocking I/O. RELEASE/RESET cannot leave active voices pointing at freed media.

### G11 — Media event semantics

Native playback completion is authoritative. Intermediate loop restart emits LOOPED while Java player state remains STARTED. Final finite completion emits END_OF_MEDIA exactly once and transitions the Java facade appropriately. Audio callbacks enqueue typed events; only the existing control-writer context serializes them back to Java.

### G12 — RMS pinned safe baseline

Pinned RecordStore persists metadata in `basename.rms` and record payloads in sibling `basename.<recordId>` files. RC1 keeps upstream synchronous persistence semantics until a future explicit transaction task can cover the complete multi-file generation. RG35XXRmsCoordinator/RG35XXRmsAtomicFile remain present but dormant/unhooked; old single-target patch 0009 must not be reapplied.

Lifecycle barriers may call the dormant coordinator safely but must not create an unnecessary worker on this baseline.

### G13 — Lifecycle and shutdown ordering

`platformStart`: initialize target-wide project subsystems without creating per-game duplicate workers.

`beforeGameLoad`: unload/reset prior per-game state defensively, but do not commit a successful-load state before `MobilePlatform.load()` succeeds.

`afterGameLoad`: commit per-game lifecycle state only after successful load.

`gameLoadFailed`: roll back prepared state when load fails.

`unloadGame` / final shutdown: preserve RMS semantics, reset native media before discarding Java player ownership, reset input/image/transform/frame state, close/stop media transports/workers and allow Java graceful cleanup before native hard-kill fallback.

### G14 — Build-input provenance and assembled-source gate

Before the first build all of the following must be physically present in one reproducible tree:

1. exact pinned FreeJ2ME source;
2. current project Java/native sources exactly once;
3. authoritative integration patches/contracts accounted for, including 0020/0021/0022;
4. exact TML/TSF vendor headers with verified Git blob identities;
5. GNU Classpath 0.99 source/resource integration required by the headless FontPeer contract;
6. one explicit authoritative SoundFont asset/provider;
7. consolidated native Makefile/include/link inputs covering every registered native module and required `-lm` linkage.

`native/vendor_tinysoundfont.sh` may be used during source acquisition, but normal release/native builds must be offline and fail closed if dependency files are absent or modified.

## Superseded pre-pin assumptions

The following old assumptions remain historical evidence but are not RC1 build policy:

- `RG35XXFontEngine` as a mandatory project class.
- shared metrics/raster ownership through the missing historical bitmap class.
- old single-target asynchronous RMS patch 0009 as the pinned persistence implementation.
- blocking dirty-frame consumption in the single LibretroIO parser.
- provisional TML/TSF blob IDs recorded before exact Git-tree reconciliation.

## First-build authorization

The project is NOT yet BUILD-READY. First Java/native compilation is authorized only after G1-G14 are represented in one assembled source tree and the hard external inputs in G3/G10/G14 are present.

BUILD-PASS requires both:

1. `rm -rf build && ant` succeeds for the assembled Java tree, and
2. the ARMv5TE/uClibc libretro core compiles/links with no undefined RG35XX symbols and exact dependency inputs.

Host/cross BUILD-PASS still does not imply DEVICE-TEST-PASS. Fresh RG35XX regression testing begins only after the consolidated artifacts are produced.