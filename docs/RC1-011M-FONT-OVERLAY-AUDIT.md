# RGJ-RC1-011M — Concrete GNU Classpath FontPeer Overlay Audit

Status: STATIC-AUDIT-PASS. This is not BUILD-PASS or DEVICE-TEST-PASS.

## Verified upstream API

The inspected GNU Classpath source exposes `OpenTypeFontPeer(String,int,int)` and `OpenTypeFontPeer(String,Map)`. Both constructors resolve a logical font through `fonts.properties`, then open the mapped value using `new File(filename)` and build the delegate with `FontFactory.createFonts(buffer)[0]`.

The inspected `HeadlessToolkit` baseline imports `ClasspathFontPeer`, `Font`, `FontPeer`, and `Map`; both `getFontPeer(String,int)` and `getClasspathFontPeer(String,Map)` are null stubs.

## 011M correction

The first overlay draft was not accepted as final because it could duplicate existing imports and used a resource-looking relative TTF path even though `OpenTypeFontPeer` treats the mapping as a filesystem filename.

The hardened overlay now:

1. adds only missing imports;
2. rewrites only the two guarded null font-peer stubs;
3. calls the verified two-argument `OpenTypeFontPeer(String,Map)` constructor;
4. caches peers in `HeadlessToolkit`;
5. maps SansSerif/Dialog/Monospaced deterministically;
6. materializes DejaVuSans.ttf under the disposable Classpath assembly tree;
7. writes the absolute materialized TTF filename into `gnu/java/awt/font/fonts.properties`;
8. fails if required Classpath source structure or constructor signatures differ;
9. explicitly checks that core imports were not duplicated.

## Remaining runtime risk

`OpenTypeFontPeer` catches constructor exceptions internally and may leave `fontDelegate` unusable. Therefore static construction alone cannot prove delegate validity. Acceptance still requires compiling the exact Classpath 0.99 assembly and running JamVM probes covering `Font.hashCode`, `createGlyphVector`, FontMetrics/string width and representative Vietnamese text.

## Decision

011M closes the concrete source-overlay design/API audit. It does not close compiler/runtime validation. BUILD-READY remains blocked until external inputs are physically materialized and the complete prebuild/assembly gates pass.
