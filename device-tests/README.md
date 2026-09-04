# RG35XX RC1 direct device tests

This directory owns standalone Java ME test content only. It does not modify platform runtime behavior.

Normal device use requires no terminal command: place the built JARs in `/mnt/mmc/Roms/JAVA`, refresh/open the RG35XX Java game menu, then select `RG35XX RC1 Device Test` or `RG35XX RC1 Switch Probe` like ordinary Java games.

`RG35XXDeviceTest.java` covers animated presentation, drawRGB alpha, clipping, indexed PNG `tRNS`, drawRegion transforms, font metrics/rendering, input press/release/repeat visibility, RMS persistence, WAV, MIDI, ToneControl/Manager.playTone and END_OF_MEDIA listener evidence.

`RG35XXSwitchProbe.java` is a second independent MIDlet used to switch A <-> B from the normal RG35XX Java menu at least five times. It has a distinct screen, its own RMS counter and a tone trigger so stale input/image/audio state is easy to detect.

The current generated RC1 test JARs are built against the accepted `freej2me_plus-lr.jar` API and are emitted as Java 6 classfile major version 50. Building test content is not DEVICE-TEST-PASS; real RG35XX observation remains mandatory.