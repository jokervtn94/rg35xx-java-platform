#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/MobilePlatform.java')
s = p.read_text()

# Pinned FreeJ2ME 13ec186... owns the public flush lifecycle here. Preserve
# synchronization, postDraw, painter and FPS limiting; replace only the
# Graphics2D-dependent transfer inside the synchronized frontbuffer boundary.
old = '''\t\t\t\tgcFrontbuffer.flushGraphics(img, x, y, width, height);'''
new = '''\t\t\t\tif (Boolean.getBoolean("rg35xx.headless.graphics.probe"))
\t\t\t\t{
\t\t\t\t\t// M1.10-r4b: GameCanvas already rendered into img's Java int[]
\t\t\t\t\t// backing store. The headless RG35XX PlatformGraphics has no
\t\t\t\t\t// Graphics2D, so transfer the requested raster rectangle directly.
\t\t\t\t\tint[] src = img.getDataBuffer();
\t\t\t\t\tint[] dst = lcdFrontbuffer.getDataBuffer();
\t\t\t\t\tint srcWidth = img.getRG35XXWidth();
\t\t\t\t\tint dstWidth = lcdFrontbuffer.getRG35XXWidth();
\t\t\t\t\tint startX = x < 0 ? 0 : x;
\t\t\t\t\tint startY = y < 0 ? 0 : y;
\t\t\t\t\tint endX = x + width;
\t\t\t\t\tint endY = y + height;
\t\t\t\t\tif (endX > img.getRG35XXWidth()) endX = img.getRG35XXWidth();
\t\t\t\t\tif (endX > lcdFrontbuffer.getRG35XXWidth()) endX = lcdFrontbuffer.getRG35XXWidth();
\t\t\t\t\tif (endY > img.getRG35XXHeight()) endY = img.getRG35XXHeight();
\t\t\t\t\tif (endY > lcdFrontbuffer.getRG35XXHeight()) endY = lcdFrontbuffer.getRG35XXHeight();
\t\t\t\t\tint copyWidth = endX - startX;
\t\t\t\t\tif (copyWidth > 0 && endY > startY)
\t\t\t\t\t{
\t\t\t\t\t\tfor (int row = startY; row < endY; row++)
\t\t\t\t\t\t{
\t\t\t\t\t\t\tSystem.arraycopy(src, row * srcWidth + startX,
\t\t\t\t\t\t\t\tdst, row * dstWidth + startX, copyWidth);
\t\t\t\t\t\t}
\t\t\t\t\t}
\t\t\t\t}
\t\t\t\telse
\t\t\t\t{
\t\t\t\t\tgcFrontbuffer.flushGraphics(img, x, y, width, height);
\t\t\t\t}'''

if s.count(old) != 1:
    raise SystemExit('M1_10_R4_FLUSH_PATCH=FAIL_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_10_R4_HEADLESS_GAMECANVAS_FLUSH_PATCH=PASS')
