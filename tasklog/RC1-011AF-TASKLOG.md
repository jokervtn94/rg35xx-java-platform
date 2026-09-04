# RG35XX Java Platform — RC1-011AF Zero-Fuzz Libretro Lifecycle Rebase

## Trigger
Strict consolidated assembly run `33865540831` passed the previously rebased 0003/0008 contracts, then stopped at `0010-libretro-platform-lifecycle.patch`: hunk #1 (the `RG35XXLifecycle` import) failed under `--fuzz=0`. The exact pinned `Libretro.java` still contains the expected `Mobile` / `MobilePlatform` imports and all lifecycle call-site anchors.

## Governance reload
Before mutation, reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current `patches/0010-libretro-platform-lifecycle.patch`, and exact pinned `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50` `Libretro.java`.

## Decision
- Action: MODIFY `patches/0010-libretro-platform-lifecycle.patch` only.
- Rebase only the stale import hunk to minimal exact context around `import org.recompile.mobile.MobilePlatform;`.
- Preserve all existing lifecycle semantics and call-site ordering: `platformStart()`, `beforeGameLoad()`, `afterGameLoad()`, `gameLoadFailed()`.
- Native EOF/process teardown remains owned by 0017; do not add a second shutdown owner.

## Acceptance
1. 0010 applies with GNU patch `--fuzz=0` in the authoritative assembly order.
2. No lifecycle hook is removed, duplicated, or reordered.
3. Strict assembly proceeds to the next contract or completes.
4. BUILD-PASS and DEVICE-TEST-PASS remain unclaimed until real compile/link/runtime/device validation succeeds.
