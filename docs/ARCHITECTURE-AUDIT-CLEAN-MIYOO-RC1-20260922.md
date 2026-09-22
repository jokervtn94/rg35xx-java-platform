# RG35XX Java Platform — Clean vs Miyoo vs RC1 Architecture Audit

Date: 2026-09-22  
Status: AUDIT ONLY / NO BUILD / NO DEVICE TEST / STABLE=NO

## User direction

All active error-hunting/device checkpoints are paused.

The project will now use the current verified clean assembly as the base, compare it against:
1. the Miyoo-inspired M1.x architecture and device-proven checkpoints;
2. the earlier integrated RG35XX RC1 stack that reached farther in commercial games;

then rebuild a smaller, evidence-driven RG35XX platform.

No runtime change is authorized by this audit.

---

## Source identities

### A. Current clean base

Repository branch:
- `verified-clean-platform-v1`
- commit: `1cfce475cbede7bd995bb436926718ca1565702d`

Important distinction:
the repository branch contains historical/project helper source files, but the clean runtime is defined by the **assembly recipe**, not by every file present in Git.

Canonical clean recipe:
- pinned FreeJ2ME: `13ec186903087156c145268f8706eecfaf9f1e50`
- `scripts/vc0_vc3_assemble.sh`
- optional B4 early observability from `scripts/b4_verified_core_assemble.sh`

Actual VC0-VC3 admitted runtime changes:
- `MobilePlatform.runJar()`: lazy media boot only
- new `RG35XXGoldenFrameTransport`
- `Libretro`: request frames through the Golden async transport
- native Golden RGB565 receiver / front-back publication / Smart-Fit
- headless AWT launcher properties at native launch boundary

Explicitly excluded at this clean stage:
- PlatformImage RG35XX compatibility modifications
- font rework
- audio rework
- lifecycle/Beta helper integration
- CV/CW resolution launcher experiments
- eager media warmup

This is the canonical BASE definition for the future rebuild.

### B. Miyoo-inspired M1.x snapshot

Final diagnostic snapshot used for source structure:
- branch: `miyoo-m1.16-r1-game-layer-diagnostic`
- commit: `196c95bf031121711c150618d130b5a77332d412`

Lineage:
- this snapshot is 373 commits after `verified-clean-platform-v1`
- therefore Miyoo work is a descendant of the clean project lineage, not an unrelated platform

Status must be taken checkpoint-by-checkpoint, not from the final snapshot as a whole.

### C. Previous integrated RG35XX RC1 snapshot

Historical integrated snapshot:
- commit: `82eee6a7c766ee5b00fe20cbde4c28896ac52431`

This snapshot predates the verified-clean branch by 243 commits.

Why it matters:
- it contains the broad integrated RG35XX helper architecture;
- historical real-device logs show Dragon Mania reached much farther than the current startup-logo stall;
- it also mixed many graphics/audio/lifecycle/input changes and accumulated regressions, so it is reference material, not a restore target.

---

# 1. High-level architecture comparison

## Current clean base philosophy

```text
Pinned FreeJ2ME
   |
   +-- MobilePlatform: lazy media boot only
   |
   +-- Libretro
          |
          +-- RG35XXGoldenFrameTransport
                 |
                 +-- async Java frame worker
                 +-- ARGB -> RGB565
                 +-- framed IPC
                         |
                         +-- native Golden receiver
                         +-- front/back publication
                         +-- Smart-Fit -> RG35XX/frontend
```

Strength:
- very small delta from pinned upstream;
- clear video ownership;
- easy fail-closed reconstruction.

Weakness:
- many RG35XX compatibility boundaries are intentionally not yet admitted.

## Miyoo M1.x philosophy

