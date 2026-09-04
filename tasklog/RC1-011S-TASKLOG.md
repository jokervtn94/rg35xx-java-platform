# RG35XX Java Platform — RGJ-RC1-011S Toolchain Source Pin

This file is an immutable continuation record for the RC1 task history. It does not replace `tasklog/RC1-TASKLOG.md`.

## RGJ-RC1-011S — ARM/uClibc SDK source acquisition
- Action: ADD / AUDIT
- Status: IMPLEMENTED
- Pre-change reload: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current build scripts and repository search completed before mutation.
- Non-overlap result: no existing project script owns ARM/uClibc SDK source acquisition; `scripts/rc1_compile.sh` remains the sole compile harness and only consumes already-materialized compiler executables.
- Authoritative source provider: `MiyooCFW/buildroot` pinned at commit `8087b52311da5c1e2fa1c50b0b064c07fd174a36`.
- Authoritative configuration: `configs/miyoo_uclibc_defconfig`, Git blob `58256d3e7afa3f9fa0dbd79b16fd0b21d93b9d7b` at that commit.
- Verified config properties: ARM target, Buildroot vendor `miyoo`, GCC 9.x, C++ enabled, target optimization `-mcpu=arm926ej-s -marm`.
- Acquisition owner: `scripts/rc1_toolchain_acquire.sh` fetches only the exact pinned commit, verifies the defconfig blob, builds `make sdk`, verifies the expected `arm-miyoo-linux-uclibcgnueabi` compiler prefix is present in the produced SDK archive, and records the resulting archive SHA-256.
- Boundary: the script does not install the SDK, does not mutate `/opt/miyoo`, does not invoke `rc1_compile.sh`, and does not claim BUILD-PASS.
- Provenance note: the old MiyooCFW toolchain v2.0.0 release is intentionally not used because its release notes identify it as musl; the RC1 compile contract requires uClibc.
- Acceptance still pending: execute the source-pinned SDK build on a suitable Linux builder, extract/relocate it, pass compiler `-dumpmachine`, JNI target preflight, Classpath/Ant build, and ARM native compile/link checks.
