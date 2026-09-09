# B5 — Canonical SD Staging

Status: `SOURCE/GATE COMMITTED — STAGING/DEVICE ACCEPTANCE PENDING`

## Purpose

B5 converts the verified-clean foundation into one canonical SD-card filesystem tree. It does not modify a mounted RG35XX card. B6 will consume this tree to implement backup, install, verify, restore, and evidence collection.

## Locked payloads

- JamVM L Production: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath baseline `glibj.zip`: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- B4 runtime JAR file: `e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed`
- B4 core: `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`
- B3 deterministic runtime content identity: `52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783`
- FreeJ2ME source pin: `13ec186903087156c145268f8706eecfaf9f1e50`
- ARM uClibc toolchain image digest: `sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

## Canonical targets

B5 stages exactly these nine targets:

1. `CFW/java/bin/jamvm`
2. `CFW/java/share/classpath/glibj.zip`
3. `CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`
4. `CFW/retroarch/.retroarch/cores/freej2me_libretro.so`
5. `BIOS/freej2me-lr.jar`
6. `BIOS/freej2me_plus-lr.jar`
7. `CFW/java/share/freej2me/freej2me-lr.jar`
8. `CFW/retroarch/.retroarch/system/freej2me-lr.jar`
9. `CFW/retroarch/system/freej2me-lr.jar`

The two core aliases must be byte-identical. All five runtime aliases must be byte-identical. No compatibility experiment may be introduced by staging.

## Gate behavior

`scripts/b5_stage_canonical_sd_tree.sh` is fail-closed. It requires four explicit input files and verifies every source SHA before creating output. It then stages all aliases, applies only required file modes, writes `STATUS.txt`, writes a canonical target list, creates a SHA256 manifest excluding the manifest itself, and verifies that manifest before returning PASS.

The script never reads from or writes to `/mnt/mmc`; it only creates a disposable staging directory supplied through `B5_OUTPUT_DIR`.

## Foundation exclusions

B5 does not admit PNG ICC compatibility, CV/CW resolution changes, CK font scaling, audio rework, old RC/CJ stacks, JamVM diagnostics, or patched GNU Classpath.

The early-native log introduced by B4 remains `/mnt/mmc/freej2me-vc3-early.log` when the core later runs on-device.

## Acceptance rule

B5 can become `STAGING-PASS` after the canonical tree is generated from the exact four locked payloads and its manifest verifies. It cannot become `DEVICE-PASS`; device acceptance belongs to the complete B6 atomic installer/foundation package running on real RG35XX hardware.
