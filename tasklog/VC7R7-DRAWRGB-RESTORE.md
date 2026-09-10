# VC7R7 — Restore audited PlatformGraphics drawRGB clipping semantics

Status: IMPLEMENTED / BUILD-TEST-PENDING

Basis:
- `tasklog/RC1-TASKLOG.md` RGJ-RC1-007 records the exact-source PlatformGraphics gate.
- `patches/0007-platformgraphics-rg35xx-fast-drawrgb.patch` is the historical audited correction.
- VC7R4/VC7R5 device evidence proves native RGB565 output and Java RGB565 encode are not the primary corruption source.

Scope:
- Apply ONLY `patches/0007-platformgraphics-rg35xx-fast-drawrgb.patch` to the current VC7R3/VC7R2 verified-clean assembly.
- Preserve VC7R2 dynamic logical resolution, VC7R3 native audio, VC7R4 native reference strip, VC7R5 Java framebuffer probe, PNG iCCP compatibility, JamVM L, immutable glibj, and reconstructed-not-Golden font.
- Do NOT apply transform-cache patch 0008 yet.
- Do NOT modify Graphics2D, GNU Classpath, RGB565 byte order, native pitch, Smart-Fit, or backlight options.

Acceptance gate:
1. Patch applies with fuzz=0 against the pinned FreeJ2ME source assembly.
2. Java compiles at class major 50.
3. Native core remains ELF32 ARM EABI5 soft-float.
4. RGB565, VC7R2 view, VC7R3 audio, VC7R4 reference strip, VC7R5 framebuffer probe remain present.
5. Device test must determine whether image corruption is removed before any further graphics patch is introduced.

No DEVICE-PASS or Golden claim is permitted by this task.