# RGJ-RC1-011K — Runtime / Make Assembly Audit

Status: STATIC-AUDIT-PASS. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Scope

011K connects the deterministic 011J FreeJ2ME assembly to two remaining build surfaces without mutating authoritative upstream trees: GNU Classpath 0.99 runtime assembly and the pinned FreeJ2ME libretro Make graph.

## Decisions

- KEEP pinned FreeJ2ME `build.xml` as Java build owner. Upstream builds Java sources with Ant and produces `freej2me-lr.jar`.
- KEEP pinned `src/libretro/Makefile` / `Makefile.common` as native platform/build owner.
- ADD only generated `rg35xx/rc1_make_overlay.mk`; it consumes the exact `rc1_sources.mk` emitted by 011J.
- KEEP `freej2me_libretro.c` as the sole libretro core entrypoint.
- KEEP GNU Classpath `HeadlessToolkit` as font peer integration owner; do not resurrect `RG35XXFontEngine`.
- 0022 remains an assembly contract until a concrete, source-backed non-null ClasspathFontPeer implementation is reconciled into the disposable Classpath tree. 011K deliberately refuses to fabricate a diff or claim it has been applied.

## Native Make contract

The generated overlay adds the ten registered RG35XX native translation units exactly once and adds the registered include paths. `pthread` and `m` are recorded as required target libraries, but host flags are not treated as ARMv5TE/uClibc proof.

The final target Make integration must preserve upstream platform detection/output naming and add the overlay through one include/call-site only. Duplicate `SOURCES_C`, duplicate TML/TSF implementation owners, or a second libretro entrypoint are failures.

## Runtime/font contract

The runtime assembly copies GNU Classpath into a disposable tree. It checks that `HeadlessToolkit` exposes both `getFontPeer` and `getClasspathFontPeer` entry points before any font integration is accepted.

BUILD-READY additionally requires:

1. concrete Classpath 0.99 peer/delegate code with non-null peer for SansSerif/Dialog/Monospaced;
2. authoritative DejaVu Sans 2.37 TTF materialized with recorded SHA-256;
3. deterministic resource mapping visible to the peer;
4. JamVM smoke probes for Font construction/hashCode/glyph vector/metrics.

## Build boundary

Upstream Java and native builds remain separate: Ant owns the Java JAR; Make owns the libretro native library. 011K does not collapse them into a new build system.

## Result

The source/build ownership boundary is now deterministic through runtime and Make overlay generation. Remaining work is physical external-input materialization plus concrete Classpath FontPeer reconciliation, followed by the first real Java/native compiler pass. No build or device pass is claimed.
