#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a8-comp02-filltriangle-boundary.py <repo-root>')

root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
if not pg.is_file():
    raise SystemExit('A8_COMP02_FILLTRIANGLE_STAGE_FAIL staged PlatformGraphics missing')

s = pg.read_text(encoding='utf-8')

# Scope is deliberately limited to the six-argument MIDP Graphics.fillTriangle
# method that fails on A8 raw2D because canonical Aweigit calls gc.fillPolygon
# while the RG35XX raw backing intentionally has gc == null.  Do not widen the
# DirectGraphics fillPolygon/fillTriangle APIs or touch non-raw canonical AWT.
old = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

new = '''\tprivate void rg35xxFillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Preserve canonical Graphics semantics: current RGB color, translated\n\t\t// user coordinates, current clip.  Raw2D only replaces the AWT backing.\n\t\tint ax = x1 + translateX, ay = y1 + translateY;\n\t\tint bx = x2 + translateX, by = y2 + translateY;\n\t\tint cx = x3 + translateX, cy = y3 + translateY;\n\n\t\tint minY = ay; if(by < minY) minY = by; if(cy < minY) minY = cy;\n\t\tint maxY = ay; if(by > maxY) maxY = by; if(cy > maxY) maxY = cy;\n\t\tif(maxY <= minY) return;\n\n\t\tint pw = platformImage.getRG35XXWidth();\n\t\tint ph = platformImage.getRG35XXHeight();\n\t\tint clipL = clipX < 0 ? 0 : clipX;\n\t\tint clipT = clipY < 0 ? 0 : clipY;\n\t\tint clipR = clipX + clipWidth;\n\t\tint clipB = clipY + clipHeight;\n\t\tif(clipR > pw) clipR = pw;\n\t\tif(clipB > ph) clipB = ph;\n\t\tif(clipR <= clipL || clipB <= clipT) return;\n\n\t\tint top = minY < clipT ? clipT : minY;\n\t\tint bottom = maxY > clipB ? clipB : maxY;\n\t\tif(bottom <= top) return;\n\n\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\tint[] intersections = new int[3];\n\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\n\t\tfor(int y = top; y < bottom; y++)\n\t\t{\n\t\t\tint count = 0;\n\t\t\tif((ay <= y && by > y) || (by <= y && ay > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - ay) * (long)(bx - ax);\n\t\t\t\tintersections[count++] = ax + (int)(num / (long)(by - ay));\n\t\t\t}\n\t\t\tif((by <= y && cy > y) || (cy <= y && by > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - by) * (long)(cx - bx);\n\t\t\t\tintersections[count++] = bx + (int)(num / (long)(cy - by));\n\t\t\t}\n\t\t\tif((cy <= y && ay > y) || (ay <= y && cy > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - cy) * (long)(ax - cx);\n\t\t\t\tintersections[count++] = cx + (int)(num / (long)(ay - cy));\n\t\t\t}\n\t\t\tif(count < 2) continue;\n\t\t\tfor(int i = 1; i < count; i++)\n\t\t\t{\n\t\t\t\tint v = intersections[i], k = i - 1;\n\t\t\t\twhile(k >= 0 && intersections[k] > v)\n\t\t\t\t{\n\t\t\t\t\tintersections[k + 1] = intersections[k];\n\t\t\t\t\tk--;\n\t\t\t\t}\n\t\t\t\tintersections[k + 1] = v;\n\t\t\t}\n\n\t\t\tint left = intersections[0] < clipL ? clipL : intersections[0];\n\t\t\tint right = intersections[count - 1] > clipR ? clipR : intersections[count - 1];\n\t\t\tif(left < 0) left = 0;\n\t\t\tif(right > pw) right = pw;\n\t\t\tif(right > left) Arrays.fill(dst, y * pw + left, y * pw + right, argb);\n\t\t}\n\t}\n\n\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxFillTriangle(x1, y1, x2, y2, x3, y3);\n\t\t\treturn;\n\t\t}\n\t\t// Pinned Aweigit fallback remains byte-for-source equivalent in behavior.\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

if s.count(old) != 1:
    raise SystemExit('A8_COMP02_FILLTRIANGLE_STAGE_FAIL six-arg anchor count=%d' % s.count(old))
if 'private void rg35xxFillTriangle(' in s:
    raise SystemExit('A8_COMP02_FILLTRIANGLE_STAGE_FAIL helper already present')

# Explicitly prove the seven-argument DirectGraphics overload is present before
# staging, but do not alter it.
dg = '\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)'
if s.count(dg) != 1:
    raise SystemExit('A8_COMP02_FILLTRIANGLE_STAGE_FAIL DirectGraphics overload anchor count=%d' % s.count(dg))

pg.write_text(s.replace(old, new, 1), encoding='utf-8')

print('A8_COMP02_FILLTRIANGLE_STAGE=PASS')
print('A8_COMP02_FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY')
print('A8_COMP02_CHANGED_METHOD=Graphics.fillTriangle_6ARG_ONLY')
print('A8_COMP02_DIRECTGRAPHICS_FILLPOLYGON=UNCHANGED')
print('A8_COMP02_DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED')
print('A8_COMP02_GAME_SPECIFIC_NAMES=NO')
