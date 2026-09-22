# RG35XX Java Platform — Clean Base vs Historical RG35XX vs Official FreeJ2ME-MiyooMini

Date: 2026-09-22
Status: ARCHITECTURE AUDIT ONLY / NO BUILD / NO DEVICE TEST / STABLE=NO

## Scope correction

This document supersedes the earlier comparison against the project's internal `miyoo-m1.*` experimental branches.

The external reference in this audit is the actual upstream handheld project:

- Repository: `aweigit/freej2me-miyoomini`
- Branch: `master`
- Audited commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- Project description: FreeJ2ME for Linux handheld devices with audio and 3D support.
- README-tested devices include Miyoo Mini, RG28XX, RG35XX Plus, RG35XX H and others.

The goal is not to port the Miyoo project verbatim. The goal is to identify architecture and compatibility policies that are proven useful on weaker handheld hardware, while retaining the stronger production pieces already developed for the original RG35XX/GarlicOS target.

---

# 1. Three baselines

## A. Current clean RG35XX base

Canonical source base:
- branch `verified-clean-platform-v1`
- commit `1cfce475cbede7bd995bb436926718ca1565702d`
- pinned FreeJ2ME-Plus `13ec186903087156c145268f8706eecfaf9f1e50`
- Java target class major 50
- JamVM L and glibj are immutable external components.

The runtime is defined by `scripts/vc0_vc3_assemble.sh`, not by every helper source file present in Git.

Admitted clean runtime:
- lazy media boot only in `MobilePlatform.runJar()`;
- `RG35XXGoldenFrameTransport`;
- async Java framebuffer snapshot / RGB565 transport;
- native receiver and front/back publication;
- Smart-Fit physical presentation;
- headless launcher properties;
- bounded B4 early observability only when using the B4 assembly.

Explicitly excluded at the clean base boundary:
- old audio stack;
- old RG35XX lifecycle graph;
- image/transform caches;
- font experiments;
- CV/CW resolution experiments;
- eager media warmup.

## B. Historical integrated RG35XX stack

Reference commit:
- `82eee6a7c766ee5b00fe20cbde4c28896ac52431`

Strength:
- broad RG35XX-specific integration;
- historical commercial-game evidence, including Dragon Mania progressing far beyond the current startup-logo regression;
- native audio/media architecture that previously produced real MIDI/END_OF_MEDIA device evidence.

Weakness:
- many coupled helpers and owners:
  - RG35XXLifecycle
  - RG35XXFrameScheduler
  - RG35XXInputEngine
  - RG35XXImageCache
  - RG35XXTransformCache
  - RG35XXRmsCoordinator / AtomicFile
  - RG35XXBitmapText
  - audio/media helper graph
- many simultaneous patches across MobilePlatform, Libretro, PlatformGraphics, PlatformImage, Manager, PlatformPlayer and native core;
- difficult regression attribution.

This stack is evidence/reference only. It is not a restore target.

## C. Official FreeJ2ME-MiyooMini upstream

