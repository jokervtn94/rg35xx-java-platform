# RG35XX PLATFORM CONTRACT / GOLDEN RECONSTRUCTION MAP v1

**Project:** Port FreeJ2ME to original RG35XX  
**Status:** COMPLETE_FOR_A8_GOLDEN_CONTRACT  
**Date:** 2026-10-01  
**Engineering ruler:** `RG35XX-PORT-RULER-LOCKED-v1.md`  

> This map is documentation/diagnostic output only. It does **not** authorize a runtime patch by itself.

---

## 1. Locked authority and identities

### Canonical upstream
- Repository: `aweigit/freej2me-miyoomini`
- Pinned commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- Canonical semantics remain the first authority for MIDP/J2ME behavior.

### Production parent
- Branch: `rg35xx-aweigit-r1-stable`
- Reset/base commit used for technical reconstruction: `e7b0860310fd5204e1d1f2d01c992002b8660df2`
- A9 / PR #16 / PR #17 / PR #18 are not production parents.

### GOLDEN A8 protected runtime identities
| Artifact | SHA256 |
|---|---|
| `freej2me-rg35xx.jar` | `057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c` |
| `librg35xx_input.so` | `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d` |
| `librg35xx_video.so` | `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d` |
| `libaudio.so` | `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644` |
| audio-prime PCM | `8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e` |
| JamVM | `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34` |
| `glibj.zip` | `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea` |

### A8 package identity rule
`build-a8-production-package.sh` proves that A8 is a **consolidation of the accepted A7 + A1P5 device-pass semantics**. The A8 package declares `RUNTIME_SEMANTIC_DELTA=NONE`; it hash-binds the exact packaged JAR/native artifacts and adds the generic launcher/package gate plus the pre-Java zero-PCM audio route prime.

---

## 2. GOLDEN physical acceptance corpus

### Tier 0 — protected parent regression

**Vua Cướp Biển**
- display = PASS
- input = PASS
- gameplay = PASS
- no hang = PASS

**God of War**
- display = PASS
- input = PASS
- gameplay = PASS
- no hang = PASS
- audio audible = PASS

Additional protected A8 behavior:
- Raw2D graphics chain
- PNG/alpha
- `drawRegion`
- ClipTranslate correction
- input lifecycle
- PERF-A1 presenter
- RMS
- Java 6 media compatibility
- SDL1_mixer bridge
- RG35XX audio-route prime

**Rule:** A Tier-1 compatibility result may not invalidate or redesign this Tier-0 contract.

---

## 3. Golden reconstruction layers

This is the reconstruction model to use. It intentionally separates canonical semantics from hardware-bound RG35XX backing.

1. **Pinned Aweigit semantic source**  
   `aweigit/freej2me-miyoomini@ca11dfe...`

2. **RG35XX bootstrap / Java 6 staging (A3)**  
   Clean Aweigit lifecycle is retained; the device launcher, protected JamVM/glibj bootstrap, `/dev/input/js0` adapter and SDL1/fbcon presenter are attached at the RG35XX boundary.

3. **Raw2D backing (A4)**  
   When `-Drg35xx.raw2d=true`, blank `PlatformImage` surfaces use RG35XX ARGB `int[]` backing instead of AWT backing. For a raw surface, `PlatformGraphics.gc` is intentionally `null`; only explicitly overlaid raw paths are safe. A4 DEVICE-PASS proves Canvas/GameCanvas/input/flush/normal-exit scope, not full image/text/RMS/media compatibility.

4. **Core2D / image expansion (A5 and accepted A6 graphics chain)**  
   `RG35XXCore2D` plus staged overlays provide RG35XX headless backing for image creation/PNG/ARGB copy/transform/blit/text and the accepted raw graphics paths while keeping MIDP ownership in canonical classes. Subsequent accepted A6 gates protect raw primitives, PNG/alpha, `drawRegion`, Adam7 where accepted, input lifecycle and classloader/runtime integration.

