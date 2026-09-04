# RGJ-RC1-011BS — Minimal boot probe for black-screen isolation

- Action: ADD / PACKAGE / DEVICE RETEST
- Status: IMPLEMENTED
- Trigger: full diagnostic MIDlet remained black on real RG35XX; process-level stderr logging was added in 011BR.
- Goal: provide a minimal Java ME content probe that avoids Font, RMS, PNG, Sprite and MMAPI so the next device run isolates JVM/MIDlet/Canvas/frame IPC before testing higher subsystems.
- Probe behavior:
  - `startApp()` appends to `/mnt/mmc/Java/test-evidence/rg35xx-boot-probe.log`;
  - Canvas uses only primitive `setColor/fillRect` and alternates blue/green every 100 ms with a white progress bar and red corner marker;
  - render thread logs selected ticks and reported canvas size;
  - key presses are logged; key 0 exits;
  - no font rendering or media/RMS/resource loading is used.
- Packaging policy:
  - deploy the new 011BR core and matching runtime JAR from consolidated run 33904619868;
  - ensure `/mnt/mmc/Java` and `/mnt/mmc/Java/test-evidence` exist through overlay files;
  - deploy the probe as `/mnt/mmc/Roms/JAVA/RG35XX_RC1_Boot_Probe.jar`.
- Diagnostic decision tree after device run:
  1. no `/mnt/mmc/Java/freej2me-java.log`: launch path did not reach `javaOpen()` or Java filesystem path was unavailable;
  2. native log exists but no boot-probe log: JamVM/JAR bootstrap failed before MIDlet `startApp()`;
  3. both logs exist but screen black: graphics/frame IPC path is the primary suspect;
  4. colored animation visible: base JVM/MIDlet/Canvas/frame path passes and testing can advance to Device Test v3 subsystems.
- This task does not imply DEVICE-TEST-PASS.
