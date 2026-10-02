# RG35XX P1A G2D-6A4C — Native ProcessPath Diagnostic

Status: diagnostic-only. No runtime patch in this checkpoint.

## Scope

Single failing drawArc case under investigation:

- FUZZ_68
- drawArc(20,39,30,29,-971,-720)
- translate(+6,-3)
- no explicit clip
- framebuffer 48x40
- AWT pixel (31,39) = ff3366cc
- Raw pixel (31,39) = ffffffff

## AWT primitive already measured

`sun.java2d.loops.DrawPath::DrawPath(AnyColor, SrcNoEa, AnyInt)`

Therefore the strict AWT reference reaches native `DrawPath.c -> doDrawPath -> native ProcessPath -> LineUtils_ProcessLine`, not the Java `GeneralRenderer` fallback.

## Canonical source authority

OpenJDK 8 source commit used for this comparison:

`64050651646459b18fa06ac90660e93999039c7e`

Native file:

`jdk/src/share/native/sun/java2d/loops/ProcessPath.c`

## First source divergence

Native `PROCESS_LINE` performs an additional integer pre-clip when `checkBounds` is true. It derives:

- `xMinf = dhnd->xMinf + 0.5f`
- `yMinf = dhnd->yMinf + 0.5f`
- `xMaxf = dhnd->xMaxf + 0.5f`
- `yMaxf = dhnd->yMaxf + 0.5f`

and applies `TESTANDCLIP(...)` to integer `X0/Y0/X1/Y1` before calling `pDrawLine`.

Current G2D-6A3 Raw helper `rg35xxArcProcessLine(...)` does not perform this native integer pre-clip. For non-single-pixel lines it calls `rg35xxPPDrawJdk8Line(X0,Y0,X1,Y1,...)` directly, where the later clipping follows the Java `GeneralRenderer.adjustLine()` model.

This is the first confirmed source-level divergence on the measured AWT native path.

## LineUtils result

`LineUtils_SetupBresenham` plus the solid drawline macro encode the same Bresenham stepping rule in a transformed state:

- setup pre-adds `errmajor`
- exported `errminor` becomes `errminor - errmajor`
- `InitBumps` makes the minor bump include the major bump
- drawline selects major vs major+minor based on error sign

For the small FUZZ_68 coordinates this is equivalent to the GeneralRenderer-style Bresenham recurrence already used by Raw. Therefore `LineUtils` itself is not the first divergence.

## Locked interpretation

```
FUZZ68_AWT_BACKEND=NATIVE_DRAWPATH_ANYINT
GENERALRENDERER_FINAL_REFERENCE=REJECTED
LINEUTILS_FIRST_DIVERGENCE=NO
FIRST_CONFIRMED_DIVERGENCE=NATIVE_PROCESSPATH_PROCESS_LINE_INTEGER_PRECLIP
CURRENT_RAW_MISSING=NATIVE_CHECKBOUNDS_INTEGER_PRECLIP
RUNTIME_PATCH=NO
HOST_DIFFERENTIAL_PASS=NO
DEVICE_PASS=NO
STABLE=NO
```

## Next checkpoint

G2D-6A4D should be diagnostic-only: instrument or simulate FUZZ_68 fixed-line segments and prove that applying the native `PROCESS_LINE` pre-clip changes the boundary segment/pixel at (31,39) before any runtime patch is accepted.