```text
Pinned FreeJ2ME canonical classes
   |
   +-- PlatformFont      <- small headless overlay
   +-- PlatformImage     <- small int[] / dimension overlay
   +-- PlatformGraphics  <- software raster/text overlay
   +-- MobilePlatform    <- GameCanvas flush overlay
   +-- RecordStore       <- mostly upstream behavior
   |
   +-- M1Input / M1InputDispatch
   |      |
   |      +-- raw /dev/input/js0 -> canonical MobilePlatform
   |
   +-- standalone SDL1/fbcon presenter for M1 acceptance
```

Strength:
- keeps FreeJ2ME canonical owners;
- applies narrow overlays at exact boundaries;
- many individual boundaries reached DEVICE-PASS on real RG35XX.

Weakness:
- standalone SDL1/raw-js0 path is not the same host architecture as the production libretro core;
- dynamic logical resolution, PNG iCCP, commercial JAR compatibility and audio are not fully covered by M1.x;
- image->Sprite/game layer remains incomplete.

## Old RC1 philosophy

```text
Pinned FreeJ2ME
   |
   +-- broad RG35XX helper subsystem graph
       |
       +-- RG35XXLifecycle
       +-- RG35XXInputEngine
       +-- RG35XXFrameScheduler
       +-- RG35XXImageCache
       +-- RG35XXTransformCache
       +-- RG35XXBitmapText
       +-- RG35XXRmsCoordinator / RG35XXRmsAtomicFile
       +-- RG35XXAudioBootstrap / Transport / Protocol
       +-- RG35XXMediaProfile / Registry / NativePlayer
       +-- RG35XXToneSequenceEncoder / WavDecoder
       +-- PlatformProfile
   |
   +-- many patches into Manager / PlatformPlayer / Libretro /
       MobilePlatform / PlatformGraphics / PlatformImage / native core
```

Strength:
- broad feature coverage;
- historical commercial-game progress;
- advanced native audio architecture.

Weakness:
- too many owners and coupled lifecycle interactions;
- helper graph increases regression surface;
- some helpers were implemented or BUILD-PASS without independent DEVICE-PASS;
- difficult to identify which component caused regressions.

---

# 2. Repository class structure versus compiled-runtime structure

## Repository-level Java source counts

These counts are useful only for source organization, not proof of runtime inclusion:

- verified-clean branch: 21 Java files total in project tree
- Miyoo M1.16 snapshot: 53 Java files total
- RC1 snapshot: 20 Java files total

The Miyoo number is larger mainly because it contains acceptance MIDlets and diagnostics.

## Shared project helper files

The following RG35XX helper sources exist in both the verified-clean repository tree and the Miyoo descendant tree:

- RG35XXAudioBootstrap
- RG35XXAudioProtocol
- RG35XXAudioTransport
- RG35XXBitmapText
- RG35XXFrameScheduler
- RG35XXImageCache
- RG35XXInputEngine
- RG35XXLifecycle
- RG35XXMediaProfile
- RG35XXMediaRegistry
- RG35XXNativePlayer
- RG35XXPlatformProfile
- RG35XXRmsAtomicFile
- RG35XXRmsCoordinator
- RG35XXToneSequenceEncoder
- RG35XXTransformCache
- RG35XXWavDecoder

Important:
their presence in Git does **not** mean the verified-clean assembly compiles or activates them.

The clean VC0-VC3 recipe explicitly excludes the old lifecycle/audio/font/PlatformImage compatibility stack.

## Clean-only admitted new Java class

Production-relevant addition:
- `org.recompile.freej2me.RG35XXGoldenFrameTransport`

This class is the primary new Java owner admitted to the clean base.

## Miyoo-specific production additions

The important production-oriented M1 additions are:

- `org.recompile.mobile.M1Input`
- `org.recompile.mobile.M1InputDispatch`

Most other `miyoo-m1/*.java` files are acceptance/diagnostic applications:
- M16DisplayProbe
- M17InputProbe
- M18* acceptance classes
- M19* acceptance lifecycle/input/presenter wrappers
- M110GameCanvasE2EMIDlet
- M111/M112/M113/M114 font probes
- M115 RMS probes
- M116 game/image probes

