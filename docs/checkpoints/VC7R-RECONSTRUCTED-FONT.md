# VC7R — Reconstructed Unicode Bitmap Font

Status: SOURCE-READY / DEVICE-PENDING

VC7R exists only because the exact Golden resource bytes are no longer available from local backups or accessible historical uploads. It must never be described as Exact Golden unless its generated output independently matches the immutable Golden SHA-256.

## Immutable Golden reference

- resource path: `/org/recompile/mobile/rg35xx-font.bin`
- Golden bytes: `727008`
- Golden SHA-256: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- records: `22719`
- bytes/record: `32`
- raster: 16 rows × 16 bits, big-endian row words
- normal source width: 8
- wide/CJK source width: 12

## What VC7R preserves

VC7R preserves the recovered container and indexing contract so the already-built VC7 renderer can consume the resource without routing normal text through GNU Classpath AWT/OpenType. The Unicode ranges and record order are unchanged.

The generator is `scripts/vc7r_reconstruct_font.py`. It accepts explicit user/system font inputs, rasterizes only into the 8/12 × 16 Golden-compatible source cells, writes exactly 727008 bytes, and emits a JSON provenance manifest with the input font hashes and generated output hash.

If a code point is unavailable in every supplied input font, its record is populated from the supplied `?` glyph. This is intentionally recorded as a fallback count in the manifest.

## Status vocabulary

Use these exact terms:

- `EXACT-GOLDEN`: allowed only when generated/resource SHA-256 equals the immutable Golden hash.
- `RECONSTRUCTED-NOT-GOLDEN`: generated resource has the same structural contract but a different hash.
- `SOURCE-READY`: generator/source has been committed but no production runtime/device acceptance has occurred.
- `DEVICE-PASS`: only after real RG35XX evidence confirms text rendering and no platform regressions.

Do not promote VC7R to VC7 Exact Golden merely because the byte count, range table, or visual appearance is correct.

## Required device acceptance

A VC7R runtime must be tested on RG35XX with at least:

1. lowercase Latin and punctuation;
2. Vietnamese / Latin Extended text;
3. Greek and Cyrillic samples;
4. Japanese kana and CJK samples;
5. real game HUD/menu text;
6. clipping, translation, LEFT/RIGHT/HCENTER and baseline semantics;
7. confirmation that the prior GNU AWT/OpenType failures are absent;
8. confirmation that video receiver/Smart-Fit and lazy media behavior remain unchanged.

Until these pass, status remains `SOURCE-READY / DEVICE-PENDING`.
