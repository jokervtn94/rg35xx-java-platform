# RC1-011AO — 0015 zero-context insertion rebase

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger: consolidated strict `patch --fuzz=0` run `33873004558` failed 8/9 hunks in 0015; the large helper-function hunk succeeded, proving runtime helper semantics are valid while surrounding insertion contexts remain stale after 0016/0017.
- Decision: preserve the helper/runtime code and lifecycle ownership exactly; convert only stale insertion hunks to zero-context/pure insertion anchors at verified assembled positions. Do not remove SoundFont loading, mixer/runtime init, audio drain worker, graceful teardown ordering, or dedicated audio-pipe ownership.
- Invariants: stdout remains binary video IPC; dedicated audio pipe remains separate; 0016 owns pipe creation/JVM FD argv; 0017 owns graceful Java EOF/event boundary; 0015 owns mixer/runtime startup, audio drain worker, and final native media shutdown.
- BUILD-PASS is not claimed until strict assembly and Java/ARMv5TE/uClibc compile/link evidence pass.
