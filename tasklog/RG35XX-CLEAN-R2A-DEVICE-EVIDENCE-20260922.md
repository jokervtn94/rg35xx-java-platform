# RG35XX Clean Consolidated R2A — Device Evidence 2026-09-22

Evidence archive:
`RG35XX-CLEAN-R2A-EVIDENCE-20260922-115120.zip`

## Installed identities

All five runtime aliases:
`5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`

Protected foundation:
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- B4 core: `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`

Install result: PASS.

## Sessions

Seven real-game sessions reached:
`CORE_INIT -> JAVA_READY -> LOAD_GAME -> IPC_RUN_SENT -> CORE_DEINIT`

Games:
1. Dragon Mania S40v6
2. Tan Tay Du Ky 3 320x240
3. Real Football 2015 240x320
4. NinjaSchool2
5. KDTT Tam Quoc Chi 320x240
6. Asphalt 4 240x320
7. Zombie Infection 240x320

No framebuffer ownership mismatch:
- FRAME_BIND_LINES=112
- FRAME_BIND_MISMATCH_TRUE=0

## R2A decoded image result

- R2A_IMAGE_NORMALIZE_COUNT=37
- PNG_ICCP_STRIP=2
- PNG_ICC_V4_ERRORS=0
- IMAGE_READ_FAILURES=0
- IMAGE_NULL_FAILURES=0

Conclusion:
R2A successfully moved image loading past the decode failure boundary. The user's remaining report that transparent/background images become white is therefore not a generic ImageIO read failure.

R2A markers also prove some decoded images contain meaningful alpha values (examples include pixels with alpha 0 and partial alpha), while other TYPE_CUSTOM images are returned as opaque white on sampled pixels.

Next transparency owner:
- preserve R2A direct getRGB normalization;
- recover standards-defined PNG tRNS metadata from raw PNG before GNU Classpath ImageIO;
- apply tRNS semantics after decode;
- if no alpha and no tRNS, optionally recognize only conservative border-connected pure-white legacy sprite matte;
- global white-as-transparent is forbidden.

## Font/AWT blocker

Evidence is severe and game-specific:

### Tan Tay Du Ky 3
- 336 `ArrayIndexOutOfBoundsException` occurrences.
- stack reaches:
  `Zone.combineWithSubGlyph -> GlyphLoader.loadCompoundGlyph -> TrueTypeScaler -> GNUGlyphVector -> AbstractGraphics2D.drawString -> PlatformGraphics.drawString`

### NinjaSchool2
- 23 `NullPointerException` / `AbstractGraphics2D.renderScanline` failures.
- stack reaches:
  `drawGlyphVector -> drawString -> PlatformGraphics.drawStringSingleLine`

### KDTT Tam Quoc Chi
- game thread terminates with `ArrayIndexOutOfBoundsException` at the same compound-glyph GNU Classpath path.

Conclusion:
The current upstream AWT/OpenType text rasterizer remains a P0 runtime blocker on JamVM/GNU Classpath and can directly explain stalls or game-thread termination in affected games.

Next font owner:
- bypass GNU AWT glyph rasterization in normal MIDP text;
- use direct framebuffer bitmap raster;
- use MIDP font metrics for advance/height to avoid the historical fixed-8-pixel layout mismatch;
- preserve translation, clip and anchor semantics;
- deterministic reconstructed Unicode resource may be used only as `RECONSTRUCTED-NOT-GOLDEN`.

## Audio blocker

Summary:
- GETSEQUENCER_ERRORS=2
- CLIP_ERRORS=2

Real Football 2015:
- `LineUnavailableException`
- `NoSuchMethodError: getSequencer`

Zombie Infection:
- `NoSuchMethodError: getSequencer`
- stack from `PlatformPlayer$midiPlayer.prefetch`

Conclusion:
Desktop JavaSound fallback is definitively invalid on this RG35XX/JamVM environment.

R2B native audio ownership reconstruction is now justified by device evidence.

## Screenshot evidence

Two collected KDTT screenshots are exactly 640x480 RGB and contain only two colors:
- pure black
- pure white

No intermediate/color pixels exist.
White occupies only the top ~37-40 rows; the remainder is black.

Because FRAME_BIND_MISMATCH_TRUE=0, current evidence does not support a Java frontbuffer ownership mismatch.
Screenshot/capture remains a separate frontend/native-presentation issue and is not yet attributed to MIDP image decode.

## Device classification

R2A:
- INSTALL-PASS=YES
- DECODE PATH ADVANCED=YES
- TRANSPARENCY PASS=NO
- FONT/AWT PASS=NO
- AUDIO PASS=NO
- FREEZE PASS=NO
- DEVICE-PASS=NO
- STABLE=NO

## Next integrated candidate

Build one user-facing candidate from R2A with independently gated owners:
1. R2C transparency semantics.
2. R2D direct metric bitmap Unicode font.
3. R2B native audio dedicated-FD worker-ring.

Do not change:
- Canvas/serviceRepaints semantics;
- RMS;
- native RGB565 presentation geometry;
- JamVM/glibj;
- dynamic logical view;
- R2A direct image normalization.

If freeze remains after removing the font/AWT crashes, only then advance Canvas/serviceRepaints diagnosis.
