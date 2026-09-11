# VC7R15 — LCD Mask Gate Fix

## Evidence

VC7R14 device logs proved the GameCanvas buffer reaches `MobilePlatform.flushGraphics()` and the frontbuffer is the same buffer later serialized by VC7R12. However, the first frontbuffer sample changed to `0xFF77EF5A`, matching FreeJ2ME's default green LCD mask color.

Pinned upstream `Mobile.java` defines:

- `lcdMaskColors[1] = 0xFF77EF5A`
- `maskIndex = 1`
- `renderLCDMask = false`

Pinned upstream `PlatformGraphics.flushGraphics()` nevertheless used:

`fastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;`

and its slow path always ANDed source pixels with `Mobile.lcdMaskColors[Mobile.maskIndex]`.

Therefore the disabled LCD-mask flag was not honored: default `maskIndex=1` could tint a normal libretro frame green even when `renderLCDMask=false`.

## VC7R15 fix

Surgical Java-only correction in `PlatformGraphics.flushGraphics()`:

1. Restore the intended fast-path gate:
   `(!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled`
2. In the slow path, apply `lcdMaskColors[maskIndex]` only when `renderLCDMask` is true; otherwise use `0xFFFFFFFF`.
3. Add diagnostic marker `RG35XX-VC7R15-LCD-MASK` reporting render flag, mask index/color, FunLights and selected fast path.

## Preserved invariants

- VC7R14 GameCanvas flush probe preserved.
- VC7R13 full-screen composition probe preserved.
- VC7R12 canonical framebuffer binding preserved.
- VC7R11 graphics state probe preserved.
- VC7R10 ImageIO normalization preserved.
- VC7R9 image blit probe preserved.
- VC7R2 dynamic logical resolution preserved.
- Native VC7R9 core unchanged.
- JamVM L unchanged.
- GNU Classpath/glibj immutable.
- Audio unchanged.
- Font remains RECONSTRUCTED-NOT-GOLDEN.

## Acceptance

Device test should show `RG35XX-VC7R15-LCD-MASK: render=false maskIndex=1 maskColor=ff77ef5a ... fastBlit=true` and remove the global green tint from KDTT. This is not a production DEVICE-PASS until tested on-device.
