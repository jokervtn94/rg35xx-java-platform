# A8 COMP-02 — GRAPHICS-FILLTRIANGLE-BOUNDARY-ONLY

Status: EXPERIMENTAL / DEVICE-PASS=NO

This candidate is governed by `RG35XX-PORT-RULER-LOCKED-v1.md` and the completed `RG35XX PLATFORM CONTRACT / GOLDEN RECONSTRUCTION MAP v1`.

## Production authority

- Canonical Aweigit: `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- RG35XX reset/base: `e7b0860310fd5204e1d1f2d01c992002b8660df2`
- Production parent: A8 GOLDEN only
- A9 branches/PRs: diagnostic evidence only; not imported and not used as parent

## Exact target evidence

- JAR: `Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar`
- SHA256: `b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b`
- Exact A8 hidden exception: `NullPointerException` at `org.recompile.mobile.PlatformGraphics.fillTriangle()`
- Failure owner for this exception only: `RG35XX_GRAPHICS_BOUNDARY`

## Seven locked answers before code

1. **Evidence requiring change** — exact A8 + exact COMP-02 JAR reaches the six-argument `PlatformGraphics.fillTriangle()` path and dereferences raw2D `gc == null`.
2. **Canonical Aweigit behavior** — the six-argument MIDP `Graphics.fillTriangle` fills the three-vertex polygon using the current Graphics RGB color.
3. **RG35XX boundary difference** — raw2D replaces desktop/AWT backing and intentionally leaves `PlatformGraphics.gc` null.
4. **Failure owner** — `RG35XX_GRAPHICS_BOUNDARY` for this NPE only.
5. **Permitted scope** — six-argument MIDP `Graphics.fillTriangle` raw path only; one changed runtime class: `org/recompile/mobile/PlatformGraphics.class`.
6. **Parent regressions** — accepted raw DrawRect, DrawLine, final rectangle-only DirectGraphics FillPolygon, ClipTranslate and Adam7 host gates, followed later by physical Vua Cướp Biển + God of War regression.
7. **Physical target acceptance** — on original RG35XX, COMP-02 must move beyond the exact pre-patch fillTriangle failure point without Tier-0 regression. That does not classify or fix later Asphalt 4 issues.

## Candidate implementation contract

The staged change adds a private raw2D triangle span fill and routes only the six-argument `fillTriangle` to it when `platformImage.isRG35XXRaw()` is true.

The implementation preserves:

- current Graphics RGB color as opaque ARGB, matching the canonical non-DirectGraphics fill path;
- raw translated coordinates;
- accepted device-space clip behavior after the God of War ClipTranslate correction;
- canonical Aweigit AWT fallback unchanged for non-raw operation.

The candidate explicitly does **not** change:

- seven-argument DirectGraphics `fillTriangle(..., argbColor)`;
- DirectGraphics `fillPolygon` final A8 rectangle-only raw contract;
- input;
- PERF-A1 presenter/video;
- audio/media;
- lifecycle;
- RMS/filesystem;
- vendor APIs;
- any game-name-specific path.

## Build gates

`build-a8-comp02-filltriangle-boundary.sh` fails closed unless:

- A7/A8 semantic parent digest is `7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf`;
- input native is `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`;
- video native is `c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d`;
- audio native is `4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644`;
- candidate JAR differs from semantic parent in exactly `PlatformGraphics.class`;
- the seven-argument DirectGraphics fillTriangle method remains bytecode-identical to parent;
- Java class major version stays <= 50;
- no Asphalt/game-specific marker is present in runtime class bytes;
- target fillTriangle host gate passes;
- final accepted A6 raw graphics regression gates pass.

## Current status vocabulary

- FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
- BUILD-PASS=NOT_YET_CONFIRMED_BY_CI
- DEVICE-PASS=NO
- TARGET_DEVICE_TEST=PENDING
- VUA_CUOP_BIEN_PHYSICAL_REGRESSION=PENDING
- GOD_OF_WAR_PHYSICAL_REGRESSION=PENDING
- STABLE=NO

No promotion is authorized by this document or by CI alone.
