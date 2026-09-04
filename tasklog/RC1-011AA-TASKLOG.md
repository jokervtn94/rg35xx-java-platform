# RG35XX Java Platform — RC1-011AA Native Audio-Pipe Declaration Compile Repair

## Trigger
Consolidated build run `33863464277` reached the first real Java/native compile. The Ant Java build completed successfully, but ARMv5TE/uClibc compilation of `freej2me_libretro.c` failed because the 0015 drain/shutdown functions referenced `rg35xx_java_audio_pipe` before the compiler had a visible declaration at those call sites.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, the active assembly order, and patches 0015/0016/0017.

## Decision
- Action: MODIFY patch `0015-libretro-native-media-runtime.patch` only.
- Preserve 0016 as the sole pipe creation / child-FD / JVM-argv owner.
- Preserve 0015 as worker drain and native media runtime owner.
- Add an early Linux-only tentative declaration of the existing `rg35xx_java_audio_pipe` object in 0015 before runtime worker functions.
- Do not create a second pipe, second transport, second audio thread, or alternate stdout/audio path.
- C permits repeated compatible tentative `static` file-scope declarations; this repair therefore changes declaration visibility only, not object count or runtime semantics.

## Acceptance
1. All 11 active patches still dry-run/apply sequentially against exact FreeJ2ME pin.
2. Java Ant build still succeeds.
3. ARMv5TE/uClibc compilation progresses beyond the prior `rg35xx_java_audio_pipe undeclared` error.
4. BUILD-PASS remains unclaimed until full Java/native compile+link and existing post-build symbol checks succeed.
