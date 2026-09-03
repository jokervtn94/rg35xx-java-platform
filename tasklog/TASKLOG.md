# RG35XX Java Platform Tasklog

Tasklog history is immutable. If a decision is reverted, create a new REVERT/REPLACE task; do not erase the original engineering decision.

Actions: `ADD`, `MODIFY`, `REMOVE`, `DISABLE`, `REPLACE`, `KEEP`, `REVERT`, `AUDIT`.

Statuses: `PLANNED`, `IMPLEMENTED`, `STATIC-AUDIT-PASS`, `BUILD-PASS`, `DEVICE-TEST-PASS`, `DEVICE-TEST-FAIL`, `ROLLED-BACK`, `SUPERSEDED`.

> Historical Alpha 1 / Beta 1 / Beta 2 / Beta 3 / Beta 4 entries remain authoritative in git history. This file continues the immutable engineering log; prior entries are not semantically revoked by the Beta 5 additions below.

## Platform 1.0 Beta 5 — RMS / Storage Engine

### RGJ-B5-001 — Upstream RecordStore semantic/storage audit
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Source basis: current FreeJ2ME devel RecordStore.
- Finding: records/IDs/tags are already held in RAM, but mutations such as addRecord/deleteRecord synchronously call saveRecordStore().
- Finding: current upstream imports java.nio.file.Files, which cannot be assumed on the RG35XX JamVM/GNU Classpath target.
- Decision: preserve upstream RMS semantics/file format and replace only target persistence policy.

### RGJ-B5-002 — RG35XXRmsCoordinator
- Action: ADD
- Status: IMPLEMENTED
- Source: src/org/recompile/mobile/RG35XXRmsCoordinator.java.
- Design: one MIN_PRIORITY Java writer; dirty stores are coalesced; no thread per RecordStore and no write per mutation.
- Failure policy: failed background flush remains dirty and is surfaced at a force-flush barrier.

### RGJ-B5-003 — RG35XXRmsAtomicFile
- Action: ADD
- Status: IMPLEMENTED
- Source: src/org/recompile/mobile/RG35XXRmsAtomicFile.java.
- Design: Java-6-compatible java.io sibling temp/backup replacement; no java.nio.file dependency.
- Reason: never truncate the known-good RMS target before replacement data has been fully written/closed.
- Device caveat: FAT rename/power-loss behavior requires later real-device validation.

### RGJ-B5-004 — RecordStore asynchronous persistence integration
- Action: MODIFY
- Status: IMPLEMENTED
- Source: patches/0009-recordstore-rg35xx-storage-policy.patch.
- Policy: mutations update semantic RAM state immediately and mark the store dirty; physical SD persistence is coalesced on RG35XX only.
- Preserve: record IDs/tags/version/listeners/auth rules, basename/suite/vendor behavior and legacy migration.

### RGJ-B5-005 — RMS lifecycle force-flush barriers
- Action: MODIFY
- Status: IMPLEMENTED
- Required barriers: final RecordStore close, MIDlet pause/destroy, game unload, Java/libretro shutdown/deinit.
- Ordering: force flush before in-memory vectors/registry state are discarded.

### RGJ-B5-006 — RMS production logging policy
- Action: MODIFY
- Status: IMPLEMENTED
- Decision: RG35XX production path must not dump record payload arrays or perform per-mutation SD diagnostics.
- Reason: avoid save-related frame/audio stalls and unnecessary SD wear.

### RGJ-B5-007 — Startup recovery policy
- Action: ADD
- Status: STATIC-AUDIT-PASS
- Target exists: target is authoritative and stale .tmp may be discarded.
- Target absent + .tmp exists: promote only after existing RecordStore parser validates the candidate; never blindly trust partial temp data.
- Backup file is a replacement safety artifact, not a new RMS format.

### RGJ-B5-008 — Real-JAR RMS compatibility focus
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Diamond Rush: RMS + Timer workload is the primary save-stall regression case.
- Prince of Persia: RMS reopen/version/record-ID behavior must remain identical.
- Remaining compatibility corpus: storage worker must remain effectively idle when RMS is unused/lightly used.
- Limitation: static audit does not prove FAT power-loss guarantees or device timing.

### RGJ-B5-009 — Beta 5 current gate
- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Architecture/source policy is lockable: RAM semantic state + coalesced low-priority persistence + atomic replacement + lifecycle barriers.
- BUILD-PASS is intentionally not claimed until the consolidated FreeJ2ME source tree applies patch 0009 and Java-6/JamVM compilation is performed.
- Legacy synchronous save path remains the rollback option if device validation exposes lifecycle/persistence defects.
