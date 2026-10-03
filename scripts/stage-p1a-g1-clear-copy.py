#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g1-clear-copy.py <stage-src>")

root = Path(sys.argv[1]).resolve()
rel = Path("org/recompile/mobile/PlatformGraphics.java")
path = root / rel
if not path.is_file():
    raise SystemExit("P1A_G1_STAGE_FAIL missing %s" % path)

text = path.read_text(encoding="utf-8")
parent_text = text


def replace_once(old, new, label):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit("P1A_G1_STAGE_FAIL %s expected=1 found=%d" % (label, count))
    text = text.replace(old, new, 1)
    print("P1A_G1_STAGE_REWRITE=%s" % label)


replace_once(
    "\tpublic void clearRect(int x, int y, int width, int height)\n"
    "\t{\n"
    "\t\tgc.clearRect(x, y, width, height);\n"
    "\t}\n",
    "\tpublic void clearRect(int x, int y, int width, int height)\n"
    "\t{\n"
    "\t\tif (platformImage.isRG35XXRaw())\n"
    "\t\t{\n"
    "\t\t\tif (width <= 0 || height <= 0) { return; }\n"
    "\t\t\tint px = x + translateX;\n"
    "\t\t\tint py = y + translateY;\n"
    "\t\t\tint left = Math.max(px, Math.max(clipX, 0));\n"
    "\t\t\tint top = Math.max(py, Math.max(clipY, 0));\n"
    "\t\t\tint right = Math.min(px + width, Math.min(clipX + clipWidth, platformImage.getRG35XXWidth()));\n"
    "\t\t\tint bottom = Math.min(py + height, Math.min(clipY + clipHeight, platformImage.getRG35XXHeight()));\n"
    "\t\t\tif (right <= left || bottom <= top) { return; }\n"
    "\t\t\tint[] dst = platformImage.getRG35XXPixels();\n"
    "\t\t\tint stride = platformImage.getRG35XXWidth();\n"
    "\t\t\tfor (int row = top; row < bottom; row++)\n"
    "\t\t\t{\n"
    "\t\t\t\tArrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
    "\t\tgc.clearRect(x, y, width, height);\n"
    "\t}\n",
    "PlatformGraphics.clearRect_RAW2D",
)

replace_once(
    "\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tx = AnchorX(x, subw, anchor);\n"
    "\t\ty = AnchorY(y, subh, anchor);\n\n"
    "\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n"
    "\t\tgc.drawImage(sub, x, y, null);\n"
    "\t}\n",
    "\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n"
    "\t{\n"
    "\t\tx = AnchorX(x, subw, anchor);\n"
    "\t\ty = AnchorY(y, subh, anchor);\n\n"
    "\t\tif (platformImage.isRG35XXRaw())\n"
    "\t\t{\n"
    "\t\t\tif (subw <= 0 || subh <= 0) { return; }\n"
    "\t\t\tint[] pixels = platformImage.getRG35XXPixels();\n"
    "\t\t\tint imageWidth = platformImage.getRG35XXWidth();\n"
    "\t\t\tint imageHeight = platformImage.getRG35XXHeight();\n"
    "\t\t\tint dstX = x + translateX;\n"
    "\t\t\tint dstY = y + translateY;\n"
    "\t\t\tfor (int row = 0; row < subh; row++)\n"
    "\t\t\t{\n"
    "\t\t\t\tint sy = suby + row;\n"
    "\t\t\t\tint dy = dstY + row;\n"
    "\t\t\t\tfor (int col = 0; col < subw; col++)\n"
    "\t\t\t\t{\n"
    "\t\t\t\t\tint sx = subx + col;\n"
    "\t\t\t\t\tint dx = dstX + col;\n"
    "\t\t\t\t\tif (dx < 0 || dy < 0 || dx >= imageWidth || dy >= imageHeight ||\n"
    "\t\t\t\t\t\tdx < clipX || dy < clipY || dx >= clipX + clipWidth || dy >= clipY + clipHeight)\n"
    "\t\t\t\t\t{\n"
    "\t\t\t\t\t\tcontinue;\n"
    "\t\t\t\t\t}\n"
    "\t\t\t\t\tint si = sy * imageWidth + sx;\n"
    "\t\t\t\t\tint di = dy * imageWidth + dx;\n"
    "\t\t\t\t\tpixels[di] = rg35xxCopyAreaSourceOver(pixels[si], pixels[di]);\n"
    "\t\t\t\t}\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n\n"
    "\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n"
    "\t\tgc.drawImage(sub, x, y, null);\n"
    "\t}\n\n"
    "\tprivate static int rg35xxCopyAreaMul8(int a, int b)\n"
    "\t{\n"
    "\t\treturn (a * b + 127) / 255;\n"
    "\t}\n\n"
    "\tprivate static int rg35xxCopyAreaDiv8(int a, int b)\n"
    "\t{\n"
    "\t\tif (b <= 0) { return 0; }\n"
    "\t\tif (a >= b) { return 255; }\n"
    "\t\tlong inc = (((255L << 24) + (b / 2)) / b);\n"
    "\t\treturn (int)(((1L << 23) + ((long)a * inc)) >> 24);\n"
    "\t}\n\n"
    "\tprivate static int rg35xxCopyAreaSourceOver(int s, int d)\n"
    "\t{\n"
    "\t\tint sa = (s >>> 24) & 0xFF;\n"
    "\t\tif (sa == 0) { return d; }\n"
    "\t\tif (sa == 255) { return s; }\n"
    "\t\tint da = (d >>> 24) & 0xFF;\n"
    "\t\tint sr = (s >>> 16) & 0xFF;\n"
    "\t\tint sg = (s >>> 8) & 0xFF;\n"
    "\t\tint sb = s & 0xFF;\n"
    "\t\tint dr = (d >>> 16) & 0xFF;\n"
    "\t\tint dg = (d >>> 8) & 0xFF;\n"
    "\t\tint db = d & 0xFF;\n"
    "\t\tint r = rg35xxCopyAreaMul8(sa, sr);\n"
    "\t\tint g = rg35xxCopyAreaMul8(sa, sg);\n"
    "\t\tint b = rg35xxCopyAreaMul8(sa, sb);\n"
    "\t\tint dstA = rg35xxCopyAreaMul8(255 - sa, da);\n"
    "\t\tint outA = sa + dstA;\n"
    "\t\tr += rg35xxCopyAreaMul8(dstA, dr);\n"
    "\t\tg += rg35xxCopyAreaMul8(dstA, dg);\n"
    "\t\tb += rg35xxCopyAreaMul8(dstA, db);\n"
    "\t\tif (outA > 0 && outA < 255)\n"
    "\t\t{\n"
    "\t\t\tr = rg35xxCopyAreaDiv8(r, outA);\n"
    "\t\t\tg = rg35xxCopyAreaDiv8(g, outA);\n"
    "\t\t\tb = rg35xxCopyAreaDiv8(b, outA);\n"
    "\t\t}\n"
    "\t\treturn (outA << 24) | (r << 16) | (g << 8) | b;\n"
    "\t}\n",
    "PlatformGraphics.copyArea_RAW2D_LIVE_RASTER_JDK8_MUL8_DIV8",
)

