# RG35XX P1A G2D-6B2 — OpenJDK8 native FillPath diagnostic

Status: diagnostic-only. No runtime semantic patch.

## Scope

- Module: Core 2D / `Graphics.fillArc`
- Representative strict failure: `FUZZ_7`
- AWT case: `fillArc(8,-4,26,9,1191,230)` on 48x40 `BufferedImage.TYPE_INT_ARGB`
- AWT trace from G2D-6B1: `FillPath(AnyColor, SrcNoEa, AnyInt)`
- Exact OpenJDK source repository: `openjdk/jdk8u`
- Exact pinned source commit: `64050651646459b18fa06ac90660e93999039c7e`
- Runtime change: NO

## Pinned native FillPath pipeline

`jdk/src/share/native/sun/java2d/loops/FillPath.c` does not evaluate ellipse membership per destination pixel.

For `FillPath(AnyColor, SrcNoEa, AnyInt)` it:

1. obtains the `Path2D.Float` types/coordinates and winding rule;
2. installs a `DrawHandler` whose fill output callback is `drawScanline`;
3. `drawScanline(x0,x1,y)` invokes the destination primitive for an inclusive horizontal run of `x1-x0+1` pixels;
4. calls native `doFillPath(...)`.

## Pinned native ProcessPath fill pipeline

`doFillPath(...)` in native `ProcessPath.c` installs:

- `pProcessFixedLine = StoreFixedLine`
- `pProcessEndSubPath = endSubPath`
- `clipMode = PH_MODE_FILL_CLIP`

Then it executes:

`ProcessPath -> StoreFixedLine -> FillPolygon -> pDrawScanline`.

This is the canonical final fill raster contract used by the traced AWT side.

### StoreFixedLine

`StoreFixedLine` stores flattened path segments in fixed-point coordinates (`MDP_PREC=10`) as a non-continuous point list. When bounds checking is required it first performs native Y clipping and X clip/clamp logic, including the fill-specific half-open contour handling, before storing the resulting line pieces.

### FillPolygon

`FillPolygon` is an active-edge scan converter derived from the Graphics Gems concave polygon algorithm and modified for subpixel precision/non-continuous paths.

Observed pinned semantics relevant to the port:

- scanlines are processed through pixel centers;
- horizontal edges are skipped when creating active edges;
- each non-horizontal edge carries a direction (`-1` or `+1`) for winding accounting;
- edge X is fixed-point and advanced by fixed-point `dx` once per scanline;
- `ArcIterator` reports `WIND_NON_ZERO`, therefore `FillPolygon` uses non-zero winding for Arc2D PIE;
- entering a filled span uses `xl = (edge.x + MDP_MULT - 1) >> MDP_PREC`;
- leaving a filled span uses `xr = (edge.x - 1) >> MDP_PREC`;
- the emitted span is inclusive `[xl,xr]`;
- if winding remains active at the right clip boundary, the scanline is extended to `xMax-1`.

These rules are materially different from the current Raw implementation.

## Current Raw fillArc contract is rejected

Current `rg35xxFillArcJdk8Lattice(...)` iterates integer destination coordinates and tests:

- normalized ellipse equation; then
- parametric sector angle via `atan2`.

That is not the raster path exercised by the AWT reference. The 18 fixed cases happen to match, but the deterministic fuzz corpus leaves 22 fill-only mismatches, so the lattice-sector equivalence claim is rejected.

## What is locked

```text
G2D6B2_PINNED_SOURCE_REPO=openjdk/jdk8u
G2D6B2_PINNED_SOURCE_COMMIT=64050651646459b18fa06ac90660e93999039c7e
G2D6B2_AWT_PRIMITIVE=FillPath(AnyColor,SrcNoEa,AnyInt)
G2D6B2_FILL_PIPELINE=ProcessPath->StoreFixedLine->FillPolygon->InclusiveScanline
G2D6B2_WINDING=NON_ZERO
G2D6B2_SUBPIXEL_PRECISION=MDP_PREC_10
G2D6B2_CURRENT_LATTICE_IMPL=REJECTED_AS_CANONICAL
G2D6B2_RUNTIME_CHANGE=NO
```

## Not yet proven

This source comparison does **not** yet prove which exact flattened edge/span decision causes `FUZZ_7` first difference `(21,5)`.

Next diagnostic checkpoint should trace or independently reproduce the canonical fixed-edge list and `FillPolygon` active-edge state for `FUZZ_7`, with emphasis on scanline `y=5`. No runtime `fillArc` patch should be written until that trace reproduces the AWT count/checksum and first-difference pixel.
