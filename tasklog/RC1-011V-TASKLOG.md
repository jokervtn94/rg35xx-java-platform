# RG35XX Java Platform — RC1 011V Tasklog

This file extends the immutable RC1 engineering record. It does not rewrite 011S/011T/011U history.

## RGJ-RC1-011V — Accept pinned prebuilt uClibc toolchain for first consolidated build
- Action: REPLACE (authoritative first-build toolchain input)
- Status: STATIC-AUDIT-PASS
- Evidence run: GitHub Actions run `33862107194`, job `100988662343`, conclusion `success`.
- Evidence artifact: `rg35xx-prebuilt-uclibc-toolchain-probe`, artifact id `9932521250`.
- Provider: `MiyooCFW/toolchain-shared-uclibc`.
- Immutable image: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`.
- Verified target triple: `arm-miyoo-linux-uclibcgnueabi`.
- Verified compilers: GCC/G++ `(Buildroot -g8087b523) 9.4.0`.
- Probe flags: `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`.
- Probe result: ELF32, little-endian, Machine ARM, EABI5, soft-float ABI.
- Probe SHA-256: `80d5e4a2e0f824a535a03ac4910d61db43ff3e9a4bbf02edc5dfd08c5e6af138`.
- Decision: use this digest-pinned prebuilt carrier for the first consolidated compile/link instead of rebuilding the entire Buildroot SDK on every disposable runner.
- Historical 011S source pin remains provenance/fallback evidence. The failed 180-minute source-build execution is not BUILD-PASS and is not retried by default.
- Acceptance boundary: this closes only the toolchain-carrier gate. FreeJ2ME/Classpath/native BUILD-PASS still requires `rc1_assemble.sh`, runtime overlay, `rc1_compile.sh`, link review, and postbuild audit.
- Rollback: if the pinned digest becomes unavailable or fails any future target probe, fall back to the 011S source-pinned Buildroot route or another immutable uClibc carrier; never silently switch to musl or a different target triple.
