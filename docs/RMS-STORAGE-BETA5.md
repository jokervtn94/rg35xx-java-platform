# Platform 1.0 Beta 5 — RMS / Storage Engine

## Goal
Reduce synchronous SD writes during gameplay without changing MIDP RecordStore semantics or FreeJ2ME's current on-disk compatibility.

## Upstream audit
Current FreeJ2ME devel `RecordStore` keeps records in memory (`Vector<byte[]>`, IDs, tags), but mutating operations such as `addRecord()` and `deleteRecord()` call `saveRecordStore()` synchronously. It also imports `java.nio.file.Files`, which is incompatible with the RG35XX JamVM/GNU Classpath Java-6-era runtime profile.

Beta 5 therefore does **not** replace RMS semantics. It adds a target storage policy beneath/around the existing RecordStore state model.

## Architecture

```text
MIDlet RecordStore API
        |
        v
FreeJ2ME RecordStore semantic state
  records / ids / tags / version / modified
        |
        | markDirty(store)
        v
RG35XXRmsCoordinator
  - RAM dirty set
  - one low-priority writer
  - coalesced requests
  - explicit force-flush barrier
        |
        v
RecordStore serialization snapshot
        |
        v
RG35XXRmsAtomicFile
  target.rms.tmp
        |
        | close + rename
        v
  target.rms
```

## Rules
1. `addRecord`, `setRecord`, `deleteRecord` update in-memory semantic state immediately.
2. Ordinary mutations mark the store dirty instead of forcing an SD write for every operation.
3. Writer coalesces multiple dirty notifications for the same store.
4. `closeRecordStore`, MIDlet pause/destroy, game unload and libretro deinit are force-flush barriers.
5. Atomic write policy: serialize to sibling `.tmp`, close it, then replace target. Never truncate the known-good target before the replacement is complete.
6. If startup finds a valid target plus stale `.tmp`, target wins and stale temp may be removed.
7. If target is absent but a complete recoverable `.tmp` exists, recovery may promote it only after the same RecordStore parser/validation accepts it.
8. No per-record debug dump of payload bytes on RG35XX production path.
9. Preserve legacy RMS migration and current basename/suite/vendor rules.
10. No `java.nio.file` dependency may remain in the RG35XX target path.

## Consistency model
The Java in-memory RecordStore remains authoritative while a game is running. Persistence is eventually flushed during normal gameplay and synchronously guaranteed at lifecycle barriers. Listener notifications continue to occur after the semantic mutation, not after physical SD completion.

## Failure policy
A background flush failure keeps the store dirty and records the failure for the next force-flush barrier. It must not discard the RAM copy. A force-flush failure is surfaced through the existing RecordStore exception/logging boundary where possible.

## Compatibility corpus focus
- Diamond Rush: RMS + timers; ensure saves do not add frame-time SD stalls.
- Prince of Persia: packed resources + RMS; verify reopen/version/record IDs remain unchanged.
- Other corpus games: ensure absence/light use of RMS does not add worker overhead.

## Deferred
Actual device power-loss behavior and FAT filesystem rename guarantees require consolidated RG35XX device testing. Beta 5 static gate only proves source/lifecycle architecture.
