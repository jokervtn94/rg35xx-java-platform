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
| RG35XXPlatformProfile | target/profile feature policy | KEEP / PRESENT |
| RG35XXFrameScheduler | dirty-frame generation/wakeup | KEEP / PRESENT |
| RG35XXImageCache | immutable decoded-image LRU/cache | KEEP / PRESENT |
| RG35XXInputEngine | deterministic key press/release/repeat | KEEP / PRESENT |
| RG35XXWavDecoder | target WAV decode/normalization helper | KEEP / PRESENT — RC1 RESTORED |
| RG35XXMediaProfile | truthful target MMAPI capability policy | KEEP / PRESENT |
| RG35XXMediaRegistry | Java semantic player registry + bounded native-event queue | KEEP / PRESENT |
| RG35XXAudioProtocol | Java/native framed audio protocol | KEEP / PRESENT |
| RG35XXAudioTransport | dedicated Java→native audio writer | KEEP / PRESENT |
| RG35XXAudioBootstrap | inherited audio-FD bootstrap/ownership | KEEP / PRESENT |
| RG35XXNativePlayer | native-backed MMAPI adapter + event binding | KEEP / PRESENT |
| RG35XXFontEngine | unified font metrics/raster policy | MISSING — RESTORE REQUIRED |
| RG35XXTransformCache | bounded MIDP Sprite transform maps | KEEP / PRESENT |
| RG35XXRmsCoordinator | coalesced low-priority RMS persistence | KEEP / PRESENT |
| RG35XXRmsAtomicFile | Java-6-compatible atomic replacement helper | KEEP / PRESENT |
| RG35XXLifecycle | central subsystem lifecycle ordering | KEEP / PRESENT |

No additional `RG35XX*` Java class should be introduced until this table is checked and the new responsibility is proven non-overlapping. A MISSING entry must be restored from authoritative source or handled by an explicit REPLACE task; do not silently invent a substitute.

## Existing upstream classes to integrate, not duplicate

These remain upstream-owned facades/implementations. RG35XX behavior must be hooked into them rather than creating replacement packages/classes with conflicting ownership:

- `javax.microedition.media.Manager`
- `javax.microedition.rms.RecordStore`
- `org.recompile.freej2me.Libretro`
- `org.recompile.mobile.MobilePlatform`
- `org.recompile.mobile.PlatformGraphics`
- `org.recompile.mobile.PlatformImage`
- `org.recompile.mobile.PlatformPlayer`
- upstream Font/PlatformFont implementation

Vendor compatibility facades (Nokia/Siemens/KDDI/DoJa/JBlend and other upstream compatibility packages) are preserved unless a specific compatibility audit records a replacement/removal.

## Authoritative native modules

| Module | State |
|---|---|
| `rg35xx_audio_protocol.h` | KEEP / PRESENT |
| `rg35xx_media_cache.h/.c` | KEEP / PRESENT |
| `rg35xx_media_events.h` | KEEP / PRESENT — RC1 NATIVE EVENT CALLBACK OWNER |
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

## Authoritative integration patches

- 0003 Manager media profile
- 0004 dedicated audio pipe
- 0005 Java audio bootstrap
- 0006 PlatformPlayer native backend
- 0007 PlatformGraphics drawRGB fast path
- 0008 PlatformGraphics transform cache
- 0009 RecordStore RG35XX storage policy
- 0010 Libretro/platform lifecycle
- 0011 PlatformImage RG35XX cache
- 0012 MobilePlatform dirty-frame integration
- 0013 Libretro RG35XX input engine
- 0014 Libretro native-media event return channel
- 0015 exact upstream `freej2me_libretro.c` native-media runtime/process-lifecycle integration

Patch 0015 is based on the inspected upstream devel `src/libretro/freej2me_libretro.c` blob `534b26cc97129c4fe7b04ea9a6b07fb8945d33b0`. It remains an integration contract until applied to the assembled RG35XX core; it must not be treated as a second core implementation.

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

- every KEEP Java class exists exactly once and every MISSING entry is resolved explicitly;
- every required native module exists exactly once or is explicitly documented as intentionally headerless/internal;
- no deleted/superseded RG35XX class is reintroduced by old overlays;
- integration targets reference current method names (`reset()`, `resetNative()`, etc.);
- every project class referenced by lifecycle/patches exists;
- no project class exists without a documented responsibility or integration path.

Current reconciliation evidence: `docs/RC1-SOURCE-RECONCILIATION.md`.
