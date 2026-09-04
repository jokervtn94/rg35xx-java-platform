# RGJ-RC1-011BR — JamVM process-level persistent stderr logging

- Action: MODIFY / REBUILD / DEVICE RETEST
- Status: IMPLEMENTATION
- Trigger: real RG35XX still shows black screen and no diagnostic file even after the device-test MIDlet was hardened in 011BQ.
- Root finding: pinned `freej2me_libretro.c::javaOpen()` redirects JamVM stdin/stdout for control/video IPC but does not persist child stderr. If JamVM or MIDlet bootstrap fails before `startApp()`, the JAR-level logger cannot run, leaving exactly black screen + no log.
- Owner: `patches/0016-libretro-java-audio-fd-exact.patch` remains the sole Linux Java-process spawn/argv owner.
- Required behavior:
  - open `/mnt/mmc/Java/freej2me-java.log` in append mode before `fork()`;
  - write a native pre-fork spawn marker so a file can exist even when fork/exec/bootstrap fails;
  - child redirects only fd 2 (stderr) to that file; stdout remains binary video IPC only;
  - child writes PID/exec marker and explicit errno text when `execvp()` fails;
  - parent closes its inherited log handle after fork;
  - log-open failure must not corrupt IPC or prevent normal process launch;
  - no text diagnostics may be written to stdout.
- Acceptance before device retest:
  1. zero-fuzz assembly PASS;
  2. Java and ARM compile/link PASS;
  3. assembled source contains persistent log path and stderr-only redirection;
  4. rebuilt core/JAR package is deployed with the hardened Device Test v3;
  5. DEVICE-TEST-PASS remains false until real hardware is observed.
