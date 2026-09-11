# VC7R12 — Canonical Framebuffer Binding Fix

VC7R11 device evidence showed that `PlatformGraphics` could render into one backing `int[]` while `RG35XXGoldenFrameTransport.requestFrame()` serialized another backing `int[]` after the JAR load lifecycle.

VC7R12 fixes only that ownership mismatch. Every transport request now fetches the current LCD `PlatformImage` and its backing `int[]` together and passes that exact pair to the Golden frame transport. The VC7R2 same-size `after-load` path also rebinds the legacy `lcdData` field so it cannot remain attached to a pre-load frontbuffer.

This checkpoint does not change native RGB565, Smart-Fit, JamVM, GNU Classpath, PNG compatibility, image normalization, drawRGB/transform patches, audio, or the font resource.

Build acceptance requires Java major 50 and source gates proving no transport call still uses cached `lcdData` with a separately fetched frontbuffer object. Device acceptance requires VC7R12 request `dataId` and VC7R11 transport `dataId` to agree, followed by visual confirmation.
