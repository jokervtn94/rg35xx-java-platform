# RG35XX BUILD / PORT RULE INDEX — LOCKED 2026-10-05

Status: LOCKED
Project: Port FreeJ2ME Miyoo/Aweigit to original RG35XX
Purpose: Repository-local guardrail index so future work cannot silently drift away from the user-supplied build/port rules.

## Binding source documents

The following exact user-supplied rule files are the source authority used to derive this repository guardrail index. Their source SHA256 values are pinned here so future rule revisions cannot be confused with the current rule set:

| File | SHA256 |
|---|---|
| `RG35XX-PORT-RULER-LOCKED-v1.md` | `ffaf5d9e05be92ad41ad0acdfdf188f0495bbd999a34b3b16b27206802ec4b8c` |
| `RG35XX-PLATFORM-CONTRACT-GOLDEN-RECONSTRUCTION-MAP-v1.md` | `8135dfb11f87ebecb7dde86a53c40908604e86541463c740246f558f5450477a` |
| `RG35XX-PLATFORM-FIRST-HARD-RULE-LOCKED-v1.md` | `c42f852ebab78781c5e1084e2b194f20ff1a578a7b683ed98d627d83245e5bcb` |
| `RG35XX-MIYOO-FIRST-PORT-RULE-LOCKED-v1.md` | `1b77ee21e7023c62d7b265a66ae83973cee14b5c4dd072bbcdf59b360aca5aa2` |

This index is a repository-local operational lock derived from those sources; it must not be weakened without an explicit user-approved rule revision. The source-file hashes above identify the rule set that governed this checkpoint.

## Non-negotiable build/port direction

1. Main build lineage is pinned Miyoo/Aweigit: `aweigit/freej2me-miyoomini` at `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`.
2. Start from pinned Miyoo/Aweigit behavior. Preserve it when it works. Do not replace it because another implementation looks cleaner/newer/easier.
3. Measured original-RG35XX hardware/runtime behavior is the authority for RG35XX-specific adaptation.
4. Adapt the smallest RG35XX boundary only after the exact failure owner is identified.
5. Do not create a second J2ME semantic layer in the RG35XX adapter.
6. No game-specific production hacks. A commercial game may reveal a platform gap but may not drive platform architecture.
7. Do not use A9/DP/VC/old experimental branches as production parents. A9 is diagnostic only.
8. Host/CI method-level tests are allowed. Physical device tests should converge at module/platform gates; minimize unnecessary device cycles.
9. Build/CI/API PASS is not DEVICE-PASS. Physical original-RG35XX observation is mandatory where required.
10. Audible audio cannot be inferred from `MIDI_LOAD=PASS`, `MIDI_PLAY=PASS`, `WAV_PLAY=PASS`, exit code 0, or lack of exceptions.
11. Commercial JARs must not be silently rebuilt/repacked. Exact filename + SHA256 are required.
12. Keep owner scope narrow; preserve unaffected protected hashes/owners.
13. No trace-only instrumentation in stable.
14. P4 3D/Bluetooth/Sensor capabilities stay measured/deferred unless exact evidence authorizes re-enable.
15. P7 protects Tier-0 Vua Cướp Biển + God of War; GoW audible audio is mandatory.
16. P8 promotion is blocked until P0-P7 requirements, including physical regression, pass.
17. Stable promotion is never implied by a candidate package.

## Required engineering sequence

```text
pinned Miyoo/Aweigit behavior
        -> measured original RG35XX contract
        -> exact failure identity
        -> canonical/source comparison
        -> failure-owner assignment
        -> smallest owner-scoped RG35XX adapter delta
        -> host/module regression gates
        -> original-RG35XX physical acceptance
        -> Tier-0 regression
        -> promotion consideration
```

Mandatory project phrase:

> PLATFORM FIRST. MODULE SECOND. GAME COMPATIBILITY LAST.

## Branch-role discipline

Use role-oriented branches such as:

```text
audit/*
module/*
platform-integration/*
physical-test/*
stable
```

Method/diagnostic branches may exist temporarily but must not silently become a long-term production parent merely because an isolated test passes.

## Status vocabulary discipline

Use scoped status values: `PASS`, `FAIL`, `PARTIAL`, `NOT_TESTED`, `NEEDS_REPRO`, `REJECTED`, `ARCHIVED_DIAGNOSTIC`.

Never write `DEVICE-PASS=YES` without required original-RG35XX physical evidence. Never write `STABLE=YES` merely because CI or a candidate test passes.

## Current checkpoint relationship

Progress/status is recorded separately in `docs/checkpoints/RG35XX-R5-AUDIO-OWNER-CHECKPOINT-20261005.md`.

The checkpoint may advance status, evidence, artifact IDs, hashes, and next gates. It does not weaken or replace these locked engineering rules.
