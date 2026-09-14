# From-Zero Foundation v1 — real-device acceptance result 2026-09-14

## Result

**FOUNDATION DEVICE-PASS: NO**  
**STABLE: NO**

The atomic installer completed successfully on the user's RG35XX SD and all pinned dependency/payload hashes matched. Real-device testing then exposed remaining compatibility failures.

## Exact installed checkpoint

- Workflow run: `34794581294`
- Artifact ID: `10328848388`
- Artifact ZIP SHA256: `a2bc71d6ca59313b330bca4fc720d93bbdfa176c574d80614f407095dc413fe7`
- Runtime SHA256: `a3c15f55088ee0940f9133c36d2df869edcc35dc0c60de2a2451c170b09acb22`
- Native core SHA256: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`
- JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Installer result was `INSTALL-PASS_DEVICE-TEST-PENDING`.

## Device evidence

### Passed / preserved

- Native Java process startup succeeds.
- Lazy Media Boot marker is present.
- 320x240 KDTT frame geometry reaches the native transport correctly.
- 240x320 NinjaSchool and Real Football frame geometry reaches the native transport correctly.
- RGB565 async transport publishes and presents frames.
- Smart-Fit centers 240x320 as 360x480 in 640x480 output.
- 320x240 presents as 640x480.

### Failed

1. **Green-tint / green-screen regression remains in affected games.**
   Real Football 2015 reproduces a strongly green scene on-device.

2. **Font path is not acceptable.**
   - KDTT: `ArrayIndexOutOfBoundsException` in GNU Classpath compound TrueType glyph loading (`Zone.combineWithSubGlyph` / `GlyphLoader`).
   - NinjaSchool: repeated `NullPointerException` in GNU Classpath scanline glyph rendering.

3. **Audio remains unimplemented for the required RG35XX path.**
   - `LineUnavailableException: no Clip available`
   - `NoSuchMethodError: getSequencer`

4. A separate malformed JAR manifest case (`ninja-school-4-crack.jar`) fails before first frame and is not treated as a foundation rendering regression.

## Green-tint investigation decision

Do **not** modify RGB565 byte order, native pitch, Smart-Fit, dynamic logical resolution, JamVM, or glibj. Device evidence shows those paths continue operating.

Historical VC7R15 evidence established that FreeJ2ME's LCD/backlight mask color `0xFF77EF5A` can tint the framebuffer when `Mobile.renderLCDMask` becomes true. Foundation v1 correctly honors the flag but does not prevent a game/API from enabling it later.

Therefore the next experiment is an isolated runtime-only A/B:

- preserve the exact Foundation v1 native core;
- preserve JamVM L and glibj;
- preserve audio/font/transparency as-is;
- suppress LCD/backlight mask application only in `PlatformGraphics.flushGraphics()`;
- retain FunLights overlay behavior;
- emit one bounded diagnostic if a title attempts to enable the mask.

This A/B is **not admitted** into the device-proven manifest unless it removes the green regression on the real device without breaking a known-normal title.

## Legacy log filename

The current exact Foundation v1 core writes B4 lifecycle evidence to the stale filename `freej2me-vc3-early.log`. Its contents are B4 markers; the filename does not mean VC3 code is running.

The filename should be changed to a neutral name in the next native-core checkpoint. It is intentionally not changed in the runtime-only green-tint A/B so the native binary remains byte-for-byte identical to the tested Foundation v1 core.
