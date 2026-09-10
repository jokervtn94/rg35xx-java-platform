# RG35XX VC7R9 — Java Image Blit Probe

Status: DIAGNOSTIC-BUILD-PENDING.

## Correction after VC7R8 visual evidence
The VC7R8 screenshots show the native 5-color strip itself correctly as BLACK | WHITE | RED | GREEN | BLUE. Therefore the final RGB565 pixel-format/pitch/frontend boundary remains accepted for diagnosis and VC7R9 MUST NOT mutate it.

VC7R5 already proved `ARGB=FF77EF5A -> direct565=776B -> encoded565=776B match=true`, and VC7R8 native logging proved `wire16=776B` remains `776B` at presentation. VC7R7 patch 0007 and VC7R8 patch 0008 did not restore full game graphics.

## VC7R9 purpose
Instrument the Java image source/blit boundary on top of the accepted VC7R8 source stack. Determine whether decoded `Image` pixel buffers are already wrong/empty/transparent, or whether valid source pixels fail to reach `canvasData` through `drawImage()` / `drawRegion(..., transform=0)`.

## Scope
KEEP unchanged:
- JamVM L
- immutable GNU Classpath / glibj.zip
- VC7R2 dynamic logical view
- VC7R3 native media bridge
- VC7R4 native RGB565 reference strip
- VC7R5 framebuffer ARGB/RGB565 probe
- VC7R7 patch 0007 drawRGB correction
- VC7R8 patch 0008 + historical RG35XXTransformCache
- PNG iCCP compatibility layer
- reconstructed VC7R font resource (NOT Golden)

ADD ONLY:
- `scripts/vc7r9_apply_image_blit_probe.py` to instrument source image dimensions, sampled ARGB values, alpha distribution, variation, destination pixel before/after `drawImage()` and transform=0 `drawRegion()`.
- version-specific Java stderr path `/mnt/mmc/freej2me-vc7r9-java.log`.
- version-specific native color log `/mnt/mmc/freej2me-vc7r9-color.log` through the existing checkpoint-aware VC7R4 diagnostic patcher.

DO NOT CHANGE:
- RGB565 packing, byte order, pitch, native Smart-Fit, or libretro pixel format
- CV/CW boot-time resolution logic
- GNU Classpath/glibj.zip
- image decode semantics
- drawRGB/drawRegion behavior beyond the already audited 0007/0008 patches
- media warmup/lazy boot behavior

## Expected markers
`RG35XX-VC7R9-IMAGE-BLIT: BEFORE_DRAWIMAGE`
`RG35XX-VC7R9-IMAGE-BLIT: AFTER_DRAWIMAGE`
`RG35XX-VC7R9-IMAGE-BLIT: BEFORE_DRAWREGION0`
`RG35XX-VC7R9-IMAGE-BLIT: AFTER_DRAWREGION0`

Each line includes source size, clip/translation, sampled ARGB values, alpha0/alpha255 counts, variation count, and destination pixel when in bounds.

No DEVICE-PASS or Golden claim until representative real games render correctly.