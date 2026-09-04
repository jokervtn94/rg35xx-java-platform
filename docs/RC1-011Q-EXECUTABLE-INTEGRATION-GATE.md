# RGJ-RC1-011Q — Executable Integration Gate

Status: **STATIC-AUDIT-PASS**. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Why this stage exists

The RC1 repository historically used the `.patch` suffix for two different things:

1. executable unified diffs that `patch(1)` can apply; and
2. integration/design specifications written as prose and code snippets.

`rc1_assemble.sh` treated the active list as if every item were an executable diff. That is not a safe assumption. For example, `0004-libretro-dedicated-audio-pipe.patch`, `0015-libretro-native-media-runtime.patch` and `0020-pinned-graphics-input-lifecycle-consolidation.patch` are specification contracts, not normal unified diffs. Feeding such a file directly to `patch(1)` cannot produce a reproducible source tree.

This is a release-gate defect rather than an emulator-runtime defect: the architecture could be correct while the assembly driver still fails or, worse, a future wrapper could skip required source mutation and produce a misleading build candidate.

## Resolution

Added `scripts/rc1_contract_gate.sh`.

The gate owns the authoritative active FreeJ2ME integration set and classifies every entry by executable unified-diff structure. A file is executable only when it contains normal `---`, `+++` and `@@` diff records. A `.patch` suffix or prose code snippets are insufficient.

Modes:

- `--project-static`: inventories active contracts and permits specification-only entries while reporting them as build blockers.
- `--build-ready`: fails if any active integration is still specification-only.

`rc1_prebuild_gate.sh` now invokes this gate before external-input/source assembly checks. Therefore `rc1_assemble.sh` cannot reach its `patch(1)` loop unless the full active integration set has first become executable.

## Invariants

- No specification document is silently treated as source mutation.
- No BUILD-READY claim is allowed while an active FreeJ2ME integration exists only as prose.
- Existing task history and design contracts remain preserved; they are not deleted merely because they are not executable.
- Future executable overlays/diffs must preserve the same ownership decisions already audited in 010K–011P.
- `RG35XXFontEngine` remains superseded; this stage does not restore old fallback paths.

## Next stage

011R must materialize the active FreeJ2ME integration contracts into exact pinned-source executable overlays/diffs, grouped by subsystem rather than as ad-hoc edits. Only after `rc1_contract_gate.sh --build-ready` passes should source assembly and the first compile attempt proceed.
