# RG35XX Java Platform — RC1 011U Tasklog

This file extends the immutable RC1 engineering record. It does not rewrite 011S/011T history.

## RGJ-RC1-011U — Pinned prebuilt uClibc toolchain probe
- Action: REPLACE (execution strategy only; 011S source-build provenance remains historical evidence)
- Status: IMPLEMENTED
- Trigger: project workflow run 33843201574 reached the 180-minute job timeout while executing the exact source-pinned Buildroot SDK build; artifact upload was skipped.
- Problem: rebuilding the entire MiyooCFW Buildroot SDK inside every disposable GitHub-hosted runner is too slow for the current RC1 iteration loop.
- Replacement strategy: use the MiyooCFW-published `toolchain-shared-uclibc` container as a prebuilt SDK carrier and pin it by immutable Docker manifest digest before it is accepted as a build input.
- Provider basis: MiyooCFW documentation explicitly recommends `miyoocfw/toolchain-shared-uclibc` for development; the published image exposes `/opt/miyoo`, cross triple `arm-miyoo-linux-uclibcgnueabi`, and the uClibc SDK tree.
- Candidate image: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`.
- Acceptance probe:
  1. Docker pull must resolve the exact pinned digest; no floating `latest` tag is accepted.
  2. `arm-miyoo-linux-uclibcgnueabi-gcc`, `g++`, `nm`, and `readelf` must exist in `/opt/miyoo/bin`.
  3. GCC/G++ `-dumpmachine` must equal `arm-miyoo-linux-uclibcgnueabi`.
  4. Compile a tiny C probe using `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`.
  5. Target `readelf -h` must report ARM machine type.
  6. Record compiler versions and immutable image digest as workflow evidence.
- Boundary: this probe does not claim BUILD-PASS for FreeJ2ME, GNU Classpath, JamVM, or the RG35XX native core. It only proves the replacement toolchain carrier is usable.
- Rollback: if the digest disappears or fails the target probe, retain 011S source-build as the fallback and investigate another pinned SDK carrier; do not silently switch libc/triple.
