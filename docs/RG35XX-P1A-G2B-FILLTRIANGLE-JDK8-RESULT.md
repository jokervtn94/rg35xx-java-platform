# RG35XX P1A G2B — fillTriangle JDK8 Host Result

## Status

```text
WORK_UNIT=P1A-G2B-FILLTRIANGLE-JDK8-RASTER
OWNER=RG35XX_GRAPHICS_BOUNDARY
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=NO
PHYSICAL_TEST_REQUIRED=NO_MODULE_INTEGRATION_PENDING
STABLE=NO
```

This is a host implementation unit only. It is not a production baseline and must converge into `P1A-COMPLETE-GRAPHICS-CANDIDATE` before physical acceptance.

## Parent / scope

```text
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G2A_SEMANTIC_SHA256=1e33e7e37b0e0e5d3d0f836f8c29e80e28fb45c961f8fbb05f72af41de76ba51
PARENT_G2A_PLATFORMGRAPHICS_CLASS_SHA256=e6e377425eb46461c42f4d16b2da77a6f4b287f5ca12add8a97e6869def434db
CHANGED_METHODS=Graphics.fillTriangle_6ARG
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
CORE2D_CHANGE=NO
DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED
GAME_SPECIFIC_CODE=NO
NO_A9_PARENT=YES
```

## Rejected first implementation

The first G2B attempt incorrectly modeled `Graphics2D.fillPolygon()` using OpenJDK `ProcessPath.FillPolygon` (`MDP_PREC=10`). Strict differential produced 13 mismatches. That implementation is rejected and is not evidence for promotion.

Source review then established the actual JDK8 BufferedImage thin-fill path:

```text
PlatformGraphics.fillTriangle
 -> Graphics2D.fillPolygon
 -> LoopPipe.fillPolygon
 -> ShapeSpanIterator.appendPoly
 -> fillSpans
```

The corrected Raw2D implementation therefore specializes the OpenJDK8 `LoopPipe/ShapeSpanIterator` polygon scan conversion for three vertices, including:

- pixel-center normalization `+0.25f`;
- `ceil(y - 0.5)` scanline start/end convention;
- `ERRSTEP_MAX=0x7fffffff` fixed-error edge stepping;
- float32 geometry behavior;
- JDK8 clip/outcode semantics needed by the characterized triangle matrix;
- half-open output spans `[x0,x1)`.

## Strict differential result

All 21 characterized cases are bit-exact AWT-vs-Raw2D matches:

```text
REFERENCE
REVERSED
PERM_BAC
PERM_BCA
PERM_CAB
PERM_CBA
FLAT_HORIZONTAL
FLAT_VERTICAL
DUPLICATE_AB
DUPLICATE_BC
ALL_DUPLICATE
SKINNY_VERTICAL
SKINNY_HORIZONTAL
TINY_RIGHT
TINY_TWO
CLIP
TRANSLATE
CLIP_TRANSLATE
PARTIAL_NEGATIVE
PARTIAL_RIGHT_BOTTOM
SPANNING
```

Locked markers:

```text
P1A_G2B_STRICT_FAILURE_COUNT=0
P1A_G2B_FILLTRIANGLE_DIFFERENTIAL_GATE=PASS
P1A_G2B_CANONICAL_EQUIVALENT=YES
P1A_G2B_SCOPE=Graphics.fillTriangle_6ARG_ONLY
```

Parent regressions remain PASS:

- G1 clear/copy differential;
- G1 copyArea alpha differential;
- G2A fillRoundRect differential;
- A6 ClipTranslate;
- drawRect;
- drawLine;
- accepted rectangle-only DirectGraphics fillPolygon;
- Adam7.

Neighbor scope sentinels remain unimplemented Raw2D paths by design at this work unit:

- `drawArc`;
- `fillArc`;
- `drawRoundRect`;
- 7-argument DirectGraphics `fillTriangle`.

## Final host evidence

```text
CI_RUN=36955426702
CI_HEAD=6a9bce7195474e40975ce69fc2fcef98e2c090d0
CANDIDATE_PLATFORM_JAR_SHA256=f668e5a6d0226d1c75ac8a68b66eeed8ef06381e202da0cf0e17b21c83ddda4f
CANDIDATE_PLATFORM_SEMANTIC_SHA256=d6cc9aa636b3435de07bff4552d4feb5ad7cada41c63ef66719fec8f192cdb77
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=a6004238f7c36455f498d024a171159cb69a7fd95647aa5cabcf966e4e625cec
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
ARTIFACT_ID=11205472513
ARTIFACT_ZIP_SHA256=fd29da5f107f916e83fd459988563d96110142c6572103aa82e5159440344a62
```

The raw JAR hash is packaging-byte-specific. Semantic digest and `PlatformGraphics.class` hash are the stable G2B code identities.

## Next

G2C characterizes and implements only `drawRoundRect` on host. No G2B physical package is required. G2A/G2B/G2C/G2D are temporary implementation units that must converge into the complete graphics module before any new original-RG35XX physical test.
