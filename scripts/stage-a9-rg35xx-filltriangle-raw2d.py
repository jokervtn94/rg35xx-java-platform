#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a9-rg35xx-filltriangle-raw2d.py <repo-root>')

root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
text = pg.read_text(encoding='utf-8')

old = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''
new = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Standard MIDP Graphics.fillTriangle uses the current opaque Graphics color.\n\t\t// On RG35XX raw2d, gc is intentionally null. Rasterize only this triangle\n\t\t// as horizontal spans and delegate every pixel write/clip/translate operation\n\t\t// to the accepted A6 raw drawLine implementation.\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tint minY = Math.min(y1, Math.min(y2, y3));\n\t\t\tint maxY = Math.max(y1, Math.max(y2, y3));\n\t\t\tint savedStroke = strokeStyle;\n\t\t\tstrokeStyle = SOLID;\n\t\t\ttry\n\t\t\t{\n\t\t\t\tif(minY == maxY)\n\t\t\t\t{\n\t\t\t\t\tint left = Math.min(x1, Math.min(x2, x3));\n\t\t\t\t\tint right = Math.max(x1, Math.max(x2, x3));\n\t\t\t\t\tdrawLine(left, minY, right, minY);\n\t\t\t\t\treturn;\n\t\t\t\t}\n\t\t\t\tfor(int yy = minY; yy < maxY; yy++)\n\t\t\t\t{\n\t\t\t\t\tint count = 0;\n\t\t\t\t\tint xa = 0, xb = 0;\n\t\t\t\t\tint ex1 = x1, ey1 = y1, ex2 = x2, ey2 = y2;\n\t\t\t\t\tfor(int edge = 0; edge < 3; edge++)\n\t\t\t\t\t{\n\t\t\t\t\t\tif(edge == 1) { ex1 = x2; ey1 = y2; ex2 = x3; ey2 = y3; }\n\t\t\t\t\t\telse if(edge == 2) { ex1 = x3; ey1 = y3; ex2 = x1; ey2 = y1; }\n\t\t\t\t\t\tif(ey1 == ey2) continue;\n\t\t\t\t\t\tint lowY = ey1 < ey2 ? ey1 : ey2;\n\t\t\t\t\t\tint highY = ey1 < ey2 ? ey2 : ey1;\n\t\t\t\t\t\tif(yy < lowY || yy >= highY) continue;\n\t\t\t\t\t\tint xx = ex1 + (int)(((long)(yy - ey1) * (long)(ex2 - ex1)) / (long)(ey2 - ey1));\n\t\t\t\t\t\tif(count == 0) xa = xx; else xb = xx;\n\t\t\t\t\t\tcount++;\n\t\t\t\t\t}\n\t\t\t\t\tif(count >= 2)\n\t\t\t\t\t{\n\t\t\t\t\t\tif(xa <= xb) drawLine(xa, yy, xb, yy);\n\t\t\t\t\t\telse drawLine(xb, yy, xa, yy);\n\t\t\t\t\t}\n\t\t\t\t}\n\t\t\t}\n\t\t\tfinally\n\t\t\t{\n\t\t\t\tstrokeStyle = savedStroke;\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

count = text.count(old)
if count != 1:
    raise SystemExit('A9_FILLTRIANGLE_STAGE_FAIL anchor count=%d' % count)
text = text.replace(old, new, 1)
pg.write_text(text, encoding='utf-8')

print('A9_FILLTRIANGLE_STAGE=PASS')
print('A9_FILLTRIANGLE_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_AWT_NULL')
print('A9_FILLTRIANGLE_DELTA=STANDARD_6ARG_ONLY')
print('A9_FILLTRIANGLE_RAW_IMPL=SCANLINE_USING_ACCEPTED_A6_DRAWLINE')
