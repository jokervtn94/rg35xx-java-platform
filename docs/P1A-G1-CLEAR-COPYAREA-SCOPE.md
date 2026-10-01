# P1A-G1 clearRect + copyArea scope

Status: implementation work unit.

Owner: `RG35XX_GRAPHICS_BOUNDARY`.

Authorized runtime methods only:

- `PlatformGraphics.clearRect(int,int,int,int)`
- `PlatformGraphics.copyArea(int,int,int,int,int,int,int)`

Permitted helper reuse:

- existing `RG35XXCore2D.blit` only; no Core2D semantic expansion is planned.

Protected behavior:

- AWT fallback remains bytecode/source-equivalent outside the inserted Raw2D branches.
- accepted raw fillRect/drawLine/drawRect/image/drawRegion/drawRGB/text/clip/translate paths remain untouched.
- input/video/audio/RMS/lifecycle/network/3D remain untouched.

Canonical facts to preserve:

- A4 non-Raw construction explicitly sets Graphics2D background to transparent black; `clearRect` therefore clears to ARGB `0x00000000` under the accepted staged parent.
- Raw device coordinates are user coordinates plus `translateX/translateY`.
- Raw clip is stored in device coordinates and is not moved by the accepted ClipTranslate `translate()` behavior.
- `copyArea` canonical source rectangle is read directly from the backing canvas; only destination drawing is affected by transform/clip.
- canonical `copyArea` snapshots a subimage then draws it with normal image compositing; existing `RG35XXCore2D.blit` snapshots the source subregion and applies source-over, making it the narrow reusable boundary for valid source regions.

Acceptance:

1. exact A7/A8 semantic parent digest `7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf`;
2. only `PlatformGraphics.class` changes in the platform JAR;
3. native input/video/audio hashes unchanged;
4. Java major <= 50;
5. G1 AWT-vs-Raw differential gate exact MATCH for clear/copy matrices;
6. existing accepted graphics host gates remain PASS;
7. BUILD-PASS only; physical DEVICE-PASS requires the platform exerciser later.
