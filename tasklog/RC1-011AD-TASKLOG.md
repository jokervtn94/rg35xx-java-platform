# RG35XX Java Platform — RC1-011AD Zero-Fuzz Rebase of Manager Capability Patch

## Trigger
Consolidated run `33864911210` used the new zero-fuzz assembly gate from 011AC and stopped at the first stale patch instead of continuing to compile an invalid partially-applied tree. The exact failure was `0003-manager-rg35xx-media-profile.patch`, hunk #1 on `src/javax/microedition/media/Manager.java`.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, `tasklog/RC1-011AC-TASKLOG.md`, current `scripts/rc1_assemble.sh`, current patch 0003, and the exact pinned FreeJ2ME Manager source at `13ec186903087156c145268f8706eecfaf9f1e50`.

## Decision
- Action: MODIFY `patches/0003-manager-rg35xx-media-profile.patch` only.
- Preserve semantics exactly: desktop capability reporting remains upstream-owned; RG35XX target capability reporting is routed through `RG35XXMediaProfile` when `RG35XXPlatformProfile.isActive()`.
- Rebase only the import hunk context to the exact pinned Manager source shape so it applies with `--fuzz=0`.
- Do not add a second Manager facade, capability registry or target selector.

## Acceptance
1. Patch 0003 applies to the exact FreeJ2ME pin with `--fuzz=0`.
2. Its target-only capability branch remains present after all active patches are applied.
3. Assembly continues to the next exact stale patch, if any.
4. BUILD-PASS and DEVICE-TEST-PASS remain unclaimed until the strict assembly and complete build/runtime gates pass.
