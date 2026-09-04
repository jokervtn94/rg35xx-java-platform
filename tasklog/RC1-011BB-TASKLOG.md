# RC1-011BB — Zero-fuzz rebase of parent audio-drain start

- Action: MODIFY
- Status: IMPLEMENTED
- Trigger: consolidated run `33880549757` failed strict assembly only at `0015-libretro-native-media-runtime.patch` hunk #9, while permissive patch integration run `33880549674` applied the same hunk at line 1819 with fuzz 1 and offset +3.
- Finding: `0017-libretro-media-process-boundary.patch` does not mutate the `javaOpen()` parent handoff region. The semantic target remains the unique successful parent path immediately after `rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);`.
- Correction: rebase the 0015 drain-start hunk to a pure insertion after exact pre-0015 old line 1683, eliminating stale context/fuzz without changing ownership or runtime behavior.
- Preserve: 0016 owns pipe creation/FD handoff/JVM argv; 0015 owns parent drain worker; child must never start the drain worker; shutdown remains in `retro_deinit()` after graceful Java teardown.
- Gate: BUILD-PASS is not claimed until a fresh zero-fuzz consolidated build and evidence review pass.
