# P1A Phase-0 Differential Baseline

Status: `LOCKED / DIAGNOSTIC ONLY / NO RUNTIME CHANGE`

Canonical: `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
Reset/base: `e7b0860310fd5204e1d1f2d01c992002b8660df2`

CI run: `36940175496`
Head: `2bfb8be81f71ee9f5e509049b640f730669116ae`
Artifact: `11200086947`
Artifact digest: `sha256:cfdef0ae9dc51a8deb5e3fb057ed8576f5f3b4b8962c85678782ad57cf226e05`

Protected reconstructed class identities:

- `PlatformGraphics.class`: `b06b027b46e3545dfcaf716dc370462919b6005ad2120907f1ce07326555b853`
- `PlatformImage.class`: `5702115c691d37817d561b578e22c29386cd863ff4a3bfed31ab317cf6827f86`

## Controls

- `fillRect`: MATCH
- axis `drawLine`: MATCH
- `drawRect`: MATCH
- clip + translate: MATCH

## Confirmed Raw2D gaps

AWT completes while Raw2D throws `NullPointerException`:

- `clearRect`
- `copyArea`
- `drawArc`
- `fillArc`
- `drawRoundRect`
- `fillRoundRect`
- MIDP six-argument `fillTriangle`
- DirectGraphics `drawTriangle`
- DirectGraphics seven-argument `fillTriangle`
- DirectGraphics `drawPolygon`
- DirectGraphics `drawPixels(int[])`
- DirectGraphics `getPixels(int[])`

Generic non-rectangle DirectGraphics `fillPolygon` is a different failure class:

- AWT completes
- Raw2D completes
- pixel output differs
- classification: `MISMATCH`

This is consistent with the accepted A6 rectangle-only raw branch returning without a generic polygon implementation.

## Authorization consequence

Phase-0 proves that the problem is platform backing coverage, not a single commercial-game quirk.

The first runtime unit is constrained to:

```text
P1A-G1-CLEAR-COPYAREA
owner=RG35XX_GRAPHICS_BOUNDARY
methods=PlatformGraphics.clearRect,PlatformGraphics.copyArea
```

No other missing primitive is authorized in G1.
