# RG35XX PLATFORM SOURCE COVERAGE AUDIT v1

**Project:** Port FreeJ2ME to original RG35XX  
**Status:** `DOCS_ONLY / NO_RUNTIME_CHANGE / CORE_SOURCE_AUDIT_V1`  
**Authority:** `RG35XX-PORT-RULER-LOCKED-v1.md`  
**Canonical source:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**RG35XX reconstruction base:** `jokervtn94/rg35xx-java-platform@e7b0860310fd5204e1d1f2d01c992002b8660df2`

## 0. Purpose

This audit corrects the project workflow from compatibility-game-driven micro-fixes back to platform porting:

```text
PINNED AWEIGIT SOURCE / BEHAVIOR
        ↓
METHOD / CAPABILITY COVERAGE AUDIT
        ↓
MEASURED ORIGINAL-RG35XX HARDWARE CONTRACT
        ↓
COMPLETE RG35XX BOUNDARY BACKING
        ↓
GENERIC INSTALLABLE PLATFORM
        ↓
MODULE TESTS ON ORIGINAL RG35XX
        ↓
TIER-0 REGRESSION
        ↓
ONLY THEN TIER-1 GAME COMPATIBILITY
```

No runtime patch is authorized by this document alone.

## 1. Locked correction

The project must not continue the loop `game touches missing method -> patch method -> next game touches another missing method -> patch again`.

`fillTriangle` proved that the current Raw2D implementation has coverage holes. It is evidence for a platform audit, not justification for allowing games to drive architecture.

The recent rebuilt-equivalent A8 audio control is `ARCHIVED_DIAGNOSTIC`. Exact A8 physical identity remains authoritative; a semantically equivalent JAR with a different raw SHA cannot replace it.

## 2. Source/build topology findings

### 2.1 A3 is not a full Aweigit build

A3 copies the pinned Aweigit tree, performs Java-6 compatibility rewrites, then deliberately removes these trees before compilation:

- `org/lwjgl`
- `ru/woesss/j2me/micro3d`
- `com/mascotcapsule/micro3d`
- `javax/microedition/m3g`

Therefore the current RG35XX build is a **2D/MIDP-oriented port with deferred 3D capability**, not yet source-feature-equivalent to the pinned Miyoo implementation.

### 2.2 Java 6 compatibility is a legitimate boundary

Examples already correctly handled at A3/A7:

- Java 7 diamond/lambda/TWR syntax -> Java 6-compatible syntax.
- `MIDletLoader` NIO zip filesystem -> `JarFile/JarEntry`.
- `PlatformPlayer` media cache directory creation -> `java.io.File.mkdirs`.

These changes should preserve canonical J2ME behavior and remain protected.

### 2.3 Raw2D creates a systemic coverage obligation

A4 deliberately sets AWT backing to null for RG35XX raw surfaces:

```text
PlatformImage raw: canvas = null
PlatformGraphics raw: gc = null
```

This is valid for a headless JamVM/SDL1 target **only if every reachable AWT-backed API has an equivalent RG35XX raw path**. The current chain does not satisfy that condition yet.

## 3. PlatformGraphics / DirectGraphics coverage

### Protected raw coverage already present

- constructor/reset/raw framebuffer state
- `fillRect`
- `setColor`
- `setFont` state
- `setClip`
- `clipRect`
- `translate` + accepted ClipTranslate correction
- `flushGraphics`
- `drawImage(Image,...)`
- `drawRegion`
- `drawRGB`
- `drawString`/substring/char family, subject to font limitations
- `drawLine`
- `drawRect`
- DirectGraphics `fillPolygon` only for the accepted 4-corner axis-aligned rectangle case

### Confirmed source-coverage gaps

Pinned Aweigit still calls AWT `gc`/`canvas`, while no accepted A8 raw overlay was found, for:

