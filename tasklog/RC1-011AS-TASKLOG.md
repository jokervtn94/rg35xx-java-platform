# RG35XX Java Platform — RC1 011AS Tasklog

## RGJ-RC1-011AS — Rebase final 0020 zero-fuzz graphics/input hunks
- Action: MODIFY
- Status: IMPLEMENTED
- Trigger evidence: consolidated ARM build run `33875444027` reached `0020-pinned-graphics-input-lifecycle-consolidation.patch` after 0019 strict integration was repaired. Under authoritative `patch --fuzz=0`, MobilePlatform hunk #1 failed while hunk #2 passed; Libretro hunks #3/#4 failed while hunks #1/#2 passed.
- Diagnostic cross-check: patch-integration run `33875444070` applied the same three failing hunks only by GNU patch fuzz (`MobilePlatform` hunk #1 fuzz 2; `Libretro` hunk #3 fuzz 1; `Libretro` hunk #4 fuzz 1). This is not acceptable for consolidated RC assembly.
- Reload performed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `0020` patch, and exact pinned `MobilePlatform.java` / `Libretro.java` source at `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.
- Ownership preserved: `MobilePlatform` remains LCD/frontbuffer/painter owner; `RG35XXFrameScheduler` remains dirty-generation helper only. `Libretro` remains stdin parser owner; `RG35XXInputEngine` remains the sole RG35XX held/repeat state machine; `Mobile.getMobileKey` remains mapping owner. 0010 remains lifecycle transaction owner and 0017 remains native-media event drain/EOF owner.
- Mutation scope: rebase only the three fuzz-dependent hunks. Do not change behavior, add classes/modules, alter lifecycle ordering, or introduce a second renderer/input/repeat path.
- Rebase method: strengthen the resize dirty insertion with exact surrounding pinned context; remove only the context-edge lines that GNU patch previously had to discard at fuzz=1 for Libretro input/repeat replacements. Preserve all replacement payloads verbatim.
- Acceptance: authoritative patch integration must pass without rejected hunks, then consolidated `rc1_assemble.sh` must pass `--fuzz=0`; only after that may Java/ARM compilation run. BUILD-PASS is not claimed by this task.
