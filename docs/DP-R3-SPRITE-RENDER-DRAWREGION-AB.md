# DP-R3 Sprite Render / drawRegion A/B

## Mandatory preflight

CURRENT_SYMPTOM:
- DP-R2 Image -> Sprite constructor boundary is real-device PASS for mutable, copied, and createRGBImage sources.
- Sprite rendering itself is not yet admitted.
- Upstream Sprite.paint() calls Graphics.drawRegion().
- The pinned upstream PlatformGraphics.drawRegion() validates source bounds through image.getCanvas().getWidth()/getHeight().
- Headless PlatformImage intentionally avoids creating AWT BufferedImage/Toolkit backing, so this boundary may still dereference a null AWT canvas.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R2 r1.4+r1.5 headless PlatformImage backing is DEVICE-PASS scoped for Image -> Sprite construction.
- DP-R1 Canvas/GameCanvas and historical font/RMS/blank PlatformImage checkpoints remain protected.

PREVIOUS_EVIDENCE_LEVEL:
- DP-R2 Image -> Sprite constructor path: DEVICE-PASS_SCOPED.
- Sprite.paint()/drawRegion transform path: UNVERIFIED.

REGRESSION_RISK:
- High if Sprite implementation, transformed renderer, collision, TiledLayer, LayerManager, audio, input, SDL1, JamVM, glibj, or font are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact DP-R2 platform, no runtime change.
- B: change only PlatformGraphics.drawRegion source-bounds lookup from image.getCanvas().getWidth()/getHeight() to LCDUI image.getWidth()/getHeight().
- No Sprite implementation change.
- No drawTransformedImage algorithm change.
- No collision/TiledLayer/LayerManager/audio change.

EXPECTED_DEVICE_TEST:
- Run one diagnostic against A then B.
- Diagnostic paints an opaque six-color Sprite through all eight MIDP Sprite transforms into a headless mutable target.
- Each transform must return from Sprite.paint(), expose correct transformed width/height, and preserve all six source colors.
- If A fails and B passes, classify PATCH_CONFIRMED.
- If A already passes, classify BASELINE_ALREADY_PASS and do not promote the B patch merely because it also passes.
- Protected JamVM/glibj hashes must remain unchanged.
- Normal return to GarlicOS; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
