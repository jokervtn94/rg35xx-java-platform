#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2b-filltriangle-jdk8-raster.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
parent = s

old = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

new = '''\tprivate void rg35xxFillTriangleJdk8(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Specialized from OpenJDK ProcessPath.FillPolygon for exactly three\n\t\t// straight integer-coordinate edges. MDP_PREC=10, horizontal edges\n\t\t// skipped, upper endpoint excluded, inclusive scanline span endpoints.\n\t\tfinal int MDP_PREC = 10;\n\t\tfinal int MDP_MULT = 1 << MDP_PREC;\n\t\tfinal int MDP_MASK = MDP_MULT - 1;\n\t\tfinal int MDP_W_MASK = -MDP_MULT;\n\n\t\tint[] vx = new int[]{x1 + translateX, x2 + translateX, x3 + translateX};\n\t\tint[] vy = new int[]{y1 + translateY, y2 + translateY, y3 + translateY};\n\t\tint[] edgeX = new int[3];\n\t\tint[] edgeDX = new int[3];\n\t\tint[] edgeY0 = new int[3];\n\t\tint[] edgeY1 = new int[3];\n\t\tboolean[] edgeValid = new boolean[3];\n\n\t\tint globalYMin = Integer.MAX_VALUE;\n\t\tint globalYMax = Integer.MIN_VALUE;\n\t\tfor(int i = 0; i < 3; i++)\n\t\t{\n\t\t\tint j = (i + 1) % 3;\n\t\t\tint X1 = vx[i] * MDP_MULT;\n\t\t\tint Y1 = vy[i] * MDP_MULT;\n\t\t\tint X2 = vx[j] * MDP_MULT;\n\t\t\tint Y2 = vy[j] * MDP_MULT;\n\t\t\tif(Y1 == Y2) continue;\n\n\t\t\tint dX = X2 - X1;\n\t\t\tint dY = Y2 - Y1;\n\t\t\tint lowX, lowY, highY;\n\t\t\tif(Y1 < Y2)\n\t\t\t{\n\t\t\t\tlowX = X1; lowY = Y1; highY = Y2;\n\t\t\t}\n\t\t\telse\n\t\t\t{\n\t\t\t\tlowX = X2; lowY = Y2; highY = Y1;\n\t\t\t}\n\n\t\t\t// Same first scanline hashing rule used by ProcessPath.FillPolygon.\n\t\t\tint firstY = ((lowY - 1) & MDP_W_MASK) + MDP_MULT;\n\t\t\tint dy = firstY - lowY;\n\t\t\tint stepX = (int)(((long)dX * (long)MDP_MULT) / (long)dY);\n\t\t\tint firstX = lowX + (int)(((long)dX * (long)dy) / (long)dY);\n\n\t\t\tedgeX[i] = firstX;\n\t\t\tedgeDX[i] = stepX;\n\t\t\tedgeY0[i] = firstY;\n\t\t\tedgeY1[i] = highY;\n\t\t\tedgeValid[i] = true;\n\t\t\tif(firstY < globalYMin) globalYMin = firstY;\n\t\t\tif(highY > globalYMax) globalYMax = highY;\n\t\t}\n\n\t\tif(globalYMin == Integer.MAX_VALUE || globalYMax <= globalYMin) return;\n\n\t\tint pw = platformImage.getRG35XXWidth();\n\t\tint ph = platformImage.getRG35XXHeight();\n\t\tint clipL = clipX < 0 ? 0 : clipX;\n\t\tint clipT = clipY < 0 ? 0 : clipY;\n\t\tint clipR = clipX + clipWidth;\n\t\tint clipB = clipY + clipHeight;\n\t\tif(clipR > pw) clipR = pw;\n\t\tif(clipB > ph) clipB = ph;\n\t\tif(clipR <= clipL || clipB <= clipT) return;\n\n\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\t\tint[] activeX = new int[3];\n\n\t\tfor(int yFixed = globalYMin; yFixed <= globalYMax; yFixed += MDP_MULT)\n\t\t{\n\t\t\tint y = yFixed >> MDP_PREC;\n\t\t\tint count = 0;\n\t\t\tfor(int e = 0; e < 3; e++)\n\t\t\t{\n\t\t\t\tif(!edgeValid[e] || yFixed < edgeY0[e] || yFixed >= edgeY1[e]) continue;\n\t\t\t\tint rows = (yFixed - edgeY0[e]) >> MDP_PREC;\n\t\t\t\tactiveX[count++] = edgeX[e] + rows * edgeDX[e];\n\t\t\t}\n\t\t\tif(count < 2) continue;\n\n\t\t\t// Three-edge convex polygon: sorting intersections is equivalent to\n\t\t\t// the ProcessPath active-edge sort for determining the outer span.\n\t\t\tfor(int i = 1; i < count; i++)\n\t\t\t{\n\t\t\t\tint v = activeX[i], k = i - 1;\n\t\t\t\twhile(k >= 0 && activeX[k] > v)\n\t\t\t\t{\n\t\t\t\t\tactiveX[k + 1] = activeX[k]; k--;\n\t\t\t\t}\n\t\t\t\tactiveX[k + 1] = v;\n\t\t\t}\n\n\t\t\tint leftFixed = activeX[0];\n\t\t\tint rightFixed = activeX[count - 1];\n\t\t\tint xl = (leftFixed + MDP_MASK) >> MDP_PREC;\n\t\t\tint xr = (rightFixed - 1) >> MDP_PREC;\n\t\t\tif(y < clipT || y >= clipB || y < 0 || y >= ph) continue;\n\t\t\tif(xl < clipL) xl = clipL;\n\t\t\tif(xr >= clipR) xr = clipR - 1;\n\t\t\tif(xl < 0) xl = 0;\n\t\t\tif(xr >= pw) xr = pw - 1;\n\t\t\tif(xl <= xr) Arrays.fill(dst, y * pw + xl, y * pw + xr + 1, argb);\n\t\t}\n\t}\n\n\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxFillTriangleJdk8(x1, y1, x2, y2, x3, y3);\n\t\t\treturn;\n\t\t}\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

if s.count(old) != 1:
    raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL six-arg anchor count=%d" % s.count(old))
if "rg35xxFillTriangleJdk8" in s:
    raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL helper already present")

# G1 + G2A clean parent markers must already be staged.
for marker in [
    "rg35xxCopyAreaSourceOver",
    "Pinned Aweigit/JDK8 final result is the following full fillRect",
]:
    if marker not in s:
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL parent marker missing: %s" % marker)

neighbors = [
    "public void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void drawRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)",
    "public void fillRoundRect(int x, int y, int width, int height, int arcWidth, int arcHeight)",
    "public void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)",
]
for a in neighbors:
    if s.count(a) != 1:
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL neighbor anchor count: %s" % a)

out = s.replace(old, new, 1)

for token in [
    "final int MDP_PREC = 10;",
    "int firstY = ((lowY - 1) & MDP_W_MASK) + MDP_MULT;",
    "int stepX = (int)(((long)dX * (long)MDP_MULT) / (long)dY);",
    "int xl = (leftFixed + MDP_MASK) >> MDP_PREC;",
    "int xr = (rightFixed - 1) >> MDP_PREC;",
    "Arrays.fill(dst, y * pw + xl, y * pw + xr + 1, argb);",
]:
    if token not in out:
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL semantic token missing: %s" % token)

for a in neighbors:
    if out.count(a) != parent.count(a):
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL neighbor signature drift: %s" % a)

for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if out.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL game-specific marker delta: %s" % forbidden)

pg.write_text(out, encoding="utf-8")
print("P1A_G2B_JDK8_STAGE=PASS")
print("P1A_G2B_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2B_CHANGED_METHOD=Graphics.fillTriangle_6ARG")
print("P1A_G2B_RASTER=OPENJDK_PROCESSPATH_FILLPOLYGON_SPECIALIZED_TRIANGLE")
print("P1A_G2B_FIXEDPOINT=MDP_PREC_10")
print("P1A_G2B_SPAN=CEIL_LEFT_FLOOR_RIGHT_EPSILON_INCLUSIVE")
print("P1A_G2B_DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED")
print("P1A_G2B_CORE2D_CHANGE=NO")
