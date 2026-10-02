# RG35XX P1A G2A — fillRoundRect Result

## Status

```text
WORK_UNIT=P1A-G2A-FILLROUNDRECT
OWNER=RG35XX_GRAPHICS_BOUNDARY
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=NO
STABLE=NO
```

No physical promotion is implied by CI.

## Parent and scope

```text
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G1_SEMANTIC_SHA256=86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527
PARENT_G1_PLATFORMGRAPHICS_CLASS_SHA256=c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0
CHANGED_METHODS=fillRoundRect
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
CORE2D_CHANGE=NO
```

The Raw2D implementation deliberately delegates to the already accepted raw `fillRect`. This preserves the pinned Aweigit quirk: canonical `fillRoundRect` calls `gc.fillRoundRect(...)` and then `gc.fillRect(...)`, so its final raster is a full rectangle rather than a rounded fill.

## Differential evidence

The following all match the pinned JDK8 AWT result exactly:

- normal arc radii;
- oversized arc radii;
- zero arc radii;
- clip;
- translate;
- clip + translate;
- zero width/height;
- negative width/height.

Both backends also directly prove `fillRoundRect == fillRect` for the reference case.

Scope sentinels remain unchanged Raw2D `NullPointerException`:

- `drawRoundRect`;
- `drawArc`;
- `fillArc`;
- six-argument MIDP `fillTriangle`.

G1 main and semi-alpha differential gates, plus accepted ClipTranslate/drawRect/drawLine/rectangle-polygon/Adam7 gates, all remain PASS on the G2A candidate.

## Final identity

```text
CI_RUN=36947221831
CI_HEAD=fa6c5e91cf53bb0e84c31458120e07903ce4ca91
CANDIDATE_PLATFORM_JAR_SHA256=eb26cebbab46c93c8285cf03bc7eac7dc27130913a2b8e4ce44116a9c861933e
CANDIDATE_PLATFORM_SEMANTIC_SHA256=1e33e7e37b0e0e5d3d0f836f8c29e80e28fb45c961f8fbb05f72af41de76ba51
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=e6e377425eb46461c42f4d16b2da77a6f4b287f5ca12add8a97e6869def434db
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
ARTIFACT_ID=11203130098
ARTIFACT_ZIP_SHA256=0ce67d08d59f2771c162ece7f9fa002debbb4aa9c218bd0d1635a68078a62fb1
```

## Next

G2B handles only the six-argument MIDP `fillTriangle`. The already physically proven COMP-02 adapter is evidence for RG35XX survivability, not proof of JDK8 pixel equivalence. G2B starts by running that adapter against a wider canonical differential matrix before any P1A promotion.
