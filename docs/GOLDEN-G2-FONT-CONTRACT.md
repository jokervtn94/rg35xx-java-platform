# Golden G2 Font Contract

This document records the font behavior recovered directly from the device-proven
`freej2me-lr.jar` supplied by the RG35XX project owner. G2 must reproduce this
behavior from clean source; the later 5x7 ASCII fallback is not the source of truth.

## Immutable resource

- classpath path: `/org/recompile/mobile/rg35xx-font.bin`
- exact byte length: `727008`
- SHA-256: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- glyph record: `32` bytes
- total glyph records: `22719`
- record raster: 16 rows, 16 bits per row, big-endian row word

The repository does not embed the binary resource. A G2 assembly must receive it
from a verified Golden input and reject any resource whose length/hash differs.

## Glyph geometry

Recovered constants/behavior:

- raster height: 16 source rows
- normal/Latin advance: 8 source pixels
- wide/CJK advance: 12 source pixels
- scale = 1 when active MIDP/DoJa font height < 26
- scale = 2 when active font height >= 26
- rendered advance = source advance * scale

Wide-character predicate is true for:

- U+3000..U+30FF
- U+4E00..U+9FFF
- U+FF00..U+FFEF

All other supported ranges use the 8-pixel advance.

## Unicode range table

`rg35xxGlyphIndex(char)` scans these exact ranges and returns
`offset[i] + codePoint - start[i]`. Unsupported characters return glyph index 31.

| # | start | end | offset |
|---|---:|---:|---:|
| 0 | U+0020 | U+007E | 0 |
| 1 | U+00A0 | U+024F | 95 |
| 2 | U+0370 | U+03FF | 527 |
| 3 | U+0400 | U+052F | 671 |
| 4 | U+1E00 | U+1EFF | 975 |
| 5 | U+3000 | U+303F | 1231 |
| 6 | U+3040 | U+309F | 1295 |
| 7 | U+30A0 | U+30FF | 1391 |
| 8 | U+4E00 | U+9FFF | 1487 |
| 9 | U+FF00 | U+FFEF | 22479 |

The final range yields the last record at index 22718, so 22719 * 32 = 727008.

## Resource loading

Golden `PlatformGraphics.rg35xxEnsureBitmapFont()`:

1. runs once through `rg35xxFontLoadTried`;
2. loads the exact classpath resource with `PlatformGraphics.class.getResourceAsStream`;
3. allocates exactly 727008 bytes;
4. repeatedly reads until full or EOF (not a one-shot `read` assumption);
5. installs the data only after the entire expected resource has been read;
6. closes the stream on every exit path;
7. logs missing, short-read, ready and exception states to stderr.

## Raster drawing

For every character:

1. choose source width 8 or 12;
2. resolve glyph index;
3. byte offset = glyphIndex * 32;
4. for each source row 0..15, read a big-endian 16-bit mask;
5. test bits from bit 15 downward for each source column;
6. expand each set source pixel to `scale x scale` pixels;
7. write opaque `0xFF000000 | color` directly into `canvasData` only inside the
   translated current clip and actual canvas bounds;
8. advance pen by source width * scale.

The direct `canvasData` ownership here is part of the Golden font renderer and is
not equivalent to the later buggy direct-write experiments: it explicitly enforces
translation, clip and canvas boundaries for every expanded pixel.

If the resource is absent or an index is impossible, the Golden renderer draws a
small built-in `?` fallback rather than using the later 5x7 whole-font path.

## Normal text path

Recovered owners in `PlatformGraphics`:

- `rg35xxAsciiSafeString(String)`
- `rg35xxEnsureBitmapFont()`
- `rg35xxGlyphIndex(char)`
- `rg35xxWideChar(char)`
- `rg35xxBitmapScale()`
- `rg35xxBitmapWidth(String,int)`
- `rg35xxDrawFallbackQuestion(...)`
- `rg35xxDrawBitmapString(...)`
- `rg35xxDrawSafeText(...)`

G2 acceptance requires lowercase, punctuation, Vietnamese/Latin Extended samples,
Greek/Cyrillic samples, Japanese kana and a real-game HUD/menu to preserve clipping,
anchors and spacing. A synthetic PASS alone is insufficient.
