# RC1-011AU Tasklog — Native media shutdown live wiring

- Task: RGJ-RC1-011AU
- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger evidence: consolidated run `33876741613` passed zero-fuzz assembly and Java/ARM compile/link, but GCC reported `rg35xx_native_media_shutdown` as defined-but-unused.
- Evidence inspection: artifact `9938192203` showed the call was present in assembled `freej2me_libretro.c` but inserted inside the `_WIN32` branch of `retro_deinit`; Linux preprocessing therefore removed the call.
- Correction: move only the 0015 native shutdown call to after the complete platform-specific Java-process teardown block in `retro_deinit`, preserving 0017 graceful Java EOF/wait ownership first and 0015 final native teardown second.
- Preserve: stdout video IPC, dedicated audio pipe ownership, independent drain pthread, SoundFont/runtime init, native END_OF_MEDIA, and all existing lifecycle invariants.
- Acceptance: strict `--fuzz=0` assembly passes; Linux ARM compile no longer reports `rg35xx_native_media_shutdown` unused; assembled source shows live shutdown after Java process teardown; no undefined RG35XX symbols.
- BUILD-PASS is not claimed by this task entry alone; a fresh consolidated run and evidence review are required.
