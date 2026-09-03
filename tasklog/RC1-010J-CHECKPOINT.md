# RGJ-RC1-010J — Exact JamVM dedicated-audio FD process contract

- Action: MODIFY / AUDIT INTEGRATION CONTRACT
- Status: IMPLEMENTED
- File: `patches/0016-libretro-java-audio-fd-exact.patch`
- Existing owner retained: `native/rg35xx_audio_pipe.h/.c`; no second pipe/process module added.
- Exact upstream owner inspected: `TASEmulators/freej2me-plus` devel `src/libretro/freej2me_libretro.c` blob `534b26cc97129c4fe7b04ea9a6b07fb8945d33b0`.
- Current upstream process facts: `retro_init()` builds launch argv then calls `javaOpen()`; Linux `javaOpen()` creates pRead/pWrite, forks, dup2s stdin/stdout and execs Java; `retro_reset()` tears down and recreates the Java process.
- Existing audio-pipe facts verified: create() makes read end nonblocking and intentionally leaves child write fd without CLOEXEC; parent_after_fork closes write; child_after_fork closes read; close() releases both endpoints and parser payload.
- Decision: dedicated audio pipe is created before fork; its write fd is passed as `-Dfreej2me.rg35xx.audio.fd=<fd>` before `-jar`; fd 0/1/2 remain stdin control, stdout video and stderr diagnostics respectively.
- Safety: pipe creation failure must not abort Java startup; fork failure closes both dedicated endpoints; deinit closes the old pipe before restart creates a new one.
- Important argv gate: exact assembled FreeJ2ME command-line order must be compiled/checked before BUILD-PASS. Patch 0016 intentionally does not guess whether the existing encoding token is a JVM option or application argument; it preserves upstream relative ordering while requiring only the RG35XX `-D` property to precede `-jar`.
- Drain ownership remains the independent native audio worker from patch 0015, never `retro_run()`.
- Registry updated to list patch 0016 and its ownership constraints.
- BUILD-PASS: NOT CLAIMED.
- DEVICE-TEST-PASS: NOT CLAIMED.
