# RG35XX Java Platform — RC1-011BF Build-Pass Record

- Task: RGJ-RC1-011BF
- Action: AUDIT
- Status: BUILD-PASS
- Source commit validated: `086d4987c0d60b5eb9abc3887e73638b24a1b964`
- Patch Integration run: `33883673569` — SUCCESS
- Consolidated ARM Build run: `33883673553` — SUCCESS
- Consolidated job: `101058147288`
- Evidence artifact: `9940954185`
- Artifact digest: `sha256:e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630`

## Acceptance evidence

- Zero-fuzz active patch assembly and lifecycle marker gate PASS.
- Consolidated Java Ant build PASS and produced `freej2me_plus-lr.jar`.
- Native compile/link PASS with exact target flags: `-marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`.
- Link used `-Wl,--no-undefined`.
- Target `arm-miyoo-linux-uclibcgnueabi-nm` undefined RG35XX symbol scan PASS.
- Evidence ELF is `ELF32`, ARM, EABI5, soft-float ABI.
- Assembled core contains exactly one fail-closed declaration `static struct rg35xx_audio_pipe rg35xx_java_audio_pipe = { -1, -1 };`.
- Assembled parent handoff sequence is structurally verified as `rg35xx_audio_pipe_parent_after_fork(...)` immediately followed by `rg35xx_audio_drain_start()` inside the successful `audio_pipe_ready` parent block.
- `rg35xx_native_media_shutdown()` is inside `retro_deinit()` before its final closing brace.
- Historical false-green warnings are absent for `rg35xx_core_media_event`, `rg35xx_native_media_shutdown`, `rg35xx_audio_drain_start`, and `rg35xx_load_soundfont_bytes`.
- Remaining compiler warnings are non-blocking for this BUILD-PASS: `rg35xx_audio_parse_header` unused static helper and mixer misleading-indentation warnings; no link or ownership failure resulted.

## Scope and limits

This BUILD-PASS establishes successful reproducible source assembly plus Java and ARMv5TE/uClibc compile/link for the current RC1 source contract. It does not claim JamVM runtime font smoke success beyond the build overlay checks, does not claim real-device audio/graphics/input/RMS behavior, and does not claim DEVICE-TEST-PASS. Hardware validation on RG35XX remains mandatory before release/device acceptance.