Repository:
- `aweigit/freej2me-miyoomini`
- audited master commit `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

Architecture:
- full FreeJ2ME-derived source tree;
- Java main class `org.recompile.freej2me.Anbu`;
- external SDL2 frontend process;
- SDL2_mixer JNI audio;
- custom font.ttf through Java2D;
- JSR-184 M3G native GLES1 renderer;
- MascotCapsule micro3d GLES2 renderer;
- ASM compatibility rewriting in MIDletLoader;
- per-suite RMS implementation derived from MicroEmulator/J2ME-Loader.

This is a much wider platform than the project's internal Miyoo acceptance branches.

---

# 2. Hardware context

Official Miyoo Mini SDK reports:
- SSD202D
- dual Cortex-A7 1.2 GHz
- 128 MB DDR3
- 640x480 LCD

Original RG35XX community documentation reports:
- Actions Semi ATM7039
- PowerVR SGX-544
- 256 MB RAM
- 640x480 LCD
- community toolchains tune ARMv7 builds for Cortex-A9-class execution.

Therefore it is reasonable to treat Miyoo Mini as the lower-resource reference.

However, the JVM/runtime environments differ materially:
- official Miyoo project builds Java with JDK17 and relies heavily on Java AWT/BufferedImage/Graphics2D;
- current RG35XX production constraint is JamVM + GNU Classpath with Java-major-50 bytecode.

So hardware headroom does not make Miyoo Java/AWT code directly portable.

The useful reference is architectural simplicity and subsystem policy, not binary/source copying.

---

# 3. Official Miyoo architecture

## Display / frame transport

Java `Anbu`:
- owns the platform painter callback;
- knows logical game width/height at launch;
- obtains full LCD RGB pixels;
- converts pixels to RGB565;
- writes raw full-frame RGB565 bytes to the SDL process.

Native `miyoomini.cpp`:
- receives full frames via blocking stdin;
- owns persistent native frame buffers;
- uses SDL2 RGB565 streaming texture;
- scales with aspect preservation to 640x480;
- uses accelerated SDL renderer + VSYNC;
- runs SDL event/input handling on a separate pthread.

Important invariant:
**blocking video transport is isolated from input/event handling.**

Weakness to avoid:
current Java `Anbu.painter` allocates a new `int[]` and `byte[]` every frame and performs Java-side full-frame RGB565 conversion.

Our Golden transport already improves this:
- dedicated Java frame worker;
- reusable/bounded transport state;
- native receiver independent of `retro_run()`;
- nonblocking libretro presentation.

Conclusion:
KEEP RG35XX Golden transport. Do not port Miyoo video loop verbatim.

## Canvas repaint model

Official Miyoo `Canvas` is intentionally simple:
- `repaint()` directly executes `paint(graphics)` on the caller;
- then sends the resulting surface through `MobilePlatform.repaint()`;
- `serviceRepaints()` only forwards the already-rendered surface to the platform;
- no paintLock;
- no 1000 ms rescue wait;
- no caller-thread fallback after a timed wait.

This is very different from modern FreeJ2ME-Plus, where Canvas uses asynchronous event-thread paint state plus a `serviceRepaints()` wait/rescue path.

Architectural lesson:
**one deterministic paint owner is more important than adding rescue/scheduler mechanisms.**

Do not copy synchronous Miyoo semantics blindly because current FreeJ2ME-Plus has a newer MIDP event model.

Recommended RG35XX invariant:
- only one thread may execute a Canvas paint callback at a time;
- `serviceRepaints()` may wait for completion but must never create an overlapping/caller-thread paint path;
- no secondary frame scheduler should become another framebuffer owner.

## MobilePlatform

Official Miyoo `MobilePlatform` is small:
- one LCD PlatformImage;
- one PlatformGraphics;
- one painter callback;
- direct key/pointer dispatch to current Displayable;
- synchronized GameCanvas key-state bitmask;
- `runJar()` simply calls loader.start();
- `flushGraphics/repaint` performs graphics copy then invokes painter.

Lesson:
keep platform ownership centralized.

The historical RG35XX graph should be reduced rather than restored.

## Input

Official Miyoo:
- one native SDL event owner;
- native event thread maps physical controls and writes compact events to Java;
- Java maintains pressed state;
- press/release/repeat are dispatched exactly once to MobilePlatform;
- key mappings are externalized in `keymap.cfg`;
- phone modes support generic/Nokia/Siemens/Motorola behavior;
- pointer/touch simulation is handled at the same boundary.

Recommended RG35XX:
- physical acquisition remains the libretro frontend;
- exactly one semantic input adapter converts frontend events to FreeJ2ME logical/MIDP keys;
- MobilePlatform remains the sole MIDP event owner;
- no parallel raw-js0 input reader;
- key profiles should be data/config-driven where possible;
- pressed state and repeat policy belong to one owner only.

## Image / graphics

Official Miyoo uses Java2D:
- PlatformImage stores explicit width/height and BufferedImage;
- ImageIO handles PNG/JPEG;
- copies/subimages/transforms create BufferedImages;
- PlatformGraphics wraps Graphics2D;
- drawRGB creates a temporary BufferedImage and draws it;
- font/text uses Java FontMetrics and Graphics2D.

This works because the Miyoo package supplies a JVM/runtime environment capable of this AWT path.

It must NOT be copied to JamVM/glibj where GTK/AWT peer paths have already caused failures.

Recommended RG35XX:
- keep semantic behavior;
- implement backing storage with canonical software ARGB int[];
- no live GTK/AWT dependency;
- no BufferedImage allocation per drawRGB;
- image decode -> canonical ARGB storage;
- transforms operate directly on software pixels;
- cache only after correctness is proven.

## Font

Official Miyoo:
- loads replaceable `font.ttf`;
- creates Java AWT Font once;
- derives size/style fonts;
- FontMetrics provides widths/heights;
- PlatformGraphics uses Graphics2D text.

Useful principle:
**font resource and font semantics are separate.**

RG35XX cannot depend on this AWT path, but should preserve:
- one replaceable font resource;
- cached glyph/metrics representation;
- face/style/size semantics;
- no per-draw font construction.

The old RG35XX 5x7 ASCII helper is not sufficient as a final renderer.

## Audio/media

Official Miyoo:
- `Manager.createPlayer` -> PlatformPlayer;
- MIDI/WAV streams are written once into per-suite files;
- SDL2_mixer native code owns playback;
- MIDI uses `Mix_LoadMUS`;
- WAV uses `Mix_LoadWAV`;
- playback is started/stopped/paused/resumed natively;
- native `Mix_HookMusicFinished` callback attaches to JVM and calls Java `onPlaybackComplete()`;
- Java then emits `PlayerListener.END_OF_MEDIA`;
- audio is not pumped by the display/render loop.

This strongly validates the historical RG35XX architectural principle:
**Java owns MMAPI lifecycle; native owns audio transport/playback; completion returns as an event; rendering never pumps audio.**

Backend choice remains open:
- if original GarlicOS can provide a proven SDL2_mixer ABI, a Miyoo-like backend may be much simpler;
- otherwise retain/rebuild the historical RG35XX worker-ring/TSF backend;
- do not restore audio into boot or `retro_run()`.

No SDL2_mixer implementation currently exists in our repository, so direct adoption is not yet authorized.

## RMS

Official Miyoo RMS:
- `RecordStore` delegates to a concrete `RecordStoreImpl`;
- one header file `.rsh` per store;
- one `.rsr` file per record;
- save happens synchronously on add/set/delete;
- broken header is detected and a new store can be reconstructed;
- broken individual record is isolated/stubbed rather than preventing the entire suite from loading;
- store is scoped under `./rms/<suite>`.

This is materially different from the zero-byte metadata failure observed in our current Dragon work.

Recommended RG35XX policy:
- keep current FreeJ2ME-Plus RecordStore API/semantics as owner;
- redesign persistence around fail-safe writes and independent corruption domains;
- never treat a basename as permanently bad;
- validate metadata before use;
- corrupted one record should not destroy unrelated stores;
- prefer temp-write + fsync/close + atomic rename when supported;
- add bounded recovery/quarantine at load;
- do not restore the broad old RG35XXRmsCoordinator unless required.

## MIDletLoader / compatibility layer

Official Miyoo uses ASM to adapt game bytecode:
- Class.getResourceAsStream redirect;
- Thread.yield -> Thread.sleep(1);
- Timer/TimerTask -> custom implementations;
- default string/reader/writer encodings made explicit;
- Runtime APIs redirected to MidletRuntime;
- vendor compatibility hooks.

Notably its inspected visitor does not contain the modern FreeJ2ME-Plus virtual currentTimeMillis/nanoTime layer used by our pin.

Lesson:
keep bytecode rewriting small and compatibility-focused.

Do not virtualize core JVM semantics unless a real compatibility requirement justifies it.

## 3D

Official Miyoo includes:
- M3G / JSR-184 native GLES1 renderer;
- MascotCapsule v3 micro3d GLES2 renderer;
- EGL/GLES libraries/bindings.

This is a valuable future feature reference but should be optional.

For original RG35XX:
- the hardware contains PowerVR SGX544;
- some community firmware can enable GPU/GLES;
- GarlicOS/runtime ABI availability still needs a dedicated source/environment audit before 3D can enter the plan.

Do not make 3D part of the initial 2D base.

---

# 4. Three-way feature comparison

| Area | Clean RG35XX | Historical RG35XX | Official Miyoo | Target decision |
|---|---|---|---|---|
| JVM | JamVM L locked | JamVM L historical | Java/JDK17-style runtime | KEEP JamVM L |
| Java bytecode | major 50 | major 50 helpers | current JDK build | KEEP major 50 |
| Core API base | modern pinned FreeJ2ME-Plus | same lineage + patches | older/forked full FreeJ2ME tree | KEEP modern pin |
| Display host | Golden libretro async | mixed libretro generations | external SDL2 process | KEEP Golden |
| Pixel transport | RGB565 framed async | historical nonblocking receiver | raw RGB565 pipe | KEEP Golden |
| Scaling | native Smart-Fit | multiple historical paths | SDL aspect-fit | KEEP Smart-Fit |
| Repaint model | modern async EDT + service wait | patched/traced repeatedly | synchronous deterministic | simplify to single paint owner |
| Input owner | libretro | libretro + helper | SDL event thread | one libretro owner |
| Key config | FreeJ2ME profile mapping | helper mapping | external keymap + phone modes | externalize profile mapping |
| Graphics backing | modern AWT/int[] mix | many software fixes/caches | BufferedImage/Graphics2D | canonical ARGB int[] on RG35XX |
| drawRGB | modern path + proven fixes | fast path experiments | temporary BufferedImage each call | direct int[] path, no allocation |
| Font | unresolved clean resource | ASCII/bitmap helpers | font.ttf + AWT metrics | software cached font semantics |
| Image | staged/proven pieces | cache/transform experiments | ImageIO + BufferedImage | software image pipeline; no cache first |
| RMS | current FreeJ2ME-Plus | custom coordinator | per-store header + per-record files | adopt recovery/atomic policy, not old graph |
| Audio | excluded from clean | worker-ring/TSF device history | SDL2_mixer JNI | native backend; choose later |
| END_OF_MEDIA | future clean stage | historical native events | native callback -> Java | KEEP native callback principle |
| 3D | not included | not established | M3G + micro3d | optional future module |
| Full stable | NO | NO | external project works on supported devices, but not our GarlicOS target | no global claim |

---

# 5. What official Miyoo proves conceptually

It does NOT prove that its exact Java sources will run on JamVM/glibj.

It DOES demonstrate that a useful handheld J2ME platform can remain conceptually simple on 128 MB hardware:

1. one display owner;
2. one physical input owner;
3. one Java MIDP dispatcher;
4. fixed logical game dimensions supplied at launch;
5. native scaling/presentation;
6. audio fully outside the frame loop;
7. per-suite persistent data;
8. native optional 3D modules;
9. minimal runtime coordination between subsystems.

Its simplicity is more important than its individual implementation details.

---

# 6. What not to copy from official Miyoo

Do not copy these implementation choices into RG35XX:

- JDK17 bytecode/runtime assumptions;
- BufferedImage/Graphics2D dependency throughout PlatformImage/PlatformGraphics;
- per-frame Java allocation of full int[] + RGB565 byte[];
- per-drawRGB temporary BufferedImage;
- blocking frame read inside a libretro `retro_run()` equivalent;
- global/single-current-music limitations from SDL2_mixer code without validation;
- synchronous Canvas paint semantics wholesale without checking current FreeJ2ME-Plus compatibility;
- hardcoded locale/platform defaults such as zh-CN/Nokia7650 as universal production defaults.

---

# 7. What to reuse from historical RG35XX

KEEP:
- Golden async transport;
- native RGB565 receiver / Smart-Fit;
- dynamic logical LCD behavior once admitted cleanly;
- PNG iCCP source-level compatibility;
- proven mask/no-mask behavior;
- bounded early diagnostics;
- historical native audio lifecycle principles.

REFERENCE/HOLD:
- worker-ring/TSF audio backend;
- native END_OF_MEDIA/BGM resume;
- commercial-game regression history.

DO NOT restore as foundation:
- RG35XXImageCache;
- RG35XXTransformCache;
- broad RG35XXLifecycle graph;
- separate RG35XXFrameScheduler as another frame owner;
- old 5x7 bitmap text as final renderer;
- RMS coordinator unless a minimal persistence layer cannot satisfy real failures.

---

# 8. Proposed RG35XX vNext architecture

```
JamVM L [locked]
      |