These must not be copied into production base merely because they exist.

---

# 3. Functional evidence matrix

Legend:
- DEVICE-PASS = real RG35XX acceptance for stated scope
- DEVICE-EVIDENCE = useful real-device evidence but not a locked full subsystem pass
- BUILD-PASS = build only
- PENDING = missing acceptance
- FAIL = observed failed boundary
- HOLD = useful historical implementation, deliberately not admitted

| Subsystem | Current clean / proven history | Miyoo M1.x | Old RC1 | Rebuild decision |
|---|---|---|---|---|
| JamVM | DEVICE-PASS binary `eea1b97...` | preserved and repeatedly hash-checked | used same proven runtime in later work | KEEP immutable |
| GNU Classpath | immutable `glibj d7abe8...` | preserved | old experiments existed | KEEP immutable; no byte patches |
| Java target | major 50 | major 50 after strategy correction | Java 6 compatible helpers | KEEP major 50 |
| Boot / media initialization | Lazy Media Boot is admitted/proven | M1 acceptance preserved clean startup | RC1 later also had lazy-media patch | KEEP clean lazy boot |
| Host presentation | Golden async RGB565 + native receiver/Smart-Fit | SDL1/fbcon standalone DEVICE-PASS | RC1 nonblocking libretro presentation existed | KEEP Golden/libretro host; use Miyoo only for semantic validation |
| Physical display | DEVICE-EVIDENCE/accepted Golden path | M1.6 DEVICE-PASS | historical game output | KEEP current Golden |
| Dynamic logical LCD | device-proven historical clean foundation requirement | not a core M1 proof | mixed historical implementations | KEEP current proven dynamic logical view when re-admitted |
| Input acquisition | libretro frontend path; current traces prove delivery but clean standalone scope is not equivalent to M1.7 | M1.7 raw js0 DEVICE-PASS | libretro input engine implemented | keep libretro acquisition; DO NOT import raw js0 owner into production |
| Input semantic dispatch | direct canonical FreeJ2ME path / historical RG35XXInputEngine | M1.8 DEVICE-PASS | RG35XXInputEngine used | adopt M1.8 semantic rules into one libretro-fed adapter; one owner only |
| Canvas | current real games exercise Canvas, but clean standalone lock is weaker | M1.9F DEVICE-PASS | worked in integrated stack | use M1.9F semantics as acceptance reference |
| Primitive software raster | proven in several RG35XX checkpoints | M1.9D/M1.9E/M1.9F proven | fast drawRGB patch existed | use canonical software int[] raster; avoid cache/optimization first |
| GameCanvas | clean historical GameCanvas->frontbuffer chain has device evidence | M1.10 DEVICE-PASS | RC1 GameCanvas path existed | import M1.10 direct int[] flush semantics into clean libretro path |
| Canonical frontbuffer | accepted/proven in current project | M1.10 proven | existed but changed repeatedly | KEEP one canonical frontbuffer owner |
| PNG iCCP | device-proven source-level compatibility history | not a main M1 subsystem | older fixes existed | re-admit clean PlatformImage iCCP sanitizer after base graphics |
| PlatformImage blank mutable image | current base upstream only at VC3 | M1.16-r1.2 DEVICE-PASS scoped | image cache/copy optimizations existed | import M1.9B + M1.16-r1.2 minimal headless int[]/dimensions |
| PlatformImage decoded/copy image | historical VC7 game assets decoded/blitted; clean base does not yet admit this | M1.16-r1.3/r1.4 FAIL due GTK/AWT toolkit on copy/RGB paths | cache and decode changes existed | PENDING; rebuild as next image layer without AWT dependency |
| Sprite constructor | not clean-locked | FAIL/PENDING after M1.16 tests | transform/cache helpers existed | PENDING; do not import transform cache first |
| TiledLayer/game package | not proven | PENDING | broad old implementation inherited upstream | PENDING |
| ASCII text | clean base excludes text rework | M1.11 device evidence but superseded by later font path | RG35XXBitmapText ASCII helper existed | do not use RC1 ASCII helper as final font |
| Unicode/Vietnamese/CJK text | reconstructed font is EXPERIMENTAL in current project | M1.12/13 evidence; M1.14 semantics DEVICE-PASS scoped | RC1 bitmap-text was much narrower | use M1.14 software font semantics, but resource remains EXPERIMENTAL |
| Font metrics/styles/faces | not admitted clean | M1.14 DEVICE-PASS scoped across 36 combinations | RC1 helper did not reach equivalent semantics | strong candidate for selective import |
| RMS lifecycle | Dragon exposed a corrupt-store edge in current production testing | M1.15-r1 DEVICE-PASS scoped | custom coordinator/storage policy existed | prefer upstream RMS semantics; no custom coordinator in base |
| RMS reboot persistence | not independently clean-locked | M1.15-r1.1 DEVICE-PASS scoped | custom persistence helper existed | accept M1.15 behavior as reference; handle corrupt-store edge separately |
| Audio/media | current clean foundation intentionally excludes audio; historical Golden worker-ring is HOLD | not solved by M1.x | strongest historical implementation; native worker-ring had device evidence | HOLD until graphics/input/RMS base is consolidated |
| playTone/MIDI/BGM lifecycle | historical device-proven native contract | not M1-proven | implemented in RC1 | later isolated stage only |
| Platform lifecycle | minimal clean host process lifecycle | M1 tests use small acceptance launchers, not full commercial-game lifecycle | RG35XXLifecycle coordinates many helpers | do not import wholesale; rebuild minimal lifecycle after owners are chosen |
| Image cache | excluded clean | not required by M1 proofs | RG35XXImageCache | REJECT from base; optimization only |
| Transform cache | explicitly not required by clean foundation | not used for M1.16 proof | RG35XXTransformCache | REJECT from base; only reconsider after Sprite pass |
| Frame scheduler helper | clean Golden transport already has async worker/receiver model | standalone presenter does not require old helper | RG35XXFrameScheduler | no separate scheduler unless a proven missing contract appears |
| Network | current Dragon trace did not reach network | not an M1 focus | inherited FreeJ2ME | keep upstream |
| Commercial JAR compatibility | not stable; Dragon currently stalls | M1.x explicitly does not prove arbitrary commercial JARs | old RC1 got farther in Dragon and other games | final acceptance track after subsystem base |
| Full platform | STABLE=NO | STABLE=NO | STABLE=NO | no global stability claim |

