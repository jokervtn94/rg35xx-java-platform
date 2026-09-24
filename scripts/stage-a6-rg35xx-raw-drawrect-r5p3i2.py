#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-raw-drawrect-r5p3i2.py <repo-root>')
root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
text = pg.read_text(encoding='utf-8')
old = '''\tpublic void drawRect(int x, int y, int width, int height)\n\t{\n\t\tgc.drawRect(x, y, width, height);\n\t}\n'''
new = '''\tpublic void drawRect(int x, int y, int width, int height)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tif(width < 0 || height < 0) return;\n\t\t\t// Reuse the device-proven raw drawLine primitive. MIDP drawRect\n\t\t\t// includes the edge at x+width/y+height. drawLine already owns\n\t\t\t// RG35XX translation, clipping, color and fast axis paths.\n\t\t\tdrawLine(x, y, x + width, y);\n\t\t\tdrawLine(x, y + height, x + width, y + height);\n\t\t\tdrawLine(x, y, x, y + height);\n\t\t\tdrawLine(x + width, y, x + width, y + height);\n\t\t\treturn;\n\t\t}\n\t\tgc.drawRect(x, y, width, height);\n\t}\n'''
if text.count(old) != 1:
    raise SystemExit('A6_R5P3I2_STAGE_FAIL drawRect anchor count=%d' % text.count(old))
pg.write_text(text.replace(old, new, 1), encoding='utf-8')
print('A6_R5P3I2_RAW_DRAWRECT_STAGE=PASS')
print('A6_R5P3I2_OWNER=RG35XX_RAW2D_PLATFORMGRAPHICS_DRAWRECT_AWT_NULL')
print('A6_R5P3I2_IMPLEMENTATION=FOUR_DEVICE_PROVEN_DRAWLINE_CALLS')
