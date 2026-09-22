# RG35XX Clean R2D-TRANSPARENCY — PNG tRNS + conservative legacy white-key

Date: 2026-09-22
Base: exact installed R2A runtime
Primary variable: image transparency semantics only
Status: BUILD-PENDING / DEVICE-PENDING / STABLE=NO

## Trigger

R2A device evidence proves:
- image decode is reaching PlatformImage;
- no ImageIO read failure;
- PNG ICC v4 failure is gone;
- framebuffer ownership mismatch is zero;
- the user still observes transparent image backgrounds rendered as white.

Therefore the next image change is not another decoder replacement. It is alpha semantics.

## R2D delta

Preserve R2A direct getRGB normalization.

Add:
1. parse raw PNG metadata before GNU Classpath ImageIO;
2. capture standards-defined tRNS metadata;
3. apply exact palette/RGB/grayscale transparency after decode;
4. when there is no meaningful alpha and no tRNS, conservatively recognize only border-connected pure-white legacy sprite matte.

Never treat all white pixels as transparent.

## Scope lock

Unchanged:
- font/text raster remains exact R2A upstream AWT path;
- audio remains exact R2A JavaSound state;
- Canvas/serviceRepaints unchanged;
- native core/video unchanged;
- JamVM/glibj unchanged;
- R2A direct decoded-image normalization preserved;
- PNG iCCP sanitizer preserved;
- dynamic view/frame transport unchanged.

## Diagnostics

Bounded marker:
`RG35XX-R2C-TRANSPARENCY`

Fields:
- image size/type
- alpha0 count
- partial-alpha count
- tRNS present
- tRNS changed
- legacy white-key changed

## Device acceptance

Test the same JAR/image that visibly showed white instead of transparent background.

PASS:
- intended background becomes transparent;
- opaque white content is not globally erased;
- no new ImageIO error;
- no physical RGB565/color regression;
- screenshots collected for A/B comparison;
- no hard reset.

Known font/audio errors are expected to remain unchanged in this checkpoint.
