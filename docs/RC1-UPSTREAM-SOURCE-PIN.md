# RC1 Upstream Source Pin

Status: STATIC-AUDIT-PASS (source-basis control only; not BUILD-PASS)

## Authoritative upstream basis

RC1 source consolidation is pinned to:

- Repository: `TASEmulators/freej2me-plus`
- Branch of origin: `devel`
- Commit: `13ec186903087156c145268f8706eecfaf9f1e50`
- Upstream tree: `ad47ab16e9025f0eb3d2067bc3b1897dc71987df`
- Pin observed: 2026-09-03

All exact-source integration audits after this checkpoint must use this commit, not the moving `devel` branch. A future upstream refresh requires an explicit REBASE/REPLACE task and re-audit of every touched owner.

## Why this pin is mandatory

The moving upstream changed materially during RC1 work, including RecordStore and libretro/frontend ownership. Applying old overlay assumptions to a newer `devel` checkout can silently produce semantically wrong patches even when they compile.

The pinned `build.xml` remains a Java 1.6 source/target build. RC1 still requires a real `rm -rf build && ant` acceptance build after source assembly.

## Exact owners already sampled at this pin

- `src/org/recompile/mobile/PlatformFont.java`: upstream AWT/FontMetrics owner; historical project `RG35XXFontEngine` is not present upstream and remains unresolved.
- `src/javax/microedition/rms/RecordStore.java`: current upstream format is a JSON metadata `.rms` file plus per-record binary sibling files. It still imports `java.nio.file.Files` and still performs synchronous `saveRecordStore()` calls at mutation sites.
- `src/libretro/freej2me_libretro.c`: remains the single native core integration owner; RC1 must not create a parallel core entrypoint.

## Gate

No patch may be called exact-source-integrated merely because its design matches an older upstream snapshot. It must be reconciled against this pin or explicitly superseded.
