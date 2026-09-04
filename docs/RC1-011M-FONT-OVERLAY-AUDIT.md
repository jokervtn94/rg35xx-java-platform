# RGJ-RC1-011M — Concrete GNU Classpath Font Runtime Overlay Audit

Status: STATIC-AUDIT-PASS. This is not BUILD-PASS or DEVICE-TEST-PASS.

## Verified source/runtime evidence

The inspected GNU Classpath 0.99 source exposes `OpenTypeFontPeer(String,int,int)` and `OpenTypeFontPeer(String,Map)`. Both constructors resolve a logical font through `fonts.properties`, open the mapped filename and create the delegate with `FontFactory.createFonts(buffer)[0]`.

The inspected `HeadlessToolkit` baseline has null `getFontPeer(String,int)` / `getClasspathFontPeer(String,Map)` stubs. Historical RG35XX/JamVM traces show the direct consequence: null FontPeer failures in `Font.getName`, `Font.getStyle`, `Font.getTransform` and `Font.createGlyphVector`.

Historical traces also prove that merely supplying a valid OpenType peer is not sufficient. When the OpenType path was active, Vietnamese/compound glyph rendering reached GNU Classpath's TrueType loader and failed with `ArrayIndexOutOfBoundsException` in `Zone.combineWithSubGlyph`, via `GlyphLoader.loadCompoundGlyph`. Therefore 011M must close both peer creation and compound-glyph capacity safety before compiler/runtime validation.

## Implemented 011M overlay

`runtime/classpath/apply_rg35xx_font_overlay.sh` now:

1. verifies the exact GNU Classpath OpenTypeFontPeer constructors and fonts.properties contract;
2. rewrites only the guarded null HeadlessToolkit font-peer stubs;
3. maps SansSerif/Dialog/Monospaced to the pinned DejaVu Sans runtime file;
4. uses a synchronized logical-family/attribute peer cache;
5. converts OpenType constructor failures from print-and-continue into fail-closed RuntimeException behavior;
6. stages the font payload for deployment without leaking a disposable host path into runtime configuration.

`runtime/classpath/apply_rg35xx_compound_glyph_fix.sh` additionally performs one narrow correction to GNU Classpath 0.99 `Zone.combineWithSubGlyph`: before the existing `System.arraycopy`, it computes the required point capacity, grows the backing Point array only when required, preserves existing points, then performs the original merge. The script refuses to modify a source tree whose baseline method does not match the audited implementation.

`scripts/rc1_runtime_build_overlay.sh` applies both corrections to the same disposable Classpath assembly and asserts both are present before generating the runtime deployment manifest/native Make overlay.

## Why this replaces the old safe-ASCII fallback

Historical builds fell back to `safe ASCII mode` after compound glyph failures. That avoided crashes but did not meet the platform requirement for Vietnamese/Unicode text. RC1 therefore does not revive `RG35XXFontEngine` or the ASCII-only renderer. The authoritative path remains PlatformFont/PlatformGraphics -> GNU Classpath FontPeer/OpenType delegate, with the smallest source correction required by the observed compound-glyph overflow.

## Remaining acceptance gate

STATIC-AUDIT-PASS does not prove renderer correctness. BUILD-READY still requires a materialized GNU Classpath 0.99 + DejaVu Sans input and successful compilation. Runtime acceptance must cover at least:

- `Font.hashCode` and basic logical font construction;
- `createGlyphVector` for ASCII and Vietnamese strings;
- width/metrics stability at the LCDUI sizes used by FreeJ2ME;
- compound glyphs that previously reached `Zone.combineWithSubGlyph`;
- representative RG35XX games that previously emitted `compound glyph failure; safe ASCII mode enabled`.

No BUILD-PASS or DEVICE-TEST-PASS is claimed by 011M.
