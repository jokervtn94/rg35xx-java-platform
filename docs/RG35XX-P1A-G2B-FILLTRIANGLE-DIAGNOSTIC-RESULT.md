# RG35XX P1A G2B — fillTriangle Diagnostic Result

## Status

```text
WORK_UNIT=P1A-G2B-FILLTRIANGLE-DIAGNOSTIC
OWNER=RG35XX_GRAPHICS_BOUNDARY
ALGORITHM_UNDER_TEST=EXACT_DEVICE_PROVEN_COMP02_SCANLINE
BUILD-PASS=YES_DIAGNOSTIC_ONLY
CANONICAL_EQUIVALENT=NO
DEVICE-PASS=NO_FOR_P1A_CANDIDATE
STABLE=NO
```

This result does **not** revoke the earlier physical finding that the COMP-02 helper reached Asphalt gameplay on original RG35XX. It establishes a different fact: that helper is not pixel-equivalent to the pinned JDK8 canonical raster and therefore cannot be promoted unchanged into P1A platform completion.

## Parent and scope

```text
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
RESET_BASE=e7b0860310fd5204e1d1f2d01c992002b8660df2
PARENT_G2A_SEMANTIC_SHA256=1e33e7e37b0e0e5d3d0f836f8c29e80e28fb45c961f8fbb05f72af41de76ba51
PARENT_G2A_PLATFORMGRAPHICS_CLASS_SHA256=e6e377425eb46461c42f4d16b2da77a6f4b287f5ca12add8a97e6869def434db
CHANGED_METHODS=Graphics.fillTriangle_6ARG_DIAGNOSTIC_ONLY
CHANGED_JAR_ENTRIES=org/recompile/mobile/PlatformGraphics.class
CORE2D_CHANGE=NO
```

DirectGraphics seven-argument `fillTriangle`, `drawArc`, `fillArc`, and `drawRoundRect` remained untouched Raw2D `NullPointerException` scope sentinels. G1/G2A parent regression, G1 alpha regression, and accepted A6 graphics/PNG regression gates all passed.

## Decisive differential result

The broad 21-case geometry matrix completed with:

```text
TRIANGLE_DIAGNOSTIC_MISMATCH_COUNT=15
TRIANGLE_ERROR_COUNT=0
SCOPE_FAILURE_COUNT=0
TRIANGLE_CANONICAL_EQUIVALENT=NO
```

Representative mismatches:

| Case | AWT | Raw COMP-02 helper | Evidence |
|---|---|---|---|
| REFERENCE | 171 painted, bounds `4,4..23,21` | 160 painted, bounds `4,4..22,21` | first diff `(5,5)` |
| REVERSED | same canonical signature as reference | same 160-pixel raw mismatch | winding reversal does not fix edge rule |
| PARTIAL_NEGATIVE | 383 painted | 365 painted | first diff `(1,0)` |
| PARTIAL_RIGHT_BOTTOM | 318 painted, bounds through y=31 | 303 painted, bounds through y=30 | bottom/right edge loss |
| SPANNING | 1038 painted | 1017 painted | first diff `(0,1)` |

Full mismatch masks/checksums are in the CI artifact.

## Failure owner

The mismatch stays inside `RG35XX_GRAPHICS_BOUNDARY`. Evidence points specifically to raster edge rules, not lifecycle/presenter/input/audio ownership.

The old helper samples at integer rows, computes intersections with truncating division, then fills `[left,right)`. Historical OpenJDK `ProcessPath.FillPolygon` instead uses 10-bit fixed-point active edges and inclusive scanline endpoints:

```text
MDP_PREC=10
MDP_MULT=1024
horizontal edges skipped
edge x stepped once per scanline in fixed-point
xl=(leftEdge.x + 1023) >> 10
xr=(rightEdge.x - 1) >> 10
drawScanline(xl,xr,y) when xl<=xr
```

This explains the systematic missing right/bottom edge pixels visible in the diagnostic.

## CI identity

```text
CI_RUN=36947926614
CI_HEAD=78c1012982cfd4105d9df70912b643e829ff5d24
CANDIDATE_PLATFORM_JAR_SHA256=c7089594772382054d0758d9d5596353c1035d141758334aede8dec5523ae209
CANDIDATE_PLATFORM_SEMANTIC_SHA256=6d5f6767fe581ee1cc921fc0dd03a0268f60eafc5462816a123b635978287490
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=722c051808362324d6488088910af1de6e9a10edd90f8f2be3b8bc21d3b11688
ARTIFACT_ID=11203893345
ARTIFACT_ZIP_SHA256=478f64902ce009b878e4fa4bf48324db510438815341778717f489d6b2ed18f7
```

## Next

A new G2B implementation must be based from the clean G2A result, **not** from this diagnostic runtime candidate. The replacement raw six-argument `fillTriangle` will specialize the pinned OpenJDK `ProcessPath.FillPolygon` active-edge rules for exactly three straight edges, then must pass the same 21-case matrix with zero mismatch before host/build promotion.