GNU Classpath [immutable]
      |
Pinned modern FreeJ2ME-Plus
      |
      +-- MIDletLoader
      |      minimal compatibility rewrite policy
      |
      +-- Display / Canvas
      |      one serialized paint owner
      |      no overlapping caller-thread rescue paint
      |
      +-- MobilePlatform
      |      sole LCD/frontbuffer + MIDP input owner
      |
      +-- PlatformImage
      |      canonical ARGB int[] backing
      |      decode/copy/RGB/transform semantics
      |
      +-- PlatformGraphics
      |      direct software raster
      |      no per-call image allocation
      |
      +-- Font backend
      |      cached software glyphs/metrics
      |
      +-- RecordStore
      |      per-suite robust persistence
      |      independent corruption domains
      |
      +-- MMAPI adapter
             lifecycle only
             |
             v
       native audio backend
       (SDL2_mixer candidate OR proven worker-ring)
             |
             +-- native END_OF_MEDIA callback

Canonical ARGB frontbuffer
      |
RG35XXGoldenFrameTransport
      |
framed RGB565 IPC
      |
native receiver / front-back / Smart-Fit
      |
libretro / GarlicOS
```

Optional later:
- M3G GLES1 module;
- micro3d GLES2 module.

---

# 9. Performance policy for stronger RG35XX hardware

The extra RG35XX RAM/CPU margin should not justify more architectural complexity.

Use the margin for:
- larger safe media/audio buffers;
- decoded image cache only after compatibility is proven;
- glyph cache;
- optional 3D;
- commercial-game compatibility;
- smoother frame pacing.

Do not spend it on:
- duplicate schedulers;
- duplicate framebuffers;
- per-frame object allocation;
- multiple input owners;
- per-frame audio pumping;
- unbounded diagnostics.

The target should be **simpler than historical RC1**, and **more efficient than official Miyoo**, while preserving the modern FreeJ2ME-Plus API surface.

---

# 10. Immediate source-only plan

Device testing remains paused.

Next source-only work should be:

1. create a canonical class/owner manifest;
2. identify modern FreeJ2ME-Plus methods corresponding to official Miyoo's simple paths;
3. specify the serialized repaint invariant;
4. specify one input ownership path;
5. design robust RMS persistence policy based on independent header/record failure domains;
6. design zero-allocation steady-state frame transport;
7. compare SDL2_mixer ABI requirements against actual original GarlicOS libraries without installing anything;
8. keep 3D optional;
9. only after the architecture is source-complete create one clean candidate build.

STABLE=NO.
