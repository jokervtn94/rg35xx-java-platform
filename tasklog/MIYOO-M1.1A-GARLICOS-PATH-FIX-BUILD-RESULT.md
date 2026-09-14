# MIYOO M1.1A GARLICOS PATH FIX — BUILD RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Commit SHA: cf8bff2841c49a22ff2a47057b32ef0874272123
Workflow: RG35XX Miyoo M1.1A GarlicOS Path Fix
Run ID: 34838826193
Job ID: 103958786253
Artifact ID: 10345805049
Artifact name: rg35xx-miyoo-m1.1a-garlicos-path-fix
Artifact digest / ZIP SHA256: 30e61cb7191d2e0bc00e4d8efafdd390c540a845b8cd4651c3c1b5a6c7ad1a41
Probe SHA256: 568e96e8264244dbd74f72d601bb3cad4487793c789bbc76f5016c8f499b3f77

## Required post-build report

- commit SHA: cf8bff2841c49a22ff2a47057b32ef0874272123
- workflow/run ID: 34838826193
- artifact ID: 10345805049
- artifact digest: 30e61cb7191d2e0bc00e4d8efafdd390c540a845b8cd4651c3c1b5a6c7ad1a41
- runtime SHA256: NOT BUILT / NOT MODIFIED
- core SHA256: NOT BUILT / NOT MODIFIED
- BUILD-PASS: YES, package/path-fix scope only
- DEVICE-PASS: NO, device retest pending
- STABLE: NO
- exact scope of change: packaging/launcher path only. Probe source, compile flags and resulting probe SHA256 are unchanged from M1.1. Files are placed directly in `Roms/APPS/` and the wrapper performs bounded known-location probe discovery.

## Device test

Copy `Roms/` to GarlicOS SD root and merge. Run `Apps -> M1.1A-DEVICE-TEST.sh`.
Return `/mnt/mmc/RG35XX-MIYOO-M1.1A-DEVICE-RESULT.txt`.

Pass criteria:
1. PROBE_RESOLUTION=PASS
2. probe SHA256 = 568e96e8264244dbd74f72d601bb3cad4487793c789bbc76f5016c8f499b3f77
3. SDL2_DLOPEN=PASS
4. SDL_INIT_0=PASS
5. M1_1_RESULT=PASS
6. PROBE_EXIT_CODE=0
7. locked fallback hashes before/after unchanged
