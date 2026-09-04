# RGJ-RC1-011BC — Align strict assembly ownership markers with corrected audio-pipe lifecycle

- Action: MODIFY
- Status: IMPLEMENTED
- Trigger: consolidated run 33881331445 reached strict marker validation after zero-fuzz patch application, then failed because `scripts/rc1_assemble.sh` still required the historical uninitialized declaration `static struct rg35xx_audio_pipe rg35xx_java_audio_pipe;`.
- Current authoritative declaration: `static struct rg35xx_audio_pipe rg35xx_java_audio_pipe = { -1, -1 };` from corrected 0016 ownership.
- File: `scripts/rc1_assemble.sh`.
- Scope: update only strict post-assembly ownership markers; no runtime semantics or patch order changes.
- Required checks:
  1. exactly one fail-closed audio-pipe declaration with `{ -1, -1 }`;
  2. exactly one `rg35xx_audio_drain_start();` call;
  3. drain-start must immediately follow `rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);` in assembled source;
  4. existing mixer init and final native shutdown markers remain required.
- Acceptance: zero-fuzz assembly PASS, Java build PASS, ARMv5TE/uClibc compile/link PASS, no unresolved `rg35xx_*`, and evidence confirms parent-only drain ownership.
- BUILD-PASS is not claimed by this task alone; fresh consolidated workflow evidence is mandatory.
