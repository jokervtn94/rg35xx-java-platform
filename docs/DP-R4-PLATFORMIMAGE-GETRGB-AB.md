# DP-R4 PlatformImage getRGB A/B

CURRENT_SYMPTOM:
- DP-R3-B Sprite.paint/drawRegion is real-device PASS across all 8 transforms.
- Sprite pixel collision is still unverified.
- Sprite pixel collision calls Image.getRGB().
- PlatformImage.getRGB() still dereferences the AWT BufferedImage canvas.
- Headless RG35XX PlatformImage intentionally has no AWT canvas.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R2 admitted headless Image -> Sprite constructors.
- DP-R3-B admitted Sprite.paint()/drawRegion and transforms.

PREVIOUS_EVIDENCE_LEVEL:
- DP-R3-B: DEVICE-PASS_SCOPED.
- PlatformImage.getRGB headless path: UNVERIFIED.
- Sprite pixel collision: UNVERIFIED.

REGRESSION_RISK:
- High if collision math, Sprite transform math, TiledLayer, renderer, audio, input, SDL1, JamVM, glibj, or font are changed together.

MINIMAL_PROPOSED_CHANGE:
- A: exact DP-R3-B runtime.
- B: only PlatformImage.getRGB() gains a headless dataBuffer-backed path.
- Keep normal AWT behavior unchanged when canvas != null.
- Do not modify Sprite collision math yet.
- Diagnostic uses square 2x2 images so width/height-order issues remain outside this checkpoint.

EXPECTED_DEVICE_TEST:
- A should fail in PlatformImage.getRGB if the hypothesis is correct.
- B direct getRGB must return exact ARGB pixels.
- B Sprite-Sprite bounding and pixel collision must produce expected true/false results for square images.
- JamVM/glibj hashes unchanged.
- Normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
