# RG35XX Java Platform — RC1 011T Tasklog

This file continues the immutable RC1 task history. It does not replace `tasklog/TASKLOG.md` or `tasklog/RC1-TASKLOG.md`.

## RGJ-RC1-011T — Source-pinned SDK materialization/verification
- Action: ADD / AUDIT
- Status: IMPLEMENTED
- Scope: materialize the exact SDK archive produced by 011S into a disposable SDK root and expose verified compiler paths for the existing `scripts/rc1_compile.sh` harness.
- Pre-change reload completed: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `scripts/` tree, `scripts/rc1_toolchain_acquire.sh`, and `scripts/rc1_compile.sh`.
- Non-overlap finding: no existing repository script owns SDK archive extraction/relocation/materialization. 011S owns source acquisition/build/provenance only; 011O/011R `rc1_compile.sh` owns platform compilation only.
- Source input contract: accept only the 011S SDK archive plus its 011S provenance manifest; verify provider, pinned Buildroot commit, defconfig Git blob, SDK file name, SHA-256, byte size and target triple before extraction.
- Materialization contract: extract only into an explicit disposable root; run Buildroot SDK `relocate-sdk.sh` when present; locate exactly one `arm-miyoo-linux-uclibcgnueabi-{gcc,g++,nm}` tool set.
- Compiler verification contract: require gcc/g++ `-dumpmachine` to resolve to ARM/uClibc, compile a minimal C object with `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`, and use target `readelf` when present to verify the probe is ARM.
- Output contract: emit `rg35xx_toolchain_env.sh` containing exact `RG35XX_CC`, `RG35XX_CXX`, and `RG35XX_NM` paths consumable by `scripts/rc1_compile.sh`, plus a materialization manifest carrying the verified SDK SHA-256.
- Boundary: 011T does not assemble FreeJ2ME, overlay Classpath, invoke Ant, link the libretro core, or claim BUILD-PASS.
- Acceptance: static shell syntax + exact archive verification + relocation/compiler probe must pass against a real 011S artifact before 011T can be considered materialized on CI/host.