5. **PERF-A1 presenter**  
   Java/game semantics remain unchanged. The video owner is narrowed to the RG35XX native presenter. Exact 240x320 frames use a latest-frame native worker with the accepted PERF-P3 scaler + `SDL_Flip`; other geometries fall back to synchronous PERF-P3. This is a presenter/timing adapter, not a J2ME primitive rewrite.

6. **God of War ClipTranslate delta**  
   The accepted delta changes only `org/recompile/mobile/PlatformGraphics.class` for the raw-device-space clip translation issue. The canonical/AWT fallback is preserved. Input, PERF-A1 native video and PNG decoder are copied unchanged from the accepted parent.

7. **A7 media/audio boundary**  
   Canonical MMAPI player state-machine behavior is retained. Only the media-cache directory creation is rewritten from `java.nio.file` to Java-6-compatible `java.io.File.mkdirs`; RG35XX launcher/audio loader attaches `libaudio.so`. Native backend is ARMv5TE soft-float SDL1_mixer loaded dynamically. No SDL2 or JavaSound fallback is part of the protected A7 contract.

8. **A1P5 audio route prime + A8 consolidation**  
   Before Java starts, the production launcher uses `aplay -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100` with the protected zero-PCM payload. A8 then launches the exact protected JAR/native identities with `-Drg35xx.raw2d=true`; A8 adds no new runtime semantics.

### Critical reconstruction warning
The checked-in baseline files under `adapter/native/` are **inputs to staging**, not sufficient by themselves to reproduce the final A8 binaries. Accepted build scripts materialize and stage later deltas (notably PERF-A1). Therefore reconstruction must execute the locked build chain and verify final artifact hashes; copying the checked-in C source and compiling it directly is not an A8 reconstruction.

---

## 4. Platform contract matrix

