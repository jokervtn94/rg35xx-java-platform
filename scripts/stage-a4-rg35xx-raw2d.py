#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: stage-a4-rg35xx-raw2d.py <stage-src> <audit-log>")

root = Path(sys.argv[1]).resolve()
audit_path = Path(sys.argv[2]).resolve()
if not root.is_dir():
    raise SystemExit("A4_RAW2D_FAIL stage source missing: %s" % root)

notes = []

def path(rel):
    return root / rel

def read(rel):
    return path(rel).read_text(encoding="utf-8")

def write(rel, text):
    path(rel).write_text(text, encoding="utf-8")

def note(rel, detail):
    notes.append("A4_RAW2D\t%s\t%s" % (rel, detail))

def replace_once(rel, old, new, label):
    text = read(rel)
    found = text.count(old)
    if found != 1:
        raise SystemExit("A4_RAW2D_FAIL %s expected=1 found=%d file=%s" % (label, found, rel))
    write(rel, text.replace(old, new, 1))
    note(rel, label)

def sub_once(rel, pattern, repl, label, flags=0):
    text = read(rel)
    text2, n = re.subn(pattern, repl, text, count=1, flags=flags)
    if n != 1:
        raise SystemExit("A4_RAW2D_FAIL %s expected=1 found=%d file=%s" % (label, n, rel))
    write(rel, text2)
    note(rel, label)

# Font: avoid BufferedImage/Graphics2D/Toolkit initialization when the A4
# raw-2D property is enabled. Metrics are deliberately minimal; A4 does not
# claim text/font compatibility. Full font acceptance remains A5 scope.
rel = "javax/microedition/lcdui/Font.java"
replace_once(
    rel,
    "\t\tsize = fontSize;\n",
    "\t\tsize = fontSize;\n\t\tif (Boolean.getBoolean(\"rg35xx.raw2d\"))\n\t\t{\n\t\t\tawtFont = null;\n\t\t\tfm = null;\n\t\t\treturn;\n\t\t}\n",
    "font-constructor-bypass-awt-toolkit",
)
replace_once(rel, "\t\treturn fm.charWidth(ch); ", "\t\tif (fm == null) { return (convertSize(size) + 1) / 2; }\n\t\treturn fm.charWidth(ch); ", "font-charwidth-raw-fallback")
replace_once(rel, "\t\treturn fm.getHeight();", "\t\tif (fm == null) { return convertSize(size) + 2; }\n\t\treturn fm.getHeight();", "font-height-raw-fallback")
replace_once(rel, "\t\treturn fm.stringWidth(str); ", "\t\tif (fm == null) { return str.length() * ((convertSize(size) + 1) / 2); }\n\t\treturn fm.stringWidth(str); ", "font-stringwidth-raw-fallback")

