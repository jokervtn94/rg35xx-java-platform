#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/MobilePlatform.java')
s = p.read_text()

old = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\tgcFrontbuffer.drawImage(image, x, y, x, y, width, height);\n\t}\n'''

new = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\t// M1.10-r4: the RG35XX headless PlatformGraphics boundary has no\n\t\t// Graphics2D object, so drawImage() cannot be the GameCanvas flush\n\t\t// transport. Copy the requested raster rectangle directly from the\n\t\t// GameCanvas PlatformImage backing store to the LCD frontbuffer.\n\t\tif (Boolean.getBoolean("rg35xx.headless.graphics.probe"))\n\t\t{\n\t\t\tint[] src = image.getDataBuffer();\n\t\t\tint[] dst = lcdFrontbuffer.getDataBuffer();\n\t\t\tint srcWidth = image.getRG35XXWidth();\n\t\t\tint dstWidth = lcdFrontbuffer.getRG35XXWidth();\n\n\t\t\tint startX = x < 0 ? 0 : x;\n\t\t\tint startY = y < 0 ? 0 : y;\n\t\t\tint endX = x + width;\n\t\t\tint endY = y + height;\n\t\t\tif (endX > image.getRG35XXWidth()) endX = image.getRG35XXWidth();\n\t\t\tif (endX > lcdFrontbuffer.getRG35XXWidth()) endX = lcdFrontbuffer.getRG35XXWidth();\n\t\t\tif (endY > image.getRG35XXHeight()) endY = image.getRG35XXHeight();\n\t\t\tif (endY > lcdFrontbuffer.getRG35XXHeight()) endY = lcdFrontbuffer.getRG35XXHeight();\n\n\t\t\tint copyWidth = endX - startX;\n\t\t\tif (copyWidth <= 0 || endY <= startY) return;\n\t\t\tfor (int row = startY; row < endY; row++)\n\t\t\t{\n\t\t\t\tSystem.arraycopy(src, row * srcWidth + startX,\n\t\t\t\t\tdst, row * dstWidth + startX, copyWidth);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\n\t\tgcFrontbuffer.drawImage(image, x, y, x, y, width, height);\n\t}\n'''

if s.count(old) != 1:
    raise SystemExit('M1_10_R4_FLUSH_PATCH=FAIL_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_10_R4_HEADLESS_GAMECANVAS_FLUSH_PATCH=PASS')
