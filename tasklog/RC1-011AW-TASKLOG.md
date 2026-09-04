# RGJ-RC1-011AW — Anchor native shutdown before retro_deinit final brace

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33877940239` passed zero-fuzz assembly and Java compilation, but ARM compilation showed `rg35xx_native_media_shutdown();` still emitted at file scope immediately after `retro_deinit()`'s final brace. GCC reported a conflicting global declaration and the helper remained defined-but-unused.
- Exact assembled-source evidence: in run artifact `9938654463`, `retro_deinit()` closes at assembled line 1704; the shutdown call begins at line 1707. Removing the 0015 insertion maps the inner platform-teardown brace to pre-0015 old line 1569 and the final function brace to old line 1570.
- Decision: move only the shutdown insertion anchor from after old line 1570 to after old line 1569, so the Linux shutdown call is emitted before the final `retro_deinit()` brace. Do not change helper implementation, Java-process shutdown ownership, pipe ownership, or teardown order.
- Acceptance: zero-fuzz assembly PASS; Java build PASS; ARMv5TE/uClibc compile/link PASS; `rg35xx_native_media_shutdown` no longer defined-but-unused; no unresolved RG35XX symbols.
- BUILD-PASS and DEVICE-TEST-PASS are not claimed by this task entry.
