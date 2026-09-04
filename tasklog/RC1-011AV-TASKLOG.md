# RGJ-RC1-011AV — Place native media shutdown inside retro_deinit

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33877281111` assembled with zero fuzz but failed native compilation because `rg35xx_native_media_shutdown();` was emitted between `void retro_reset(void)` and its opening brace. The function therefore remained unused and the Linux build failed with `expected declaration specifiers`.
- Decision: keep 0017 as Java-process graceful shutdown owner and 0015 as final native media teardown owner. Move only the 0015 shutdown call so it executes inside `retro_deinit()` after the Java process teardown block and before the function's final closing brace.
- Invariants preserved: stdout video IPC only; dedicated audio pipe remains process-lifetime until platform exit; final teardown order remains audio drain stop -> pipe close -> mixer reset -> event queue reset -> media cache reset -> media runtime shutdown -> SoundFont release.
- Acceptance: zero-fuzz assembly PASS; Java build PASS; ARMv5TE/uClibc compile/link PASS; `rg35xx_native_media_shutdown` no longer reports defined-but-unused; no undefined RG35XX symbols.
- BUILD-PASS and DEVICE-TEST-PASS are not claimed by this task entry.
