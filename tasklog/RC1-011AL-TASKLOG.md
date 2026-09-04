# RC1-011AL — 0016 launch-argv zero-context rebase

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0016-libretro-java-audio-fd-exact.patch`
- Trigger evidence: consolidated run `33871364749` rejected only 0016 hunk #4 under `--fuzz=0`; patch-integration run `33871364778` applied the same hunk only with `fuzz 1` at line 856.
- Exact pinned source: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`, `src/libretro/freej2me_libretro.c`; launch argument block old lines 854–869.
- Decision: preserve 0016 JVM selector/audio-FD semantics and replace the context-sensitive launch-argument hunk with zero-context operations: insert Linux argv after its `params[0]`, insert Windows argv after its `params[0]`, then delete the six legacy common argv assignments.
- Invariants preserved: `NUM_ARGUMENTS=9`; Linux `-Dfreej2me.rg35xx=true` precedes optional `-Dfreej2me.rg35xx.audio.fd=N` and `-jar`; Windows behavior retains ordinary `-jar` launch; stdout remains video IPC only; audio uses dedicated inherited FD; no lifecycle ownership changes.
- No BUILD-PASS claim. Strict consolidated assembly and ARM/Java compile evidence remain required.
