# RGJ-RC1-011BI — Exact RG35XX device install map

- Action: MODIFY / ADD
- Status: IMPLEMENTED
- Basis: previously captured real-device logs for this RG35XX installation.
- Confirmed runtime paths:
  - RetroArch: `/mnt/mmc/CFW/retroarch/retroarch`
  - libretro core: `/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`
  - JamVM: `/mnt/mmc/CFW/java/bin/jamvm`
  - FreeJ2ME runtime JAR: `/mnt/mmc/BIOS/freej2me-lr.jar`
  - Java game directory: `/mnt/mmc/Roms/JAVA`
  - DejaVu runtime font: `/mnt/mmc/Java/runtime/DejaVuSans.ttf`
  - GeneralUser SoundFont: `/mnt/mmc/Java/runtime/GeneralUser-GS.sf2`
- Decision: replace the previous intentionally-generic device package install map with the exact paths already proven by this device's logs.
- Add a device-side installer that verifies the accepted BUILD-PASS payload hashes before replacement and preserves one pre-RC1 backup of existing core/JAR/runtime assets when present.
- Preserve: no firmware-wide modification, no launcher replacement, no game JAR redistribution, no DEVICE-TEST-PASS claim.
- Accepted build identity remains source commit `086d4987c0d60b5eb9abc3887e73638b24a1b964`, run `33883673553`, artifact `9940954185`.
- Rollback: restore the `.pre-rc1` backups created by the installer or manually replace only the four deployed payload files.