# PlatformImage: blank LCD/GameCanvas images use a raw ARGB int[] instead of a
# BufferedImage. AWT-backed constructors remain unchanged for later A5 work.
rel = "org/recompile/mobile/PlatformImage.java"
replace_once(
    rel,
    "\tprotected BufferedImage canvas;\n\tprotected PlatformGraphics gc;\n",
    "\tprotected BufferedImage canvas;\n\tprotected PlatformGraphics gc;\n\tprotected int[] rg35xxPixels;\n\n\tpublic boolean isRG35XXRaw() { return rg35xxPixels != null; }\n\tpublic int[] getRG35XXPixels() { return rg35xxPixels; }\n\tpublic int getRG35XXWidth() { return width; }\n\tpublic int getRG35XXHeight() { return height; }\n",
    "platformimage-add-raw-framebuffer",
)
blank_pattern = r"\tpublic PlatformImage\(int Width, int Height\)\n\t\{.*?\n\t\}\n\n\tpublic PlatformImage\(String name\)"
blank_repl = """\tpublic PlatformImage(int Width, int Height)\n\t{\n\t\t// Create blank Image\n\t\twidth = Width;\n\t\theight = Height;\n\n\t\tif (Boolean.getBoolean(\"rg35xx.raw2d\"))\n\t\t{\n\t\t\tif (width < 1) { width = 1; }\n\t\t\tif (height < 1) { height = 1; }\n\t\t\trg35xxPixels = new int[width * height];\n\t\t\tArrays.fill(rg35xxPixels, 0xFFFFFFFF);\n\t\t\tcreateGraphics();\n\t\t\tgc.setColor(0x000000);\n\t\t\tplatformImage = this;\n\t\t\treturn;\n\t\t}\n\n\t\tcanvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_ARGB);\n\t\tcreateGraphics();\n\n\t\tgc.setColor(0xFFFFFF);\n\t\tgc.fillRect(0, 0, width, height);\n\t\tgc.setColor(0x000000);\n\n\t\tplatformImage = this;\n\t}\n\n\tpublic PlatformImage(String name)"""
sub_once(rel, blank_pattern, blank_repl, "platformimage-blank-raw-allocation", re.S)
replace_once(
    rel,
    "\tpublic void getRGB(int[] rgbData, int offset, int scanlength, int x, int y, int width, int height)\n\t{\n\t\tcanvas.getRGB(x, y, width, height, rgbData, offset, scanlength);\n\t}\n",
    "\tpublic void getRGB(int[] rgbData, int offset, int scanlength, int x, int y, int width, int height)\n\t{\n\t\tif (rg35xxPixels != null)\n\t\t{\n\t\t\tfor (int row = 0; row < height; row++)\n\t\t\t{\n\t\t\t\tSystem.arraycopy(rg35xxPixels, (y + row) * this.width + x, rgbData, offset + row * scanlength, width);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tcanvas.getRGB(x, y, width, height, rgbData, offset, scanlength);\n\t}\n",
    "platformimage-getrgb-raw",
)
replace_once(
    rel,
    "\tpublic int getARGB(int x, int y)\n\t{\n\t\treturn canvas.getRGB(x, y);\n\t}\n",
    "\tpublic int getARGB(int x, int y)\n\t{\n\t\tif (rg35xxPixels != null) { return rg35xxPixels[y * width + x]; }\n\t\treturn canvas.getRGB(x, y);\n\t}\n",
    "platformimage-getargb-raw",
)
replace_once(
    rel,
    "\tpublic int getPixel(int x, int y)\n\t{\n\t\tint[] rgbData = { 0 };\n\t\tcanvas.getRGB(x, y, 1, 1, rgbData, 0, 1);\n\t\treturn rgbData[0];\n\t}\n",
    "\tpublic int getPixel(int x, int y)\n\t{\n\t\tif (rg35xxPixels != null) { return rg35xxPixels[y * width + x]; }\n\t\tint[] rgbData = { 0 };\n\t\tcanvas.getRGB(x, y, 1, 1, rgbData, 0, 1);\n\t\treturn rgbData[0];\n\t}\n",
    "platformimage-getpixel-raw",
)
replace_once(
    rel,
    "\tpublic void setPixel(int x, int y, int color)\n\t{\n\t\tint[] rgbData = { color };\n\t\tgc.drawRGB(rgbData, 0, 1, x, y, 1, 1, false);\n\t}\n",
    "\tpublic void setPixel(int x, int y, int color)\n\t{\n\t\tif (rg35xxPixels != null)\n\t\t{\n\t\t\trg35xxPixels[y * width + x] = color;\n\t\t\treturn;\n\t\t}\n\t\tint[] rgbData = { color };\n\t\tgc.drawRGB(rgbData, 0, 1, x, y, 1, 1, false);\n\t}\n",
    "platformimage-setpixel-raw",
)

