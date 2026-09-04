# RGJ-RC1-011O — First Build Harness / Native Make Integration Audit

Status: **STATIC-AUDIT-PASS**

This stage closes the build-graph wiring gap between the already-audited RC1 source modules and the first real consolidated Java + ARMv5TE/uClibc compile. It does **not** claim BUILD-PASS or DEVICE-TEST-PASS.

## Mandatory reload / non-overlap check

Before mutation, the authoritative task history, RC1 tasklog, source registry, current `rc1_assemble.sh`, `rc1_runtime_build_overlay.sh`, GNU Classpath font overlay, and pinned FreeJ2ME Makefiles were re-read. No new runtime subsystem/class/package was added. This stage modifies only build/assembly ownership.

## Pinned upstream Make ownership

At FreeJ2ME pin `13ec186903087156c145268f8706eecfaf9f1e50`:

- `src/libretro/Makefile` includes `Makefile.common` **before** calculating `OBJECTS`.
- `Makefile.common` owns `SOURCES_C += freej2me_libretro.c` and `INCLUDES += -Ideps/libretro-common/include`.
- Therefore the correct integration point is one guarded include of `rg35xx/rc1_make_overlay.mk` from the disposable assembled `Makefile.common`.
- No second Makefile, link command, libretro entrypoint, or parallel object list is allowed.

## Corrections found during 011O

1. The earlier generated overlay wrote RG35XX include flags to `INCFLAGS`, but pinned upstream consumes `INCLUDES`. That would allow source assembly to pass while native compilation could fail to find `rg35xx`/TML/TSF headers. 011O changes the generated overlay to `INCLUDES += $(RG35XX_NATIVE_CFLAGS)`.
2. The earlier runtime overlay generated `rc1_make_overlay.mk` but did not actually include it from pinned `Makefile.common`. 011O now verifies the exact baseline and appends one include in the **disposable** source tree before `OBJECTS` are calculated.
3. pthread was documented but not linked. 011O adds `-pthread` to C, C++, and link flags through the single Make overlay. `-lm` remains owned by upstream Makefile `LIBM`.
4. The first compile harness initially checked the wrong Java artifact name. Pinned `build.xml` emits `build/freej2me_plus-lr.jar`; 011O now checks that exact artifact.

## Deterministic compile harness

`scripts/rc1_compile.sh` now defines the first-build procedure:

- requires the disposable assembled FreeJ2ME tree and completed runtime overlay;
- requires explicit ARM/uClibc `RG35XX_CC` and `RG35XX_CXX` executables;
- checks compiler target triplets instead of accepting a host compiler;
- performs a clean Ant build;
- performs a clean native libretro build with `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`;
- verifies `freej2me_plus-lr.jar` and `freej2me_plus_libretro.so` exist;
- requires a target `nm` and rejects unresolved `rg35xx_*` symbols;
- never upgrades a successful compile to DEVICE-TEST-PASS.

## Build graph invariants after 011O

- one `freej2me_libretro.c` owner;
- ten project RG35XX `.c` translation units, each listed once;
- one TML/TSF implementation translation unit;
- upstream Makefile/Makefile.common remain build owners;
- RG35XX overlay is included exactly once;
- no host architecture fallback is accepted by the compile harness;
- runtime font deployment remains separated from disposable Classpath source assembly.

## Remaining gates

011O is source/build-harness closure only. Before `BUILD-PASS`, the complete pinned dependencies/assets must be materialized and the harness must run successfully with compiler/link output reviewed. GNU Classpath/JamVM font smoke validation remains a separate runtime gate, and actual RG35XX execution remains DEVICE-TEST only.
