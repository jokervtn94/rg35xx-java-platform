# DP-R2 Image -> Sprite r1.5 A/B

## Mandatory preflight

CURRENT_SYMPTOM:
- DP-R1 standalone foundation has reproduced Canvas and GameCanvas on real RG35XX.
- Historical M1.14 font matrix, M1.15 RMS lifecycle/persistence, and M1.16-r1.2 blank PlatformImage dimensions are already device-proven scoped.
- The first unresolved boundary is Image -> Sprite isolation.
- Historical r1.4 reached mutable Image -> Sprite and copied Image -> Sprite, but createRGBImage() still entered java.awt.image.BufferedImage -> GtkToolkit and failed because libgtkpeer.so is absent on RG35XX.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- M1.16-r1.2: headless blank PlatformImage width/height fallback, DEVICE-PASS scoped.
- M1.16-r1.4: headless LCDUI Image copy backing, DEVICE-EVIDENCE for the copy boundary.
- Historical r1.5 source patch exists for headless createRGBImage backing but has no admitted real-device result.

PREVIOUS_EVIDENCE_LEVEL:
- DP-R1 Canvas/GameCanvas: DEVICE-PASS on the current clean rebuild.
- M1.14/M1.15/M1.16-r1.2: historical DEVICE-PASS scoped.
- r1.4 copy boundary: DEVICE-EVIDENCE, not global DEVICE-PASS.
- r1.5 createRGBImage patch: UNVERIFIED until this checkpoint.

REGRESSION_RISK:
- High if Sprite, renderer, font, RMS, audio, input, SDL presenter, JamVM, glibj, or GNU Classpath are changed together.
- This checkpoint therefore permits PlatformImage.class as the only Java runtime class whose byte content may change relative to DP-R1.

MINIMAL_PROPOSED_CHANGE:
1. Rebuild the exact DP-R1 pinned foundation.
2. Apply historical r1.4 PlatformImage LCDUI-copy headless patch as prior device-evidenced prerequisite.
3. Apply historical r1.5 PlatformImage createRGBImage headless backing patch as the ONE new primary variable.
4. Do not modify Sprite implementation, renderer, input, SDL1 presenter, font, RMS, audio, JamVM, or glibj.
5. Build an isolated Image -> Sprite diagnostic and GarlicOS top-level launcher.

EXPECTED_DEVICE_TEST:
- A_MUTABLE Sprite constructor PASS.
- B_COPY Sprite constructor PASS.
- C_RGB createRGBImage + Sprite constructor PASS.
- No GtkToolkit/libgtkpeer error.
- JamVM exit 0.
- JamVM/glibj hashes unchanged.
- Normal return to GarlicOS; no hard reset.

## Status before device test

BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
