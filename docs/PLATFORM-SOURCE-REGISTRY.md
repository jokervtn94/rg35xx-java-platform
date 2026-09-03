# RG35XX Java Platform — Authoritative Source Registry

Status: RC1 PRE-BUILD control document.

This registry is the mandatory duplicate/missing-source gate for all future platform work. Before ADD/REMOVE/REPLACE of any RG35XX class, package, native module or integration patch, both `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md` and this registry must be reloaded.

## Rules

1. Never create a second class for an existing responsibility without an explicit REPLACE task.
2. Never resurrect a removed/superseded class or package from an older ZIP/patch without an explicit REVERT task.
3. Never remove a class/package solely because an old patch no longer references it; verify current source registry and integration manifest first.
4. Project-owned RG35XX Java code lives under `org.recompile.mobile` unless upstream API compatibility requires modifying an existing upstream package/class.
5. Do not create parallel RG35XX implementations inside `javax.microedition.*`; modify/adapt the existing upstream facade instead.
6. stdout is reserved for binary video IPC. Audio uses the dedicated RG35XX audio transport.
7. BUILD-PASS and DEVICE-TEST-PASS may only be recorded after the corresponding real validation.
8. Registry intent is not proof of file presence: every turn must also verify the current source tree for touched responsibilities.

## Authoritative RG35XX Java classes

Package `org.recompile.mobile`:

| Class | Responsibility | State |
|---|---|---|
| RG35XXPlatformProfile | target/profile feature policy | KEEP / PRESENT — EXPLICIT `freej2me.rg35xx` TARGET SELECTOR; 010L STATIC-AUDIT-PASS |
| RG35XXFrameScheduler | dirty-frame generation/wakeup | KEEP / PRESENT — PRODUCER/LIFECYCLE ONLY UNDER 011B; NO BLOCKING CASE-15 CONSUMER |
| RG35XXImageCache | immutable decoded-image LRU/cache | KEEP / PRESENT — 011B PINNED CALL-SITE CONTRACT |
| RG35XXInputEngine | deterministic key press/release/repeat | KEEP / PRESENT — 011B PINNED CALL-SITE CONTRACT |
| RG35XXWavDecoder | target WAV decode/normalization helper | KEEP / PRESENT — RC1 RESTORED |
| RG35XXMediaProfile | truthful target MMAPI capability policy | KEEP / PRESENT — MIDI/WAV/TONE ONLY AFTER 010N; VENDOR CONTAINERS NOT PROMOTED |
| RG35XXMediaRegistry | Java semantic player registry + bounded native-event queue | KEEP / PRESENT — LOOPED RETAINS STARTED; 010L CORRECTED |
| RG35XXAudioProtocol | Java/native framed audio protocol | KEEP / PRESENT |
| RG35XXAudioTransport | dedicated Java→native audio writer | KEEP / PRESENT |
| RG35XXAudioBootstrap | inherited audio-FD bootstrap/ownership | KEEP / PRESENT |
| RG35XXNativePlayer | native-backed MMAPI adapter + event binding | KEEP / PRESENT — MIDI/WAV/TONE-CONVERTED BACKEND; LOOPED/END SEMANTICS CORRECTED |
| RG35XXToneSequenceEncoder | JavaSound-free MIDP ToneControl A-BNF -> SMF format 0 | KEEP / PRESENT — 010M STATIC-AUDIT-PASS |
| RG35XXFontEngine | historical bitmap metrics/raster responsibility | SUPERSEDED / DO NOT RESTORE FROM MEMORY — 011D replaces ownership with GNU Classpath headless FontPeer + existing PlatformFont/PlatformGraphics |
| RG35XXTransformCache | bounded MIDP Sprite transform maps | KEEP / PRESENT — 011B PINNED CALL-SITE CONTRACT |
| RG35XXRmsCoordinator | coalesced low-priority RMS persistence | KEEP / PRESENT BUT DORMANT ON PINNED RC1 SYNC BASELINE — 011C |
| RG35XXRmsAtomicFile | Java-6-compatible atomic replacement helper | KEEP / PRESENT BUT UNHOOKED FROM PINNED MULTI-FILE RMS — 011C |
| RG35XXLifecycle | central subsystem lifecycle ordering | KEEP / PRESENT — 011B LOAD COMMIT SEMANTICS; 011C SYNC RMS BARRIERS SAFE |

No additional `RG35XX*` Java class should be introduced until this table is checked and the new responsibility is proven non-overlapping. A missing/superseded entry must be restored from authoritative source or handled by an explicit REPLACE task; do not silently invent a substitute.

## Existing upstream classes to integrate, not duplicate

These remain upstream-owned facades/implementations. RG35XX behavior must be hooked into them rather than creating replacement packages/classes with conflicting ownership:

