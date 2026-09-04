# RG35XX Java Platform — RC1-011AT

## RGJ-RC1-011AT — Final exact-coordinate rebase for 0020
- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0020-pinned-graphics-input-lifecycle-consolidation.patch`
- Trigger: consolidated run `33876151412` still failed strict `--fuzz=0` dry-run for MobilePlatform hunk #1 and Libretro hunks #3/#4 after RC1-011AS, while patch-integration continued to pass using fuzz.
- Governance reload: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current 0020 patch and exact pinned target source were reloaded before mutation.
- Decision: preserve all 0020 semantics and remove stale surrounding context completely from the three failing regions. Use a pure insertion after the completed resize/display replacement block, two minimal two-line input transition replacements, and one minimal repeat-loop replacement.
- Ownership preserved: MobilePlatform remains display/frontbuffer owner; RG35XXFrameScheduler remains dirty-generation helper; Libretro remains protocol parser; RG35XXInputEngine remains sole RG35XX held/repeat state machine; 0010 remains lifecycle transaction owner; 0017 remains native event drain/EOF owner.
- No new class/module/responsibility is introduced.
- Acceptance: consolidated `scripts/rc1_assemble.sh` must apply all active patches under `--fuzz=0`; BUILD-PASS remains forbidden until Java + ARMv5TE/uClibc compile/link and evidence gates pass.
