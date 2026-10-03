# RG35XX P1A G2 — MIDP Shapes Diagnostic Result

## Status

```text
WORK_UNIT=P1A-G2-MIDP-SHAPES-DIAGNOSTIC
OWNER=RG35XX_GRAPHICS_BOUNDARY
RUNTIME_CHANGE=NO
BUILD-PASS=YES_DIAGNOSTIC_ONLY
DEVICE-PASS=NO
STABLE=NO
```

CI run `36946788735` completed successfully from G1 host-passing parent. No G2 runtime implementation was staged.

## Parent

```text
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G1_SEMANTIC_SHA256=86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527
PARENT_G1_PLATFORMGRAPHICS_CLASS_SHA256=c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0
```

## Pre-G2 failure classification

All tested G2 methods are `RAW_EXCEPTION` with `java.lang.NullPointerException` while canonical AWT completes:

- `drawArc`
- `fillArc`
- `drawRoundRect`
- `fillRoundRect`
- MIDP six-argument `fillTriangle`

This preserves the Phase-0 owner classification and gives a clean pre-implementation reference.

## JDK8 canonical raster signatures

| Case | Checksum | Painted pixels | Bounds |
|---|---|---:|---|
| DRAWARC_PARTIAL | `2e2997b45d1c05d` | 28 | `5,4..21,17` |
| DRAWARC_FULL | `8eb82820524d6b47` | 52 | `4,3..22,21` |
| DRAWARC_NEGATIVE | `f5e80014479de61` | 26 | `4,4..20,17` |
| FILLARC_PARTIAL | `990120d9efec27ed` | 106 | `6,5..20,16` |
| FILLARC_FULL | `fd571c43c24c137d` | 250 | `4,4..21,20` |
| FILLARC_NEGATIVE | `bc473a29432a7a19` | 114 | `4,4..19,16` |
| DRAWROUNDRECT_NORMAL | `33ebd2731f539f33` | 60 | `4,4..24,18` |
| DRAWROUNDRECT_OVERSIZE | `f815016ab6d89ba3` | 48 | `4,4..24,18` |
| DRAWROUNDRECT_ZERO_ARC | `64594b29c3b20413` | 68 | `4,4..24,18` |
| FILLROUNDRECT_NORMAL | `d146a57f06c4aa3` | 280 | `4,4..23,17` |
| FILLROUNDRECT_OVERSIZE | `d146a57f06c4aa3` | 280 | `4,4..23,17` |
| FILLTRIANGLE_NORMAL | `b48e18e5b0a5e906` | 171 | `4,4..23,21` |
| FILLTRIANGLE_REVERSED | `b48e18e5b0a5e906` | 171 | `4,4..23,21` |
| FILLTRIANGLE_FLAT | `6773006c437cf6eb` | 0 | `EMPTY` |

The artifact also contains the full 34×28 pixel masks for every case, so implementation gates can compare exact pixels rather than only the compact signatures above.

## Proven canonical quirks

`fillRoundRect(4,4,20,14,7,5)` is pixel-identical to `fillRect(4,4,20,14)`. The same final full-rectangle result remains for oversized arc radii. This follows the pinned Aweigit method, which calls `gc.fillRoundRect(...)` and then `gc.fillRect(...)`.

For the tested triangle:

- normal and reversed winding are pixel-identical;
- the fully collinear horizontal triangle paints zero pixels in the pinned JDK8 path.

Therefore the earlier physical COMP-02 triangle adapter is useful evidence for device survivability, but P1A must still pass the JDK8 pixel differential before it can be considered canonical-equivalent.

## Java2D path reference

The historical OpenJDK Java2D path routes:

- `drawArc` through `Arc2D.OPEN` and the draw shape pipeline;
- `fillArc` through `Arc2D.PIE` and the fill shape pipeline;
- round rectangles through `RoundRectangle2D.Float`.

This is why G2 arc/round-rect raster must be reference-driven rather than replaced with an unverified midpoint approximation.

## Artifact

```text
CI_RUN=36946788735
CI_HEAD=b5d6887d410596886face3cb7f4cd1d454ae898f
ARTIFACT_ID=11202715908
ARTIFACT_ZIP_SHA256=8cb6ef006fd7dd89e5ab6c3bb9ebba4928a389c5326b6d2d86e9d2bf53028f0a
```

## Implementation decomposition

```text
G2A=fillRoundRect only
G2B=fillTriangle only, canonical differential against JDK8 masks
G2C=drawRoundRect raster
G2D=drawArc/fillArc raster
```

Each sub-unit remains owner-scoped and must keep G1 locked.
