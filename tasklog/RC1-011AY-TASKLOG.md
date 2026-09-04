# RGJ-RC1-011AY — Remove stale outer context from retro_deinit shutdown hunk

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33879047490` failed zero-fuzz assembly only at 0015 hunk #8. The permissive patch-integration run `33879047580` applied the same hunk at line 1702 with fuzz 1 and offset +3; hunks #6/#7/#9 remained applicable.
- Finding: hunk #8 carries three closing-context lines (`#endif`, inner brace, final function brace). Fuzz 1 demonstrates one outer context line is stale while the two braces identify the actual end of `retro_deinit()`.
- Decision: remove only the stale `#endif` context from hunk #8. Keep the inner `if(javaRunning)` closing brace and the final `retro_deinit()` brace as the zero-fuzz anchor, inserting final native media shutdown between them.
- Ownership/order preserved: 0017 owns graceful Java-process teardown; 0015 runs final native shutdown only after that inner teardown closes and before `retro_deinit()` returns.
- Acceptance: zero-fuzz assembly PASS, Java build PASS, ARMv5TE/uClibc compile/link PASS, `rg35xx_native_media_shutdown` is live/used, and no undefined RG35XX symbols.
- BUILD-PASS and DEVICE-TEST-PASS are not claimed by this task entry.
