# RGJ-RC1-011BL — Direct-device MIDlet build evidence

- Action: AUDIT
- Status: STATIC-AUDIT-PASS
- Source task: RGJ-RC1-011BK.
- Runtime API used for compilation: accepted RC1 `freej2me_plus-lr.jar` from build artifact `9940954185`.
- Main diagnostic JAR: `RG35XX_RC1_Device_Test.jar`.
- Main JAR SHA-256: `0ec90c9cba4343789ee9bb1a034ef4b3061230a6c1047129162628ebbe31ee9e`.
- Switch probe JAR: `RG35XX_RC1_Switch_Probe.jar`.
- Switch probe SHA-256: `c1a9bd2fbb6cbb5ec90cbf5da31702f58c2421fd4dcf4e97ac6ab99ad0690aa3`.
- Both MIDlets compiled successfully against the accepted runtime API after correcting the exact FreeJ2ME `Canvas` override visibility (`keyPressed/keyReleased/keyRepeated` are public in the accepted runtime).
- Both generated JARs contain Java 6-compatible classfile major version 50.
- Bytecode audit found no `InvokeDynamic`, `MethodHandle`, or `MethodType` constant-pool dependency in the main diagnostic class.
- Main JAR embeds deterministic self-test fixtures: 8 kHz PCM16 mono WAV, standard MIDI file, indexed PNG with `tRNS`, and asymmetric RGBA sprite PNG.
- Direct device deployment path: `/mnt/mmc/Roms/JAVA`; normal execution is by selecting the JAR from the RG35XX Java menu, not by entering a shell command.
- Game-switch procedure uses the two independent MIDlets A/B through the normal device UI.
- Limitation: after committing source/builder, the current container could not re-download raw GitHub files because outbound DNS was unavailable, so no separate post-commit repository-download rebuild is claimed in this task. The committed sources were derived from the source that produced the audited artifacts, and `device-tests/build.sh` was added for reproducible follow-up build verification.
- DEVICE-TEST-PASS is not claimed. Real RG35XX observation remains mandatory.