#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2b-filltriangle-diagnostic.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2B_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
parent = s

# Diagnostic import of the exact six-argument MIDP raw helper that previously
# reached Asphalt gameplay on original RG35XX.  Do not alter the algorithm in
# this stage: P1A must first measure it against the pinned JDK8 raster.
old = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

new = '''\tprivate void rg35xxFillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Exact previously device-proven COMP-02 helper. P1A diagnostic only.\n\t\tint ax = x1 + translateX, ay = y1 + translateY;\n\t\tint bx = x2 + translateX, by = y2 + translateY;\n\t\tint cx = x3 + translateX, cy = y3 + translateY;\n\n\t\tint minY = ay; if(by < minY) minY = by; if(cy < minY) minY = cy;\n\t\tint maxY = ay; if(by > maxY) maxY = by; if(cy > maxY) maxY = cy;\n\t\tif(maxY <= minY) return;\n\n\t\tint pw = platformImage.getRG35XXWidth();\n\t\tint ph = platformImage.getRG35XXHeight();\n\t\tint clipL = clipX < 0 ? 0 : clipX;\n\t\tint clipT = clipY < 0 ? 0 : clipY;\n\t\tint clipR = clipX + clipWidth;\n\t\tint clipB = clipY + clipHeight;\n\t\tif(clipR > pw) clipR = pw;\n\t\tif(clipB > ph) clipB = ph;\n\t\tif(clipR <= clipL || clipB <= clipT) return;\n\n\t\tint top = minY < clipT ? clipT : minY;\n\t\tint bottom = maxY > clipB ? clipB : maxY;\n\t\tif(bottom <= top) return;\n\n\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\tint[] intersections = new int[3];\n\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\n\t\tfor(int y = top; y < bottom; y++)\n\t\t{\n\t\t\tint count = 0;\n\t\t\tif((ay <= y && by > y) || (by <= y && ay > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - ay) * (long)(bx - ax);\n\t\t\t\tintersections[count++] = ax + (int)(num / (long)(by - ay));\n\t\t\t}\n\t\t\tif((by <= y && cy > y) || (cy <= y && by > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - by) * (long)(cx - bx);\n\t\t\t\tintersections[count++] = bx + (int)(num / (long)(cy - by));\n\t\t\t}\n\t\t\tif((cy <= y && ay > y) || (ay <= y && cy > y))\n\t\t\t{\n\t\t\t\tlong num = (long)(y - cy) * (long)(ax - cx);\n\t\t\t\tintersections[count++] = cx + (int)(num / (long)(ay - cy));\n\t\t\t}\n\t\t\tif(count < 2) continue;\n\t\t\tfor(int i = 1; i < count; i++)\n\t\t\t{\n\t\t\t\tint v = intersections[i], k = i - 1;\n\t\t\t\twhile(k >= 0 && intersections[k] > v)\n\t\t\t\t{\n\t\t\t\t\tintersections[k + 1] = intersections[k];\n\t\t\t\t\tk--;\n\t\t\t\t}\n\t\t\t\tintersections[k + 1] = v;\n\t\t\t}\n\n\t\t\tint left = intersections[0] < clipL ? clipL : intersections[0];\n\t\t\tint right = intersections[count - 1] > clipR ? clipR : intersections[count - 1];\n\t\t\tif(left < 0) left = 0;\n\t\t\tif(right > pw) right = pw;\n\t\t\tif(right > left) Arrays.fill(dst, y * pw + left, y * pw + right, argb);\n\t\t}\n\t}\n\n\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxFillTriangle(x1, y1, x2, y2, x3, y3);\n\t\t\treturn;\n\t\t}\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

if s.count(old) != 1:
    raise SystemExit("P1A_G2B_STAGE_FAIL six-arg anchor count=%d" % s.count(old))
if "private void rg35xxFillTriangle(" in s:
    raise SystemExit("P1A_G2B_STAGE_FAIL helper already present")

# Prove neighboring G2/G3 API anchors exist but do not change them here.
anchors = [
    "public void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void drawRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)",
    "public void fillRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)",
    "public void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)",
]
for a in anchors:
    if s.count(a) != 1:
        raise SystemExit("P1A_G2B_STAGE_FAIL neighbor anchor count for %s = %d" % (a, s.count(a)))

out = s.replace(old, new, 1)

# G1 and G2A must already be staged in the parent source.
for marker in [
    "P1A diagnostic only",
    "Pinned Aweigit/JDK8 final result is the following full fillRect",
    "rg35xxCopyAreaSourceOver",
]:
    if marker not in out:
        raise SystemExit("P1A_G2B_STAGE_FAIL parent marker missing: %s" % marker)

# No new game-specific marker in this delta.
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if out.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_G2B_STAGE_FAIL game-specific marker delta: %s" % forbidden)

# Only the six-arg method/helper may be new. Neighbor signatures must retain count.
for a in anchors:
    if out.count(a) != parent.count(a):
        raise SystemExit("P1A_G2B_STAGE_FAIL neighbor signature drift: %s" % a)

pg.write_text(out, encoding="utf-8")
print("P1A_G2B_STAGE=PASS")
print("P1A_G2B_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2B_CHANGED_METHOD=Graphics.fillTriangle_6ARG_DIAGNOSTIC_ONLY")
print("P1A_G2B_ALGORITHM=EXACT_DEVICE_PROVEN_COMP02_SCANLINE")
print("P1A_G2B_DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED")
print("P1A_G2B_ARC_ROUNDRECT_NEIGHBORS=UNCHANGED")
print("P1A_G2B_CORE2D_CHANGE=NO")
