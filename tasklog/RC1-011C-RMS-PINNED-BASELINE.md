# RGJ-RC1-011C — Pinned RMS Safe Baseline

Status: STATIC-AUDIT-PASS. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: REPLACE-INTEGRATION-CONTRACT / MODIFY / AUDIT.

Source pin: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.

Mandatory reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current coordinator/atomic helper/lifecycle sources and exact pinned RecordStore persistence call sites.

## Replacement decision

Historical `patches/0009-recordstore-rg35xx-storage-policy.patch` is not deleted, but its application is SUPERSEDED for the pinned RC1 source by `patches/0021-pinned-rms-safe-baseline.patch`.

Old integration assumption: one serialized RecordStore snapshot can be persisted through one target/temp/backup atomic replacement.

Pinned source reality: metadata lives in `<basename>.rms` while each record payload lives in `<basename>.<recordId>`. The store is therefore a multi-file generation, and the old single-target helper cannot provide an all-or-nothing transaction for the complete store.

Replacement: retain upstream synchronous `saveRecordStore()` mutation persistence for RC1. `RG35XXRmsCoordinator` and `RG35XXRmsAtomicFile` remain present but dormant/unhooked from pinned RecordStore. No new RMS format is introduced.

## Source modification

`RG35XXRmsCoordinator.forceFlush()` now returns immediately without starting a worker when the coordinator has never been activated and has no pending/failed work. Existing lifecycle barriers can therefore remain in place without spawning an idle RMS thread on the synchronous baseline.

## Rollback / future optimization

Async/coalesced persistence may return only under a new explicit task that defines a multi-file generation/commit/recovery protocol and validates it on device. Do not silently reapply patch 0009 to the pinned RecordStore.

Audit: `docs/RC1-RMS-PINNED-BASELINE-AUDIT.md`.

Gate result: STATIC-AUDIT-PASS only.
