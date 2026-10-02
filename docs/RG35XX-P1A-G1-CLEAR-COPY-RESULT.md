# RG35XX P1A G1 — Clear/Copy Result

## Status

```text
WORK_UNIT=P1A-G1-CLEAR-COPY
OWNER=RG35XX_GRAPHICS_BOUNDARY
BUILD-PASS=YES
HOST-DIFFERENTIAL-PASS=YES
DEVICE-PASS=YES
G1_LOCKED=YES
STABLE=NO
```

G1 is accepted only for its scoped `clearRect` + `copyArea` platform boundary. This does not promote the whole platform to stable.

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

## Physical RG35XX acceptance

The dedicated platform exerciser was run on the original RG35XX from the GarlicOS APPS flow.

Human physical observation:

```text
SCREEN=GREEN_BACKGROUND_PLUS_3_HORIZONTAL_BARS
EXPECTED_G1_PASS_PATTERN=YES
```

Runtime evidence on the same package reported:

```text
IDENTITY_GATE=PASS
P1A_G1_DEVICE_CASE=CLEAR_BASIC RESULT=PASS
P1A_G1_DEVICE_CASE=CLEAR_CLIP_TRANSLATE RESULT=PASS
P1A_G1_DEVICE_CASE=CLEAR_DEGENERATE RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_BASIC RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_ANCHOR RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_CLIP_TRANSLATE RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_OVERLAP_RIGHT_LIVE RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_OVERLAP_DOWN_LIVE RESULT=PASS
P1A_G1_DEVICE_CASE=COPY_TRANSPARENT_SOURCE RESULT=PASS
P1A_G1_DEVICE_EXERCISER_FAIL_CASE=NONE
P1A_G1_DEVICE_EXERCISER_RESULT=PASS
P1A_G1_DEVICE_EXERCISER_NORMAL_EXIT=PASS
RUNTIME_EXIT_CODE=0
PROGRAMMATIC_EXERCISER=PASS
PROTECTED_HASHES=PASS
NORMAL_EXIT=PASS
```

Accepted device identities:

```text
G1_PLATFORM_SHA256=72feb0a928539f428c57978774c6e5a5677c3c23d4203bc63e1a2087fde45ba8
EXERCISER_JAR_SHA256=6c4c0563c8b8eb0923b3677d876986e2cd109bd0ea4b03682571874f86d043fe
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

## Lock

```text
P1A_G1_DEVICE_PASS=YES
P1A_G1_LOCKED=YES
P1A_G1_OWNER=CLOSED
REFRACTOR_G1_WITHOUT_NEW_EVIDENCE=NO
```

## Next

`P1A-G2-MIDP-SHAPES` starts from canonical differential characterization. G1 methods are protected and must not be refactored while G2 is developed unless new G1 evidence appears.
