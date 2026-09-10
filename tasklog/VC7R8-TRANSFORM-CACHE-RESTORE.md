# RG35XX VC7R8 — Audited PlatformGraphics transform restore

Status: DEVICE-TEST-PENDING.

## Trigger
VC7R7 restored audited `patches/0007-platformgraphics-rg35xx-fast-drawrgb.patch` and built successfully, but real-device KDTT evidence still shows the game framebuffer as green/black while the native RGB565 reference strip is correct. Java framebuffer probes continue to show `ARGB=FF77EF5A -> RGB565=776B` with encoder match=true, so RGB565 transport/native presentation are not the primary suspect.

## Historical basis
RC1 tasklog registered `RG35XXTransformCache` and `patches/0008-platformgraphics-transform-cache.patch` as the audited transform path for `PlatformGraphics.drawTransformedImage()` / MIDP Sprite transforms. Historical helper source is pinned at `d79180df9ae8621f2ddcf00f4f0648e4a43dc374`.

## VC7R8 scope
KEEP:
- JamVM L
- immutable GNU Classpath / glibj.zip
- VC7R2 filename-token dynamic logical view
- VC7R3 native media bridge
- VC7R4 native RGB565 reference-strip implementation
- VC7R5 Java framebuffer color probe
- VC7R7 audited drawRGB patch 0007
- PNG iCCP compatibility path
- reconstructed VC7R font resource (NOT Golden)

ADD ONLY:
- exact historical `src/org/recompile/mobile/RG35XXTransformCache.java`
- audited `patches/0008-platformgraphics-transform-cache.patch`

DO NOT CHANGE:
- RGB565 packing, byte order, pitch, or native Smart-Fit
- boot-time CV/CW resolution logic
- GNU Classpath / glibj.zip
- font ownership
- media warmup/lazy boot semantics

## Diagnostic log naming correction
Device evidence from VC7R7 exposed a packaging/diagnostic naming defect: the reusable VC7R4 color-strip overlay still hard-coded `/mnt/mmc/freej2me-vc7r4-color.log`, so newer checkpoints produced stale/misleading filenames.

Correction before any VC7R8 installer is allowed:
- `scripts/vc7r4_apply_video_color_diag.py` now derives the checkpoint token from the disposable assembly directory (`vc7r8`, etc.).
- For VC7R8 the native color diagnostic MUST compile with `/mnt/mmc/freej2me-vc7r8-color.log`.
- `/mnt/mmc/freej2me-vc7r4-color.log` MUST NOT remain in the assembled VC7R8 native source.
- Installer/collector for VC7R8 must collect `freej2me-vc7r8-color.log`, not any older checkpoint name.
- No installer may be issued from the earlier VC7R8 artifact built before this correction.

## Acceptance
- 0007 and 0008 both apply with `--fuzz=0` against the disposable pinned assembly.
- exact historical transform helper is materialized from the pinned history commit, not recreated from memory.
- Java build remains class version 50.
- ARM core remains ELF32 ARM EABI5 soft-float.
- no CV/CW markers.
- native RGB565/reference strip and VC7R5 framebuffer probes remain present.
- assembled native source contains `/mnt/mmc/freej2me-vc7r8-color.log` exactly once.
- assembled native source contains no `/mnt/mmc/freej2me-vc7r4-color.log` path.

No DEVICE-PASS claim until RG35XX evidence shows representative transformed sprite/image rendering correctly.