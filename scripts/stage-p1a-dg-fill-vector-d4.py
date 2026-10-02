#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-dg-fill-vector-d4.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_DG_D4_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
parent = s

new_fill_poly = '''\tprivate static int rg35xxDGSSIOutcode(float x, float y, int lox, int loy, int hix, int hiy)\n\t{\n\t\tint out = 0;\n\t\tif(y <= loy) out = 4;\n\t\telse if(y >= hiy) out = 8;\n\t\tif(x <= lox) out |= 1;\n\t\telse if(x >= hix) out |= 2;\n\t\treturn out;\n\t}\n\n\tprivate static int rg35xxDGSSIAppendSegment(float x0, float y0, float x1, float y1,\n\t\tint lox, int loy, int hix, int hiy,\n\t\tint[] segCurX, int[] segCurY, int[] segLastY, int[] segError,\n\t\tint[] segBumpX, int[] segBumpErr, int count)\n\t{\n\t\tif(y0 > y1)\n\t\t{\n\t\t\tfloat tx = x0; x0 = x1; x1 = tx;\n\t\t\tfloat ty = y0; y0 = y1; y1 = ty;\n\t\t}\n\t\tint istarty = (int)Math.ceil(y0 - 0.5f);\n\t\tint ilasty = (int)Math.ceil(y1 - 0.5f);\n\t\tif(istarty >= ilasty || istarty >= hiy || ilasty <= loy) return count;\n\t\tif(count >= segCurX.length) return count;\n\n\t\tfloat dx = x1 - x0;\n\t\tfloat dy = y1 - y0;\n\t\tfloat slope = dx / dy;\n\t\tfloat ystartbump = istarty + 0.5f - y0;\n\t\tx0 += ystartbump * dx / dy;\n\t\tint istartx = (int)Math.ceil(x0 - 0.5f);\n\t\tdouble slopeFloor = Math.floor((double)slope);\n\t\tint bumpx = (int)slopeFloor;\n\t\tint bumperr = (int)(((double)slope - slopeFloor) * (double)0x7fffffff);\n\t\tint error = (int)((x0 - (istartx - 0.5f)) * (double)0x7fffffff);\n\n\t\tsegCurX[count] = istartx;\n\t\tsegCurY[count] = istarty;\n\t\tsegLastY[count] = ilasty;\n\t\tsegError[count] = error;\n\t\tsegBumpX[count] = bumpx;\n\t\tsegBumpErr[count] = bumperr;\n\t\treturn count + 1;\n\t}\n\n\tprivate static int rg35xxDGSSIAppendClosingSegment(float x0, float y0, float x1, float y1,\n\t\tint lox, int loy, int hix, int hiy,\n\t\tint[] segCurX, int[] segCurY, int[] segLastY, int[] segError,\n\t\tint[] segBumpX, int[] segBumpErr, int count)\n\t{\n\t\tfloat miny = Math.min(y0, y1);\n\t\tfloat maxy = Math.max(y0, y1);\n\t\tfloat minx = Math.min(x0, x1);\n\t\tfloat maxx = Math.max(x0, x1);\n\t\tif(maxy <= loy || miny >= hiy || minx >= hix) return count;\n\t\tif(maxx <= lox)\n\t\t{\n\t\t\treturn rg35xxDGSSIAppendSegment(maxx, y0, maxx, y1, lox, loy, hix, hiy,\n\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, count);\n\t\t}\n\t\treturn rg35xxDGSSIAppendSegment(x0, y0, x1, y1, lox, loy, hix, hiy,\n\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, count);\n\t}\n\n\tprivate void rg35xxDGFillPolygonSSI(int[] xPoints, int[] yPoints, int nPoints, int argbColor)\n\t{\n\t\tif(nPoints <= 0) return;\n\t\tint pw = platformImage.getRG35XXWidth();\n\t\tint ph = platformImage.getRG35XXHeight();\n\t\tint lox = Math.max(0, clipX);\n\t\tint loy = Math.max(0, clipY);\n\t\tint hix = Math.min(pw, clipX + clipWidth);\n\t\tint hiy = Math.min(ph, clipY + clipHeight);\n\t\tif(hix <= lox || hiy <= loy) return;\n\n\t\tfloat xoff = (float)translateX + 0.25f;\n\t\tfloat yoff = (float)translateY + 0.25f;\n\t\tint[] segCurX = new int[nPoints];\n\t\tint[] segCurY = new int[nPoints];\n\t\tint[] segLastY = new int[nPoints];\n\t\tint[] segError = new int[nPoints];\n\t\tint[] segBumpX = new int[nPoints];\n\t\tint[] segBumpErr = new int[nPoints];\n\t\tint segCount = 0;\n\n\t\tfloat movx = ((float)xPoints[0]) + xoff;\n\t\tfloat movy = ((float)yPoints[0]) + yoff;\n\t\tfloat curx = movx, cury = movy;\n\t\tint out0 = rg35xxDGSSIOutcode(curx, cury, lox, loy, hix, hiy);\n\t\tfor(int i = 1; i < nPoints; i++)\n\t\t{\n\t\t\tfloat nx = ((float)xPoints[i]) + xoff;\n\t\t\tfloat ny = ((float)yPoints[i]) + yoff;\n\t\t\tif(ny == cury)\n\t\t\t{\n\t\t\t\tif(nx != curx)\n\t\t\t\t{\n\t\t\t\t\tout0 = rg35xxDGSSIOutcode(nx, ny, lox, loy, hix, hiy);\n\t\t\t\t\tcurx = nx;\n\t\t\t\t}\n\t\t\t\tcontinue;\n\t\t\t}\n\t\t\tint out1 = rg35xxDGSSIOutcode(nx, ny, lox, loy, hix, hiy);\n\t\t\tint common = out0 & out1;\n\t\t\tif(common == 0)\n\t\t\t{\n\t\t\t\tsegCount = rg35xxDGSSIAppendSegment(curx, cury, nx, ny, lox, loy, hix, hiy,\n\t\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t\t}\n\t\t\telse if(common == 1)\n\t\t\t{\n\t\t\t\tsegCount = rg35xxDGSSIAppendSegment((float)lox, cury, (float)lox, ny, lox, loy, hix, hiy,\n\t\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t\t}\n\t\t\tout0 = out1; curx = nx; cury = ny;\n\t\t}\n\t\tif(curx != movx || cury != movy)\n\t\t{\n\t\t\tsegCount = rg35xxDGSSIAppendClosingSegment(curx, cury, movx, movy, lox, loy, hix, hiy,\n\t\t\t\tsegCurX, segCurY, segLastY, segError, segBumpX, segBumpErr, segCount);\n\t\t}\n\t\tif(segCount == 0) return;\n\n\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\tint[] xs = new int[segCount];\n\t\tfor(int y = loy; y < hiy; y++)\n\t\t{\n\t\t\tint n = 0;\n\t\t\tfor(int e = 0; e < segCount; e++)\n\t\t\t{\n\t\t\t\tif(segCurY[e] > y || segLastY[e] <= y) continue;\n\t\t\t\tint rows = y - segCurY[e];\n\t\t\t\tint x = segCurX[e] + rows * segBumpX[e];\n\t\t\t\tif(rows != 0)\n\t\t\t\t{\n\t\t\t\t\tlong stepError = ((long)segError[e]) + ((long)rows * (long)segBumpErr[e]);\n\t\t\t\t\tx += (int)(stepError >> 31);\n\t\t\t\t}\n\t\t\t\txs[n++] = x;\n\t\t\t}\n\t\t\tif(n == 0) continue;\n\t\t\tfor(int i = 1; i < n; i++)\n\t\t\t{\n\t\t\t\tint v = xs[i], k = i - 1;\n\t\t\t\twhile(k >= 0 && xs[k] > v)\n\t\t\t\t{\n\t\t\t\t\txs[k + 1] = xs[k]; k--;\n\t\t\t\t}\n\t\t\t\txs[k + 1] = v;\n\t\t\t}\n\t\t\tfor(int i = 0; i < n; i += 2)\n\t\t\t{\n\t\t\t\tint sx0 = xs[i];\n\t\t\t\tint sx1 = (i + 1 < n) ? xs[i + 1] : hix;\n\t\t\t\tif(sx0 < lox) sx0 = lox;\n\t\t\t\tif(sx1 > hix) sx1 = hix;\n\t\t\t\tif(sx1 <= sx0) continue;\n\t\t\t\tint base = y * pw;\n\t\t\t\tfor(int x = sx0; x < sx1; x++)\n\t\t\t\t{\n\t\t\t\t\tint di = base + x;\n\t\t\t\t\tdst[di] = rg35xxCopyAreaSourceOver(argbColor, dst[di]);\n\t\t\t\t}\n\t\t\t}\n\t\t}\n\t}\n\n\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n\t{\n\t\tint temp = color;\n\t\tint[] x = new int[nPoints];\n\t\tint[] y = new int[nPoints];\n\n\t\tfor(int i=0; i<nPoints; i++)\n\t\t{\n\t\t\tx[i] = xPoints[xOffset+i];\n\t\t\ty[i] = yPoints[yOffset+i];\n\t\t}\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxDGFillPolygonSSI(x, y, nPoints, argbColor);\n\t\t\treturn;\n\t\t}\n\n\t\tsetAlphaRGB(argbColor);\n\t\tgc.fillPolygon(x, y, nPoints);\n\t\tsetColor(temp);\n\t}\n'''

