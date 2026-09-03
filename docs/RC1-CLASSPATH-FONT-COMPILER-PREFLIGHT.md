# RC1 — GNU Classpath Font / Compiler Preflight

Task: RGJ-RC1-011L
Status: STATIC-AUDIT-PASS / BUILD-READY NOT CLAIMED

## Authoritative source basis

GNU Classpath 0.99 is the target runtime library release. Official GNU release announcement identifies `classpath-0.99.tar.gz` with SHA-256 `f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8`.

The existing Classpath font stack contains `FontDelegate`, `FontFactory`, `GNUGlyphVector`, and `OpenTypeFontPeer`; RC1 therefore keeps that stack as the implementation owner instead of restoring `RG35XXFontEngine`.

## Concrete 011L gate

`scripts/rc1_classpath_preflight.sh` requires:

- extracted GNU Classpath source with `HeadlessToolkit.java`;
- existing `OpenTypeFontPeer`, `FontDelegate`, and `FontFactory` sources;
- both FontPeer entry concepts visible in HeadlessToolkit;
- a non-empty materialized `DejaVuSans.ttf`;
- SHA-256 recorded from the actual materialized TTF.

The project deliberately does not hard-code a guessed TTF digest. The exact binary identity must come from the actual DejaVu 2.37 artifact/build selected during reproducible assembly.

## 0022 status

`0022-pinned-headless-font-peer-consolidation.patch` remains a contract, not an executable historical patch. It may not be marked APPLIED until the exact Classpath 0.99 HeadlessToolkit implementation is inspected and a concrete non-null peer/cache implementation is reconciled against it.

## Compiler boundary

011L does not fake ARMv5TE/uClibc compiler evidence. Native compiler/link validation remains a real-toolchain gate. Java/ClassPath runtime validation requires JamVM smoke probes for `Font.hashCode`, `createGlyphVector`, metrics, logical-font mapping and Vietnamese glyph behavior.

## Result

The source/provenance/preflight contract is closed. Runtime FontPeer implementation and real compiler execution remain open and must be completed before BUILD-PASS.
