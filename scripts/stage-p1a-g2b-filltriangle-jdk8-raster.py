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

new = '''\tprivate static int rg35xxSSIOutcode(float x, float y, int lox, int loy, int hix, int hiy)\n\t{\n\t\tint out = 0;\n\t\tif(y <= loy) out = 4;\n\t\telse if(y >= hiy) out = 8;\n\t\tif(x <= lox) out |= 1;\n\t\telse if(x >= hix) out |= 2;\n\t\treturn out;\n\t}\n\n\tprivate static int rg35xxSSIAppendSegment(float x0, float y0, float x1, float y1,\n\t\tint lox, int loy, int hix, int hiy,\n\t\tint[] segCurX, int[] segCurY, int[] segLastY, int[] segError,\n\t\tint[] segBumpX, int[] segBumpErr, int count)\n\t{\n\t\tif(y0 > y1)\n\t\t{\n\t\t\tfloat tx = x0; x0 = x1; x1 = tx;\n\t\t\tfloat ty = y0; y0 = y1; y1 = ty;\n\t\t}\n\t\tint istarty = (int)Math.ceil(y0 - 0.5f);\n\t\tint ilasty = (int)Math.ceil(y1 - 0.5f);\n\t\tif(istarty >= ilasty || istarty >= hiy || ilasty <= loy) return count;\n\t\tif(count >= segCurX.length) return count;\n\n\t\tfloat dx = x1 - x0;\n\t\tfloat dy = y1 - y0;\n\t\tfloat slope = dx / dy;\n\t\tfloat ystartbump = istarty + 0.5f - y0;\n\t\tx0 += ystartbump * dx / dy;\n\t\tint istartx = (int)Math.ceil(x0 - 0.5f);\n\t\tfloat slopeFloor = (float)Math.floor(slope);\n\t\tint bumpx = (int)slopeFloor;\n\t\tint bumperr = (int)((slope - slopeFloor) * (double)0x7fffffff);\n\t\tint error = (int)((x0 - (istartx - 0.5f)) * (double)0x7fffffff);\n\n\t\tsegCurX[count] = istartx;\n\t\tsegCurY[count] = istarty;\n\t\tsegLastY[count] = ilasty;\n\t\tsegError[count] = error;\n\t\tsegBumpX[count] = bumpx;\n\t\tsegBumpErr[count] = bumperr;\n\t\treturn count + 1;\n\t}\n\n\tprivate static int rg35xxSSIAppendClosingSegment(float x0, float y0, float x1, float y1,\n\t\tint lox, int loy, int hix, int hiy,\n\t\tint[] segCurX, int[] segCurY, int[] segLastY, int[] segError,\n\t\tint[] segBumpX, int[] segBumpErr, int count)\n\t{\n\t\tfloat miny = Math.min(y0, y1);\n\t\tfloat maxy = Math.max(y0, y1);\n\t\tfloat minx = Math.min(x0, x1);\n\t\tfloat maxx = Math.max(x0, x1);\n\t\tif(maxy <= loy || miny >= hiy || minx >= hix) return count;\n\t\tif(maxx <= lox)\n\t\t{\n\t\t\treturn rg35xxSSIAppendSegment(maxx, y0, maxx, y1, lox, loy, hix, hiy,\n\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, count);\n\t\t}\n\t\treturn rg35xxSSIAppendSegment(x0, y0, x1, y1, lox, loy, hix, hiy,\n\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, count);\n\t}\n\n\tprivate void rg35xxFillTriangleJdk8SSI(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\t// Match the actual OpenJDK8 LoopPipe.fillPolygon path: ShapeSpanIterator\n\t\t// appendPoly + pixel-center spans, including its 0.25 normalization and\n\t\t// ERRSTEP_MAX fixed-error stepping. This is specialized to 3 points.\n\t\tint pw = platformImage.getRG35XXWidth();\n\t\tint ph = platformImage.getRG35XXHeight();\n\t\tint lox = Math.max(0, clipX);\n\t\tint loy = Math.max(0, clipY);\n\t\tint hix = Math.min(pw, clipX + clipWidth);\n\t\tint hiy = Math.min(ph, clipY + clipHeight);\n\t\tif(hix <= lox || hiy <= loy) return;\n\n\t\tfloat xoff = (float)translateX + 0.25f;\n\t\tfloat yoff = (float)translateY + 0.25f;\n\t\tfloat[] px = new float[]{((float)x1) + xoff, ((float)x2) + xoff, ((float)x3) + xoff};\n\t\tfloat[] py = new float[]{((float)y1) + yoff, ((float)y2) + yoff, ((float)y3) + yoff};\n\n\t\tint[] segCurX = new int[3];\n\t\tint[] segCurY = new int[3];\n\t\tint[] segLastY = new int[3];\n\t\tint[] segError = new int[3];\n\t\tint[] segBumpX = new int[3];\n\t\tint[] segBumpErr = new int[3];\n\t\tint segCount = 0;\n\n\t\tfloat movx = px[0], movy = py[0];\n\t\tfloat curx = movx, cury = movy;\n\t\tint out0 = rg35xxSSIOutcode(curx, cury, lox, loy, hix, hiy);\n\t\tfor(int i = 1; i < 3; i++)\n\t\t{\n\t\t\tfloat nx = px[i], ny = py[i];\n\t\t\tif(ny == cury)\n\t\t\t{\n\t\t\t\tif(nx != curx)\n\t\t\t\t{\n\t\t\t\t\tout0 = rg35xxSSIOutcode(nx, ny, lox, loy, hix, hiy);\n\t\t\t\t\tcurx = nx;\n\t\t\t\t}\n\t\t\t\tcontinue;\n\t\t\t}\n\n\t\t\tint out1 = rg35xxSSIOutcode(nx, ny, lox, loy, hix, hiy);\n\t\t\tint common = out0 & out1;\n\t\t\tif(common == 0)\n\t\t\t{\n\t\t\t\tsegCount = rg35xxSSIAppendSegment(curx, cury, nx, ny, lox, loy, hix, hiy,\n\t\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t\t}\n\t\t\telse if(common == 1)\n\t\t\t{\n\t\t\t\tsegCount = rg35xxSSIAppendSegment((float)lox, cury, (float)lox, ny, lox, loy, hix, hiy,\n\t\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t\t}\n\t\t\tout0 = out1;\n\t\t\tcurx = nx; cury = ny;\n\t\t}\n\n\t\tif(curx != movx || cury != movy)\n\t\t{\n\t\t\tsegCount = rg35xxSSIAppendClosingSegment(curx, cury, movx, movy, lox, loy, hix, hiy,\n\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t}\n\t\tif(segCount == 0) return;\n\n\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\t\tint[] xs = new int[3];\n\t\tfor(int y = loy; y < hiy; y++)\n\t\t{\n\t\t\tint n = 0;\n\t\t\tfor(int e = 0; e < segCount; e++)\n\t\t\t{\n\t\t\t\tif(segCurY[e] > y || segLastY[e] <= y) continue;\n\t\t\t\tint rows = y - segCurY[e];\n\t\t\t\tint x = segCurX[e] + rows * segBumpX[e];\n\t\t\t\tif(rows != 0)\n\t\t\t\t{\n\t\t\t\t\tlong stepError = ((long)segError[e]) + ((long)rows * (long)segBumpErr[e]);\n\t\t\t\t\tx += (int)(stepError >> 31);\n\t\t\t\t}\n\t\t\t\txs[n++] = x;\n\t\t\t}\n\t\t\tif(n == 0) continue;\n\n\t\t\tfor(int i = 1; i < n; i++)\n\t\t\t{\n\t\t\t\tint v = xs[i];\n\t\t\t\tint k = i - 1;\n\t\t\t\twhile(k >= 0 && xs[k] > v)\n\t\t\t\t{\n\t\t\t\t\txs[k + 1] = xs[k];\n\t\t\t\t\tk--;\n\t\t\t\t}\n\t\t\t\txs[k + 1] = v;\n\t\t\t}\n\n\t\t\tfor(int i = 0; i < n; i += 2)\n\t\t\t{\n\t\t\t\tint sx0 = xs[i];\n\t\t\t\tint sx1 = (i + 1 < n) ? xs[i + 1] : hix;\n\t\t\t\tif(sx0 < lox) sx0 = lox;\n\t\t\t\tif(sx1 > hix) sx1 = hix;\n\t\t\t\tif(sx1 <= sx0) continue;\n\t\t\t\tArrays.fill(dst, y * pw + sx0, y * pw + sx1, argb);\n\t\t\t}\n\t\t}\n\t}\n\n\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxFillTriangleJdk8SSI(x1, y1, x2, y2, x3, y3);\n\t\t\treturn;\n\t\t}\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t}\n'''

