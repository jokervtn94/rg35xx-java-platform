# RGJ-RC1-011BN — Copy-to-SD overlay package

- Action: ADD
- Status: IMPLEMENTED
- Scope: deployment/package layout only; no runtime Java/native behavior change.
- Goal: provide a single archive whose relative paths match the exact RG35XX SD-card tree so installation requires only extracting/merging at the SD-card root.
- Overlay paths:
  - `CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so`
  - `BIOS/freej2me-lr.jar`
  - `Java/runtime/DejaVuSans.ttf`
  - `Java/runtime/GeneralUser-GS.sf2`
  - `Roms/JAVA/RG35XX_RC1_Device_Test.jar`
  - `Roms/JAVA/RG35XX_RC1_Switch_Probe.jar`
- JamVM remains the existing `/mnt/mmc/CFW/java/bin/jamvm`; this task does not replace or repackage it.
- Accepted hashes remain mandatory for core/runtime JAR and direct-test JARs. Font/SoundFont are included only if exact pinned bytes are available; no substitute assets are permitted.
- Package carries a SHA-256 manifest and a Vietnamese copy-to-SD guide.
- After merge, tests are launched through the normal RG35XX Java menu; no terminal command is required to run them.
- DEVICE-TEST-PASS is not implied; real-device execution remains mandatory.