---

# 4. Exact class-owner comparison

## MobilePlatform

### Clean
Admitted change:
- lazy media boot

Future proven behavior to restore:
- canonical frontbuffer / GameCanvas flow

### Miyoo
Keeps MobilePlatform as canonical MIDP owner.
M1.10 changes only the headless GameCanvas transfer:
- source = PlatformImage int[]
- destination = lcdFrontbuffer int[]
- bounded rectangle `System.arraycopy`
- existing synchronization/postDraw/painter/FPS lifecycle remains

This is a good design pattern.

### RC1
MobilePlatform also participates in:
- dirty-frame scheduling
- old RG35XX frame scheduler signaling
- input/lifecycle interactions

Decision:
MobilePlatform should stay canonical and small.
Adopt the M1.10 direct headless copy semantics, not the full RC1 scheduler coupling.

---

## PlatformGraphics

### Clean
Pinned upstream at early clean stage; later proven graphics fixes are staged separately.

### Miyoo
Incrementally removes AWT/Graphics2D dependency:
- state kept in Java
- setColor/fillRect software raster
- clip/translate/font state software path
- bitmap text path
- font layout/metrics semantics

### RC1
Modified for:
- fast drawRGB
- transform cache
- bitmap-text bypass
- native/video-related work in some combined patches

