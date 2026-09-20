# B4-VIDEO-MASK-R1-AB — Restore device-proven no-mask semantics

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TEST-PENDING
Primary variable: PLATFORMGRAPHICS_LCD_MASK_GATE_ONLY

## Current device evidence

Current GarlicOS baseline is exactly B4:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- B4 runtime: e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed

The device shows the historical global green tint.

## History

VC7R15 isolated the tint to pinned FreeJ2ME PlatformGraphics.flushGraphics():
- renderLCDMask=false
- maskIndex defaults to 1
- lcdMaskColors[1] = 0xFF77EF5A
- the pinned fastBlit expression ignored renderLCDMask
- slow path also always ANDed pixels with lcdMaskColors[maskIndex]

Project rules classify the no-mask green-tint fix as DEVICE-PASS for the green-tint symptom.

## Minimal delta

Apply only scripts/vc7r15_apply_lcd_mask_gate_fix.py to the freshly assembled B4 Java runtime.

Preserve unchanged:
- B4 native core binary on the SD
- JamVM L
- GNU Classpath
- Lazy Media boot
- Golden RGB565 receiver/presenter
- audio implementation
- font
- resolution behavior
- game JARs

Do not apply VC7R22 hot-path cleanup in this checkpoint. The current device also shows heavy per-frame diagnostics, but that is a separate primary variable and will be tested only after R1 mask behavior is confirmed.

## Device acceptance

1. Installer must fail closed unless current SD is exact B4 baseline.
2. Same affected game is launched directly from GarlicOS Roms/JAVA.
3. Global green tint is absent.
4. Core/JamVM/glibj hashes remain unchanged.
5. No new hard hang/reset regression is introduced.

BUILD-PASS does not imply DEVICE-PASS.
