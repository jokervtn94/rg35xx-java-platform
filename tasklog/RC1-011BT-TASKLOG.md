# RGJ-RC1-011BT — Correct runtime JAR filename and multi-path menu compatibility

- Action: FIX / PACKAGE / DEVICE RETEST
- Status: IMPLEMENTED
- Trigger: black screen persisted with no process-level or MIDlet log files after 011BR/011BS.
- New evidence: the accepted diagnostic core binary contains the literal runtime filename `freej2me_plus-lr.jar`, while the recent SD overlay packaged the runtime only as `/mnt/mmc/BIOS/freej2me-lr.jar`.
- Fix:
  - package the accepted runtime JAR at `/mnt/mmc/BIOS/freej2me_plus-lr.jar` (authoritative name required by the new core);
  - also retain `/mnt/mmc/BIOS/freej2me-lr.jar` as a compatibility alias for older launcher/core variants;
  - package the diagnostic core as both `freej2me_plus_libretro.so` and `freej2me_libretro.so` in the standard RetroArch cores directory so menu variants using the old core basename still receive the same diagnostic build;
  - retain the minimal `RG35XX_RC1_Boot_Probe.jar` test content;
  - add Windows-side SD verification guidance so deployment can be checked without RG35XX shell commands.
- Diagnostic expectation:
  - if the menu reaches either diagnostic core alias, `/mnt/mmc/Java/freej2me-java.log` must be attempted before JamVM exec;
  - if JamVM reaches the MIDlet, `/mnt/mmc/Java/test-evidence/rg35xx-boot-probe.log` must be attempted.
- This task does not imply DEVICE-TEST-PASS.