- `javax.microedition.media.Manager`
- `javax.microedition.rms.RecordStore`
- `org.recompile.freej2me.Libretro`
- `org.recompile.mobile.MobilePlatform`
- `org.recompile.mobile.PlatformGraphics`
- `org.recompile.mobile.PlatformImage`
- `org.recompile.mobile.PlatformPlayer`
- upstream `org.recompile.mobile.PlatformFont`
- target GNU Classpath `gnu.java.awt.peer.headless.HeadlessToolkit` / one real `ClasspathFontPeer` backend for headless AWT fonts (011D replacement owner)

Vendor compatibility facades and upstream container decoders (Nokia/Siemens/KDDI/DoJa/JBlend, SMAF/MMF, MLD/MFi, EMS melody) are preserved. `RGJ-RC1-010N` proves that the current SMAFDecoder, MLDDecoder and EMSMelodyDecoder still rely on `javax.sound.midi` object construction and/or `MidiSystem.write`; therefore those container types are not advertised on RG35XX until an explicit JavaSound-free conversion task replaces only the backend conversion responsibility.

## Authoritative native modules

| Module | State |
|---|---|
| `rg35xx_audio_protocol.h` | KEEP / PRESENT |
| `rg35xx_media_cache.h/.c` | KEEP / PRESENT |
| `rg35xx_media_events.h` | KEEP / PRESENT — RC1 NATIVE EVENT CALLBACK OWNER |
| `rg35xx_media_event_queue.h/.c` | KEEP / PRESENT — BOUNDED CROSS-THREAD LOOPED/END HANDOFF; 010K STATIC-AUDIT-PASS |
| `rg35xx_audio_dispatch.c` | KEEP / PRESENT |
| `rg35xx_audio_dispatch.h` | KEEP / PRESENT — RC1 DECLARATION OWNERSHIP RESOLVED |
| `rg35xx_audio_pipe.h/.c` | KEEP / PRESENT |
| `rg35xx_mixer.h/.c` | KEEP / PRESENT |
| `rg35xx_midi_backend.h/.c` | KEEP / PRESENT |
| `rg35xx_tsf_worker.h/.c` | KEEP / PRESENT — RC1 REPLACEMENT IMPLEMENTATION; DEPENDENCY/BUILD AUDIT PENDING 010F |
| `rg35xx_tsf_impl.c` | KEEP / PRESENT — SINGLE TML/TSF IMPLEMENTATION TRANSLATION UNIT; VENDOR HEADERS PENDING |
| `rg35xx_soundfont_source.h/.c` | KEEP / PRESENT — EXPLICIT ALLOCATION-FREE SF2 BYTE SOURCE CONTRACT; CORE PROVIDER PENDING |
| `rg35xx_media_runtime.h/.c` | KEEP / PRESENT — NATIVE SF2 SOURCE→TSF WORKER INIT/SHUTDOWN ORDER OWNER; CORE CALL-SITE PENDING |
| existing `freej2me_libretro.c` | integration owner; do not create a parallel core entrypoint |

Dependency policy for the TML/TSF worker is locked in `docs/RC1-TML-TSF-DEPENDENCY-GATE.md`. The replacement worker source, explicit SoundFont byte-source contract, and native media runtime lifecycle coordinator now exist, but this does not claim that TinyMidiLoader/TinySoundFont vendored headers, an authoritative SoundFont asset/provider, consolidated core call-sites, native link, or device behavior is complete. The source holder owns no filesystem path, performs no I/O/allocation, and cannot substitute an arbitrary SoundFont for the still-unresolved authoritative asset/provider. Runtime ordering is source_set -> worker_init on startup and worker_shutdown -> source_clear on final shutdown; mixer/audio-pipe ownership remains outside this coordinator.

`RGJ-RC1-010K` closes the media process-boundary architecture at STATIC-AUDIT-PASS: mixer callbacks enqueue typed LOOPED/END events into the bounded native queue; only the existing libretro control-writer context serializes case-14 packets; Java case 14 queues and case 15 drains through `RG35XXMediaRegistry`; final Linux shutdown uses control-pipe EOF to give `RG35XXLifecycle.platformShutdown()` an RMS/media barrier opportunity before the existing hard-kill fallback.

`RGJ-RC1-010L` closes direct MIDI/WAV Java facade architecture at STATIC-AUDIT-PASS: an explicit RG35XX JVM property selects target behavior, desktop Manager/PlatformPlayer remains unchanged when false, JavaxPlatformPlayer remains the javax facade, and direct MIDI/WAV branch before desktop JavaSound/JLayer backend construction. Audit: `docs/RC1-DIRECT-MEDIA-FACADE-AUDIT.md`.

`RGJ-RC1-010M` closes ToneControl/Manager.playTone architecture at STATIC-AUDIT-PASS: `RG35XXToneSequenceEncoder` implements MIDP ToneControl grammar without JavaSound and produces SMF for the existing native MIDI backend; `audio/x-tone-seq` is truthfully promoted. `device://midi` live-message control remains explicitly unclaimed. Audit: `docs/RC1-TONECONTROL-AUDIT.md`.

