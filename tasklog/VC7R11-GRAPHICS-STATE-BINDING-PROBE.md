# VC7R11 — Graphics State / Framebuffer Binding Probe

Status: SOURCE-PATCHED / BUILD-PENDING / DEVICE-TEST-PENDING

## Evidence entering VC7R11

VC7R10 device evidence shows decoded images contain varied ARGB data, including full-size 320x240 images. VC7R9 shows software drawRGB/drawRegion can copy sampled pixels correctly for several sprites. Nevertheless the presented scene remains mostly black/green. Therefore VC7R11 does not change ImageIO, RGB565, native presentation, Smart-Fit, audio, drawRGB semantics, transform semantics, JamVM, or GNU Classpath.

## Probe question

Determine whether the Graphics object drawing scene content is bound to the same PlatformImage/int[] framebuffer that RG35XXGoldenFrameTransport sends to the native core, and whether clip/translation state yields a valid effective destination rectangle.

## Diagnostic fields

PlatformGraphics constructor/reset/drawRGB records:

- graphics object identity
- base PlatformImage identity
- BufferedImage identity
- backing int[] identity
- canvas width/height
- translate fields
- raw clip fields
- getClipX/Y/Width/Height values
- translated draw destination and size
- effective clipped rectangle
- source int[] identity, offset, scanlength, alpha mode

RG35XXGoldenFrameTransport requestFrame records the submitted framebuffer int[] identity and lock identity.

## Acceptance logic

- If PlatformGraphics `dataId` matches requestFrame `dataId` for the 320x240 display surface and effective rectangles are valid, canvas binding/clip state is not the primary blocker.
- If IDs diverge, locate the stale/offscreen PlatformImage lifecycle and fix binding rather than pixel conversion.
- If effective rectangles collapse or clip state is inconsistent, fix state semantics without touching RGB565/native transport.

VC7R11 is diagnostic-only. No DEVICE-PASS claim is permitted until real-device evidence is reviewed.
