# RGJ-RC1-011M — Font Runtime Checkpoint

Status: STATIC-AUDIT-PASS only.

## Added / changed

- Added guarded GNU Classpath `Zone.combineWithSubGlyph` capacity correction.
- Integrated the correction into the disposable runtime assembly immediately after the concrete HeadlessToolkit/OpenTypeFontPeer overlay.
- Updated 011M audit to include historical RG35XX/JamVM evidence for both null FontPeer failure and compound TrueType glyph overflow.

## Historical evidence retained

Previous RG35XX runs showed:

- null peer failures through `Font.getName`, `Font.getStyle`, `Font.getTransform`, and `Font.createGlyphVector`;
- `ArrayIndexOutOfBoundsException` from `Zone.combineWithSubGlyph` while rendering compound glyphs;
- subsequent `RG35XX-FONT: compound glyph failure; safe ASCII mode enabled` fallback.

These failures are the reason RC1 does not accept a FontPeer-only fix and does not restore an ASCII-only renderer.

## Ownership decision

KEEP: `PlatformFont` / `PlatformGraphics` as FreeJ2ME facade owners.
KEEP: GNU Classpath HeadlessToolkit + OpenTypeFontPeer as the Java font backend.
ADD: narrow audited `Zone` capacity correction for compound TrueType glyphs.
SUPERSEDED: historical safe-ASCII / reconstructed `RG35XXFontEngine` approaches.

## Required before promotion

- compile exact Classpath 0.99 disposable assembly;
- deploy exact DejaVu Sans runtime file used by fonts.properties;
- JamVM probes for Font.hashCode, metrics, ASCII, Vietnamese and compound glyph vectors;
- no `safe ASCII mode` fallback in representative game logs.

No BUILD-PASS or DEVICE-TEST-PASS is recorded here.
