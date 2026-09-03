# RC1 Pinned RMS Baseline Audit

Status: STATIC-AUDIT-PASS for RGJ-RC1-011C. BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Source basis

Upstream is pinned to `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.
Exact `javax.microedition.rms.RecordStore` was inspected together with project `RG35XXRmsCoordinator`, `RG35XXRmsAtomicFile`, lifecycle barriers, historical patch 0009 and the source registry.

## Exact pinned persistence format

The pinned RecordStore does not persist one monolithic RMS image. `<basename>.rms` contains JSON metadata including IDs/tags/version/authentication/owner fields, while record payloads are written separately as `<basename>.<recordId>`. `saveRecordStore()` deletes outdated payload files, rewrites metadata, then rewrites the current payload set. `addRecord`, `deleteRecord` and `setRecord` invoke that save synchronously.

This invalidates the old Beta-5 assumption that one serialized snapshot plus one sibling temp/backup replacement is enough to make an entire RecordStore transaction atomic.

## Safety decision

RC1 keeps upstream synchronous RecordStore persistence unchanged. Patch 0009 remains historical engineering evidence but is superseded for the pinned RC1 source by `patches/0021-pinned-rms-safe-baseline.patch`.

`RG35XXRmsCoordinator` and `RG35XXRmsAtomicFile` are not deleted. They remain source-controlled because their responsibilities may be reused after a future multi-file generation/commit protocol is designed. However pinned RecordStore must not call `markDirty()` or implement `flushRG35XX()` in RC1.

The coordinator was hardened so `forceFlush()` returns without starting its worker when no store has activated it. Therefore existing lifecycle barrier calls remain safe and effectively free on the synchronous baseline instead of creating an idle Java thread on ARM.

## Why separate per-file atomic replacement is insufficient

Replacing `<basename>.rms` atomically does not atomically commit the payload files. Replacing every payload separately still allows process termination or power loss between replacements, exposing metadata from one generation with payloads from another. RC1 will not claim crash consistency from such a scheme.

## Preserved semantics

Record IDs, tags, version increments, authentication/writable flags, suite/vendor naming, legacy conversion, binary payload layout and upstream file naming remain owned by RecordStore. No new RMS file format is introduced.

## Performance trade-off

The known downside is synchronous SD I/O at mutation sites. For RC1 this is accepted as a correctness-first baseline. Performance optimization must be a later explicit stage with a real multi-file commit/recovery protocol and device testing; it must not be smuggled into the first consolidated build.

## Gate result

RGJ-RC1-011C = STATIC-AUDIT-PASS. The RMS architecture is now internally consistent with the pinned upstream format and cannot accidentally apply the obsolete single-target atomic assumption. Consolidated Java compilation and real RG35XX save/reopen/game-switch testing remain required before BUILD-PASS/DEVICE-TEST-PASS.