- `clearRect`
- `copyArea`
- `drawArc`
- `drawRoundRect`
- `fillArc`
- `fillRoundRect`
- `setAlphaRGB`
- `drawImage2(BufferedImage,...)`
- `drawImage2Test(BufferedImage,...)`
- Nokia `DirectGraphics.drawImage(... manipulation)`
- all three `DirectGraphics.drawPixels(...)` overloads
- `DirectGraphics.drawPolygon`
- `DirectGraphics.drawTriangle`
- non-rectangle `DirectGraphics.fillPolygon`
- 7-argument `DirectGraphics.fillTriangle`
- `DirectGraphics.getPixels(int[])`
- `DirectGraphics.getPixels(short[])`

Exact A8 also lacked the 6-argument MIDP `fillTriangle`; COMP-02 physically proved this particular platform gap. That candidate is useful evidence, but it is not a substitute for completing the entire graphics matrix.

`DirectGraphics.getPixels(byte[],...)` is a canonical limitation: the pinned Aweigit implementation itself is only a stub/log.

## 4. Image coverage

Aweigit uses `ImageIO` for resource/InputStream/byte-array decoding and treats source bytes as general image data. RG35XX Core2D currently provides a raw PNG decoder. Later accepted work adds Adam7 support, but it remains PNG-only.

Therefore:

- PNG/alpha/drawRegion accepted scope = protected.
- non-PNG decode equivalence = `MISSING_RG35XX_BACKING`.
- image copy/RGB/subimage transforms/raw pixel access = accepted raw backing.
- any canonical caller requiring `PlatformImage.getCanvas()` remains unsafe in Raw2D unless separately adapted.

## 5. Font/text coverage

Pinned Aweigit uses a real AWT font resource and `FontMetrics`. RG35XX raw text uses the Core2D bitmap glyph path. It is physically useful but not feature-equivalent: limited glyphs, unsupported characters fall back to a box, face/style/proportional fidelity is limited, and the Miyoo `font.ttf` frontend path is not present in production RG35XX.

Classification: `RG35XX_RAW_BACKING_PARTIAL_FONT`.

## 6. Canvas / GameCanvas / lifecycle

Protected:
- canonical Canvas/GameCanvas ownership;
- A4 Canvas render/input and repeated GameCanvas `flushGraphics()` / `getKeyStates()` physical evidence;
- input terminates at `MobilePlatform`;
- A6 input-start-before-runJar correction;
- Java6 `MIDletLoader` JarFile/JarEntry compatibility.

Not yet complete:
- current-chain `resizeLCD` module acceptance;
- pointer/touch producer;
- haptic hardware capability.

## 7. Input/frontend comparison with Miyoo

The historical M1.8 RG35XX contract and current native adapter agree on a 12-bit semantic bitmap:

```text
UP DOWN LEFT RIGHT
A B X Y
L1 R1 START SELECT
```

Miyoo additionally provides L2/R2, configurable `keymap.cfg`, runtime key/hotkey behavior, touch/mouse emulation and rotation. These are not present in the current RG35XX production frontend.

Do not guess L2/R2 joystick button numbers. The current physical RG35XX contract did not validate them; a narrow hardware-input probe is required first.

## 8. Video/presenter comparison

Protected RG35XX behavior:
- SDL1/fbcon;
- physical 640x480 surface;
- aspect-fit presentation;
- final PERF-A1 staged native binary;
- exact 240x320 fast path.

Boundaries:
- checked-in video C is only a staging input, not the final PERF-A1 implementation by itself;
- other logical resolutions do not have equivalent performance evidence;
- Miyoo rotation exists; RG35XX production frontend currently lacks it.

## 9. Media/audio comparison

`PlatformPlayer`/`SdlMixerManager` own MMAPI semantics in Aweigit. A7 keeps the Java state machine and changes only Java6-incompatible media directory creation.

Aweigit SDL2 and RG35XX SDL1 backends share the same important high-level model: one global music channel, halt current music before a new MIDI, WAV/effect on channel 0, mixer pause/resume/stop/isPlaying and finite-MIDI callback.

Therefore that model is canonical behavior, not automatically an RG35XX bug.

Do not use the rebuilt-equivalent A8 audio control to revise Golden audio. Exact A8 identity must be restored/reproduced first.

