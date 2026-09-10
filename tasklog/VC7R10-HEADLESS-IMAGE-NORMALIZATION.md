# VC7R10 — Headless decoded-image normalization

Status: SOURCE-PATCHED / BUILD-PENDING / DEVICE-TEST-PENDING

## Evidence from VC7R9 device logs

VC7R9 showed that the Java framebuffer and RGB565 encoder were internally consistent: ARGB `FF77EF5A` encoded to RGB565 `776B`, and native received/presented the same `776B`. The native five-color reference strip was visually correct on device, so the final RGB565 path must not be changed.

The new VC7R9 image-blit probe then showed major source images already arriving at `PlatformGraphics.drawImage()` as uniform opaque black. Examples include repeated `128x128` sources with `alpha255=256`, `varying=0`, and all sampled source pixels equal to `FF000000`. Smaller `drawRegion(0)` sources sometimes contain variation, proving the blitter itself can receive non-uniform source data.

This moves the primary suspect upstream of `drawImage()` into decoded-image normalization.

## Pinned upstream behavior

Pinned FreeJ2ME `PlatformImage` uses `ImageIO.read(...)`. If the returned `BufferedImage` is not `TYPE_INT_ARGB` or `TYPE_INT_RGB`, it normalizes it by creating a new ARGB image and executing:

```java
canvas.getGraphics().drawImage(image, 0, 0, null);
```

That conversion enters GNU Classpath headless Graphics2D. Earlier project tasklogs already established that the target Graphics2D/headless implementation has compatibility failures. VC7R9 now provides device evidence consistent with this conversion silently producing black pixel data.

## VC7R10 change

`vc7r10_apply_headless_image_normalize.py` replaces only the three decoded-image normalization sites in `PlatformImage`.

For already-native `TYPE_INT_ARGB` / `TYPE_INT_RGB`, the decoded image is returned unchanged.

For every other decoded image type, VC7R10 performs:

```text
ImageIO decoded BufferedImage
  -> BufferedImage.getRGB(...)
  -> TYPE_INT_ARGB destination DataBufferInt
  -> System.arraycopy
```

No Graphics2D rasterization is used for decoded-image normalization.

A dedicated versioned diagnostic log is written to:

```text
/mnt/mmc/freej2me-vc7r10-java.log
```

Expected markers:

```text
RG35XX-VC7R10-IMAGE-NORMALIZE: passthrough ...
RG35XX-VC7R10-IMAGE-NORMALIZE: direct-getRGB ...
```

The direct-getRGB marker records source type and first/middle/last decoded ARGB samples.

## Scope lock

Preserve unchanged:

- JamVM L
- GNU Classpath / `glibj.zip` immutable B2
- VC7R2 dynamic logical LCD
- VC7R3 native audio
- VC7R4/native RGB565 reference architecture
- VC7R5 Java RGB565 encoder
- VC7R7 patch 0007 drawRGB
- VC7R8 patch 0008 transform cache
- PNG iCCP sanitizer
- reconstructed font status (NOT Golden)

Do not change RGB565 format, pitch, byte order, Smart-Fit, backlight, CV/CW boot resolution, or GNU Classpath.

## Acceptance

BUILD-PASS requires Java 6 class major 50, exact scope gate, and no remaining `canvas.getGraphics().drawImage(image, 0, 0, null)` in the three decoded-image normalization sites.

DEVICE evidence should show at least one `direct-getRGB` source with non-black/varied samples for a game whose VC7R9 source was uniform black, followed by visible game graphics restoration. Until that evidence exists, VC7R10 is not DEVICE-PASS and not Golden production.