new_fill_tri7 = '''\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)\n\t{\n\t\t//System.out.println("fillTriangle"); // Found In Use\n\t\tint temp = color;\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxDGFillPolygonSSI(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3, argbColor);\n\t\t\treturn;\n\t\t}\n\t\tsetAlphaRGB(argbColor);\n\t\tgc.fillPolygon(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);\n\t\tsetColor(temp);\n\t}\n'''

fill_poly_sig = "\tpublic void fillPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n"
fill_tri6_sig = "\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3)\n"
fill_tri7_sig = "\tpublic void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)\n"
get_pixels_byte_sig = "\tpublic void getPixels(byte[] pixels, byte[] transparencyMask, int offset, int scanlength, int x, int y, int width, int height, int format)\n"

for sig, label in [
    (fill_poly_sig, "fillPolygon signature"),
    (fill_tri6_sig, "fillTriangle6 boundary"),
    (fill_tri7_sig, "fillTriangle7 signature"),
    (get_pixels_byte_sig, "getPixels byte boundary"),
]:
    if s.count(sig) != 1:
        raise SystemExit("P1A_DG_D4_STAGE_FAIL %s count=%d" % (label, s.count(sig)))

poly_start = s.index(fill_poly_sig)
poly_end = s.index(fill_tri6_sig, poly_start)
if poly_end <= poly_start:
    raise SystemExit("P1A_DG_D4_STAGE_FAIL fillPolygon boundary order")

