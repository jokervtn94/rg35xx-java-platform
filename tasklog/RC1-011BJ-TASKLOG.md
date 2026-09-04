# RG35XX Java Platform — RC1-011BJ

Task: RGJ-RC1-011BJ — Exact-path real-device launch harness
Action: ADD
Status: IMPLEMENTED

## Scope
Add one shell launcher for real RG35XX validation using the exact paths already confirmed by prior device logs:
- RetroArch: `/mnt/mmc/CFW/retroarch/retroarch`
- core: `/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`
- runtime JAR: `/mnt/mmc/BIOS/freej2me-lr.jar`
- Java games: `/mnt/mmc/Roms/JAVA`
- evidence collector: project `scripts/rc1_device_evidence.sh` when staged with the package.

## Contract
- The harness is test tooling only; it does not modify Java/native runtime code.
- It accepts exactly one game JAR path or a basename resolved below `/mnt/mmc/Roms/JAVA`.
- It validates required executable/files before launch.
- It records pre-launch evidence, RetroArch stdout/stderr, exit code, post-launch process state and post-launch evidence into one timestamped session directory.
- It launches RetroArch with the accepted RC1 core and the selected JAR as content.
- It never writes DEVICE-TEST-PASS automatically.
- It must not kill unrelated JamVM/RetroArch processes or use a watchdog; abnormal exit/hang remains evidence for manual review.

## Non-overlap
Repository search before this task found no existing `rc1_run_device_test` harness. Existing `rc1_device_evidence.sh` remains the read-only evidence owner; this task only orchestrates one real-device session.

## Build identity under test
- source commit: `086d4987c0d60b5eb9abc3887e73638b24a1b964`
- build run: `33883673553`
- artifact: `9940954185`
- core SHA256: `3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58`
- runtime JAR SHA256: `f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b`

DEVICE-TEST-PASS remains pending real hardware execution and manual review of all mandatory gates.
