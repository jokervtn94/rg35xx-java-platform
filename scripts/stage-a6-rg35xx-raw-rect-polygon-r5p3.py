#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-raw-rect-polygon-r5p3.py <repo-root>')
root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
core = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'

ct = core.read_text(encoding='utf-8')
old = '    private static int sourceOver(int s, int d) {'
new = '    public static int sourceOver(int s, int d) {'
if ct.count(old) != 1:
    raise SystemExit('A6_R5P3_STAGE_FAIL sourceOver anchor count=%d' % ct.count(old))
core.write_text(ct.replace(old, new, 1), encoding='utf-8')

pt = pg.read_text(encoding='utf-8')
old = '''\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n\t{\n\t\tint temp = color;\n\t\tint[] x = new int[nPoints];\n\t\tint[] y = new int[nPoints];\n\n\t\tsetAlphaRGB(argbColor);\n\n\t\tfor(int i=0; i<nPoints; i++)\n\t\t{\n\t\t\tx[i] = xPoints[xOffset+i];\n\t\t\ty[i] = yPoints[yOffset+i];\n\t\t}\n\t\tgc.fillPolygon(x, y, nPoints);\n\t\tsetColor(temp);\n\t}\n'''
new = '''\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tif(xPoints == null || yPoints == null || nPoints != 4 || xOffset < 0 || yOffset < 0 ||\n\t\t\t   xOffset + 4 > xPoints.length || yOffset + 4 > yPoints.length) return;\n\t\t\tint x0 = xPoints[xOffset] + translateX, x1 = xPoints[xOffset+1] + translateX;\n\t\t\tint x2 = xPoints[xOffset+2] + translateX, x3 = xPoints[xOffset+3] + translateX;\n\t\t\tint y0 = yPoints[yOffset] + translateY, y1 = yPoints[yOffset+1] + translateY;\n\t\t\tint y2 = yPoints[yOffset+2] + translateY, y3 = yPoints[yOffset+3] + translateY;\n\t\t\tif(x0 != x3 || x1 != x2 || y0 != y1 || y2 != y3) return;\n\t\t\tint left = x0 < x1 ? x0 : x1, right = x0 < x1 ? x1 : x0;\n\t\t\tint top = y0 < y2 ? y0 : y2, bottom = y0 < y2 ? y2 : y0;\n\t\t\tif(left < clipX) left = clipX; if(top < clipY) top = clipY;\n\t\t\tif(right > clipX + clipWidth) right = clipX + clipWidth;\n\t\t\tif(bottom > clipY + clipHeight) bottom = clipY + clipHeight;\n\t\t\tint pw = platformImage.getRG35XXWidth(), ph = platformImage.getRG35XXHeight();\n\t\t\tif(left < 0) left = 0; if(top < 0) top = 0;\n\t\t\tif(right > pw) right = pw; if(bottom > ph) bottom = ph;\n\t\t\tif(right <= left || bottom <= top) return;\n\t\t\tint a = (argbColor >>> 24) & 0xFF;\n\t\t\tif(a == 0) return;\n\t\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\t\tfor(int yy = top; yy < bottom; yy++)\n\t\t\t{\n\t\t\t\tint from = yy * pw + left, to = yy * pw + right;\n\t\t\t\tif(a == 255) Arrays.fill(dst, from, to, argbColor);\n\t\t\t\telse for(int di = from; di < to; di++) dst[di] = RG35XXCore2D.sourceOver(argbColor, dst[di]);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tint temp = color;\n\t\tint[] x = new int[nPoints];\n\t\tint[] y = new int[nPoints];\n\n\t\tsetAlphaRGB(argbColor);\n\n\t\tfor(int i=0; i<nPoints; i++)\n\t\t{\n\t\t\tx[i] = xPoints[xOffset+i];\n\t\t\ty[i] = yPoints[yOffset+i];\n\t\t}\n\t\tgc.fillPolygon(x, y, nPoints);\n\t\tsetColor(temp);\n\t}\n'''
if pt.count(old) != 1:
    raise SystemExit('A6_R5P3_STAGE_FAIL fillPolygon anchor count=%d' % pt.count(old))
pg.write_text(pt.replace(old, new, 1), encoding='utf-8')

print('A6_R5P3_RAW_RECT_POLYGON_STAGE=PASS')
print('A6_R5P3_IMPLEMENTATION=R5_PLATFORMGRAPHICS_TINY_RECT_PATH+EXISTING_CORE2D_SOURCEOVER')
print('A6_R5P3_NEW_CLASS=NO')
print('A6_R5P3_GENERIC_SCANLINE=NO')