Decision:
Miyoo structure is preferable:
- correctness first in canonical PlatformGraphics;
- no transform/image cache in base;
- add optimization only after semantic DEVICE-PASS.

---

## PlatformImage

### Clean
Must remain upstream at VC3.

Historical clean/device-proven compatibility exists for:
- PNG iCCP source sanitizer
- decoded image -> software drawImage
but it is intentionally not part of VC3.

### Miyoo
Minimal headless path:
- blank image stores width/height + int[]
- M1.16-r1.2 getWidth/getHeight fallback = DEVICE-PASS
- copy/RGB image paths still hit GTK/AWT and remain FAIL/PENDING

### RC1
Adds RG35XXImageCache and broader image integration.

Decision:
build PlatformImage in layers:
1. blank int[] + width/height semantics from M1.9B/M1.16-r1.2;
2. source-level PNG iCCP compatibility;
3. decoded/copy/RGB headless paths;
4. only then Sprite.
Do not add cache until compatibility is proven.

---

## PlatformFont + text

### Clean
No font rework in base.
Historical reconstructed font SHA `20c2...` remains EXPERIMENTAL.
Historical Golden resource expected SHA `7d835f...`.

### Miyoo
Most complete semantic work:
- removes live AWT FontMetrics dependency for headless path
- bitmap Unicode backend
- layout/raster separation
- size semantics
- bold/italic/underline
- system/monospace/proportional face semantics
- 36-combination matrix DEVICE-PASS scoped

### RC1
RG35XXBitmapText:
- 5x7 ASCII fallback
- uses MIDP Font width/height
- narrow coverage
- useful emergency bypass but inferior semantic coverage to M1.14

Decision:
M1.14 is the preferred semantic architecture.
Do not use RC1 RG35XXBitmapText as the final production font renderer.
Keep font resource classification separate from renderer semantics.

---

## Input

### Clean / production host
Libretro frontend is the natural physical-input owner.

### Miyoo M1.8
Strong semantic contract:
- one raw owner
- edge-triggered press/release
- bounded repeat
- map semantic RG35XX control -> FreeJ2ME canonical logical index
- `Mobile.getMobileKey()` remains phone/profile mapper
- `MobilePlatform` remains sole MIDP event owner
- never dispatch directly to Displayable

### RC1 RG35XXInputEngine
Also implements:
- held state
- repeat delay/interval
- sink abstraction

But it operates on libretro slots and had a broader repeat set.

Decision:
do not run `M1Input.rawGetState()` in the production libretro stack.
Instead create/retain exactly one **semantic input adapter** fed by libretro events, adopting the M1.8 ownership rules.
This can replace or simplify RG35XXInputEngine.

---

## RMS

### Miyoo
Critical result:
basic lifecycle and reboot persistence passed **without changing RMS implementation**.

### RC1
Adds:
- RG35XXRmsCoordinator
- RG35XXRmsAtomicFile
- custom storage policy/lifecycle ordering

### Current commercial evidence
Dragon previously created zero-byte metadata in an edge case, so commercial-game robustness still needs investigation.

Decision:
base should use upstream RecordStore behavior proven by M1.15.
Do not admit coordinator/async/atomic wrappers as foundation unless a specific real-game RMS failure demonstrates necessity.

---

## Video/presentation

### Clean
Best production architecture:
- libretro-native
- async worker
- framed RGB565
- native receiver
- Smart-Fit
- nonblocking frontend presentation

### Miyoo
Excellent acceptance architecture:
- Java ARGB int[]
- JNI
- SDL1/fbcon
- physical LCD

But it bypasses the final production libretro presentation architecture.

Decision:
keep Golden/libretro for production.
Use Miyoo SDL1 results as proof of Java raster semantics, not as the new production presenter.

