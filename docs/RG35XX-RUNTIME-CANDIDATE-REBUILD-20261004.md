# RG35XX Runtime Candidate Rebuild — 2026-10-04

Status: **BUILD_READY / PHYSICAL_TEST_PENDING**.

This is a disposable alternative-runtime track. It does not replace the
accepted JamVM/glibj bytes and does not write `CFW/java`.

## Direction

- Platform base: Aweigit Miyoo/freej2me-miyoomini.
- Runtime candidate: JamVM 2.0.0 plus GNU Classpath 0.99.
- RG35XX adaptation input: the measured original-device ABI, namely ARM EABI5
  soft-float with uClibc.
- FreeJ2ME remains the algorithm/reference source; it is not used to replace
  the Miyoo platform base in this runtime task.

## Reproducible build

The build is defined by:

- `scripts/build-rg35xx-runtime-candidate.sh`
- `.github/workflows/rg35xx-runtime-candidate-rebuild.yml`
- pinned Miyoo toolchain image:
  `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`
- JamVM source SHA-256:
  `297c14d255f8c88534790818e00276ff97542c1d02d47d7f546537d8fa164491`
- GNU Classpath 0.99 source SHA-256:
  `f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8`

The resulting JamVM is hard-gated as ELF32 ARM EABI5 soft-float. The runtime
root is compiled as an app-local path for the probe package:

`/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime`

## Current decision

The local Windows host cannot execute this cross-build because Docker, GNU
make, GCC and the Miyoo cross compiler are not installed. Therefore no binary
is being claimed yet:

```text
BUILD=NOT_TESTED_LOCAL_HOST
PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
CFW_JAVA_MUTATION=NO
```

After the GitHub workflow produces `RG35XX-RUNTIME-CANDIDATE-REBUILD.zip`,
replace only the `runtime/` directory inside the existing runtime-probe
package, run `RG35XX-RUNTIME-CANDIDATE-PROBE.sh` on the original RG35XX, and
collect `/mnt/mmc/RG35XX-RUNTIME-CANDIDATE-EVIDENCE/RUNTIME-PROBE.log`.

Only a log containing `RUNTIME_PROBE_RESULT=PASS` can advance to platform
testing. It still does not promote this runtime to the accepted baseline.