tri7_start = s.index(fill_tri7_sig, poly_end)
tri7_end = s.index(get_pixels_byte_sig, tri7_start)
if tri7_end <= tri7_start:
    raise SystemExit("P1A_DG_D4_STAGE_FAIL fillTriangle7 boundary order")

for forbidden_helper in ["rg35xxDGFillPolygonSSI", "rg35xxDGSSIAppendSegment", "rg35xxDGSSIOutcode"]:
    if forbidden_helper in s:
        raise SystemExit("P1A_DG_D4_STAGE_FAIL helper preexists: %s" % forbidden_helper)
for required in [
    "private static int rg35xxCopyAreaSourceOver(int s, int d)",
    "private void rg35xxFillTriangleJdk8SSI(int x1, int y1, int x2, int y2, int x3, int y3)",
    "public void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
    "public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)",
]:
    if required not in s:
        raise SystemExit("P1A_DG_D4_STAGE_FAIL parent marker missing: %s" % required)

s = s[:poly_start] + new_fill_poly + s[poly_end:]
tri7_start = s.index(fill_tri7_sig)
tri7_end = s.index(get_pixels_byte_sig, tri7_start)
s = s[:tri7_start] + new_fill_tri7 + s[tri7_end:]

for token in [
    "double slopeFloor = Math.floor((double)slope);",
    "int bumperr = (int)(((double)slope - slopeFloor) * (double)0x7fffffff);",
    "dst[di] = rg35xxCopyAreaSourceOver(argbColor, dst[di]);",
    "rg35xxDGFillPolygonSSI(x, y, nPoints, argbColor);",
    "rg35xxDGFillPolygonSSI(new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3, argbColor);",
]:
    if token not in s:
        raise SystemExit("P1A_DG_D4_STAGE_FAIL semantic token missing: %s" % token)

# Fail closed on forbidden scope expansion.
for signature in [
    "public void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)",
    "public void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int argbColor)",
    "public void drawPixels(byte[] pixels",
    "public void drawPixels(int[] pixels",
    "public void drawPixels(short[] pixels",
]:
    if s.count(signature) != parent.count(signature):
        raise SystemExit("P1A_DG_D4_STAGE_FAIL forbidden signature drift: %s" % signature)
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if s.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_DG_D4_STAGE_FAIL game-specific marker delta: %s" % forbidden)

pg.write_text(s, encoding="utf-8")
print("P1A_DG_D4_STAGE=PASS")
print("P1A_DG_D4_OWNER=OPENJDK8_SHAPESPANITERATOR_APPENDPOLY")
print("P1A_DG_D4_METHODS=DirectGraphics.fillTriangle_7arg,DirectGraphics.fillPolygon")
print("P1A_DG_D4_WINDING=EVEN_ODD")
print("P1A_DG_D4_EDGE_PRECISION=DOUBLE_SLOPE_FLOOR_SUBTRACTION_BEFORE_FRACTTOJINT")
print("P1A_DG_D4_ALPHA=G1_EXACT_8BIT_SRCOVER")
print("P1A_DG_D4_CORE2D_CHANGE=NO")
print("P1A_DG_D4_DRAW_VECTOR_CHANGE=NO")
print("P1A_DG_D4_GAME_SPECIFIC_CODE=NO")