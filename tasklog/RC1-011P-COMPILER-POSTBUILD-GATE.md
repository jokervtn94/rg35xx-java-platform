# RGJ-RC1-011P — Compiler Invocation + Postbuild Gate

- Action: MODIFY / ADD BUILD HARNESS / RECONCILE REGISTRY
- Status: STATIC-AUDIT-PASS
- Files:
  - `scripts/rc1_compile.sh`
  - `scripts/rc1_postbuild_audit.sh`
  - `tasklog/CLASS-REGISTRY.md`
  - `docs/RC1-011P-COMPILER-INVOKE-POSTBUILD-AUDIT.md`

## Changes

- Reloaded RC1 task history and discovered 011N/011O were already present; did not duplicate those stages.
- Audited the exact pinned FreeJ2ME libretro Makefile before changing compiler invocation.
- Removed command-line `CFLAGS` / `CXXFLAGS` injection from the first-build harness so GNU make cannot suppress upstream-owned `-O3`, `-Wall`, `-D__LIBRETRO__`, include and PIC flags.
- Moved ARMv5TE/ARM926EJ-S/soft-float options into the target `CC` / `CXX` commands.
- Explicitly removes host/user flag leakage before native make.
- Added independent postbuild audit for ARM identity, hard-float rejection, glibc rejection, unresolved `rg35xx_*` symbols, Java owner presence and runtime-font manifest integrity.
- Reconciled stale Class Registry entry: `RG35XXFontEngine` is `SUPERSEDED / DO NOT RESTORE`, matching 011D/011M.

## Evidence basis

Historical device/build work used compiler-command target flags rather than replacing upstream CFLAGS. Historical font traces prove null FontPeer and compound-glyph failures were runtime causes; RC1 therefore must also prevent the old `RG35XXFontEngine`/safe-ASCII path from returning accidentally.

## Gate

STATIC-AUDIT-PASS only. No BUILD-PASS until the complete assembled tree compiles successfully and `rc1_postbuild_audit.sh` passes on those exact artifacts. No DEVICE-TEST-PASS until hardware validation.

Primary commits:
- compile harness correction: `2e270fdc5663330e8f9cd9941960dcc697179c80`
- class registry reconciliation: `80300d24e4e44d08b41d99da83da29383ba5d5b6`
- postbuild audit: `f6cc979d282e19d1ca842aafec8e43fde81a4d24`
- audit document: `781c803a7025fa86de1c3e36fd88845f061e9a08`
