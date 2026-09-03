# RC1 Headless Font / GNU Classpath Audit

Status: STATIC-AUDIT-PASS for source ownership and root cause. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Scope

This audit reconciles the FreeJ2ME pinned font facade with the actual RG35XX JamVM/GNU Classpath 0.99 runtime that produced the historical font failures.

Pinned FreeJ2ME source: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.

## Proven call chain

`javax.microedition.lcdui.Font` -> `org.recompile.mobile.PlatformFont` -> `java.awt.Font` / `FontMetrics` -> GNU Classpath headless AWT -> `AbstractGraphics2D.drawString()` / glyph vector path.

Pinned `PlatformFont` constructs `java.awt.Font`, installs it into an AWT Graphics object and asks that graphics context for FontMetrics. It therefore requires a functional AWT Font peer even though the target is headless.

## Historical failure evidence

The supplied RG35XX logs contain repeated failures in:
- `java.awt.Font.getName/getStyle/getTransform/hashCode`
- `java.awt.Font.createGlyphVector`
- `gnu.java.awt.java2d.AbstractGraphics2D.drawString`

The supplied GNU Classpath 0.99 source excerpt shows `gnu.java.awt.peer.headless.HeadlessToolkit.getFontPeer(String,int)` returning null. The supplied `java.awt.Font` source shows constructors and most semantic methods dereferencing the peer. This is sufficient to identify null/unusable FontPeer ownership as a root cause, not a FreeJ2ME LCDUI metrics bug.

The historical progression `safe-ascii` -> `bitmap-fallback` -> `Unicode8x12` proves that previous target builds worked around the AWT failure in PlatformGraphics. Those workarounds are not authoritative source because their implementation/resource was not recovered; they also left explicit `compound glyph failure; safe ASCII mode enabled` diagnostics in several games.

## Existing GNU Classpath path

Supplied GNU Classpath source shows `gnu.java.awt.font.OpenTypeFontPeer` as an existing pure-Java TrueType/OpenType peer. It loads a mapped font file, creates a `FontDelegate` through `FontFactory.createFonts(ByteBuffer)`, then provides glyph vectors/metrics through that delegate.

This means RC1 does not need to invent a parallel font API. The correct integration layer is the headless Toolkit/FontPeer path plus deterministic font resource mapping.

## RC1 decisions

1. Keep FreeJ2ME `PlatformFont` as the LCDUI/DoJa facade and font-size policy owner.
2. Keep FreeJ2ME `PlatformGraphics` as the text drawing consumer.
3. Supersede the missing `RG35XXFontEngine` class responsibility; do not recreate it from memory.
4. Repair/provide one GNU Classpath headless FontPeer path, preferably reusing `OpenTypeFontPeer`/`FontDelegate` rather than a second raster stack.
5. Bundle or otherwise provide one authoritative font resource at install/runtime assembly time; no repeated directory scanning/file load in frame rendering.
6. Fail closed during initialization if the delegate/resource cannot be created. Do not leave a Font object whose peer/delegate will NPE later in `hashCode()` or glyph layout.
7. Do not globally replace unsupported Unicode with ASCII. Missing-glyph behavior must remain visible/deterministic and must not corrupt string width accounting.

## Required acceptance before BUILD-PASS

- HeadlessToolkit returns a non-null peer for SansSerif, Dialog and Monospaced logical fonts used by PlatformFont.
- Peer creation for the configured target font produces a non-null FontDelegate.
- `new java.awt.Font(...).hashCode()` and `createGlyphVector()` do not throw on the target classpath build.
- FontMetrics width/height/ascent/descent remain stable for repeated calls.
- Vietnamese precomposed characters used by the test corpus are displayable or deterministically fall back to a defined missing glyph without ASCII substitution.
- No font file open/mmap/load occurs per drawString call.
- Metal Slug, Lưu Tinh Hồ Điệp, Magic Sushi and NinjaSchool are retained as font regression cases because historical logs exposed the failure there.

## Remaining implementation gate

The project repository does not currently own the GNU Classpath 0.99 source tree or an authoritative font asset. Therefore this audit closes architecture/root-cause ownership only. `patches/0022-pinned-headless-font-peer-consolidation.patch` is the assembly contract that must be applied when the classpath source/resource is added to the reproducible build input.