| Subsystem | Canonical Aweigit owner | RG35XX adapter / accepted delta | Accepted physical evidence | Protected identity / owner | Status | Known limitation / boundary |
|---|---|---|---|---|---|---|
| **Startup / lifecycle** | `MobilePlatform`, `Mobile`, MIDlet loader/lifecycle | `RG35XXLauncher`; JamVM/glibj bootstrap; hash-gated launcher; clean Aweigit lifecycle | A4 Canvas/GameCanvas launch + normal exit; A8 Tier-0 games launch/run | JamVM + glibj hashes; A8 platform JAR; `RG35XXLauncher` family | **PASS** | Full vendor/game-specific lifecycle behavior is not implied. Do not suppress `notifyDestroyed()` or replace lifecycle to hide failures. |
| **Canvas / GameCanvas** | `javax.microedition.lcdui.Canvas`, `game.GameCanvas`, `MobilePlatform.repaint/flushGraphics/getKeyState` | Raw blank-surface backing + presenter callback; no direct `Displayable` ownership in input adapter | A4 physical Canvas input/render; GameCanvas `getKeyStates`, repeated `flushGraphics`; Vua/GoW parent regressions | A6 graphics/input protected owners; A8 JAR | **PASS** | Contract covers accepted raw backing. Unsupported primitive paths must be classified individually; GameCanvas does not authorize adapter ownership of J2ME semantics. |
| **Graphics primitives** | `PlatformGraphics` defines MIDP drawing semantics | A4/A5/A6 raw branches and `RG35XXCore2D`; accepted raw line/rect/polygon family and related A6 gates | A6 protected Raw2D chain + Tier-0 games | `A6_GRAPHICS`; A8 JAR | **PARTIAL** | **Important:** raw2D sets canonical `gc=null`; any canonical method not given a raw branch can fail. `fillTriangle` is an identified uncovered path on A8, not a golden-proven primitive. Do not generalize A9 code into production. |
| **Image / PNG / alpha / drawRegion** | `PlatformImage` + `PlatformGraphics.drawImage/drawRegion/drawRGB`; Sprite transforms | `RG35XXCore2D` raw ARGB image, PNG decode, transform, source-over blit; staged PNG/Adam7/drawRegion support | Protected `PNG_ALPHA_DRAWREGION`; Vua/GoW rendering; accepted graphics gates | A8 JAR + `PNG_ALPHA_DRAWREGION` | **PASS** | PASS is for accepted PNG/alpha/transform corpus, not every image format or malformed PNG variant. Canonical non-RG35XX AWT path remains fallback semantics. |
| **Framebuffer / presenter / scaling** | Logical LCD belongs to `MobilePlatform` / logical `PlatformImage` | `RG35XXVideo` JNI + SDL1/fbcon physical 640x480; aspect-fit; PERF-A1 exact 240x320 latest-frame worker using accepted P3 scaler | A4 SDL fbcon 640x480; PERF-A1 accepted; Tier-0 display/gameplay | `librg35xx_video.so` `c6687c...`; `PERF_A1` | **PASS** | Presenter owns physical fit/flip only. It must not change MIDP drawing semantics. Other logical geometries use accepted fallback and are not performance-equivalent to 240x320 path. |
| **Input** | `MobilePlatform.keyPressed/keyReleased/keyRepeated` + GameCanvas key-state ownership | `rg35xx_input.c` reads `/dev/input/js0`; `RG35XXKeyDispatcher` maps semantic bits to Aweigit key boundary; 10 ms pump | A4 physical D-pad/FIRE/GameCanvas; Vua/GoW input PASS | `librg35xx_input.so` `69a8ae...`; `A6_INPUT` | **PASS** | Adapter terminates at `MobilePlatform`; must not call `Displayable` directly. Repeat timings/mapping are RG35XX boundary behavior and should not be changed due to one game without exact evidence. |
| **RMS / filesystem** | `RecordStore` -> `AndroidRecordStoreManager`; canonical `./rms/<suitename>` persistence | Launcher supplies device `dataPath/rootPath`; Java/filesystem compatibility only as needed | RMS is protected A8 behavior; exercised in accepted real-game regression | A8 JAR; `RMS` protected owner | **PASS** | Not proof of every RecordStore API/vendor filesystem case. Path/permission failures must be reproduced before changing RMS semantics. |
| **Media / audio** | `PlatformPlayer` MMAPI state/control logic + `SdlMixerManager` interface | Java6 cache-path overlay; RG35XX audio loader; `libaudio.so` SDL1_mixer; pre-Java hardware route prime | Direct audible WAV/MIDI acceptance + God of War audio PASS | `libaudio.so` `452215...`; prime `8c3069...`; `A7_JAVA6_MEDIA_COMPAT`, `A7_SDL1_MIXER_BACKEND`, `A1P5_AUDIO_ROUTE_PRIME` | **PASS** | PASS is scoped to accepted formats/flows. API/MIDI/WAV return codes alone are not audible-device proof. Other MMAPI codecs/formats remain outside the golden claim. |
| **Shutdown / exit** | MIDlet lifecycle + JVM process behavior | Launcher shutdown hook stops input and shuts down display; audio/backend cleanup remains adapter-owned | A4 normal exit; Tier-0 normal/no-hang acceptance | A8 JAR/native hashes + protected runtime | **PASS** | Exit code 0 alone is not DEVICE-PASS. A game-driven clean exit can still represent a swallowed runtime exception; physical behavior and logs remain required. |
| **Performance / timing** | Game/J2ME timing semantics stay canonical | RG35XX input pump; PERF-A1 presenter worker; exact P3 scale + flip; native latest-frame queue | PERF-A1 owner was evidence-driven from measured presenter cost; Tier-0 games gameplay/no-hang | `PERF_A1`; video hash `c6687c...` | **PARTIAL** | Protected presenter performance is accepted; **general cross-game performance is not guaranteed**. A Tier-1 slow game does not justify primitive, thread, or timing redesign without profiling and owner classification. |

---

## 5. Canonical ↔ RG35XX ownership rules

### Canonical-owned — do not move into adapter
- MIDlet lifecycle semantics
- Canvas/GameCanvas behavior
- key event and GameCanvas state semantics after adapter dispatch
- J2ME graphics API semantics
- image/drawRegion transform semantics
- RMS logical behavior
- MMAPI Player state/control behavior