`RGJ-RC1-010N` closes the vendor/container capability boundary at STATIC-AUDIT-PASS. Upstream SMAF/MMF, MLD/MFi and EMS iMelody/eMelody decoders are preserved but not promoted because their current conversion path constructs JavaSound MIDI objects and/or calls `MidiSystem.write`. Mixed sequence+PCM timing is part of any future replacement contract. Audit: `docs/RC1-VENDOR-MEDIA-CONTAINER-AUDIT.md`.

`RGJ-RC1-011B` closes pinned graphics/input/lifecycle call-site ownership at STATIC-AUDIT-PASS. It supersedes blocking dirty-frame consumption inside the single LibretroIO parser, routes key transition/repeat ownership through the existing RG35XXInputEngine, and splits game load prepare/success/failure lifecycle semantics. Audit: `docs/RC1-GRAPHICS-INPUT-LIFECYCLE-AUDIT.md`.

`RGJ-RC1-011C` closes the pinned RMS safe baseline at STATIC-AUDIT-PASS. Historical single-target async/atomic integration is superseded for the pinned multi-file RecordStore; upstream synchronous persistence remains the RC1 baseline while RG35XXRmsCoordinator/RG35XXRmsAtomicFile stay present but dormant/unhooked. Audit: `docs/RC1-RMS-PINNED-BASELINE-AUDIT.md`.

`RGJ-RC1-011D` closes font ownership/root-cause reconciliation at STATIC-AUDIT-PASS. The missing historical `RG35XXFontEngine` class is explicitly superseded rather than reconstructed. Existing FreeJ2ME PlatformFont/PlatformGraphics remain facade/consumer owners and the target GNU Classpath headless Toolkit/FontPeer path becomes the replacement backend owner. Audit: `docs/RC1-FONT-HEADLESS-PEER-AUDIT.md`.

## Authoritative integration patches

- 0003 Manager media profile
- 0004 dedicated audio pipe
- 0005 Java audio bootstrap
- 0006 PlatformPlayer native backend
- 0007 PlatformGraphics drawRGB fast path
- 0008 PlatformGraphics transform cache
- 0009 RecordStore RG35XX storage policy — historical; superseded for pinned RC1 by 0021
- 0010 Libretro/platform lifecycle
- 0011 PlatformImage RG35XX cache
- 0012 MobilePlatform dirty-frame integration — blocking consumer portion superseded by 0020
- 0013 Libretro RG35XX input engine
- 0014 Libretro native-media event return channel
- 0015 exact upstream `freej2me_libretro.c` native-media runtime/process-lifecycle integration
- 0016 exact upstream `javaOpen()` dedicated-audio FD/argv inheritance contract
- 0017 consolidated media process-boundary completion: native event handoff + case 14/15 + EOF graceful shutdown
- 0018 Manager/PlatformPlayer direct RG35XX MIDI/WAV facade routing + target selector contract
- 0019 JavaSound-free PlatformPlayer ToneControl + Manager.playTone integration
- 0020 pinned graphics/input/lifecycle consolidation contract
- 0021 pinned multi-file RMS safe synchronous baseline
- 0022 GNU Classpath 0.99 headless FontPeer consolidation contract

Patches 0015-0022 are integration contracts until applied to the exact assembled source tree; none is a second upstream facade/core implementation. Superseded historical patches remain engineering evidence and must not be silently re-applied.

A patch may be superseded by consolidated source, but its behavior must be accounted for before removal.

## Mandatory pre-change procedure

For every subsequent implementation turn:

1. Reload `tasklog/TASKLOG.md`.
2. Reload `tasklog/RC1-TASKLOG.md`.
3. Reload this registry.
4. Inspect repository tree/current target files.
5. Classify intended change as KEEP/MODIFY/ADD/REPLACE/REMOVE.
6. For ADD, prove no current class/module already owns the responsibility.
7. For REMOVE/REPLACE, record the old symbol/path and replacement/rollback in Tasklog before deletion.
8. For KEEP, verify the file/module is actually PRESENT; if missing, stop dependent gates and record a reconciliation task.
9. After modification, audit imports/package names/call sites against the registry.

## RC1 missing/duplicate gate

The source tree is not considered consolidated until:

- every KEEP Java class exists exactly once and every missing/superseded responsibility is resolved explicitly;
- every required native module exists exactly once or is explicitly documented as intentionally headerless/internal;
- no deleted/superseded RG35XX class is reintroduced by old overlays;
- integration targets reference current method names (`reset()`, `resetNative()`, etc.);
- every project class referenced by lifecycle/patches exists;
- no project class exists without a documented responsibility or integration path;
- the GNU Classpath headless FontPeer/resource gate is present in the reproducible assembled source;
- pinned TML/TSF headers, authoritative SoundFont provider and consolidated native call-sites are present before native BUILD-PASS.

Current reconciliation evidence: `docs/RC1-SOURCE-RECONCILIATION.md`.