# P1A Core Graphics Differential Harness

Status: DESIGN/TEST ONLY. No runtime change.

Parent authority: exact A8 Golden platform JAR SHA256 `057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`.
Canonical source: `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`.
Reset/base: `e7b0860310fd5204e1d1f2d01c992002b8660df2`.

## Goal

Stop commercial-game-driven graphics fixes. Establish a method-level platform gate that compares the staged AWT/canonical path against the RG35XX Raw2D path for the same inputs.

## Differential model

The accepted A4/A5/A6 staged `PlatformImage` chooses its backing at construction time from `Boolean.getBoolean("rg35xx.raw2d")`.

For each case the harness creates two images in the same JVM:

1. clear `rg35xx.raw2d`; construct AWT-backed image and execute the operation;
2. set `rg35xx.raw2d=true`; construct Raw2D image and execute the same operation;
3. read both results through `PlatformImage.getRGB`;
4. compare results or record the exact exception class.

This keeps anchors, clipping, translation and canonical quirks in one implementation while varying only the RG35XX backing boundary.

## Phase 0 expected result

Before P1A implementation the coverage harness is intentionally diagnostic. It must identify unsupported Raw2D methods without claiming BUILD-PASS or DEVICE-PASS.

Expected current gaps include at least:

- clearRect
- copyArea
- drawArc / fillArc
- drawRoundRect / fillRoundRect
- MIDP fillTriangle on exact A8
- DirectGraphics polygon/triangle generic paths
- DirectGraphics drawPixels/getPixels raw paths
- DirectGraphics explicit-alpha paths

Existing protected methods are included as controls:

- fillRect
- drawLine
- drawRect
- clip/translate

## Coordinate rule

Raw2D device coordinate = user coordinate + `translateX/translateY`.
Raw clip is stored in device coordinates. `translate()` must not move an already established raw clip.

## Classification emitted by harness

- `MATCH`: AWT and Raw2D outputs match exactly.
- `RAW_EXCEPTION`: Raw2D throws while AWT completes.
- `AWT_EXCEPTION`: canonical path throws; not an RG35XX-only gap.
- `MISMATCH`: both complete but pixel output differs.
- `CANONICAL_STUB`: method intentionally not compared because pinned Aweigit itself is a stub.

## Promotion rule

P1A runtime implementation is allowed only after every target method has:

1. a canonical reference case in this harness;
2. a known current classification;
3. a documented raw equivalent;
4. host regression coverage;
5. one platform-exerciser case for original RG35XX.

No commercial game name may appear in P1A runtime logic or host gates.