### RG35XX-owned boundary
- physical `/dev/input/js0` acquisition
- mapping RG35XX controls to canonical key boundary
- physical SDL1/fbcon display init/present/shutdown
- physical 640x480 fit/scale/flip
- headless/raw backing required because original RG35XX runtime cannot use the desktop AWT path
- Java-6 compatibility glue required by protected JamVM/glibj
- SDL1_mixer native device backend
- original-RG35XX audio route prime
- launcher/package paths and identity gates

### Not an allowed production owner
- game-name-specific code
- A9 experiment code
- trace instrumentation
- generic “compatibility optimization” without evidence
- vendor stubs added merely to move a failing game further

---

## 6. Contract gaps found during reconstruction

### GAP-01 — `PlatformGraphics.fillTriangle` raw2D coverage
**Status: NEEDS_REPRO for any candidate implementation; root contract mismatch is identified.**

Canonical pinned Aweigit implementation:
```text
fillTriangle(x1,y1,x2,y2,x3,y3)
    -> gc.fillPolygon(...)
```

A4 raw2D constructor behavior:
```text
if raw2d:
    canvas = null
    gc = null
```

A5 Core2D expands image blit/drawRegion/drawRGB/text and other raw paths, but the A5 staging source has no `fillTriangle` overlay. Repository search at the locked parent finds no production `fillTriangle` staging implementation.

**Resulting contract statement:** on the accepted A8 raw2D path, `fillTriangle()` is outside the proven raw-primitive coverage and canonical AWT backing cannot execute because `gc` is null. The COMP-02 hidden `NullPointerException` at `PlatformGraphics.fillTriangle()` is therefore consistent with a **RG35XX raw-graphics backing coverage gap**, not evidence that canonical MIDP triangle semantics are wrong.

**What this does NOT authorize:** copying the A9 experimental triangle implementation, redesigning graphics, or touching presenter/audio/input.

### GAP-02 — Source tree vs generated accepted native video
`adapter/native/rg35xx_video_sdl1.c` at the reset base is the staging input. The accepted A8 `librg35xx_video.so` includes PERF-A1 materialized by the build chain. Rebuilding the checked-in C source alone cannot claim equivalence.

**Required reconstruction gate:** final `librg35xx_video.so` must equal `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`.

### GAP-03 — Physical acceptance cannot be inferred from build metadata
Several build identity files intentionally say `DEVICE-PASS=NO` before device review. Final A8 acceptance comes from later physical evidence, not from `BUILD-PASS`, API return values, or exit code.

---

## 7. COMP-02 classification after completing this map

Target:
- file: `Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar`
- SHA256: `b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b`

Already established on exact A8:
- menu/display/input can run
- transition into gameplay reaches hidden clean-exit path
- swallowed Java exception was exposed diagnostically
- exception: `NullPointerException` in `org.recompile.mobile.PlatformGraphics.fillTriangle()`
- A9 experimental Raw2D triangle path could start gameplay, but A9 also had unrelated image/performance/audio/exit problems and is not a parent

### Failure-owner result
For the **specific `fillTriangle` NPE only**:

`FAILURE_OWNER = RG35XX_GRAPHICS_BOUNDARY`

Reason:
1. canonical owner exists and has defined triangle semantics (`gc.fillPolygon`);
2. RG35XX raw2D intentionally replaces the AWT backing and nulls `gc`;
3. accepted raw overlay coverage does not include `fillTriangle`;
4. the exact A8 failure occurs at that uncovered boundary.

This owner assignment applies **only** to the `fillTriangle` NPE. It does not assign Asphalt 4's later performance, splash/background, audible audio or exit behavior to the same owner.

---

## 8. Next approved engineering action

The map is complete enough to leave the documentation-only phase. The next action permitted by the ruler is **not** “fix Asphalt 4 completely.” It is one controlled owner-scoped candidate design:

### Candidate scope proposal — GRAPHICS-FILLTRIANGLE-BOUNDARY-ONLY
Before code is written, lock these seven answers:

1. **Evidence requiring change**  
   Exact A8 + exact COMP-02 JAR -> NPE at `PlatformGraphics.fillTriangle()`.

2. **Canonical Aweigit behavior**  
   Fill the triangle using the current Graphics color via polygon fill semantics.

