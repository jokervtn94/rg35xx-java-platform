# RGJ-RC1-011BV — Force GNU Classpath HeadlessToolkit on RG35XX boot

- Action: FIX / BOOT-BASELINE / DEVICE RETEST
- Status: IMPLEMENTED
- Trigger: after 011BU fixed the JamVM executable path, real-device stderr reached FreeJ2ME startup but failed before MIDlet start with `java.awt.AWTError: Cannot load AWT toolkit: gnu.java.awt.peer.gtk.GtkToolkit` and missing `libgtkpeer.so`.
- Evidence-derived scope:
  - the RG35XX JamVM runtime already boots GNU Classpath from `/mnt/mmc/CFW/java/share/classpath/glibj.zip`;
  - the project must not add GTK as a target dependency;
  - GNU Classpath 0.99 contains `gnu.java.awt.peer.headless.HeadlessToolkit`;
  - this task tests the smallest reversible boot fix before any PlatformFont rewrite: supply `-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit` only on the Linux/RG35XX JVM argv path.
- Required argv ordering:
  1. argv0 `java` (exec target remains absolute JamVM from 011BU)
  2. `-Dfreej2me.rg35xx=true`
  3. `-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit`
  4. optional `-Dfreej2me.rg35xx.audio.fd=<fd>`
  5. `-jar ...`
- Safety:
  - desktop/Windows argv remains upstream behavior;
  - stdout remains binary video IPC;
  - stderr remains persistent diagnostics from 011BR;
  - no GTK libraries are packaged;
  - no claim that the full Unicode font path is solved by this task.
- Device decision after rebuild:
  - if the previous `GtkToolkit/libgtkpeer.so` failure disappears and Boot Probe reaches `startApp()`, retain the flag as the RG35XX baseline and continue font rendering validation;
  - if HeadlessToolkit itself fails or metrics/rendering remain unusable, move to an AWT-independent RG35XX PlatformFont renderer based on the proven historical bitmap/VN/Unicode baseline.
- This task does not imply DEVICE-TEST-PASS.
