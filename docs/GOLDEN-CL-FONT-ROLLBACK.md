# Golden CL — Font rollback after CK regression

Device evidence from CK showed that the Unicode resource loaded successfully (`RG35XX-FONT: metric Unicode renderer ready bytes=727008`) while all visible glyphs disappeared. This rules out a missing `rg35xx-font.bin` resource.

Bytecode comparison between the device-proven Golden runtime and CK isolated the regression: CK replaced `PlatformGraphics.rg35xxDrawSafeText(String,int,int,int)` with a call to `RG35XXMetricUnicodeText.draw(...)`. The remaining Golden font helpers were otherwise still present.

CL therefore uses a deliberately narrow recovery:

- preserve CK media changes, including the `playTone` native path that returned PASS on device;
- restore the exact `PlatformGraphics.class` from the device-proven Golden `freej2me-lr.jar`;
- remove the CK-only `RG35XXMetricUnicodeText.class` override;
- do not change G1 receiver-thread video, RGB565, Smart-Fit, input or RMS paths;
- do not attempt to solve footer/text overlap by scaling glyph raster dimensions.

Golden renderer invariants restored by CL:

- classpath resource `/org/recompile/mobile/rg35xx-font.bin`;
- 727008-byte Unicode bitmap resource;
- 16 source rows per glyph;
- normal advance 8, wide advance 12;
- scale 1/2 based on active font height;
- anchor handling remains inside `PlatformGraphics`;
- direct canvas rasterization obeys translation, clip and canvas bounds.

## Acceptance

1. Text on page 4/9 must become visible again.
2. Graphics page must remain unchanged.
3. `MEDIA_PLAYTONE` must remain PASS.
4. Any remaining footer overlap is handled later at anchor/baseline/clip/layout level, not by modifying the Golden glyph raster contract.
5. WAV/MIDI/ToneControl testing resumes only after text is visible enough to navigate the test JAR.
