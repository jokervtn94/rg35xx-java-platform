# M1.13 Hybrid Font Layout v1 — Contract

## Baseline
- Parent: M1.12-r4E commit `f4d502325121cfcee5d2555b069f89d0e155fab3`.
- M1.12-r4E experimental Unicode bitmap renderer is preserved as the raster backend.
- Resource classification remains `EXPERIMENTAL_NOT_GOLDEN`.
- Expected reconstructed resource: 727008 bytes, SHA256 `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`.

## Device evidence inherited
- Unicode/Vietnamese raster appears in the Java ARGB frame on real RG35XX.
- Java ARGB live capture and BMP24 screenshot work before SDL presenter.
- JamVM/glibj protected hashes remain unchanged.
- M1.12-r4E is the A baseline for visual comparison; it does not make the resource Golden and does not make the full platform Stable.

## M1.13 primary variable
Layout/geometry only.

Do not change:
- Unicode range-to-glyph mapping.
- 16-row / 32-byte glyph bitmap decoding.
- `rg35xx-font.bin` bytes or classification.
- GameCanvas flush path.
- Java ARGB canonical framebuffer.
- SDL1/fbcon presenter.
- input.
- audio.
- JamVM or glibj.

## Layout model
Miyoo-inspired separation of raster from layout:
1. Bitmap backend owns glyph pixels only.
2. Layout owns advance, string width, ascent, descent, line height, and anchor placement.
3. Never scale glyph raster from FontMetrics. This avoids the historical CK regression.
4. First M1.13 A/B checkpoint must retain the M1.12-r4E bitmap pixels and change only geometry/layout.

## Required test profile
`ASCII_VIETNAMESE_SIZE_ANCHOR_V2`

The device package must automatically produce:
- `RG35XX-MIYOO-M1.13-RESULT.txt`
- `RG35XX-MIYOO-M1.13-LIVE-FRAME.argb`
- `RG35XX-MIYOO-M1.13-LIVE-FRAME.txt`
- `RG35XX-MIYOO-M1.13-SCREENSHOT.bmp`

Test content must cover:
- ASCII baseline.
- Vietnamese uppercase.
- Vietnamese lowercase.
- Vietnamese tone-heavy words.
- SMALL / MEDIUM / LARGE.
- LEFT / HCENTER / RIGHT.
- TOP / BASELINE / BOTTOM.
- punctuation and digits.
- mixed ASCII + Vietnamese on the same line.

## Acceptance
BUILD-PASS requires CI build/package/hash gates only.
DEVICE-PASS requires real RG35XX evidence showing:
- all required strings visible;
- no missing-glyph regression;
- no all-glyph disappearance;
- no clipping caused by anchor/layout changes;
- ASCII remains visible;
- screenshot/live-frame capture succeeds;
- normal exit;
- protected hashes pass.

Full platform remains `STABLE=NO` until separately proven.