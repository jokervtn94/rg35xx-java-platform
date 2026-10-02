# RG35XX P1A G1 — Clear/Copy Result

## Status

```text
WORK_UNIT=P1A-G1-CLEAR-COPY
OWNER=RG35XX_GRAPHICS_BOUNDARY
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=NO
STABLE=NO
```

No promotion is implied by host CI.

## Parent and scope

- Canonical: Aweigit `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`.
- Reset base: `e7b0860310fd5204e1d1f2d01c992002b8660df2`.
- A8 semantic parent: `7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf`.
- Changed methods: `clearRect`, `copyArea` only.
- Changed JAR entry: `org/recompile/mobile/PlatformGraphics.class` only.
- `RG35XXCore2D`: unchanged.
- Input/video native identities: unchanged golden hashes.
- JamVM/glibj: untouched.
- A9 parent: no.
- Game-specific G1 runtime delta: no.

## Proven canonical behavior

`clearRect` is a translated, device-clipped transparent clear.

Pinned JDK8 `copyArea` is not snapshot/memmove self-copy. The canonical `getSubimage()+drawImage()` path was characterized as live-raster traversal top-to-bottom and left-to-right for the tested `TYPE_INT_ARGB` path. Consequently right/down overlap propagates earlier writes into later reads. Both forward/backward horizontal, up/down vertical, and tested diagonal directions are locked by differential gates.

Semi-alpha SrcOver is also bit-exact to the pinned Java2D path. The correct result requires staged 8-bit `MUL8`/`DIV8` rounding; the earlier single high-precision blend formula was rejected by differential evidence.

## Gates

The final G1 build requires:

- exact A8 semantic parent and accepted `PlatformGraphics.class` parent hash;
- Java 6 bytecode;
- exact single-class JAR scope;
- clear/copy AWT-vs-Raw differential cases;
- live-raster overlap matrix;
- transparent-source copy;
- normalized semi-alpha AWT/Raw pre-copy baseline equality;
- semi-alpha non-overlap/right-overlap/down-overlap equality;
- sentinels proving `drawArc` and MIDP `fillTriangle` remain raw exceptions and generic DirectGraphics `fillPolygon` remains the pre-G1 mismatch;
- ClipTranslate, drawRect, drawLine, rectangle-polygon and Adam7 protected regression gates.

## Final host evidence

```text
CI_RUN=36946272693
CI_HEAD=14bb0d4e3c8f3e1c7fe4a5e92ae2b76f5dedd014
CANDIDATE_PLATFORM_JAR_SHA256=72feb0a928539f428c57978774c6e5a5677c3c23d4203bc63e1a2087fde45ba8
CANDIDATE_PLATFORM_SEMANTIC_SHA256=86cdf216cf08a93747e38ed90a81b29cff84139dcfd013fcf9f5aead5e9ca527
CANDIDATE_PLATFORMGRAPHICS_CLASS_SHA256=c92cc05b31e4ce56eed8f7afae5abee6a62eba9a731ba39b232d3a8b895004b0
ARTIFACT_ID=11201888516
ARTIFACT_ZIP_SHA256=7d56fc6e1b2cd2258b555494ba9285f9f97b54468c954f0bb415bfae46eb2f71
```

The raw JAR SHA is packaging-byte specific; semantic JAR digest plus class hash are the stable G1 identities.

## Next

`P1A-G2-MIDP-SHAPES` starts with canonical differential characterization. No G1 method is to be refactored while G2 is developed unless new G1 evidence appears.
