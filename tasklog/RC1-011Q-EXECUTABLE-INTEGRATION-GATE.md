# RGJ-RC1-011Q — Executable Integration Gate

- Action: ADD RELEASE GATE / CORRECT ASSEMBLY ASSUMPTION
- Status: STATIC-AUDIT-PASS
- BUILD-PASS: NO
- DEVICE-TEST-PASS: NO

## Reload / anti-duplication

Before mutation, recent RC1 history was reloaded. 011M, 011N, 011O and 011P already existed, so this task was allocated as 011Q rather than duplicating those stages.

## Finding

The active `patches/*.patch` set is not uniformly executable. Several files are integration specifications containing prose and code snippets, not unified diffs. The existing assembly path nevertheless attempted to feed the whole active set to `patch(1)`.

That means the repository was not honestly BUILD-READY even if external assets/toolchains were materialized.

## Changes

- Added `scripts/rc1_contract_gate.sh`.
- Added explicit executable-diff structural classification (`---`, `+++`, `@@`).
- Added static inventory mode and strict build-ready mode.
- Updated `scripts/rc1_prebuild_gate.sh` so BUILD-READY fails before source assembly when any active integration remains specification-only.
- Preserved all historical specification contracts; no source/task history was deleted.
- Added `docs/RC1-011Q-EXECUTABLE-INTEGRATION-GATE.md`.

## Result

The false-ready path is closed. `rc1_assemble.sh` can no longer be reached through the normal BUILD-READY pipeline while prose contracts are still being mistaken for executable patches.

## Next

011R must convert the active integration contracts into exact pinned-source executable overlays/diffs by subsystem and then pass `rc1_contract_gate.sh --build-ready` before the first real build.

Primary commits:
- contract gate: `1ff45fb9550752af5afa53b37fead6d3b6478e00`
- prebuild hardening: `69601c8797ffe677c01946b795551cb86e839544`
- audit document: `3bc2795f5c9965ba5063f6f19051d2fbb86fa9bd`
