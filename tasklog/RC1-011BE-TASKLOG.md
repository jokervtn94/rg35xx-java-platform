# RG35XX Java Platform — RC1-011BE

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0015-libretro-native-media-runtime.patch`
- Trigger: consolidated run `33882679440` on commit `503a69a442814514f19b2905c0df4f7626324f65` failed the ownership marker `audio drain start is not immediately after parent audio-pipe handoff` before compile.
- Finding: the zero-context pure insertion used by RC1-011BB is line-coordinate based and does not structurally lock the drain call between `rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);` and the closing brace of `if(audio_pipe_ready)`.
- Decision: replace the final drain-start hunk with a two-line exact-context hunk using the parent handoff call and its immediate closing brace, inserting `rg35xx_audio_drain_start();` between them. GNU patch may relocate the exact context by offset, but `--fuzz=0` remains mandatory.
- Preserve: 0016 remains sole pipe/JVM argv owner; 0015 owns parent drain worker; stdout remains binary video IPC; dedicated audio pipe stays process-lifetime; no child drain start; final native media shutdown ownership unchanged.
- Acceptance: strict zero-fuzz assembly passes; ownership gate proves one fail-closed `{ -1, -1 }` pipe declaration and exactly one drain-start immediately after parent handoff; Java and ARMv5TE/uClibc compile/link pass; no historical live-wiring unused warnings; target nm shows no unresolved `rg35xx_*`.
- BUILD-PASS: not claimed by this task.
- DEVICE-TEST-PASS: not claimed.
