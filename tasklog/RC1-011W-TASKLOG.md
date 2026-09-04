# RG35XX Java Platform — RC1 011W Tasklog

This file extends the immutable RC1 engineering record.

## RGJ-RC1-011W — First consolidated build execution with pinned prebuilt uClibc carrier
- Action: ADD / AUDIT
- Status: IMPLEMENTED
- Trigger: RC1-011U/011V prebuilt toolchain probe run `33862107194` completed successfully for the immutable MiyooCFW shared-uClibc image digest.
- Goal: run the existing authoritative assembly/runtime/compile pipeline end-to-end and surface the first real source/compiler/link blocker without adding parallel platform logic.
- Toolchain carrier: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`.
- Execution strategy: pull the exact image, copy `/opt/miyoo` to the Ubuntu 22.04 runner at the same absolute path, then invoke the existing `rc1_assemble.sh`, `rc1_runtime_build_overlay.sh`, and `rc1_compile.sh` owners on the host.
- External inputs:
  - FreeJ2ME exact commit `13ec186903087156c145268f8706eecfaf9f1e50`.
  - GNU Classpath official `classpath-0.99.tar.gz`, SHA-256 `f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8`.
  - DejaVu official `dejavu-sans-ttf-2.37.zip`, SHA-256 `5c6e497a2f36552cb5ffb112c413a6af39c0f3c47653662b90b4fa6499822fd7`; actual extracted `DejaVuSans.ttf` SHA-256 is recorded at run time.
  - GeneralUser-GS exact commit/blob/size already enforced by project prebuild/runtime gates.
- Runtime deployment paths for this first build candidate are explicit and non-disposable: `/mnt/mmc/Java/runtime/DejaVuSans.ttf` and `/mnt/mmc/Java/runtime/GeneralUser-GS.sf2`. Device packaging/validation may later REPLACE these paths; this task does not claim device correctness.
- Acceptance: pipeline must produce `build/freej2me_plus-lr.jar` and ARM `freej2me_plus_libretro.so`, target `nm` must find no unresolved `rg35xx_*` symbols, and workflow artifacts/logs must be reviewed before BUILD-PASS.
- Boundary: a successful toolchain probe is not BUILD-PASS. A failed consolidated run is useful blocker evidence and must not be hidden by fallback compilation or host compilers.
