# Platform 1.0 Beta 4 — Graphics Engine

## Baseline

Current FreeJ2ME-Plus already uses hand-written LCDUI rendering for many operations. RG35XX Beta 4 therefore optimizes existing direct-raster paths instead of replacing them with a new renderer.

Stable RG35XX behavior that must not regress:

- indexed PNG `tRNS` transparency repair
- immutable decoded-image LRU
- direct raster alpha/local-coordinate fixes
- Unified Font Engine metrics/raster agreement
- dirty-frame generation scheduler
- Java/native RGB565 IPC
- fixed 640x480 frontend geometry and SMART-FIT aspect preservation

## Real-JAR pressure points

- Diamond Rush: PNG-heavy rendering, `createRGBImage/getRGB`, Sprite, timers.
- Asphalt 4: `drawRGB/getRGB/drawRegion/createRGBImage`, packed resources.
- Zombie Infection: packed resources, threads, vibration and image-heavy scenes.
- Prince of Persia — The Two Thrones: TiledLayer, packed resources and sprite regions.
- God of War — Betrayal: GameCanvas/flushGraphics, drawRGB and frame/input latency.
- Vua Cướp Biển: transition/GC pressure; avoid adding per-draw allocation.

## Tasks

### RGJ-B4-001 — Source semantic audit
Audit `PlatformGraphics`, `PlatformImage`, Sprite/TiledLayer and GameCanvas before modifying fast paths.

### RGJ-B4-002 — drawRGB fast paths
Preserve MIDP semantics while reducing per-pixel work:

1. clipped opaque copy when source alpha is already fully opaque
2. `processAlpha=false`: force alpha to FF; never incorrectly preserve transparent source alpha
3. `processAlpha=true`: alpha=255 direct copy, alpha=0 skip, partial alpha blend
4. no temporary arrays or allocations in the draw loop

A raw `System.arraycopy` is only legal when forcing alpha is unnecessary. It must not replace the general `processAlpha=false` path because MIDP requires source alpha to be ignored/forced opaque.

### RGJ-B4-003 — drawRegion/Sprite transform maps
Precompute/cache coordinate mappings for the eight MIDP Sprite transforms. The cache key is dimensions + transform, not image identity. Pixel data remains in the existing image buffer.

### RGJ-B4-004 — clipping normalization
Compute effective destination/source rectangle once per operation. Avoid repeated clip getters and per-pixel bounds checks after a valid clipped rectangle is established.

### RGJ-B4-005 — alpha specialization
Use explicit branches for alpha 0/255 before generic blending. Preserve DoJa blending modes; do not route DoJa operations through a MIDP-only shortcut.

### RGJ-B4-006 — GameCanvas/dirty integration
`flushGraphics` remains the authoritative completed-frame dirty signal. Rendering primitives must not independently serialize frames or wake native IPC.

### RGJ-B4-007 — no-allocation hot-path gate
No new `BufferedImage`, transformed image, temporary pixel array, collection or exception-driven fallback in repeated Sprite/drawRGB hot paths.

### RGJ-B4-008 — six-JAR regression audit
Static API/resource evidence is mapped to the optimized paths; no game-specific rendering hacks are accepted.

### RGJ-B4-009 — consolidated graphics gate
Before Beta 4 lock: Java 6 source compatibility, anchor/clip/transform semantics, tRNS preservation, font preservation, no protocol change, no per-frame allocation regression.

## Non-goals

- no frontend geometry change
- no bilinear filtering
- no conversion of the LCD framebuffer to native RGB565 inside individual Graphics calls
- no JNI renderer before Java-level avoidable work is removed
- no game-name/package-specific hacks
