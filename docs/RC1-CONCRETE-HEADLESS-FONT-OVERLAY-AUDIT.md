# RGJ-RC1-011M — Concrete HeadlessToolkit FontPeer Overlay Audit

Status: STATIC-AUDIT-PASS (corrected API contract); NOT BUILD-READY / NOT BUILD-PASS / NOT DEVICE-TEST-PASS.

## Finding that changed the implementation

Direct inspection of GNU Classpath `gnu.java.awt.font.OpenTypeFontPeer` shows the available constructors are `OpenTypeFontPeer(String,int,int)` and `OpenTypeFontPeer(String,Map)`. The first 011M overlay draft incorrectly assumed a `(String,Map,File)` constructor. That draft was therefore not compile-valid and has been replaced before any BUILD-PASS claim.

`OpenTypeFontPeer` itself owns filename resolution through package resource `fonts.properties`, then opens/maps the selected file and creates the `FontDelegate` via `FontFactory.createFonts(...)`.

## Corrected RC1 ownership

- `HeadlessToolkit`: logical font peer factory/cache only.
- `OpenTypeFontPeer`: existing GNU Classpath OpenType peer and delegate owner.
- `fonts.properties`: existing GNU Classpath mapping mechanism; RC1 overlay rewrites the single authoritative resource in the disposable assembly tree.
- `resource/rg35xx/DejaVuSans.ttf`: deterministic pinned runtime font bytes.
- `PlatformFont` / `PlatformGraphics`: unchanged FreeJ2ME facade/consumer owners.
- `RG35XXFontEngine`: remains SUPERSEDED and must not return.

## Corrected overlay behavior

`runtime/classpath/apply_rg35xx_font_overlay.sh` now:

1. verifies both real OpenTypeFontPeer constructors and the existing `mapFontToFilename`/`fonts.properties` contract;
2. requires exactly one existing `gnu/java/awt/font/fonts.properties` in the Classpath tree;
3. copies the materialized DejaVuSans.ttf to deterministic `resource/rg35xx/DejaVuSans.ttf`;
4. maps SansSerif, Dialog and Monospaced style variants to that one RC1 font resource;
5. patches only the known null-returning HeadlessToolkit baseline;
6. constructs peers with the real `new OpenTypeFontPeer(logical, attrs)` API;
7. caches peers and rejects the obsolete nonexistent three-argument constructor pattern.

## Remaining runtime gate

OpenTypeFontPeer catches internal initialization exceptions and can therefore exist with an unusable/null delegate. Static constructor correctness is not sufficient. The first real Classpath/JamVM build must exercise Font.hashCode, metrics and glyph-vector creation (including Vietnamese text) and treat any delegate/glyph failure as a build/runtime gate failure.

## Result

011M concrete source ownership and constructor/mapping contract: STATIC-AUDIT-PASS after correction. Physical Classpath/font materialization and compiler/JamVM smoke execution remain required before BUILD-READY/BUILD-PASS.
