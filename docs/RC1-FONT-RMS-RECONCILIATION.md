# RC1 Font + RMS Reconciliation

Status: STATIC-AUDIT-PASS for reconciliation decisions only. This document does not claim implementation BUILD-PASS.

Source basis: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50` plus current RG35XX project registry and retained device logs.

## Font subsystem

### Current truth

The project registry names `RG35XXFontEngine` but the file has never existed in this repository history. Repository code search and path-specific commit history return no authoritative copy. Library/conversation retrieval also did not recover the historical Beta-2 source artifact.

Pinned upstream `PlatformFont` remains the real facade/metrics owner. It constructs `java.awt.Font`, obtains `FontMetrics` from a 1x1 `BufferedImage` Graphics object, and uses those metrics for widths/heights.

Retained RG35XX device logs prove that the previous runtime encountered `RG35XX-FONT: compound glyph failure; safe ASCII mode enabled` and advertised `font=bitmap-fallback`. Those logs prove a fallback existed on-device; they do not provide sufficient source to reconstruct its exact implementation or its historical Unicode bitmap resource.

### Decision

Do **not** recreate the missing historical `RG35XXFontEngine` from memory and do not silently add a small ASCII-only substitute. The old registry state `MISSING — RESTORE REQUIRED` remains a hard source gate.

The final integration owner remains upstream `PlatformFont`. When an authoritative bitmap resource/source is recovered, RG35XX behavior must be attached as a target adapter/fallback under that owner so metrics and raster advances stay unified. Until then the consolidated RC cannot claim the Font gate or DEVICE-TEST-PASS.

## RMS subsystem

### New pinned-source finding

The current pinned `RecordStore` no longer matches the earlier Beta-5 assumption of a single atomic RMS target. Its save representation is multi-file:

- `basename.rms`: JSON metadata, IDs, tags and ownership fields;
- `basename.<recordId>`: one binary sibling file per record.

Mutation paths still synchronously call `saveRecordStore()`. `closeRecordStore()` clears vectors after the last open handle. The source still imports `java.nio.file.Files`, which remains unsuitable as a required JamVM/GNU Classpath dependency.

### Consequence for the old Beta-5 design

`RG35XXRmsAtomicFile.write(file, snapshot)` can protect one file but cannot truthfully provide atomic replacement of the complete current multi-file RecordStore representation. Treating the old single-file policy as complete would risk metadata/data generation mismatch after interruption.

Therefore the old patch 0009 is retained as historical policy intent but is **not sufficient for exact-source integration at the RC1 pin**.

### Revised safe boundary

The RC must preserve upstream IDs/tags/version/auth/migration and current on-disk naming. Before asynchronous persistence is enabled, the target implementation must snapshot metadata plus every record blob as one logical generation and define recovery for interruption between sibling-file replacements and the metadata commit. If that recovery contract is not implemented and audited, RG35XX must retain synchronous upstream persistence rather than claim unsafe atomicity.

The low-priority coordinator may still own coalescing/lifecycle barriers, but `RG35XXRmsAtomicFile` alone is not a complete transaction owner for the pinned format.

## Stage result

This reconciliation prevents two unsafe shortcuts:

1. inventing the missing Font Engine from memory;
2. applying a single-file RMS atomicity model to a multi-file upstream format.

Both are now explicit source-consolidation gates rather than hidden assumptions.
