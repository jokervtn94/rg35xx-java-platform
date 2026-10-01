# P1A-G1 clearRect + copyArea scope

Status: implementation work unit.

Owner: `RG35XX_GRAPHICS_BOUNDARY`.

Authorized runtime methods:

- `PlatformGraphics.clearRect(int,int,int,int)`
- `PlatformGraphics.copyArea(int,int,int,int,int,int,int)`

Authorized supporting raster helper after differential evidence:

- `RG35XXCore2D.copyAreaAliased(...)` only.

No other Core2D behavior is authorized.

Protected behavior:

- AWT fallback remains source-equivalent outside inserted Raw2D branches.
- accepted raw fillRect/drawLine/drawRect/image/drawRegion/drawRGB/text/clip/translate paths remain untouched.
- input/video/audio/RMS/lifecycle/network/3D remain untouched.

Canonical facts to preserve:

- A4 non-Raw construction explicitly sets Graphics2D background to transparent black; `clearRect` therefore clears to ARGB `0x00000000` under the accepted staged parent.
- Raw device coordinates are user coordinates plus `translateX/translateY`.
- Raw clip is stored in device coordinates and is not moved by accepted ClipTranslate `translate()` behavior.
- `copyArea` canonical source rectangle is read directly from the backing canvas; only destination drawing is affected by transform/clip.
- Pinned Aweigit obtains the source using `BufferedImage.getSubimage()` and then draws it back through the same canvas Graphics2D.
- Phase G1 run `36941065871` proved that this is an aliased/shared-raster operation, not snapshot semantics: `COPY_OVERLAP_FORWARD` produced AWT `0xffc04020` where snapshot Raw2D produced `0xff2080c0`.
- Therefore existing `RG35XXCore2D.blit`, which snapshots via `subRaw`, is not a canonical replacement for overlapping `copyArea`.
- The only newly authorized Core2D helper reads and writes the same raw array in the Java2D order observed by differential evidence, while reusing existing `sourceOver` and destination clipping.

Acceptance:

1. exact A7/A8 semantic parent digest `7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf`;
2. changed JAR entries exactly `PlatformGraphics.class` and `RG35XXCore2D.class`;
3. `RG35XXCore2D` delta is only `copyAreaAliased`;
4. native input/video/audio hashes unchanged;
5. Java major <= 50;
6. G1 AWT-vs-Raw differential gate exact MATCH for clear, clip/translate, anchors, overlap in all directions, and alpha/source-over cases;
7. existing accepted graphics host gates remain PASS;
8. BUILD-PASS only; physical DEVICE-PASS requires platform exerciser later.
