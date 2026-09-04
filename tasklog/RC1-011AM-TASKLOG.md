# RG35XX Java Platform — RC1-011AM Tasklog

## RGJ-RC1-011AM — Rebase 0017 process boundary for strict zero-fuzz assembly
- Action: MODIFY
- Status: IMPLEMENTED
- Scope: `patches/0017-libretro-media-process-boundary.patch` only.
- Trigger: consolidated run `33871690446` proved 0016 applies cleanly under `--fuzz=0`; the next blocker is 0017, with native hunk 4 and Java hunks 2-4 requiring fuzz in the permissive integration workflow.
- Preserve: stdout remains binary video IPC; media callbacks enqueue only; opcode 14 payload remains 13 bytes; `retro_run()` drains events; Linux deinit closes only parent->Java stdin first, waits about two seconds with `waitpid(..., WNOHANG)`, then SIGKILL fallback only; Java parser is strict and finalizes through `RG35XXLifecycle.platformShutdown()`.
- Ownership: 0016 remains sole JVM argv/audio-FD owner; 0015 remains native media runtime startup/final teardown owner; no new class/module is introduced.
- Method: reduce stale hunk context / rebase hunk anchors against exact pinned FreeJ2ME plus prior active patches; do not weaken `scripts/rc1_assemble.sh` zero-fuzz gate.
- Acceptance: 0017 dry-run and apply pass with `--fuzz=0`; later 0015/0018/0019/0020 blockers, compile/link, and device tests remain separate gates.
- BUILD-PASS: not claimed.
