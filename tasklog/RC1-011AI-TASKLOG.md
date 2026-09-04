# RC1-011AI — PlatformImage cache tail hunk exact-context rebase

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0011-platformimage-rg35xx-cache.patch`
- Source pin: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`, `src/org/recompile/mobile/PlatformImage.java`.
- Evidence: consolidated run `33866977690` failed zero-fuzz dry-run only at 0011 hunk #2, while hunk #1 passed.
- Exact pinned anchor: immutable byte-array constructor assigns `dataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();` at old line 203, followed by `isMutable = mutable;`.
- Decision: rebase only hunk #2 as a one-context-line insertion anchored on the exact `dataBuffer` assignment. Preserve the existing cache-store code and all decoder/constructor semantics.
- Constraint: do not weaken `--fuzz=0`, marker checks, cache eligibility, defensive-copy behavior, or lifecycle contracts.
- Success criterion: consolidated strict assembly passes 0011 and advances to the next active patch; this task alone does not authorize BUILD-PASS.