---

## Audio/media

### Clean
excluded deliberately.

### Miyoo
M1.x did not solve production audio/media.

### RC1 / historical RG35XX
Contains the best known device-proven architecture:
- async callback
- dedicated worker
- ring 16384
- worker chunk 1470
- TSF synth 14700 -> 44100 mono-x3
- PCM prime/re-prime
- native END_OF_MEDIA
- native BGM resume
- no retro_run audio pumping

Decision:
retain as HOLD/reference.
Audio becomes a later isolated integration stage after graphics/input/image/RMS base is source-clean.

---

# 5. What is actually better in Miyoo

The main value of the Miyoo track is not SDL1 itself.

The valuable patterns are:

1. **Canonical owner preservation**
   - MobilePlatform owns input dispatch.
   - PlatformGraphics owns drawing semantics.
   - PlatformImage owns image semantics.
   - PlatformFont owns font metrics.
   - RecordStore remains the persistence owner.

2. **Headless int[] software rendering**
   - avoids GTK/AWT peer dependency on RG35XX.

3. **One boundary per checkpoint**
   - display
   - raw input
   - MIDP input
   - Canvas
   - GameCanvas
   - text
   - Unicode
   - font semantics
   - RMS
   - PlatformImage
   - Sprite

4. **DEVICE-PASS before optimization**
   - caches and schedulers are not required to prove correctness.

5. **Diagnostic/probe code stays outside production architecture**
   - an important contrast with later RC1 where many helpers became integrated dependencies.

---

# 6. What the clean RG35XX base has that Miyoo does not replace

Do not discard these just because Miyoo is cleaner:

- Golden async libretro transport
- RGB565 native receiver
- Smart-Fit
- dynamic logical LCD history
- PNG iCCP compatibility history
- current libretro host integration
- historical commercial-game compatibility evidence
- historical native audio worker-ring architecture

Therefore the target is **not “port Miyoo to RG35XX”**.

The target is:

> Keep the RG35XX production host/core foundation, but rebuild the Java compatibility layer using the smaller Miyoo ownership model and only device-proven semantics.

---

# 7. Old RC1 classes: disposition

## KEEP / REFERENCE

### RG35XXGoldenFrameTransport
KEEP — already admitted to clean base.

### RG35XXAudioBootstrap / AudioProtocol / AudioTransport
HOLD — historical audio architecture reference.

### RG35XXMediaProfile / MediaRegistry / NativePlayer
HOLD — may be reused only with the native audio stage.

### RG35XXToneSequenceEncoder / RG35XXWavDecoder
HOLD — audio stage only.

## REPLACE / SIMPLIFY

### RG35XXInputEngine
Replace or simplify using M1.8 ownership semantics.
One adapter only.

### RG35XXBitmapText
Superseded by M1.12-M1.14 bitmap Unicode/font semantics.

### RG35XXLifecycle
Do not restore wholesale.
Rebuild minimal lifecycle after subsystem ownership is finalized.

## DO NOT ADMIT TO BASE

### RG35XXImageCache
Optimization; not required for compatibility baseline.

### RG35XXTransformCache
Optimization; clean manifest explicitly says not required.

### RG35XXFrameScheduler
Do not create an additional frame owner/scheduler while Golden async transport already owns frame production/presentation coordination.

### RG35XXRmsCoordinator / RG35XXRmsAtomicFile
Do not use in base while upstream RecordStore lifecycle/persistence is already M1.15 DEVICE-PASS scoped.
Reconsider only for a concrete game failure.

---

# 8. Proposed target architecture — RG35XX Clean Platform vNext

