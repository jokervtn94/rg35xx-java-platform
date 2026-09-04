# RG35XX Java Platform — RC1-011BH Tasklog

## RGJ-RC1-011BH — Device-validation package assembly
- Action: ADD
- Status: IMPLEMENTED
- Scope: add a host-side packaging script and package layout document for real RG35XX validation.
- Reason: BUILD-PASS artifacts and required runtime assets currently exist as separate inputs; device validation needs one deterministic staging layout without introducing a launcher or changing runtime architecture.
- Inputs: BUILD-PASS core `freej2me_plus_libretro.so`, BUILD-PASS `freej2me_plus-lr.jar`, DejaVuSans.ttf SHA-256 `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`, GeneralUser-GS.sf2 SHA-256 `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`, and `scripts/rc1_device_evidence.sh`.
- Output policy: create a disposable directory/zip that mirrors `/mnt/mmc/Java/runtime` for runtime assets and keeps validation scripts/docs separate. Do not modify JARs, game files, RMS data, or firmware paths automatically.
- Validation: fail closed on missing inputs or mismatched runtime-asset hashes; record SHA-256 manifest for all staged payloads.
- Non-goal: no DEVICE-TEST-PASS claim, no launcher integration, no firmware-specific install automation, no proprietary game JAR inclusion.
- Rollback: remove only the new package script/document if a later deployment owner replaces them.