if s.count(old) != 1:
    raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL six-arg anchor count=%d" % s.count(old))
for helper in ["rg35xxFillTriangleJdk8SSI", "rg35xxSSIAppendSegment", "rg35xxSSIOutcode"]:
    if helper in s:
        raise SystemExit("P1A_G2B_JDK8_STAGE_FAIL helper already present: %s" % helper)

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
    "float xoff = (float)translateX + 0.25f;",
    "int istarty = (int)Math.ceil(y0 - 0.5f);",
    "int bumperr = (int)((slope - slopeFloor) * (double)0x7fffffff);",
    "long stepError = ((long)segError[e]) + ((long)rows * (long)segBumpErr[e]);",
    "int sx1 = (i + 1 < n) ? xs[i + 1] : hix;",
    "Arrays.fill(dst, y * pw + sx0, y * pw + sx1, argb);",
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
print("P1A_G2B_RASTER=OPENJDK8_LOOPPIPE_SHAPESPANITERATOR_SPECIALIZED_TRIANGLE")
print("P1A_G2B_NORMALIZE=PIXEL_CENTER_0_25")
print("P1A_G2B_EDGE_STEPPING=ERRSTEP_MAX_FLOAT32")
print("P1A_G2B_DIRECTGRAPHICS_FILLTRIANGLE_7ARG=UNCHANGED")
print("P1A_G2B_CORE2D_CHANGE=NO")
