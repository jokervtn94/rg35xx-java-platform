# VC7 — Golden Unicode Font Path

Status: `SOURCE-IMPLEMENTED / JAVA6-SOURCE-GATE-PASS / MATERIALIZATION-KIT-BUILD-PASS / GOLDEN-RESOURCE-INJECTION-PENDING / DEVICE-TEST-PENDING`

## Why VC7 exists

VC6 device evidence advanced past the previously observed PNG ICC-v4 exception, then exposed two failures in GNU Classpath AWT/OpenType text rendering beneath `PlatformGraphics.drawString`/`drawChar`:

- `AbstractGraphics2D.renderScanline` -> `NullPointerException`
- `Zone.combineWithSubGlyph` -> `ArrayIndexOutOfBoundsException` through the TrueType compound-glyph path

B2 `glibj.zip` is immutable, so VC7 does not repair these failures by patching GNU Classpath. It restores the recovered Golden FreeJ2ME Unicode bitmap text path instead.

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

The VC7 source implementation reproduces the behavior documented in `docs/GOLDEN-G2-FONT-CONTRACT.md`:

- normal/Latin source advance: 8 pixels
- wide/CJK source advance: 12 pixels
- scale 1 when active MIDP/DoJa font height is below 26
- scale 2 otherwise
- supported range table and offsets remain exact
- unsupported code points use the recovered small `?` fallback
- resource loading reads until all 727008 bytes are obtained, then publishes atomically
- every expanded pixel honors graphics translation, current clip and actual canvas bounds

Recovered Golden owners retained by the overlay:

`rg35xxAsciiSafeString`, `rg35xxEnsureBitmapFont`, `rg35xxGlyphIndex`, `rg35xxWideChar`, `rg35xxBitmapScale`, `rg35xxBitmapWidth`, `rg35xxDrawFallbackQuestion`, `rg35xxDrawBitmapString`, `rg35xxDrawSafeText`.

The implementation is a source reconstruction from the recovered contract and pinned upstream semantics. It is not claimed to be byte-for-byte identical to the historic Golden `PlatformGraphics.class`.

## Layering

VC7 starts from a completed VC6 assembly. It preserves:

- JamVM L unchanged
- GNU Classpath baseline unchanged
- VC6 source-level PNG iCCP compatibility unchanged
- accepted VC6 native core unchanged on device
- Golden asynchronous RGB565 transport unchanged
- lazy-media boot unchanged

VC7 does not admit CV/CW, audio rework, Classpath font overlays, compound-glyph Classpath patches, or the later ASCII 5x7 renderer as the normal text path.

## Source gate result

Workflow `Verified Clean VC7 Font Source Gate` run `34329657410` completed successfully at commit `f4c30d2eb5eee69032cf2a1a35aa275f41da0ab2`.

The source gate proves:

- VC6 foundation assembly succeeds
- pinned upstream text boundary is still the expected one before overlay
- VC7 font overlay applies cleanly
- Java 6 runtime compiles successfully
- compiled classes remain class major 50
- normal text raster ownership is changed to the Golden bitmap path
- GNU AWT glyph raster is bypassed for the replaced normal path
- source-gate template deliberately does not contain `rg35xx-font.bin`
- strict scope gate passes

This is not yet a production runtime acceptance because the exact Golden resource must still be injected locally and verified.

## Materialization kit result

The same successful run published artifact:

- name: `rg35xx-vc7-golden-font-materialization-kit`
- artifact id: `10095212595`
- artifact digest: `sha256:37ecfa964c259c84c7b146dba051f7831bc663f857db4d0f5d72b195c22daca3`

The kit contains the source-gated runtime template and fail-closed materialization tooling. The template intentionally excludes the Golden font binary.

The current template SHA-256 used by the local installer is:

`7aacea52397a084e9bef249541e6f60a263b3773ebe35148e0b66481e23d8b1f`

## Local materialization and recovery paths

Two fail-closed Windows paths now exist:

- `scripts/installer/vc7_materialize_and_install.ps1`: requires an exact Golden runtime input and injects the verified resource.
- `scripts/installer/vc7_auto_recover_and_install.ps1`: searches the installer directory and the complete mounted SD card, including historical backup directories, for any JAR carrying the exact Golden font resource. It accepts the resource only when both byte length and SHA-256 match exactly.

The auto-recovery path verifies the accepted VC6/JamVM/ClassPath foundation before any SD modification, backs up all five runtime aliases before replacement, changes runtime aliases only, and leaves core/JamVM/glibj untouched. If the exact Golden resource is not found, it records `RESULT=NO-GOLDEN-FONT-FOUND` and does not replace the runtime aliases.

## Production materialization gate

A materialized VC7 runtime can advance only after proving:

- exact embedded resource path `org/recompile/mobile/rg35xx-font.bin`
- exact embedded resource byte length `727008`
- exact embedded resource SHA-256 `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- all five installed runtime aliases have the same final materialized runtime SHA-256
- JamVM L remains `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath remains `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- accepted VC6 core remains `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`

Whole-JAR SHA of the final materialized runtime is not compared to the historic Golden runtime because the VC7 classes and ZIP metadata differ. The exact embedded resource identity is the Golden-resource gate.

## Device acceptance

Synthetic metrics alone are not enough. Acceptance requires visual/log evidence for lowercase, punctuation, Vietnamese/Latin Extended, Greek/Cyrillic, Japanese kana, clipping/translation, LEFT/CENTER/RIGHT anchors, TOP/BOTTOM/BASELINE behavior, and real-game HUD/menu screens.

At minimum, the device acceptance pass must verify that text-heavy games no longer emit either current P0 failure:

- `AbstractGraphics2D.renderScanline` `NullPointerException`
- `Zone.combineWithSubGlyph` `ArrayIndexOutOfBoundsException`

It must also verify visible Unicode text, no frame-transport regression, no lazy-media boot regression, and no new PNG compatibility regression.

Current classification remains `DEVICE-TEST-PENDING` until that evidence is captured.
