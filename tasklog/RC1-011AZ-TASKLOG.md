# RGJ-RC1-011AZ — Repair parent audio-drain ownership and pipe initializer

- Action: MODIFY
- Status: IMPLEMENTED
- Targets: `patches/0016-libretro-java-audio-fd-exact.patch`, `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33879529762` compiled/linked successfully, but artifact inspection showed `rg35xx_java_audio_pipe` assembled without the required `{ -1, -1 }` initializer and `rg35xx_audio_drain_start()` executing in the child branch before `execvp`, rather than in the parent after `rg35xx_audio_pipe_parent_after_fork()`.
- Decision: preserve 0016 as sole audio-pipe/JVM-FD owner and restore its static pipe initializer; preserve 0015 as worker-drain owner but move only the drain-start call into the successful parent handoff path after parent-side FD ownership is established.
- Invariants preserved: pipe creation before fork; child inherits only the Java write endpoint; parent owns the read/drain endpoint; drain thread exists only in parent; stdout remains binary video IPC; final native shutdown remains after graceful Java process teardown.
- Acceptance: zero-fuzz assembly PASS; assembled source contains `static struct rg35xx_audio_pipe rg35xx_java_audio_pipe = { -1, -1 };`; exactly one `rg35xx_audio_drain_start()` call exists and it is within `if(pid>0)` after `rg35xx_audio_pipe_parent_after_fork()`; Java and ARMv5TE/uClibc compile/link PASS; no unresolved `rg35xx_*`; prior false-green unused warnings remain absent.
- BUILD-PASS is not claimed until the new consolidated evidence is reviewed. DEVICE-TEST-PASS remains hardware-only.
