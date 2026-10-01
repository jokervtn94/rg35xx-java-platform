# RG35XX P1A CORE GRAPHICS COVERAGE — DESIGN & TEST MATRIX v1

**Status:** `DESIGN_LOCK / NO_RUNTIME_CHANGE`  
**Parent authority:** exact device-accepted Golden `057567d4...336c`  
**Canonical authority:** Aweigit `ca11dfe8...`  
**Failure owner:** `RG35XX_GRAPHICS_BOUNDARY`  
**Game-specific runtime code:** `FORBIDDEN`

## 1. Why P1A exists

Whole-source audit proved that Raw2D intentionally nulls AWT backing but does not cover the complete pinned `PlatformGraphics`/Nokia `DirectGraphics` API surface. This is a platform contract issue. Commercial games are not the design input.

## 2. Seven locked RULER answers

1. **Evidence requiring change:** 52 PlatformGraphics methods, 38 AWT-backed, 16 AWT-backed methods without RG35XX stage coverage; exact-A8 `fillTriangle` physically demonstrated the failure class.
2. **Canonical behavior:** pinned `PlatformGraphics.java`, including quirks/stubs.
3. **RG35XX boundary difference:** Raw surfaces use `int[]` and set `canvas=null`, `gc=null`.
4. **Failure owner:** `RG35XX_GRAPHICS_BOUNDARY`.
5. **Permitted scope:** raw `PlatformGraphics`, pixel/raster helpers in `RG35XXCore2D`, host/exerciser tests only.
6. **Parent regressions:** accepted A4/A5/A6 graphics, PNG/alpha/drawRegion, ClipTranslate, protected input/video/audio identities and Tier-0 before promotion.
7. **Physical acceptance:** one graphics platform exerciser on original RG35XX; commercial games are not the P1A acceptance surface.

## 3. Coordinate contract

```text
user-space arguments + translateX/Y -> device-space destination
clipX/clipY = device-space
translate() changes translateX/Y only and does not move stored raw clip
```

Every P1A method must use the accepted ClipTranslate convention.

## 4. Canonical quirks to preserve

- `copyArea`: pinned source reads source subx/suby directly and destination is affected by Graphics translation.
- `fillRoundRect`: pinned source performs `fillRoundRect` and then `fillRect`; final covered region is a full rectangle.
- DirectGraphics `getPixels(byte[])` is a canonical stub/log; P1A will not invent behavior.
- DirectGraphics `drawPixels(int[])` keeps pinned alpha/transparency behavior.
- DirectGraphics `drawPixels(short[])` keeps pinned conversion/transparency behavior.
- manipulation constants map exactly through pinned `manipulateImage()` semantics.
- `getPixels(short[])` preserves pinned conversion/indexing behavior.
- existing raw dotted-line behavior is recorded as a raw-vs-canonical divergence; it is not silently changed in P1A without separate owner/evidence.

## 5. Method groups

### G1 — Clear/copy
- `clearRect`: clipped device-space transparent clear matching canonical transparent background.
- `copyArea`: overlap-safe source snapshot + canonical anchor + translated/clipped destination.

### G2 — MIDP shapes
- `drawArc`
- `fillArc`
- `drawRoundRect`
- `fillRoundRect` preserving pinned final full-rectangle result
- `fillTriangle` using current opaque Graphics color

Accepted `fillRect`, `drawLine`, `drawRect` remain protected and are not refactored merely for cleanliness.

### G3 — DirectGraphics explicit-color shapes
- `drawPolygon`
- `drawTriangle`
- `fillPolygon`: accepted rectangle fast path + generic fallback
- `fillTriangle(argb)`

Explicit DirectGraphics ARGB must use source-over. Normal MIDP Graphics color stays opaque as in the accepted raw path.

### G4 — DirectGraphics image/pixel writes
- `drawImage(... manipulation)` -> pinned manipulation mapping -> existing raw transform/blit
- `drawPixels(byte[])`: pinned supported formats `-1` and `1`
- `drawPixels(int[])`
- `drawPixels(short[])`