# PlatformGraphics: implement only the A4 blank-surface semantics needed for
# Canvas/GameCanvas: color, fillRect, clip, translate, flush and font state.
rel = "org/recompile/mobile/PlatformGraphics.java"
replace_once(rel, "import java.awt.FontMetrics;\n", "import java.awt.FontMetrics;\nimport java.util.Arrays;\n", "platformgraphics-import-arrays")
ctor_pattern = r"\tpublic PlatformGraphics\(PlatformImage image\)\n\t\{.*?\n\t\}\n\n\tpublic void reset\(\)"
ctor_repl = """\tpublic PlatformGraphics(PlatformImage image)\n\t{\n\t\tplatformImage = image;\n\t\tplatformGraphics = this;\n\n\t\tif (image.isRG35XXRaw())\n\t\t{\n\t\t\tcanvas = null;\n\t\t\tgc = null;\n\t\t\tclipX = 0;\n\t\t\tclipY = 0;\n\t\t\tclipWidth = image.getRG35XXWidth();\n\t\t\tclipHeight = image.getRG35XXHeight();\n\t\t\tsetColor(0, 0, 0);\n\t\t\tfm = null;\n\t\t\treturn;\n\t\t}\n\n\t\tcanvas = image.getCanvas();\n\t\tgc = canvas.createGraphics();\n\n\t\tclipX = 0;\n\t\tclipY = 0;\n\t\tclipWidth = canvas.getWidth();\n\t\tclipHeight = canvas.getHeight();\n\n\t\tsetColor(0,0,0);\n\t\tgc.setBackground(new Color(0, 0, 0, 0));\n\t\tgc.setFont(new java.awt.Font(\"MiSans Normal\",0, 14));\n\t\tfm=gc.getFontMetrics();\n\t}\n\n\tpublic void reset()"""
sub_once(rel, ctor_pattern, ctor_repl, "platformgraphics-constructor-raw", re.S)
replace_once(
    rel,
    "\tpublic void reset() //Internal use method, resets the Graphics object to its inital values\n\t{\n\t\ttranslate(-1 * translateX, -1 * translateY);\n\t\tsetClip(0, 0, canvas.getWidth(), canvas.getHeight());\n\t\tsetColor(0,0,0);\n\t\tsetFont(Font.getDefaultFont());\n\t\tsetStrokeStyle(SOLID);\n\t}\n",
    "\tpublic void reset() //Internal use method, resets the Graphics object to its inital values\n\t{\n\t\ttranslate(-1 * translateX, -1 * translateY);\n\t\tif (platformImage.isRG35XXRaw()) { setClip(0, 0, platformImage.getRG35XXWidth(), platformImage.getRG35XXHeight()); }\n\t\telse { setClip(0, 0, canvas.getWidth(), canvas.getHeight()); }\n\t\tsetColor(0,0,0);\n\t\tsetFont(Font.getDefaultFont());\n\t\tsetStrokeStyle(SOLID);\n\t}\n",
    "platformgraphics-reset-raw",
)
replace_once(
    rel,
    "\tpublic void flushGraphics(Image image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\t\ttry\n\t\t{\n\t\t\tBufferedImage sub = image.platformImage.getCanvas().getSubimage(x, y, width, height);\n\t\t\tgc.drawImage(sub, x, y, null);\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\t//System.out.println(\"flushGraphics A:\"+e.getMessage());\n\t\t}\n\t}\n",
    "\tpublic void flushGraphics(Image image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\t\tif (platformImage.isRG35XXRaw() && image.platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tint[] src = image.platformImage.getRG35XXPixels();\n\t\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\t\tint srcWidth = image.platformImage.getRG35XXWidth();\n\t\t\tint dstWidth = platformImage.getRG35XXWidth();\n\t\t\tint maxWidth = Math.min(width, Math.min(srcWidth - x, dstWidth - x));\n\t\t\tint maxHeight = Math.min(height, Math.min(image.platformImage.getRG35XXHeight() - y, platformImage.getRG35XXHeight() - y));\n\t\t\tif (x < 0 || y < 0 || maxWidth <= 0 || maxHeight <= 0) { return; }\n\t\t\tfor (int row = 0; row < maxHeight; row++)\n\t\t\t{\n\t\t\t\tSystem.arraycopy(src, (y + row) * srcWidth + x, dst, (y + row) * dstWidth + x, maxWidth);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\ttry\n\t\t{\n\t\t\tBufferedImage sub = image.platformImage.getCanvas().getSubimage(x, y, width, height);\n\t\t\tgc.drawImage(sub, x, y, null);\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\t//System.out.println(\"flushGraphics A:\"+e.getMessage());\n\t\t}\n\t}\n",
    "platformgraphics-flush-raw",
)
replace_once(
    rel,
    "\tpublic void fillRect(int x, int y, int width, int height)\n\t{\n\t\tgc.fillRect(x, y, width, height);\n\t}\n",
    "\tpublic void fillRect(int x, int y, int width, int height)\n\t{\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tif (width <= 0 || height <= 0) { return; }\n\t\t\tint px = x + translateX;\n\t\t\tint py = y + translateY;\n\t\t\tint left = Math.max(px, clipX);\n\t\t\tint top = Math.max(py, clipY);\n\t\t\tint right = Math.min(px + width, clipX + clipWidth);\n\t\t\tint bottom = Math.min(py + height, clipY + clipHeight);\n\t\t\tleft = Math.max(left, 0);\n\t\t\ttop = Math.max(top, 0);\n\t\t\tright = Math.min(right, platformImage.getRG35XXWidth());\n\t\t\tbottom = Math.min(bottom, platformImage.getRG35XXHeight());\n\t\t\tif (left >= right || top >= bottom) { return; }\n\t\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\t\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\t\tint stride = platformImage.getRG35XXWidth();\n\t\t\tfor (int row = top; row < bottom; row++)\n\t\t\t{\n\t\t\t\tArrays.fill(dst, row * stride + left, row * stride + right, argb);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tgc.fillRect(x, y, width, height);\n\t}\n",
    "platformgraphics-fillrect-raw",
)
replace_once(
    rel,
    "\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tcolor = (r<<16) + (g<<8) + b;\n\t\tawtColor = new Color(r, g, b);\n\t\tgc.setColor(awtColor);\n\t}\n",
    "\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tcolor = (r<<16) + (g<<8) + b;\n\t\tif (platformImage != null && platformImage.isRG35XXRaw()) { return; }\n\t\tawtColor = new Color(r, g, b);\n\t\tgc.setColor(awtColor);\n\t}\n",
    "platformgraphics-setcolor-raw",
)
replace_once(
    rel,
    "\tpublic void setFont(Font font)\n\t{\n\t\tsuper.setFont(font);\n\t\tgc.setFont(font.awtFont);\n\t\tfm=gc.getFontMetrics();\n\t}\n",
    "\tpublic void setFont(Font font)\n\t{\n\t\tsuper.setFont(font);\n\t\tif (platformImage != null && platformImage.isRG35XXRaw()) { fm = null; return; }\n\t\tgc.setFont(font.awtFont);\n\t\tfm=gc.getFontMetrics();\n\t}\n",
    "platformgraphics-setfont-raw",
)
replace_once(
    rel,
    "\tpublic void setClip(int x, int y, int width, int height)\n\t{\n\t\tgc.setClip(x, y, width, height);\n\t\tclipX = (int)gc.getClipBounds().getX();\n\t\tclipY = (int)gc.getClipBounds().getY();\n\t\tclipWidth = (int)gc.getClipBounds().getWidth();\n\t\tclipHeight = (int)gc.getClipBounds().getHeight();\n\t}\n",
    "\tpublic void setClip(int x, int y, int width, int height)\n\t{\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tclipX = x + translateX;\n\t\t\tclipY = y + translateY;\n\t\t\tclipWidth = Math.max(0, width);\n\t\t\tclipHeight = Math.max(0, height);\n\t\t\treturn;\n\t\t}\n\t\tgc.setClip(x, y, width, height);\n\t\tclipX = (int)gc.getClipBounds().getX();\n\t\tclipY = (int)gc.getClipBounds().getY();\n\t\tclipWidth = (int)gc.getClipBounds().getWidth();\n\t\tclipHeight = (int)gc.getClipBounds().getHeight();\n\t}\n",
    "platformgraphics-setclip-raw",
)
replace_once(
    rel,
    "\tpublic void clipRect(int x, int y, int width, int height)\n\t{\n\t\tgc.clipRect(x, y, width, height);\n\t\tclipX = (int)gc.getClipBounds().getX();\n\t\tclipY = (int)gc.getClipBounds().getY();\n\t\tclipWidth = (int)gc.getClipBounds().getWidth();\n\t\tclipHeight = (int)gc.getClipBounds().getHeight();\n\t}\n",
    "\tpublic void clipRect(int x, int y, int width, int height)\n\t{\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tint nx = x + translateX;\n\t\t\tint ny = y + translateY;\n\t\t\tint left = Math.max(clipX, nx);\n\t\t\tint top = Math.max(clipY, ny);\n\t\t\tint right = Math.min(clipX + clipWidth, nx + Math.max(0, width));\n\t\t\tint bottom = Math.min(clipY + clipHeight, ny + Math.max(0, height));\n\t\t\tclipX = left;\n\t\t\tclipY = top;\n\t\t\tclipWidth = Math.max(0, right - left);\n\t\t\tclipHeight = Math.max(0, bottom - top);\n\t\t\treturn;\n\t\t}\n\t\tgc.clipRect(x, y, width, height);\n\t\tclipX = (int)gc.getClipBounds().getX();\n\t\tclipY = (int)gc.getClipBounds().getY();\n\t\tclipWidth = (int)gc.getClipBounds().getWidth();\n\t\tclipHeight = (int)gc.getClipBounds().getHeight();\n\t}\n",
    "platformgraphics-cliprect-raw",
)
replace_once(
    rel,
    "\tpublic void translate(int x, int y)\n\t{\n\t\ttranslateX += x;\n\t\ttranslateY += y;\n\t\tgc.translate(x, y);\n\t\tclipX -= x;\n\t\tclipY -= y;\n\t}\n",
    "\tpublic void translate(int x, int y)\n\t{\n\t\ttranslateX += x;\n\t\ttranslateY += y;\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tclipX += x;\n\t\t\tclipY += y;\n\t\t\treturn;\n\t\t}\n\t\tgc.translate(x, y);\n\t\tclipX -= x;\n\t\tclipY -= y;\n\t}\n",
    "platformgraphics-translate-raw",
)

