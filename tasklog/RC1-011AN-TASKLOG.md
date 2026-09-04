# RC1-011AN — Rebase 0015 native media runtime to strict zero-fuzz assembled context

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger: consolidated run 33872463482 proved 0016 and 0017 now pass strict `--fuzz=0`, while 0015 fails 4/5 hunks (#1, #3, #4, #5).
- Source basis: exact FreeJ2ME pin `13ec186903087156c145268f8706eecfaf9f1e50`, current 0016 audio-FD patch, current 0017 process-boundary patch, and the authoritative source registry.
- Ownership preserved: 0015 alone owns process-lifetime native media runtime setup/teardown, pinned SoundFont load, and independent audio drain worker. 0016 remains pipe creation/JVM-FD argv owner. 0017 remains native→Java event wire and graceful EOF owner.
- Invariants preserved: stdout remains video IPC only; dedicated audio pipe stays independent; mixer callback only enqueues native media events; audio drain worker performs no render/AudioBatch; graceful Java shutdown completes before final native teardown.
- Rebase policy: modify hunk anchoring/context only where required for exact sequential application after 0016+0017. Do not change runtime semantics or weaken `--fuzz=0`.
- Acceptance: 0015 applies under strict zero-fuzz; required live markers remain present; compile/link must subsequently prove the previously optimized-out native lifecycle symbols are actually wired.
- BUILD-PASS: NOT CLAIMED.
- DEVICE-TEST-PASS: NOT CLAIMED.
