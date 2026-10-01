#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a9-rg35xx-filltriangle-raw2d.py <repo-root>')

root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
text = pg.read_text(encoding='utf-8')

old = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''
new = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Standard MIDP Graphics.fillTriangle uses the current opaque Graphics color.\n\t\t// On RG35XX raw2d, gc is intentionally null, so reuse the already accepted\n\t\t// A6 raw polygon rasterizer instead of falling through to AWT Graphics2D.\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tint[] x = new int[]{x1, x2, x3};\n\t\t\tint[] y = new int[]{y1, y2, y3};\n\t\t\trg35xxFillPolygon(x, 0, y, 0, 3, 0xFF000000 | (color & 0x00FFFFFF));\n\t\t\treturn;\n\t\t}\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

count = text.count(old)
if count != 1:
    raise SystemExit('A9_FILLTRIANGLE_STAGE_FAIL anchor count=%d' % count)
text = text.replace(old, new, 1)
pg.write_text(text, encoding='utf-8')

print('A9_FILLTRIANGLE_STAGE=PASS')
print('A9_FILLTRIANGLE_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_AWT_NULL')
print('A9_FILLTRIANGLE_DELTA=STANDARD_6ARG_ONLY')
print('A9_FILLTRIANGLE_RAW_IMPL=REUSE_A6_RG35XXFILLPOLYGON')