### G5 — DirectGraphics pixel reads
- `getPixels(int[])`
- `getPixels(short[])`
- `getPixels(byte[])` remains canonical stub

### G6 — Internal AWT helper reachability
`drawImage2(BufferedImage,...)` and `drawImage2Test(BufferedImage,...)` are not blindly ported. Raw-reachable callers must instead be adapted at their owning RawImage/Core2D boundary; AWT-only fallback remains canonical.

## 6. RG35XXCore2D boundary

Reusable helper categories may include clip bounds, opaque/ARGB pixel operations, overlap-safe copy, explicit-color line, polygon outline/fill, ellipse/arc raster, round-rect raster and DirectGraphics pixel conversion/transform staging.

`RG35XXCore2D` owns backing only; API argument/anchor/state/quirk semantics remain in `PlatformGraphics`.

## 7. Differential canonical-reference gate

Every P1A operation runs twice on host:

```text
A) pinned canonical AWT-backed PlatformGraphics
B) rg35xx.raw2d PlatformGraphics
```

Same canvas, initial pixels, color/ARGB, stroke state, translation, clipping, coordinates, anchors and transforms. Compare outputs through `getRGB`.

Bit-exact comparison is required where practical (clear/copy/pixels/transforms/clip/alpha). Arc/round-rect raster work must be reference-driven against the pinned CI JDK rather than accepted merely because it looks similar.

## 8. One platform exerciser JAR

`RG35XX-Platform-Exerciser-P1A.jar` covers:

```text
CLEAR_RECT
COPY_AREA + overlap
DRAW_ARC / FILL_ARC
DRAW_ROUND_RECT / FILL_ROUND_RECT
FILL_TRIANGLE
DG_DRAW_IMAGE_MANIPULATION
DG_DRAW_PIXELS_BYTE/INT/SHORT
DG_DRAW_POLYGON / DG_DRAW_TRIANGLE
DG_FILL_POLYGON / DG_FILL_TRIANGLE
DG_GET_PIXELS_INT/SHORT
CLIP_MATRIX
TRANSLATE_MATRIX
CLIP_PLUS_TRANSLATE_MATRIX
ALPHA_MATRIX
ANCHOR_MATRIX
DEGENERATE_GEOMETRY
BOUNDS_MATRIX
```

It reports per-test PASS/FAIL and an overall result/checksum to screen/stdout.

## 9. Candidate scope gate

```text
CANONICAL_PIN=ca11dfe8...
JAMVM/GLIBJ=PROTECTED
INPUT_NATIVE=UNCHANGED
VIDEO_NATIVE=UNCHANGED
AUDIO_NATIVE=UNCHANGED
AUDIO_PRIME=UNCHANGED
JAVA_CHANGED_ENTRIES only PlatformGraphics + explicitly documented RG35XXCore2D entries
NO_GAME_NAMES_IN_RUNTIME=YES
NO_A9_PARENT=YES
NO_TRACE_IN_STABLE_CANDIDATE=YES
```

## 10. Promotion sequence

```text
P1A design
-> host differential gates
-> P1A platform exerciser on original RG35XX
-> protected graphics/module regression
-> Vua Cướp Biển
-> God of War
-> integrate into platform-completion parent
```

P1A does not claim full-platform DEVICE-PASS.

## 11. Platform modules after P1A

```text
P1B IMAGE FORMAT COVERAGE
P1C FONT/TEXT BACKEND
P2 FRONTEND/DEVICE CONTRACT
P3 COMPLETE PLATFORM EXERCISER
P4 3D CAPABILITY DECISION
P5 ONE GENERIC INSTALLER
P6 FULL PHYSICAL ACCEPTANCE
```

These are platform modules, not per-game fixes.

## 12. Current status

```text
P0_EXACT_GOLDEN=RECOVERED
AUDIT_V1_1=LOCKED
P1A_DESIGN=LOCKED
P1A_RUNTIME_CHANGE=NOT_YET_STARTED
NEXT_ACTION=P1A_DIFFERENTIAL_TEST_HARNESS_AND_STAGING_DESIGN
```
