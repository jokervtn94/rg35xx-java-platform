# RGJ-RC1-011M — Concrete GNU Classpath FontPeer Overlay

Action: MODIFY / ADD ASSEMBLY OVERLAY / AUDIT

Status: STATIC-AUDIT-PASS

## Reload / governance

Before mutation, the RC1 tasklog, authoritative source registry and current Classpath/runtime overlay sources were reloaded. `RG35XXFontEngine` remains SUPERSEDED and was not restored. GNU Classpath remains the single headless font backend owner.

## Exact-source basis

GNU Classpath 0.99 `HeadlessToolkit` contains null-returning `getFontPeer(String,int)` and `getClasspathFontPeer(String,Map)` stubs. GNU Classpath 0.99 `OpenTypeFontPeer` has the required `(String,int,int)` and `(String,Map)` constructors, reads package `fonts.properties`, maps to a filesystem TTF, memory maps the file and creates its `FontDelegate` with `FontFactory`.

The exact 0.99 OpenType constructors catch exceptions and continue after printing, which can leave `fontDelegate` null. This is incompatible with the RC1 fail-closed requirement and historical Font/hash/glyph crash evidence.

## Changes

- Hardened `runtime/classpath/apply_rg35xx_font_overlay.sh`.
- Overlay refuses unexpected/non-0.99 source shapes.
- Deterministic DejaVu Sans mapping is installed for SansSerif/Dialog/Monospaced and four styles.
- HeadlessToolkit now returns cached OpenTypeFontPeer instances; cache identity uses logical family + defensive attribute Map copy/Map equality.
- Both OpenType constructor catch-and-continue paths are changed in the disposable assembly to immediate RuntimeException failure.
- `scripts/rc1_runtime_build_overlay.sh` now preflights Classpath/font input, clones the runtime source, applies the concrete font overlay and verifies its markers before proceeding with native Make overlay structure.
- Added `docs/RC1-CONCRETE-CLASSPATH-FONT-OVERLAY-AUDIT.md`.
- Updated `docs/PLATFORM-SOURCE-REGISTRY.md` minimally to register 011M without changing ownership rules.

## Gate result

Concrete source implementation for the 0022 contract is now present in project-controlled assembly logic. This closes the previous contract-only gap at STATIC source level.

No BUILD-READY, BUILD-PASS or DEVICE-TEST-PASS is claimed. Remaining mandatory validation: build the modified GNU Classpath/JamVM runtime, run Font.hashCode/FontMetrics/createGlyphVector/Vietnamese rendering smoke probes, then compile/link the complete ARMv5TE/uClibc native core with the exact target toolchain.
