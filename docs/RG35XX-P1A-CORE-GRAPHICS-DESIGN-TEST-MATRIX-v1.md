# RG35XX P1A CORE GRAPHICS COVERAGE — DESIGN & TEST MATRIX v1

**Status:** `G1_BUILD_HOST_PASS / P1A_IN_PROGRESS`  
**Parent authority:** exact device-accepted Golden `057567d4...336c` / semantic A8 `7cd3a4a2...4adf`  
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

- `copyArea`: pinned source reads source `subx/suby` directly and destination is affected by Graphics translation.
- `copyArea` overlap is **not snapshot/memmove semantics** in the pinned JDK8 reference path. `canvas.getSubimage(...)` is a live sub-raster and `gc.drawImage(...)` was experimentally characterized as top-to-bottom, left-to-right for the tested `TYPE_INT_ARGB` path; right/down overlap therefore propagates writes into later source reads.
- `copyArea` semi-alpha SrcOver must match the pinned Java2D staged 8-bit arithmetic. G1 uses OpenJDK-compatible `MUL8`/`DIV8` rounding, not a single high-precision blend followed by one final rounding step.
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
- `copyArea`: canonical anchor + translated/clipped destination + live same-raster top-to-bottom/left-to-right traversal, including canonical overlap propagation.
- `copyArea` alpha: Java2D-compatible staged `MUL8`/`DIV8` SrcOver rounding.
- G1 implementation scope is `PlatformGraphics.class` only; `RG35XXCore2D.blit` remains unchanged because its snapshot/source-over behavior is protected for image/drawRegion ownership.
- G1 host/build status: `PASS` at run `36946272693`; physical status remains `DEVICE-PASS=NO`.

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

Reusable helper categories may include clip bounds, opaque/ARGB pixel operations, explicit-color line, polygon outline/fill, ellipse/arc raster, round-rect raster and DirectGraphics pixel conversion/transform staging.

`copyArea` is intentionally **not** routed through the protected `RG35XXCore2D.blit` helper because the pinned Java2D self-copy contract is live-raster rather than snapshot semantics.

`RG35XXCore2D` owns backing only; API argument/anchor/state/quirk semantics remain in `PlatformGraphics`.

## 7. Differential canonical-reference gate

Every P1A operation runs twice on host:

```text
A) pinned canonical AWT-backed PlatformGraphics
B) rg35xx.raw2d PlatformGraphics
```

Same canvas, initial pixels, color/ARGB, stroke state, translation, clipping, coordinates, anchors and transforms. Compare outputs through `getRGB`.

Bit-exact comparison is required where practical (clear/copy/pixels/transforms/clip/alpha). Arc/round-rect raster work must be reference-driven against the pinned CI JDK rather than accepted merely because it looks similar.

G1 additionally locks:
- copy overlap in both horizontal directions, both vertical directions and both tested diagonal directions;
- transparent source behavior;
- semi-alpha non-overlap and overlapping self-copy;
- AWT/Raw pre-operation alpha baseline equality before attributing any mismatch to `copyArea`;
- scope sentinels proving G2/G3 remain untouched (`drawArc` and MIDP `fillTriangle` still raw exceptions; generic DirectGraphics `fillPolygon` still the known mismatch).

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

For G1 specifically, the changed JAR entry is exactly `org/recompile/mobile/PlatformGraphics.class`; `CORE2D_CHANGE=NO`.

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
P1A_PHASE0_DIFFERENTIAL=PASS
P1A_G1_CLEAR_COPY_BUILD=PASS
P1A_G1_HOST_DIFFERENTIAL=PASS
P1A_G1_DEVICE_PASS=NO
P1A_G1_STABLE=NO
P1A_G2_PLUS=NOT_STARTED
NEXT_ACTION=P1A_G2_MIDP_SHAPES_DIFFERENTIAL_FIRST
```

G1 authoritative build/host evidence:
- CI run: `36946272693`
- head: `14bb0d4e3c8f3e1c7fe4a5e92ae2b76f5dedd014`
- parent A8 semantic: `7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf`
- candidate semantic: `86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527`
- candidate `PlatformGraphics.class`: `c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0`
- protected input/video hashes unchanged.
- artifact ID: `11201888516`; uploaded artifact ZIP digest: `7d56fc6e1b2cd2258b555494ba9285f9f97b54468c954f0bb415bfae46eb2f71`.