## 10. RMS/filesystem

`RecordStoreImpl` implements the main CRUD, enumeration, listener, size, version and persistence behavior. A3 performs Java6 compatibility rewrites without intentionally changing logical semantics.

Canonical limitations include partial authmode/writable/vendor-suite handling and fixed 1 MiB `getSizeAvailable()` behavior. Do not classify those as RG35XX bugs without a canonical divergence.

## 11. Capability inventory omitted by the old Golden matrix

Pinned Aweigit also contains:
- `javax.microedition.io`
- `javax.microedition.pim`
- `javax.microedition.pki`
- `javax.microedition.sensor`
- Nokia APIs
- Samsung APIs
- Siemens APIs
- M3G
- MascotCapsule/Micro3D
- LWJGL/OpenGL support

A future complete-platform claim must not equate `compiled` with `supported`.

## 12. Current platform status

| Area | Status |
|---|---|
| Lifecycle/JAR load | PASS scoped |
| Canvas/GameCanvas | PASS scoped |
| Core graphics | PARTIAL |
| Nokia DirectGraphics | PARTIAL |
| PNG/alpha/transform | PASS scoped |
| General image formats | PARTIAL |
| Font/text | PARTIAL |
| Input D-pad/FIRE | PASS scoped |
| Full frontend key parity | PARTIAL |
| Video/presenter | PASS scoped |
| Other resolutions | PARTIAL |
| RMS | PASS scoped |
| Media/audio | PASS scoped; exact-Golden revalidation required |
| Haptic | NOT_TESTED / hardware unresolved |
| IO/network | NOT_TESTED as module |
| PIM/PKI/Sensor | NOT_TESTED |
| M3G | DEFERRED_CAPABILITY |
| MascotCapsule/Micro3D | DEFERRED_CAPABILITY |

## 13. Required engineering order

### P0 — Restore exact Golden authority
Recover exact A8 physical identities, especially `freej2me-rg35xx.jar = 057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`.

### P1 — Close 2D core source coverage
1. complete MIDP `PlatformGraphics` raw coverage;
2. complete Nokia DirectGraphics raw coverage;
3. define non-PNG decode backing/policy;
4. complete the raw font backend;
5. add method-level host gates for every newly covered API.

### P2 — Complete frontend/device contract
Evidence-driven L2/R2 mapping, configurable mapping decision, pointer/touch decision, rotation decision, generic width/height configuration.

### P3 — Expand one platform exerciser
Cover lifecycle/resources, Canvas/GameCanvas, full graphics/DirectGraphics matrix, images, fonts, all physical buttons, RMS, FileConnection, HTTP/socket where available, MMAPI, resizeLCD and clean shutdown.

### P4 — 3D hardware capability decision
Inventory actual EGL/GLES on original RG35XX/GarlicOS and map the 3D calls that depend on AWT `getCanvas()/getGraphics2D()` before re-enabling M3G/Micro3D.

### P5 — Build one generic installable platform
A single `FreeJ2ME-RG35XX.sh` + payload, with games remaining under `Roms/JAVA`. No game-name-specific runtime code.

### P6 — Physical platform acceptance
Module exerciser first, then Vua Cướp Biển and God of War. Tier-1 compatibility only after generic platform acceptance.

## 14. Immediate lock

```text
AUDIO01_LIFECYCLE_TRACE=ARCHIVED_DIAGNOSTIC
A8_REBUILT_EQUIVALENT_AUDIO_CONTROL=ARCHIVED_DIAGNOSTIC
COMP02_FILLTRIANGLE=PLATFORM_GAP_EVIDENCE
GAME_DRIVEN_RUNTIME_PATCHING=STOPPED
CURRENT_OWNER=PLATFORM_SOURCE_CONTRACT_AUDIT
RUNTIME_CHANGE_AUTHORIZED=NO
NEXT_IMPLEMENTATION_OWNER=P1_CORE_2D_SOURCE_COVERAGE
BUT_ONLY_AFTER_AUDIT_MATRIX_IS_LOCKED
```
