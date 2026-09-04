# RGJ-RC1-011P — Compiler Invocation Reconciliation + Postbuild Artifact Gate

Status: STATIC-AUDIT-PASS. Not BUILD-PASS. Not DEVICE-TEST-PASS.

## Why this stage exists

The first-build harness from 011O passed static ownership review, but one invocation detail was still unsafe: passing `CFLAGS=` / `CXXFLAGS=` on the GNU make command line can override ordinary makefile variable assignments. The pinned FreeJ2ME libretro Makefile appends critical flags after including Makefile.common: optimization/debug selection, `-Wall`, `-D__LIBRETRO__`, `$(INCLUDES)` and `$(fpic)`. RC1 must not risk deleting those flags merely to inject ARMv5TE CPU options.

Historical RG35XX build work also used the target flags as part of the compiler command (`arm-miyoo-linux-uclibcgnueabi-gcc -marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft ...`), which preserves upstream make-owned CFLAGS. 011P restores that ownership model deliberately.

## Implemented changes

`scripts/rc1_compile.sh` now:

- verifies the target compiler and C++ compiler triplets;
- guards the pinned Makefile shape before compilation;
- carries `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft` in `CC` / `CXX` commands instead of command-line `CFLAGS` / `CXXFLAGS`;
- unsets host/user `CFLAGS`, `CXXFLAGS`, `LDFLAGS` and `CPPFLAGS` immediately before native make;
- leaves `-O3`, `-Wall`, `-D__LIBRETRO__`, include expansion and PIC ownership to the pinned upstream Makefile;
- retains `pthread` ownership in the single generated RC1 make overlay;
- still requires target `nm` to reject unresolved `rg35xx_*` symbols.

`scripts/rc1_postbuild_audit.sh` adds a second, independent artifact gate after a successful compile:

- confirms Java JAR and native core exist;
- confirms the core is ARM when host `file` is available;
- rejects unresolved project-owned `rg35xx_*` symbols;
- rejects `Tag_ABI_VFP_args: VFP registers` hard-float output;
- rejects glibc `libc.so.6` / `ld-linux` dependencies in the RG35XX/uClibc artifact;
- checks the consolidated JAR contains the registered RG35XX platform classes;
- fails if superseded `RG35XXFontEngine.class` is reintroduced;
- validates the deterministic font deployment manifest has one absolute target and SHA-256.

## Tasklog reconciliation

`tasklog/CLASS-REGISTRY.md` previously still marked `RG35XXFontEngine` as PLANNED from Beta 2. This contradicted 011D/011M. 011P changes that entry to `SUPERSEDED / DO NOT RESTORE`, explicitly keeping GNU Classpath HeadlessToolkit -> ClasspathFontPeer/OpenTypeFontPeer + DejaVu Sans as the RC1 font owner.

## Acceptance boundary

011P closes compiler-invocation ownership and postbuild artifact auditing only. A real `BUILD-PASS` still requires the materialized pinned inputs, successful `rc1_assemble.sh`, runtime overlay, Ant build, ARMv5TE/uClibc make build and a passing `rc1_postbuild_audit.sh` against the same assembled tree. Hardware execution is a separate DEVICE-TEST gate.
