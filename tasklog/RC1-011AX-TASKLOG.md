# RGJ-RC1-011AX — Lock native shutdown to retro_deinit closing context

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33878510000` assembled with zero fuzz but native compilation still placed `rg35xx_native_media_shutdown();` at file scope. Artifact `9938878623` shows the exact end of `retro_deinit()` as `#endif`, then the closing brace of `if(javaRunning)`, then the final function brace.
- Decision: replace the final three-line closing context of `retro_deinit()` so the Linux native shutdown call is inserted between the inner `if(javaRunning)` brace and the function's final brace. Do not use another zero-context line-only insertion.
- Ownership preserved: 0017 remains graceful Java process boundary owner; 0015 remains final native media teardown owner.
- Invariants preserved: stdout video IPC only; dedicated audio pipe closes only at final platform exit; native teardown order remains drain stop -> pipe close -> mixer reset -> event queue reset -> media cache reset -> media runtime shutdown -> SoundFont release.
- Acceptance: zero-fuzz assembly PASS; Java build PASS; ARMv5TE/uClibc compile/link PASS; `rg35xx_native_media_shutdown` is live and no longer defined-but-unused; no undefined RG35XX symbols.
- BUILD-PASS and DEVICE-TEST-PASS are not claimed by this task entry.
