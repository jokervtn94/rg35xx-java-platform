# VC7 — Golden Unicode Font Path

Status: `SOURCE-PREFLIGHT-READY / IMPLEMENTATION-PENDING / DEVICE-TEST-PENDING`

## Why VC7 exists

VC6 device evidence advanced past the previously observed PNG ICC-v4 exception, then exposed two failures in GNU Classpath AWT/OpenType text rendering beneath `PlatformGraphics.drawString`/`drawChar`:

- `AbstractGraphics2D.renderScanline` -> `NullPointerException`
- `Zone.combineWithSubGlyph` -> `ArrayIndexOutOfBoundsException` through the TrueType compound-glyph path

B2 `glibj.zip` is immutable, so VC7 does not repair these failures by patching GNU Classpath. It restores the device-proven Golden FreeJ2ME text path instead.

## Immutable Golden resource contract

VC7 accepts exactly one external bitmap resource:

- JAR/resource path: `org/recompile/mobile/rg35xx-font.bin`
- byte length: `727008`
- SHA-256: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- record size: 32 bytes
- glyph records: 22719
- source raster: 16 rows, 16 bits per row, big-endian row word

The binary is deliberately not committed to this repository. `scripts/vc7_extract_golden_font.py` extracts it from a verified Golden runtime and refuses any length/hash mismatch.

## Recovered rendering contract

VC7 source implementation must reproduce the behavior documented in `docs/GOLDEN-G2-FONT-CONTRACT.md`:

- normal/Latin source advance: 8 pixels
- wide/CJK source advance: 12 pixels
- scale 1 when active MIDP/DoJa font height is below 26
- scale 2 otherwise
- supported range table and offsets must remain exact
- unsupported code points use the Golden small `?` fallback
- resource loading must read until all 727008 bytes are obtained, then publish atomically
- every expanded pixel must honor graphics translation, current clip and actual canvas bounds

Recovered Golden owners remain:

`rg35xxAsciiSafeString`, `rg35xxEnsureBitmapFont`, `rg35xxGlyphIndex`, `rg35xxWideChar`, `rg35xxBitmapScale`, `rg35xxBitmapWidth`, `rg35xxDrawFallbackQuestion`, `rg35xxDrawBitmapString`, `rg35xxDrawSafeText`.

## Layering

VC7 starts from a completed VC6 assembly. It must preserve:

- JamVM L unchanged
- GNU Classpath baseline unchanged
- VC6 source-level PNG iCCP compatibility unchanged
- B4 observed native core unchanged
- Golden asynchronous RGB565 transport unchanged
- lazy-media boot unchanged

VC7 must not admit CV/CW, audio rework, Classpath font overlays, compound-glyph Classpath patches, or the later ASCII 5x7 renderer as the normal text path.

## Baseline-aware preflight

`scripts/vc7_golden_font_preflight.sh` verifies both the Golden resource and the exact pinned `PlatformGraphics` text boundary before any font source modification is permitted. The pinned upstream normal path currently resolves anchors/metrics and finishes with `gc.drawString(str, x, y)`. VC7 will replace only that text raster ownership; unrelated Graphics primitives remain untouched.

## Implementation gate before build

The source overlay is not considered ready until the exact anchor/baseline behavior can be reconstructed without inventing missing Golden semantics. Build must then prove:

- Java class major 50
- exact resource path/size/hash in `freej2me_plus-lr.jar`
- all Golden font owner methods present
- normal `PlatformGraphics.drawString`/`drawChar` no longer enter GNU AWT glyph rasterization
- VC6 PNG marker still present
- native core SHA unchanged from the accepted B4-observed core
- no modifications to `glibj.zip`

## Device acceptance

Synthetic metrics alone are not enough. Acceptance requires visual evidence for lowercase, punctuation, Vietnamese/Latin Extended, Greek/Cyrillic, Japanese kana, clipping/translation, LEFT/CENTER/RIGHT anchors, TOP/BOTTOM/BASELINE behavior, and at least two real-game HUD/menu screens.

The current screenshots/logs are therefore treated as the blocker evidence, not as a font-quality acceptance baseline.
