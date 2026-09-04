# RGJ-RC1-011BQ — Fail-safe direct-device diagnostic boot/logging

- Action: MODIFY / AUDIT
- Status: IMPLEMENTED
- Trigger: real RG35XX observation reported the diagnostic MIDlet opened to a black screen and produced no accessible log file.
- Scope: harden `device-tests/RG35XXDeviceTest.java` only; no production media/input/graphics/RMS implementation semantics are changed by this task.
- Required behavior:
  - first visible frame must not depend on Font, RMS, PNG, Sprite, MMAPI, or other optional subsystem initialization;
  - subsystem initialization is deferred until after the MIDlet is made current;
  - all startup/paint/subsystem failures are caught at the diagnostic boundary and appended to `/mnt/mmc/Java/test-evidence/rg35xx-device-test.log` using ordinary `java.io` available on the JamVM/GNU Classpath host;
  - if normal text rendering fails, the diagnostic canvas must paint a primitive red failure screen rather than remain black;
  - successful boot paints a primitive boot indicator before entering the normal test pages;
  - log write failure must never crash the test MIDlet;
  - existing direct-test functionality and SUMMARY page remain, but are secondary to boot visibility and failure capture.
- Device-test policy: this diagnostic hardening does not imply DEVICE-TEST-PASS.
- Follow-up: rebuild the MIDlet against the accepted RC1 runtime API, lock the new JAR hash, update package/install hash gates, then ask for the generated device log if any test still fails.
