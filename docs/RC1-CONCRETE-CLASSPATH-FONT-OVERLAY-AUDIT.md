# RC1 Concrete GNU Classpath Font Overlay Audit

Status: STATIC-AUDIT-PASS for source reconciliation. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Scope

RGJ-RC1-011M converts the earlier 0022 headless-font contract into a deterministic source overlay for the exact GNU Classpath 0.99 runtime tree. It does not create a new FreeJ2ME font facade and does not restore `RG35XXFontEngine`.

## Exact GNU Classpath 0.99 findings

The audited 0.99 source has `HeadlessToolkit.getFontPeer(String,int)` and `HeadlessToolkit.getClasspathFontPeer(String,Map)` implemented as null-returning stubs. `java.awt.Font` obtains its peer through the toolkit, so the headless null peer is a direct cause candidate for the historical `Font.hashCode` / glyph-vector / draw-string failures.

The audited `gnu.java.awt.font.OpenTypeFontPeer` exposes both constructors required by the overlay:

- `OpenTypeFontPeer(String name, int style, int size)`
- `OpenTypeFontPeer(String name, Map atts)`

It loads `gnu/java/awt/font/fonts.properties`, maps logical family/style to a filesystem filename, memory maps that TTF and creates a `FontDelegate` through `FontFactory.createFonts`.

A critical exact-source defect for the RC target is that both constructors catch all exceptions, print them, and continue. That can leave private `fontDelegate` null and defer the failure until metrics/glyph operations. 011M changes only the disposable assembled Classpath tree so constructor failure throws a RuntimeException immediately instead.

## Concrete overlay policy

`runtime/classpath/apply_rg35xx_font_overlay.sh` now:

1. verifies the exact OpenTypeFontPeer constructor/mapping shape before mutation;
2. requires exactly one `gnu/java/awt/font/fonts.properties`;
3. materializes the externally pinned DejaVuSans TTF into a deterministic assembly path;
4. maps SansSerif, Dialog and Monospaced, all four styles, to that one file for RC1;
5. replaces only the two headless null font-peer stubs;
6. caches peers by logical family and a defensive Map copy of the attribute set, relying on Map semantic equality rather than unstable string formatting;
7. converts both OpenTypeFontPeer constructor catch-and-continue paths to fail-closed RuntimeException paths;
8. refuses source drift or already-modified baselines rather than performing a fuzzy rewrite.

The overlay remains source-only. No font file is checked into this repository by the text connector and no font binary hash is fabricated. The materialized file identity remains governed by the prebuild/font provenance gates.

## Runtime assembly integration

`scripts/rc1_runtime_build_overlay.sh` now runs `rc1_classpath_preflight.sh` on the source/input pair, clones Classpath to a disposable runtime tree, applies the 011M concrete overlay there, verifies the resulting HeadlessToolkit/OpenTypeFontPeer markers, and preserves the 011K native Make overlay behavior.

The original GNU Classpath source input is never mutated.

## Ownership

- FreeJ2ME `PlatformFont` remains the MIDP font facade.
- FreeJ2ME `PlatformGraphics` remains the draw-string consumer.
- GNU Classpath `HeadlessToolkit` is the headless toolkit font-peer provider.
- GNU Classpath `OpenTypeFontPeer` / `FontDelegate` / `FontFactory` remain the raster/metrics backend.
- DejaVu Sans is the pinned external RC1 TTF provider.
- `RG35XXFontEngine` remains SUPERSEDED / DO NOT RESTORE.

## Remaining gates

STATIC source reconciliation does not prove the modified Classpath compiles under the actual JamVM/Classpath build. Before BUILD-PASS, the assembled runtime must compile and the JamVM smoke probe must exercise at least logical SansSerif/Dialog/Monospaced through `Font.hashCode`, `FontMetrics`, `createGlyphVector`, Vietnamese glyph strings and representative FreeJ2ME drawString usage. Native ARMv5TE/uClibc compilation/linking is a separate mandatory gate.

## Result

011M closes the previous `0022 is only a contract` gap at project-source level. The repository now contains a guarded, deterministic concrete overlay and runtime-assembly hook. Status is STATIC-AUDIT-PASS only; first real compiler execution remains the next major gate.