# Fail closed on the accepted coordinate contract, JDK8-observed live-raster
# traversal, and exact OpenJDK 8-bit compositing arithmetic. Do not route
# copyArea through protected Core2D.blit.
for token in [
    "int px = x + translateX;",
    "int py = y + translateY;",
    "Arrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);",
    "int dstX = x + translateX;",
    "int dstY = y + translateY;",
    "for (int row = 0; row < subh; row++)",
    "for (int col = 0; col < subw; col++)",
    "pixels[di] = rg35xxCopyAreaSourceOver(pixels[si], pixels[di]);",
    "private static int rg35xxCopyAreaMul8(int a, int b)",
    "return (a * b + 127) / 255;",
    "private static int rg35xxCopyAreaDiv8(int a, int b)",
    "long inc = (((255L << 24) + (b / 2)) / b);",
    "private static int rg35xxCopyAreaSourceOver(int s, int d)",
]:
    if token not in text:
        raise SystemExit("P1A_G1_STAGE_FAIL missing semantic token: %s" % token)

copy_start = text.index("\tpublic void copyArea(")
copy_end = text.index("\n\tpublic void drawArc", copy_start)
copy_block = text[copy_start:copy_end]
if "RG35XXCore2D.blit" in copy_block:
    raise SystemExit("P1A_G1_STAGE_FAIL copyArea must not modify protected Core2D.blit semantics")

# Parent staging history may contain diagnostic names in comments/log strings.
# G1 must not add any new game-specific marker; compare delta, not whole parent.
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if text.count(forbidden) != parent_text.count(forbidden):
        raise SystemExit("P1A_G1_STAGE_FAIL game-specific marker delta: %s" % forbidden)

path.write_text(text, encoding="utf-8")
print("P1A_G1_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G1_CHANGED_SOURCE=org/recompile/mobile/PlatformGraphics.java")
print("P1A_G1_METHODS=clearRect,copyArea")
print("P1A_G1_COPYAREA_SEMANTICS=JDK8_LIVE_RASTER_TOP_TO_BOTTOM_LEFT_TO_RIGHT")
print("P1A_G1_COPYAREA_ALPHA=JDK8_MUL8_DIV8_SRCOVER")
print("P1A_G1_CORE2D_CHANGE=NO")
print("P1A_G1_GAME_SPECIFIC_MARKER_DELTA=NO")
print("P1A_G1_STAGE=PASS")
