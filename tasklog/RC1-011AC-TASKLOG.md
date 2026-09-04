# RG35XX Java Platform — RC1-011AC Zero-Fuzz Patch Assembly Gate

## Trigger
Consolidated diagnostic run `33864362771` assembled successfully but the captured final `freej2me_libretro.c` proved that critical 0016 audio-FD/JVM-selector mutations were absent while later 0015 helper bodies had been inserted. The build then failed because `rg35xx_java_audio_pipe` was referenced without a declaration. This demonstrates that the prior assembly gate accepted an invalid partially/fuzz-applied patch state.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `scripts/rc1_assemble.sh`, patches 0010/0015/0016, and the assembled-source evidence from run `33864362771`.

## Decision
- Action: MODIFY `scripts/rc1_assemble.sh` only in this task.
- Require GNU patch `--fuzz=0 --batch --forward` for both dry-run and real application.
- Capture patch output and fail if any hunk is skipped, reversed, rejected or ignored.
- After all active patches apply, require exact final native markers for 0016/0015 lifecycle ownership: `NUM_ARGUMENTS 9`, target selector property, dedicated audio-FD property path, one audio-pipe state declaration, native mixer init, drain start, and final native shutdown call.
- Do not add a second audio pipe, process owner, mixer, worker or libretro entrypoint.

## Acceptance
1. A patch cannot pass merely because GNU patch applied with fuzz or silently skipped a reversed hunk.
2. Final assembled source must contain every mandatory native media lifecycle marker before `ASSEMBLY PASS` is emitted.
3. The next CI run may fail earlier at the exact stale patch needing rebase; that failure is expected and is preferable to a false assembly pass.
4. BUILD-PASS and DEVICE-TEST-PASS remain unclaimed until the strict assembly, Java build, ARMv5TE/uClibc compile/link, runtime smoke tests and device validation pass.