```text
                   +---------------------------+
                   |      JamVM L (locked)     |
                   +-------------+-------------+
                                 |
                   +-------------v-------------+
                   | GNU Classpath (immutable) |
                   +-------------+-------------+
                                 |
                   +-------------v-------------+
                   |   pinned FreeJ2ME core    |
                   +-------------+-------------+
                                 |
          +----------------------+----------------------+
          |                      |                      |
+---------v---------+  +---------v---------+  +---------v---------+
|  LCDUI software  |  | canonical input   |  | upstream RMS      |
|  compatibility   |  | semantic adapter  |  | semantics         |
|                  |  |                   |  |                   |
| PlatformImage    |  | libretro events   |  | M1.15 behavior    |
| PlatformGraphics |  | -> logical index  |  | as reference      |
| PlatformFont     |  | -> MobilePlatform |  +-------------------+
| Canvas/GameCanvas|  +-------------------+
+---------+---------+
          |
+---------v---------------------+
| canonical Java ARGB frontbuf  |
+---------+---------------------+
          |
+---------v---------------------+
| RG35XXGoldenFrameTransport    |
| async snapshot / RGB565 IPC   |
+---------+---------------------+
          |
+---------v---------------------+
| native Golden receiver        |
| front/back + Smart-Fit        |
+---------+---------------------+
          |
+---------v---------------------+
| libretro / RG35XX frontend    |
+-------------------------------+
```

Later, only after this base is accepted:

```text
Native Audio Worker Ring
     |
Manager / PlatformPlayer adapter
     |
media registry / END_OF_MEDIA
```

No image cache, transform cache or broad lifecycle coordinator is required in the first vNext base.

---

# 9. Rebuild stages without device testing yet

The current phase is source/audit only.

## Stage S0 — Freeze evidence

- stop Dragon-specific test branches
- no more behavioral patches
- keep their logs as diagnostic evidence only

## Stage S1 — Canonical base manifest

Define exact source allowlist:
- pinned FreeJ2ME
- lazy media boot
- Golden async video
- early bounded logging
- immutable JamVM/glibj

## Stage S2 — Miyoo semantic import plan

Prepare source-only overlays, with no build/test yet:
1. input ownership contract
2. PlatformImage blank int[] + dimensions
3. PlatformGraphics headless primitive state/raster
4. GameCanvas canonical int[] flush
5. PlatformFont + M1.14 font semantics
6. upstream RMS unchanged

## Stage S3 — RG35XX-proven compatibility add-ons

Prepare but keep separate:
- dynamic logical LCD
- PNG iCCP compatibility
- LCD mask/no-mask proven behavior

## Stage S4 — image/game layer completion plan

Missing boundary:
- createImage(byte[])
- createRGBImage
- image copy
- decoded image headless backing
- Sprite constructor
- drawRegion/transforms
- TiledLayer

Do not use RG35XXTransformCache until the non-cached semantics pass.

## Stage S5 — audio plan

Only after the non-audio platform is structurally complete:
- reintroduce historical worker-ring architecture as a separate module
- no eager media boot
- no JavaSound sequencer/clip
- no retro_run audio pumping

## Stage S6 — lifecycle

Implement only the cleanup actually required by the admitted owners.

---

# 10. Current decision

The project should **not** continue from the latest Dragon diagnostic runtime.

It should **not** restore RC1 wholesale.

It should **not** switch production presentation to Miyoo SDL1/fbcon.

The recommended source base is:

```text
verified-clean VC0-VC3 assembly
        +
Miyoo-proven Java semantic overlays
        +
RG35XX-proven dynamic-view / PNG / mask compatibility
        +
current Golden libretro host transport
```

Then add image/Sprite and audio as separate stages.

This architecture minimizes duplicate owners while preserving the strongest real-device evidence from all three histories.

---

## Global status

- current clean foundation: usable as source base
- Miyoo individual subsystems: multiple DEVICE-PASS scoped checkpoints
- RC1: historical reference, not baseline
- commercial-game compatibility: incomplete
- audio in new clean base: HOLD
- image/Sprite: PENDING
- full platform STABLE: NO
- active device testing: PAUSED by user direction