# MobilePlatform exposes only the raw LCD framebuffer to the RG35XX adapter.
rel = "org/recompile/mobile/MobilePlatform.java"
replace_once(
    rel,
    "\tpublic BufferedImage getLCD() { return lcd.getCanvas(); }\n",
    "\tpublic BufferedImage getLCD() { return lcd.getCanvas(); }\n\tpublic int[] getRG35XXLCDPixels() { return lcd.getRG35XXPixels(); }\n\tpublic int getRG35XXLCDWidth() { return lcdWidth; }\n\tpublic int getRG35XXLCDHeight() { return lcdHeight; }\n",
    "mobileplatform-expose-raw-lcd",
)

# Sanity: no A4 raw rewrite is allowed to delete the canonical AWT declarations;
# they must remain as fallback when rg35xx.raw2d is not enabled.
for rel in ["org/recompile/mobile/PlatformImage.java", "org/recompile/mobile/PlatformGraphics.java", "javax/microedition/lcdui/Font.java"]:
    text = read(rel)
    if "rg35xx.raw2d" not in text:
        raise SystemExit("A4_RAW2D_FAIL property guard missing in %s" % rel)

with audit_path.open("a", encoding="utf-8") as f:
    for line in notes:
        f.write(line + "\n")
    f.write("SUMMARY\t*\tA4_RAW2D_OVERLAY=YES scope=blank-surface-canvas-gamecanvas-only\n")

print("A4_RAW2D_STAGE=PASS")
print("A4_RAW2D_REWRITES=%d" % len(notes))
