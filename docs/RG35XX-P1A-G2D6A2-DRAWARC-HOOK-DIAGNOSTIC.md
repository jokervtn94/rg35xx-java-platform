# RG35XX P1A G2D-6A2 drawArc hook diagnostic

Status: DIAGNOSTIC LOCKED

Branch: `p1a-g2d-arc-family-jdk8-raster`
Parent examined: `69a66e4b568a0e088227cf3e6544e978431f8bec`
Canonical reference: OpenJDK 8u `ProcessPath.java` at `64050651646459b18fa06ac90660e93999039c7e`

## CI fact

Run `36961924643` remained at:

```text
G2D_FIXED_CASES=37/37 PASS
G2D_FUZZ_FAILURES=27
DRAWARC_FUZZ_FAILURES=5
FILLARC_FUZZ_FAILURES=22
```

The G2D-6A `GeneralRenderer.adjustLine` stage was applied successfully, but the five drawArc failures were unchanged.

## Five remaining drawArc cases

The deterministic fuzz generator (`Random(0x35AA2D5L)`) reproduces these exact draw cases:

```text
FUZZ_68  drawArc x=20 y=39 w=30 h=29 start=-971 extent=-720 translate=(+6,-3) clip=none
FUZZ_148 drawArc x=18 y=-14 w=14 h=27 start=819 extent=179 translate=(-1,-5) clip=none
FUZZ_192 drawArc x=23 y=-4 w=29 h=23 start=-1039 extent=90 translate=(+4,+4) clip=(8,2,27,1)
FUZZ_208 drawArc x=20 y=19 w=34 h=20 start=870 extent=359 translate=(+5,0) clip=none
FUZZ_316 drawArc x=1 y=31 w=34 h=23 start=-436 extent=-450 translate=(-3,-6) clip=none
```

All five are boundary-intersecting cases after translation and/or explicit clipping.

## Why G2D-6A did not change the result

G2D-6A replaces only the final integer-line helper `rg35xxPPDrawJdk8Line(...)` and adds an integer `GeneralRenderer.adjustLine` equivalent.

The Raw helper immediately above it remains:

```text
rg35xxPPProcessFixedLine(x1,y1,x2,y2,argb)
```

It has no equivalents for canonical ProcessPath state:

```text
pixelInfo[]
checkBounds
endSubPath
```

OpenJDK 8 `DrawMonotonicCubic(...)` calls:

```text
hnd.processFixedLine(..., pixelInfo, checkBounds, false)
```

and `ProcessMonotonicCubic(...)` computes `checkBounds` from the fractional clipping box (`xMinf/yMinf/xMaxf/yMaxf`) before forwarding the cubic to the fixed-line raster stage.

Therefore the information needed to reproduce canonical boundary semantics has already been discarded before `rg35xxPPDrawJdk8Line(...)` is reached. Adding integer endpoint clipping at that later helper cannot reconstruct it.

## Correct owner / next hook

The remaining drawArc owner is now:

```text
OPENJDK8_PROCESSPATH_DRAWPROCESSHANDLER_STATE
```

The next implementation must be scoped to the drawArc ProcessPath subset and preserve, at minimum:

```text
fractional curve bounds
checkBounds propagation
pixelInfo first/last pixel state across the arc subpath
processFixedLine endpoint semantics
```

Do not modify:

```text
ArcIterator geometry
cubic extrema splitting
fillArc
G2C drawRoundRect accepted raster
Core2D
native input/video/audio
JamVM/glibj
```

## Rejected approach

```text
G2D-6A_GENERALRENDERER_ADJUSTLINE_ONLY=REJECTED
```

Reason: correct lower-level algorithm, wrong hook level; strict fuzz output unchanged.

## Status

```text
DRAWARC_FIXED_MATRIX=PASS
DRAWARC_FUZZ=5_FAIL
DRAWARC_GEOMETRY=LOCKED
DRAWARC_EXTREMA_SPLIT=LOCKED
DRAWARC_REMAINING_OWNER=PROCESSPATH_DRAWPROCESSHANDLER_STATE
FILLARC_CURRENT_IMPL=REJECTED_SEPARATE_OWNER
HOST-DIFFERENTIAL-PASS=NO
PHYSICAL_TEST=NO
STABLE=NO
NEXT=G2D-6A3_PROCESSPATH_DRAW_STATE
```
