# RGJ-RC1-011BA — Rebase parent drain-start to exact parent_after_fork line

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: patch-integration run `33880283015` failed only 0015 hunk #9; the wider parent-block context did not match the exact pre-0015 tree. Prior successful assembled evidence places `rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);` at assembled line 1817. Subtracting the 137 lines inserted by earlier 0015 hunks gives exact pre-0015 line 1680.
- Decision: replace the failed wider context hunk with a one-line exact-context hunk on the unique `rg35xx_audio_pipe_parent_after_fork(...)` call, adding `rg35xx_audio_drain_start();` immediately after it.
- Invariants preserved: drain worker starts only in parent after parent FD handoff; child never starts drain; stdout remains binary video IPC; shutdown ordering unchanged.
- Acceptance: patch integration PASS; zero-fuzz assembly PASS; assembled source contains exactly one drain-start call inside `if(pid>0)` after parent_after_fork; Java/ARM compile-link PASS; no unresolved `rg35xx_*`.
- BUILD-PASS remains blocked until new evidence review.
