# RGJ-RC1-011D — Headless Font Ownership Replacement

Status: STATIC-AUDIT-PASS. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: REPLACE / AUDIT / DEFINE-INTEGRATION-CONTRACT.

Source basis:
- FreeJ2ME-Plus pin: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.
- GNU Classpath target observed on RG35XX: JamVM 2.0.0 + GNU Classpath 0.99 headless AWT.
- Historical RG35XX logs and source excerpts supplied during device debugging.

Mandatory reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current RG35XX source tree, pinned upstream `PlatformFont`, and historical GNU Classpath/font failure evidence.

## Replacement decision

Registered historical responsibility `org.recompile.mobile.RG35XXFontEngine` is MISSING and no authoritative source was recovered from repository history or supplied source artifacts. RC1 will NOT recreate that class from memory.

The old missing-class responsibility is explicitly SUPERSEDED by a lower-level headless-font integration contract:

1. `org.recompile.mobile.PlatformFont` remains the FreeJ2ME LCDUI/DoJa font facade and metrics owner.
2. `gnu.java.awt.peer.headless.HeadlessToolkit` / GNU Classpath FontPeer path becomes the target font backend owner.
3. `PlatformGraphics` remains the text drawing consumer; it must not carry a second font engine or silently sanitize all non-ASCII text.
4. No second `RG35XXFontEngine` class is added.

## Root-cause evidence

Historical device failures repeatedly reached `java.awt.Font.hashCode()`, `Font.createGlyphVector()` and `AbstractGraphics2D.drawString()` with an unusable/null peer. Supplied GNU Classpath 0.99 source shows `HeadlessToolkit.getFontPeer(...)` returning null while `java.awt.Font` delegates name/style/layout/glyph operations to its peer. Earlier safe-ASCII/bitmap fallbacks avoided the crash but produced known missing/incorrect glyphs.

A later runtime banner advertised `font=Unicode8x12`, proving a non-AWT fallback existed historically, but its source/resource was not recovered. Runtime banners are compatibility evidence only and are not sufficient to reconstruct the lost implementation.

## RC1 contract

`patches/0022-pinned-headless-font-peer-consolidation.patch` defines the only accepted replacement direction: repair/provide a real GNU Classpath headless FontPeer with deterministic font-resource ownership, then let existing PlatformFont/PlatformGraphics use it. The patch must fail closed if the font resource/delegate cannot be initialized; it must not leave a non-null Font object with a null delegate/peer.

The final backend must support at minimum Latin-1 plus Vietnamese precomposed characters used by the target corpus, preserve LCDUI width/height consistency, and avoid per-frame font file I/O.

## Rollback

If the real FontPeer path cannot be made stable on JamVM/GNU Classpath, a future task may introduce a project-owned bitmap renderer only after an authoritative glyph resource/source and metrics contract are provided. That future task must be an explicit REPLACE and must not resurrect the missing historical class from memory.

Gate result: STATIC-AUDIT-PASS for ownership/root-cause/replacement direction only.