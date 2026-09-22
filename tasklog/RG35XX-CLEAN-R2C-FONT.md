# RG35XX Clean R2C-FONT — Direct Metric Bitmap Text

Date: 2026-09-22
Base: exact installed R2A runtime
Primary variable: font/text raster only
Status: BUILD-PENDING / DEVICE-PENDING / STABLE=NO

## Trigger

R2A device evidence shows:
- Tan Tay Du Ky 3: hundreds of compound-glyph `ArrayIndexOutOfBoundsException` failures in GNU Classpath.
- NinjaSchool2: repeated `AbstractGraphics2D.renderScanline` NullPointerException.
- KDTT Tam Quoc Chi: compound-glyph failure terminates a game thread.

All stacks converge on:
`PlatformGraphics.drawStringSingleLine -> GNU AWT/OpenType glyph raster`.

## R2C-FONT delta

Preserve all R2A image/video/audio behavior.

Replace only the final normal text raster boundary:
- BEFORE: `gc.drawString(...)` -> GNU Classpath `drawGlyphVector`.
- AFTER: Unicode bitmap resource -> direct `canvasData` pixels.

Layout policy:
- retain upstream MIDP/DoJa `stringWidth`, baseline and anchor calculations;
- per-character advance comes from active font metrics;
- glyph source raster is scaled into active font height/advance;
- translation and clipping are enforced for every output pixel.

## Resource

Recovered structural contract:
- 727008 bytes
- 22719 records
- 32 bytes/record
- Unicode range table matches recovered Golden format.

Exact Golden SHA is unavailable:
`7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`

R2C-FONT uses the deterministic reconstructed resource:
`20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`

Classification:
`RECONSTRUCTED-NOT-GOLDEN`

It must never be described as Exact Golden.

## Scope lock

Unchanged:
- JamVM L
- glibj
- protected B4 core
- R2A direct image normalization
- PNG iCCP
- transparency semantics (still R2A; no R2D transparency patch)
- dynamic view
- frame transport/native RGB565
- Canvas/serviceRepaints
- audio/JavaSound state
- RMS

## Device acceptance

Test text-heavy games first:
1. Tan Tay Du Ky 3
2. NinjaSchool2
3. KDTT Tam Quoc Chi

PASS criteria:
- `RG35XX-R2D-FONT: ready bytes=727008` appears;
- `Zone.combineWithSubGlyph` failures become zero;
- `AbstractGraphics2D.renderScanline` text failures become zero;
- game thread does not terminate at text rendering;
- text remains readable/aligned enough for real gameplay;
- physical RGB565 color/input unchanged;
- no hard reset.

Audio and transparency are expected to remain unchanged in this checkpoint.
