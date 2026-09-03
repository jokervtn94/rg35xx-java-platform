# RGJ-RC1-011F — Consolidated Prebuild Source Gate

Status: STATIC-AUDIT-PASS for project-source policy. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: MODIFY / ADD / AUDIT.

Mandatory reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, current `docs/PLATFORM-SOURCE-REGISTRY.md`, dependency gate/verifier, native tree, patch tree and the current integration manifest.

## Purpose

Replace the stale first RC1 integration manifest with one source policy that reflects all pin-era decisions through 011E, then add a fail-closed prebuild checker so the project cannot drift back to superseded Font/RMS/dirty-frame/dependency assumptions.

## Manifest reconciliation

`docs/RC1-INTEGRATION-MANIFEST.md` now pins FreeJ2ME-Plus at `13ec186903087156c145268f8706eecfaf9f1e50` and defines G1-G14.

Important superseded assumptions removed from build policy:

- `RG35XXFontEngine` is no longer a required class; 011D gives backend ownership to the GNU Classpath headless FontPeer path.
- pinned RecordStore uses the safe synchronous multi-file baseline from 011C; old patch 0009 is not the RC1 persistence implementation.
- dirty-frame scheduling cannot block the sole LibretroIO parser.
- TML/TSF provenance uses the corrected authoritative blob identities from 011E.
- the complete native module set now includes media events/queue, TSF worker/implementation, SoundFont source and media runtime.

## Prebuild checker

Added `scripts/rc1_prebuild_gate.sh` with two modes.

`--project-static` checks current project-owned control docs, Java classes, native modules, sole TML/TSF implementation ownership, pin-era patch contracts and dependency-control scripts. It also fails if the superseded `RG35XXFontEngine.java` is silently reintroduced.

`--build-ready` adds hard external requirements:

- exact FreeJ2ME checkout at the pinned commit;
- exact vendored TML/TSF headers passing offline verification;
- GNU Classpath 0.99 HeadlessToolkit source root;
- explicit non-empty authoritative SoundFont file;
- required pinned upstream integration targets.

The checker does not run `ant` or the cross compiler and cannot grant BUILD-PASS. Its successful build-ready result only authorizes an assembled build attempt.

## Audit correction during implementation

Initial checker draft referred to a non-existent `0021-pinned-recordstore-safe-baseline.patch`. Patch-tree audit found the actual authoritative filename is `0021-pinned-rms-safe-baseline.patch`; the checker was corrected before this task was closed. This is recorded to prevent the wrong filename from reappearing in later assembly scripts.

## Remaining hard blockers before first build

1. physical exact TML/TSF headers are not yet committed/materialized in the project tree;
2. authoritative SoundFont asset/provider is unresolved;
3. GNU Classpath 0.99 source + font-resource implementation from 011D must be included in the reproducible assembly;
4. all integration contracts must be applied/accounted for in one pinned FreeJ2ME source tree;
5. consolidated native Makefile/include/link ownership still requires final assembly audit.

Gate result: STATIC-AUDIT-PASS for the consolidated manifest and fail-closed prebuild policy only.