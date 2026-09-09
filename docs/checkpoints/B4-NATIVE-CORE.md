# B4 — Verified Clean Native Core + Early Observability

Status: `SOURCE/GATE COMMITTED — CI/DEVICE ACCEPTANCE PENDING`

## Purpose

B4 keeps the verified-clean B3 Java runtime and Golden RGB565 receiver/presenter unchanged, while adding one foundation requirement: a native log must exist even if Java never reaches its own stderr/log path.

The early log path is:

`/mnt/mmc/freej2me-vc3-early.log`

The filename retains `vc3` for continuity with the current acceptance tooling, but this file is introduced by checkpoint B4.

## Required checkpoints

The core records at least:

`CORE_INIT -> RUNTIME_PATH -> JAVA_OPEN_BEGIN -> PIPE_CREATE -> FORK_RESULT -> CHILD_PRE_EXEC -> JAVA_READY -> LOAD_GAME_ENTER -> GAME_PATH -> IPC_LOAD_SENT -> IPC_RUN_SENT -> CORE_DEINIT`

If `execv()` fails, `CHILD_EXEC_FAIL errno=N` is written by the child before `_exit(127)`.

## Implementation constraints

- direct native `open/write/fsync/close`; no dependency on Java logging;
- append-only so multiple game sessions remain visible until the installer/collector deliberately rotates the log;
- stdout remains binary frame IPC and is never used for diagnostics;
- no change to RGB565 frame protocol, receiver thread, front/back buffers or Smart-Fit;
- no PNG compatibility, CV/CW resolution, font or audio change;
- B3 runtime binary is required to remain byte-identical to SHA256 `d83febe95e08ebd4bb7e03ffb76359d8ea119bcacffdc6ec0c0e285591695529` during B4 CI.

## Diagnostic interpretation

- no B4 log at all: selected libretro core was probably not loaded, or the frontend failed before `retro_init()`;
- `CORE_INIT` only: native initialization/frontend lifecycle failure;
- stops before `JAVA_READY`: runtime path / pipe / fork / exec / JamVM startup problem;
- reaches `JAVA_READY` but not `LOAD_GAME_ENTER`: frontend did not invoke game load;
- reaches `GAME_PATH` but not `IPC_LOAD_SENT`: native game-path/IPC failure;
- reaches `IPC_RUN_SENT` but no normal frame evidence: Java/MIDlet/runtime compatibility becomes the next boundary to inspect.

## Acceptance rule

CI success means `B4 BUILD-PASS` only. B4 becomes `DEVICE-PASS` only after a real RG35XX test demonstrates that the early log is created for both a known-working game and a blue/black-screen case, without changing B3 runtime behavior.
