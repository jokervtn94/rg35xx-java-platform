# B4 — Verified Clean Native Core + Early Observability

Status: `BUILD-PASS — STARTUP/RELAUNCH DEVICE-PASS — RENDER ACCEPTANCE PENDING`

## Purpose

B4 keeps the verified-clean B3 Java runtime and Golden RGB565 receiver/presenter semantics unchanged, while making native startup and first-frame evidence available even if Java logging is missing.

The early log path is:

`/mnt/mmc/freej2me-vc3-early.log`

The filename retains `vc3` for continuity with current acceptance tooling, but this file is owned by checkpoint B4.

## Required startup checkpoints

`CORE_INIT -> RUNTIME_PATH -> JAVA_OPEN_BEGIN -> PIPE_CREATE -> FORK_RESULT -> CHILD_PRE_EXEC -> JAVA_READY -> LOAD_GAME_ENTER -> GAME_PATH -> IPC_LOAD_SENT -> IPC_RUN_SENT -> CORE_DEINIT`

If `execv()` fails, `CHILD_EXEC_FAIL errno=N` is written by the child before `_exit(127)`.

Successful `pipe()` and `fork()` calls now report `errno=0`; stale errno values are no longer logged as failures.

## Required render checkpoints

The observability-only Golden video overlay adds one-shot markers per core lifecycle:

- `B4 FIRST_FRAME_HEADER src=WxH rot=N payload=BYTES`
- `B4 FIRST_FRAME_PUBLISH generation=N src=WxH rot=N`
- `B4 FIRST_PRESENT generation=N src=WxH dst=WxH x=X y=Y output=WxH`
- `B4 VIDEO_DEINIT generation=N presented=N`

These markers do not change RGB565 framing, exact reads, receiver synchronization, front/back publish, Smart-Fit, or presentation behavior.

## Build checkpoint

Observed-core build:

- GitHub Actions run: `34322720684`
- head commit: `e39f29bb041483a26963fae75cdf47ef9dcac090`
- artifact: `10092521754`
- artifact digest: `sha256:3d0b1599b11dd0efcd5dc471013e5e8bee840865ebbb82d639803bc3abe33ca1`
- B3 runtime deterministic content identity: `52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783`
- observed-build runtime file SHA256: `67bbac1f682a9b51a72988a0faccacca78ea7655b6633e876c92e1747031ce9b`
- observed B4 core SHA256: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`

CI completed successfully with the pinned ARMv5TE/uClibc toolchain and the runtime content identity remained exactly equal to B3.

## Device evidence already established

The previous B4/B6 core demonstrated on RG35XX hardware that KDTT, NinjaSchool1 and Qix all reached `JAVA_READY`, `GAME_PATH`, `IPC_LOAD_SENT`, `IPC_RUN_SENT`, then `CORE_DEINIT`, with successful relaunch into the next game. Therefore startup/process/LOAD-RUN/relaunch is device-proven.

The observed core has not yet been device-tested for `FIRST_FRAME_*` / `FIRST_PRESENT`; render acceptance remains pending.

## Foundation exclusions

No PNG ICC compatibility, CV/CW resolution patch, CK font scaling, audio rework, media prewarm, JamVM diagnostic build or patched GNU Classpath is admitted by this checkpoint.

## Acceptance rule

CI success is `BUILD-PASS`. Full B4/foundation freeze requires one real-device acceptance run showing startup plus valid `FIRST_FRAME_HEADER -> FIRST_FRAME_PUBLISH -> FIRST_PRESENT`, expected Smart-Fit geometry, clean deinit/relaunch, and representative 240x320 / 320x240 / 352x416 / 360x640 behavior.
