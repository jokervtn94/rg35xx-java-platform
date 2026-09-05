# RC1-011CB — Fixed 8x12 raster reconstruction

## Basis
Device evidence from RC1-011CA:
- automatic suite completed: 18 PASS / 0 FAIL / 6 PENDING;
- no more `AbstractGraphics2D.renderScanline` paint exception;
- user observed slow-looking startup, stripes/pixel corruption, then a visually frozen screen.

Conclusion: bypassing GNU Classpath glyph rasterization is correct, but CA's dynamic 5x7 renderer is not acceptable as the retained renderer.

## Change
`RG35XXBitmapText` is changed to a fixed 8x12 cell renderer:
- `CELL_WIDTH = 8`, `CELL_HEIGHT = 12`;
- no `Font.charWidth()` use;
- no runtime glyph scaling based on font height/metrics;
- fixed nearest-neighbour 5x7 seed -> 8x12 cell reconstruction;
- hard canvas/clip/index bounds before framebuffer writes;
- AWT drawString remains bypassed only on RG35XX through patch 0026;
- desktop/non-RG35XX path unchanged;
- media/playTone and lazy startup unchanged.

## Restoration status
Historical logs prove an old stable path identified itself as `font=VN-raster` and `bitmap engine Unicode8x12, baseH=12`, but the exact old Unicode8x12 source/resource has not been recovered from available Git history. Therefore RC1-011CB is a **compatible reconstruction**, not an exact restoration.

## Device acceptance target
- no stripes/pixel corruption attributable to text renderer;
- Summary page remains responsive/changes pages;
- no `AbstractGraphics2D.renderScanline` NPE;
- auto suite remains >=18 PASS, 0 FAIL;
- do not claim DEVICE-TEST-PASS until hardware evidence is supplied.
