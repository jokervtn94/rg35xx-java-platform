# RGJ-RC1-011BK — Direct RG35XX MIDlet diagnostics

- Action: ADD
- Status: PLANNED
- Scope: add a standalone Java ME diagnostic MIDlet under `device-tests/` that is launched from the normal RG35XX Java game menu. No terminal command is required for normal test execution.
- Non-overlap: this is test content only; it does not replace or duplicate platform runtime owners (`Manager`, `PlatformGraphics`, `RecordStore`, lifecycle, native media, libretro core).
- Required coverage inside the MIDlet: animated video, drawRGB alpha/clip, indexed PNG transparency (`tRNS`), drawRegion/Sprite transforms, font metrics/rendering, input press/release/repeat visibility, RMS create/write/reopen persistence marker, WAV, MIDI, ToneControl/Manager.playTone, and END_OF_MEDIA listener evidence.
- Device-only coverage that remains outside one MIDlet: ordinary switch between two separate JARs and final frontend/core process shutdown. These must be validated by exiting/selecting JARs through the RG35XX UI, never by claiming an automatic in-MIDlet proof.
- Build rule: diagnostic JAR must use only Java ME APIs present in the accepted `freej2me_plus-lr.jar` and must be emitted with Java 6-compatible classfile version 50. No proprietary game bytecode/assets are included.
- Acceptance: source compiles against the accepted runtime API, generated diagnostic resources are self-contained, JAR manifest exposes a valid MIDlet entry, classfiles are version 50 with no InvokeDynamic/MethodHandle constant-pool entries, and the output JAR is provided for `/mnt/mmc/Roms/JAVA` deployment.
- DEVICE-TEST-PASS is not implied by building this diagnostic JAR.