3. **Exact RG35XX boundary difference**  
   raw2D surface has `gc=null`; no accepted raw branch exists for `fillTriangle`.

4. **Failure owner**  
   `RG35XX_GRAPHICS_BOUNDARY` for this exception only.

5. **Permitted class/file scope**  
   One raw graphics backing path only. No input, video presenter, audio, lifecycle, RMS or game-name condition.

6. **Mandatory parent regressions**  
   All existing host/raw graphics gates + Vua Cướp Biển physical regression + God of War physical regression.

7. **Physical target acceptance**  
   COMP-02 must pass beyond the exact pre-patch `fillTriangle` failure point on original RG35XX without introducing a Tier-0 regression. That observation alone does not promote unrelated COMP-02 subsystems.

**No code modification is included in this map.**

---

## 9. Promotion guard

Any future candidate remains experimental unless all of the following are true:
- canonical pin preserved
- JamVM/glibj preserved
- non-owner native identities preserved
- exact candidate scope documented
- automated gates PASS
- Vua Cướp Biển physical regression PASS
- God of War physical regression PASS
- target scoped failure physical test PASS
- no new regression observed
- normal exit verified where applicable
- audible audio verified where applicable
- `DEVICE-PASS=YES`

---

## 10. Audit sources

### User-locked project authority
- `RG35XX-PORT-RULER-LOCKED-v1.md`
- `RESET-STATUS-20261001.md`
- `NEW-CHAT-START-PROMPT.txt`

### Pinned canonical source (`aweigit/freej2me-miyoomini@ca11dfe...`)
- `src/org/recompile/mobile/MobilePlatform.java`
- `src/org/recompile/mobile/PlatformGraphics.java`
- `src/org/recompile/mobile/PlatformImage.java`
- `src/org/recompile/mobile/PlatformPlayer.java`
- `src/javax/microedition/lcdui/Canvas.java`
- `src/javax/microedition/lcdui/game/GameCanvas.java`
- `src/javax/microedition/rms/RecordStore.java`
- `src/javax/microedition/rms/impl/AndroidRecordStoreManager.java`

### Reset-base reconstruction source (`jokervtn94/rg35xx-java-platform@e7b086...`)
- `docs/A2-RG35XX-ADAPTER-INVENTORY.md`
- `docs/ACCEPTED-BASELINE.md`
- `docs/A4-DEVICE-PASS-20260923.md`
- `docs/A8-COMPATIBILITY-REGRESSION-MATRIX.md`
- `adapter/ADAPTER-MANIFEST.tsv`
- `adapter/java/org/recompile/rg35xx/RG35XXLauncher.java`
- `adapter/java/org/recompile/rg35xx/RG35XXKeyDispatcher.java`
- `adapter/java/org/recompile/rg35xx/RG35XXCore2D.java`
- `adapter/native/rg35xx_video_sdl1.c`
- `scripts/stage-a4-rg35xx-raw2d.py`
- `scripts/stage-a5-rg35xx-core2d.py`
- `scripts/stage-a6-rg35xx-perf-a1-async-native.py`
- `scripts/build-a6-perf-a1.sh`
- `scripts/build-a6-corpus3-cliptranslate-fix.sh`
- `scripts/build-a7-audio-java-a1p1.sh`
- `scripts/build-a7-audio-native.sh`
- `scripts/build-a8-production-package.sh`
- `packaging/a8/RG35XX-AWEIGIT-R1.sh`

---

## 11. Final lock from this map

```text
PINNED AWEIGIT SEMANTICS
        ↓
RG35XX RAW/HARDWARE BACKING ONLY WHERE REQUIRED
        ↓
A6 PROTECTED GRAPHICS + INPUT + PERF-A1
        ↓
A7 JAVA6 MEDIA + SDL1_MIXER
        ↓
A1P5 AUDIO ROUTE PRIME
        ↓
A8 HASH-GATED CONSOLIDATION
        ↓
TIER-0 PHYSICAL DEVICE-PASS
```

For COMP-02, the next legal engineering unit is the **single `fillTriangle` RG35XX raw-graphics boundary gap**. All other Asphalt 4 observations remain separately unassigned until their own evidence workflow is completed.
