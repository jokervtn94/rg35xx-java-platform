# RGJ-RC1-011BU — Absolute JamVM launcher on RG35XX

- Action: FIX / BUILD / DEVICE RETEST
- Status: IMPLEMENTED
- Trigger: real-device `/mnt/mmc/Java/freej2me-java.log` proved the core reached `javaOpen()`, forked successfully, then failed at `execvp("java", ...)` with `errno=2 (No such file or directory)`.
- Root cause: the RG35XX firmware does not expose a `java` executable through the PATH inherited by RetroArch. The validated JamVM executable is `/mnt/mmc/CFW/java/bin/jamvm`.
- Fix ownership:
  - keep 0023 immutable as stderr/process diagnostics;
  - add 0024 after 0023;
  - on Linux/RG35XX execute `/mnt/mmc/CFW/java/bin/jamvm` with `execv()` instead of PATH-dependent `execvp(cmd, params)`;
  - preserve the existing argument vector and stdout binary video IPC;
  - write the selected absolute JamVM path and any `execv()` failure to the existing persistent stderr log.
- Assembly gates:
  - assembled source must contain `/mnt/mmc/CFW/java/bin/jamvm`;
  - assembled source must contain `execv(rg35xx_jamvm_path, params)`;
  - assembled source must not contain active `execvp(cmd, params)` in the Linux child launch path.
- Device success criterion for this task only: the next `freej2me-java.log` must progress past the previous `execvp failed for java` boundary. This task alone does not imply DEVICE-TEST-PASS.
