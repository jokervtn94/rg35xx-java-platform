#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-raw-polygon-r5p2.py <repo-root>')
root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
core = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'

pt = pg.read_text(encoding='utf-8')
old = '''\tpublic void setAlphaRGB(int ARGB)\n\t{\n\t\tgc.setColor(new Color(ARGB, true));\n\t}\n'''
new = '''\tpublic void setAlphaRGB(int ARGB)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tcolorAlpha = (ARGB >>> 24) & 0xFF;\n\t\t\tcolor = ARGB & 0x00FFFFFF;\n\t\t\treturn;\n\t\t}\n\t\tgc.setColor(new Color(ARGB, true));\n\t}\n'''
if pt.count(old) != 1:
    raise SystemExit('A6_R5P2_STAGE_FAIL setAlphaRGB anchor count=%d' % pt.count(old))
pt = pt.replace(old, new, 1)

old = '''\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n\t{\n\t\tint temp = color;\n\t\tint[] x = new int[nPoints];\n\t\tint[] y = new int[nPoints];\n\n\t\tsetAlphaRGB(argbColor);\n\n\t\tfor(int i=0; i<nPoints; i++)\n\t\t{\n\t\t\tx[i] = xPoints[xOffset+i];\n\t\t\ty[i] = yPoints[yOffset+i];\n\t\t}\n\t\tgc.fillPolygon(x, y, nPoints);\n\t\tsetColor(temp);\n\t}\n'''
new = '''\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tRG35XXCore2D.fillPolygon(platformImage.getRG35XXPixels(), platformImage.getRG35XXWidth(), platformImage.getRG35XXHeight(),\n\t\t\t\txPoints, xOffset, yPoints, yOffset, nPoints, argbColor, translateX, translateY,\n\t\t\t\tclipX, clipY, clipWidth, clipHeight);\n\t\t\treturn;\n\t\t}\n\t\tint temp = color;\n\t\tint[] x = new int[nPoints];\n\t\tint[] y = new int[nPoints];\n\n\t\tsetAlphaRGB(argbColor);\n\n\t\tfor(int i=0; i<nPoints; i++)\n\t\t{\n\t\t\tx[i] = xPoints[xOffset+i];\n\t\t\ty[i] = yPoints[yOffset+i];\n\t\t}\n\t\tgc.fillPolygon(x, y, nPoints);\n\t\tsetColor(temp);\n\t}\n'''
if pt.count(old) != 1:
    raise SystemExit('A6_R5P2_STAGE_FAIL fillPolygon anchor count=%d' % pt.count(old))
pg.write_text(pt.replace(old, new, 1), encoding='utf-8')

ct = core.read_text(encoding='utf-8')
anchor = '''    public static int fontHeight(int size) {\n'''
helper = r'''    public static void fillPolygon(int[] dst, int dstWidth, int dstHeight,
                                   int[] xPoints, int xOffset, int[] yPoints, int yOffset,
                                   int nPoints, int argbColor, int translateX, int translateY,
                                   int clipX, int clipY, int clipWidth, int clipHeight) {
        if (dst == null || xPoints == null || yPoints == null || nPoints < 3) return;
        if (xOffset < 0 || yOffset < 0 || xOffset + nPoints > xPoints.length || yOffset + nPoints > yPoints.length) return;
        int clipL = Math.max(0, clipX);
        int clipT = Math.max(0, clipY);
        int clipR = Math.min(dstWidth, clipX + clipWidth);
        int clipB = Math.min(dstHeight, clipY + clipHeight);
        if (clipR <= clipL || clipB <= clipT) return;

        int[] xs = new int[nPoints];
        int[] ys = new int[nPoints];
        int minX = Integer.MAX_VALUE, maxX = Integer.MIN_VALUE;
        int minY = Integer.MAX_VALUE, maxY = Integer.MIN_VALUE;
        for (int i = 0; i < nPoints; i++) {
            int x = xPoints[xOffset + i] + translateX;
            int y = yPoints[yOffset + i] + translateY;
            xs[i] = x; ys[i] = y;
            if (x < minX) minX = x; if (x > maxX) maxX = x;
            if (y < minY) minY = y; if (y > maxY) maxY = y;
        }

        if (nPoints == 4 && minX < maxX && minY < maxY) {
            int mask = 0; boolean rect = true;
            for (int i = 0; i < 4; i++) {
                int bit;
                if (xs[i] == minX && ys[i] == minY) bit = 1;
                else if (xs[i] == maxX && ys[i] == minY) bit = 2;
                else if (xs[i] == maxX && ys[i] == maxY) bit = 4;
                else if (xs[i] == minX && ys[i] == maxY) bit = 8;
                else { rect = false; break; }
                mask |= bit;
            }
            if (rect && mask == 15) {
                int left = Math.max(minX, clipL), right = Math.min(maxX, clipR);
                int top = Math.max(minY, clipT), bottom = Math.min(maxY, clipB);
                for (int y = top; y < bottom; y++) fillSpan(dst, dstWidth, y, left, right, argbColor);
                return;
            }
        }

        int top = Math.max(minY, clipT), bottom = Math.min(maxY, clipB);
        if (bottom <= top) return;
        int[] intersections = new int[nPoints];
        for (int y = top; y < bottom; y++) {
            int count = 0;
            for (int i = 0, j = nPoints - 1; i < nPoints; j = i++) {
                int y1 = ys[j], y2 = ys[i];
                if ((y1 <= y && y2 > y) || (y2 <= y && y1 > y)) {
                    long num = (long)(y - y1) * (long)(xs[i] - xs[j]);
                    intersections[count++] = xs[j] + (int)(num / (long)(y2 - y1));
                }
            }
            for (int i = 1; i < count; i++) {
                int v = intersections[i], k = i - 1;
                while (k >= 0 && intersections[k] > v) { intersections[k + 1] = intersections[k]; k--; }
                intersections[k + 1] = v;
            }
            for (int i = 0; i + 1 < count; i += 2) {
                int left = Math.max(intersections[i], clipL);
                int right = Math.min(intersections[i + 1], clipR);
                fillSpan(dst, dstWidth, y, left, right, argbColor);
            }
        }
    }

    private static void fillSpan(int[] dst, int dstWidth, int y, int left, int right, int argb) {
        if (right <= left) return;
        int di = y * dstWidth + left;
        int a = (argb >>> 24) & 0xFF;
        if (a == 255) {
            for (int x = left; x < right; x++, di++) dst[di] = argb;
        } else if (a != 0) {
            for (int x = left; x < right; x++, di++) dst[di] = sourceOver(argb, dst[di]);
        }
    }

'''
if ct.count(anchor) != 1:
    raise SystemExit('A6_R5P2_STAGE_FAIL Core2D helper anchor count=%d' % ct.count(anchor))
core.write_text(ct.replace(anchor, helper + anchor, 1), encoding='utf-8')

print('A6_R5P2_RAW_POLYGON_STAGE=PASS')
print('A6_R5P2_PLATFORMGRAPHICS_SCOPE=SMALL_BRANCH_AND_HELPER_CALL')
print('A6_R5P2_CORE2D_POLYGON=RECT_FASTPATH+GENERIC_SCANLINE+SOURCE_OVER')
print('A6_R5P2_NEW_CLASS=NO')
