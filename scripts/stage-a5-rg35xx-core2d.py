#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: stage-a5-rg35xx-core2d.py <stage-src> <audit-log>")
root = Path(sys.argv[1]).resolve()
audit = Path(sys.argv[2]).resolve()
if not root.is_dir():
    raise SystemExit("A5_CORE2D_FAIL stage source missing: %s" % root)
notes = []

def p(rel): return root / rel
def read(rel): return p(rel).read_text(encoding="utf-8")
def write(rel, text): p(rel).write_text(text, encoding="utf-8")
def note(rel, label): notes.append("A5_CORE2D\t%s\t%s" % (rel, label))

def replace_once(rel, old, new, label):
    text = read(rel)
    n = text.count(old)
    if n != 1:
        raise SystemExit("A5_CORE2D_FAIL %s expected=1 found=%d file=%s" % (label, n, rel))
    write(rel, text.replace(old, new, 1)); note(rel, label)

def sub_once(rel, pattern, repl, label, flags=0):
    text = read(rel)
    text2, n = re.subn(pattern, repl, text, count=1, flags=flags)
    if n != 1:
        raise SystemExit("A5_CORE2D_FAIL %s expected=1 found=%d file=%s" % (label, n, rel))
    write(rel, text2); note(rel, label)

# Font: retain A4's AWT constructor bypass but replace provisional metrics with
# the A5 headless backing. No desktop Toolkit is touched in raw2d mode.
rel = "javax/microedition/lcdui/Font.java"
replace_once(rel, "import org.recompile.mobile.Mobile;\n", "import org.recompile.mobile.Mobile;\nimport org.recompile.rg35xx.RG35XXCore2D;\n", "font-import-core2d")
replace_once(rel,
    "\t\tif (fm == null) { return (convertSize(size) + 1) / 2; }\n\t\treturn fm.charWidth(ch); ",
    "\t\tif (fm == null) { return RG35XXCore2D.charWidth(ch, size, face, style); }\n\t\treturn fm.charWidth(ch); ",
    "font-charwidth-headless")
replace_once(rel,
    "\t\tif (fm == null) { return convertSize(size) + 2; }\n\t\treturn fm.getHeight();",
    "\t\tif (fm == null) { return RG35XXCore2D.fontHeight(size); }\n\t\treturn fm.getHeight();",
    "font-height-headless")
replace_once(rel,
    "\t\tif (fm == null) { return str.length() * ((convertSize(size) + 1) / 2); }\n\t\treturn fm.stringWidth(str); ",
    "\t\tif (fm == null) { return RG35XXCore2D.stringWidth(str, size, face, style); }\n\t\treturn fm.stringWidth(str); ",
    "font-stringwidth-headless")
replace_once(rel,
    "\tpublic int getBaselinePosition() { return convertSize(size); }",
    "\tpublic int getBaselinePosition() { return fm == null ? RG35XXCore2D.fontAscent(size) : convertSize(size); }",
    "font-baseline-headless")

# PlatformImage: all constructors used by A5 gain a raw path. The canonical AWT
# code remains the non-RG35XX fallback and the pinned gitlink stays untouched.
rel = "org/recompile/mobile/PlatformImage.java"
replace_once(rel, "import org.recompile.mobile.Mobile;\n", "import org.recompile.mobile.Mobile;\nimport org.recompile.rg35xx.RG35XXCore2D;\n", "platformimage-import-core2d")
replace_once(rel,
    "\tprotected void createGraphics()\n\t{\n\t\tgc = new PlatformGraphics(this);\n\t\tgc.setColor(0x000000);\n\t}\n",
    "\tprotected void createGraphics()\n\t{\n\t\tgc = new PlatformGraphics(this);\n\t\tgc.setColor(0x000000);\n\t}\n\n\tprivate void rg35xxInit(RG35XXCore2D.RawImage raw)\n\t{\n\t\twidth = raw.width;\n\t\theight = raw.height;\n\t\trg35xxPixels = raw.pixels;\n\t\tcanvas = null;\n\t\tcreateGraphics();\n\t\tplatformImage = this;\n\t}\n",
    "platformimage-add-raw-init")

# Resource name constructor.
pattern = r"\tpublic PlatformImage\(String name\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic PlatformImage\(InputStream stream\)"
repl = '''\tpublic PlatformImage(String name)\n\t{\n\t\tInputStream stream = Mobile.getPlatform().loader.getMIDletResourceAsStream(name);\n\t\tif (stream == null) { isNull = true; platformImage = this; return; }\n\t\tif (Boolean.getBoolean("rg35xx.raw2d"))\n\t\t{\n\t\t\ttry { rg35xxInit(RG35XXCore2D.decodePng(stream)); }\n\t\t\tcatch (Exception e) { System.out.println("RG35XX_A5_IMAGE_RESOURCE_FAIL=" + name + ":" + e); isNull = true; platformImage = this; }\n\t\t\ttry { stream.close(); } catch (Exception e) { }\n\t\t\treturn;\n\t\t}\n\t\tBufferedImage temp;\n\t\ttry\n\t\t{\n\t\t\ttemp = ImageIO.read(stream); width = (int)temp.getWidth(); height = (int)temp.getHeight();\n\t\t\tcanvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB); createGraphics(); gc.drawImage2(temp, 0, 0);\n\t\t}\n\t\tcatch (Exception e) { isNull = true; }\n\t\tplatformImage = this;\n\t}\n\n\tpublic PlatformImage(InputStream stream)'''
sub_once(rel, pattern, repl, "platformimage-resource-raw", re.S)

# Stream constructor.
pattern = r"\tpublic PlatformImage\(InputStream stream\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic PlatformImage\(Image source\)"
repl = '''\tpublic PlatformImage(InputStream stream)\n\t{\n\t\tif (Boolean.getBoolean("rg35xx.raw2d"))\n\t\t{\n\t\t\ttry { rg35xxInit(RG35XXCore2D.decodePng(stream)); }\n\t\t\tcatch (Exception e) { System.out.println("RG35XX_A5_IMAGE_STREAM_FAIL=" + e); isNull = true; platformImage = this; }\n\t\t\treturn;\n\t\t}\n\t\ttry\n\t\t{\n\t\t\tBufferedImage temp = ImageIO.read(stream); width = (int)temp.getWidth(); height = (int)temp.getHeight();\n\t\t\tcanvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB); createGraphics(); gc.drawImage2(temp, 0, 0);\n\t\t}\n\t\tcatch (Exception e) { isNull = true; }\n\t\tplatformImage = this;\n\t}\n\n\tpublic PlatformImage(Image source)'''
sub_once(rel, pattern, repl, "platformimage-stream-raw", re.S)

# Copy constructor.
pattern = r"\tpublic PlatformImage\(Image source\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic PlatformImage\(byte\[\] imageData"
repl = '''\tpublic PlatformImage(Image source)\n\t{\n\t\twidth = source.platformImage.width; height = source.platformImage.height;\n\t\tif (Boolean.getBoolean("rg35xx.raw2d") && source.platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxInit(RG35XXCore2D.copy(source.platformImage.getRG35XXPixels(), width, height)); return;\n\t\t}\n\t\tcanvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB); createGraphics();\n\t\tgc.drawImage2(source.platformImage.getCanvas(), 0, 0); platformImage = this;\n\t}\n\n\tpublic PlatformImage(byte[] imageData'''
sub_once(rel, pattern, repl, "platformimage-copy-raw", re.S)

# Byte array decode constructor.
pattern = r"\tpublic PlatformImage\(byte\[\] imageData, int imageOffset, int imageLength\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic PlatformImage\(int\[\] rgb"
repl = '''\tpublic PlatformImage(byte[] imageData, int imageOffset, int imageLength)\n\t{\n\t\tif (Boolean.getBoolean("rg35xx.raw2d"))\n\t\t{\n\t\t\ttry { rg35xxInit(RG35XXCore2D.decodePng(new ByteArrayInputStream(imageData, imageOffset, imageLength))); }\n\t\t\tcatch (Exception e) { System.out.println("RG35XX_A5_IMAGE_BYTES_FAIL=" + e); isNull = true; platformImage = this; }\n\t\t\treturn;\n\t\t}\n\t\ttry\n\t\t{\n\t\t\tBufferedImage temp = ImageIO.read(new ByteArrayInputStream(imageData, imageOffset, imageLength));\n\t\t\twidth = (int)temp.getWidth(); height = (int)temp.getHeight(); canvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);\n\t\t\tcreateGraphics(); gc.drawImage2(temp, 0, 0);\n\t\t}\n\t\tcatch (Exception e) { isNull = true; }\n\t\tplatformImage = this;\n\t}\n\n\tpublic PlatformImage(int[] rgb'''
sub_once(rel, pattern, repl, "platformimage-bytes-raw", re.S)

# RGB constructor.
pattern = r"\tpublic PlatformImage\(int\[\] rgb, int Width, int Height, boolean processAlpha\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic PlatformImage\(Image image, int x"
repl = '''\tpublic PlatformImage(int[] rgb, int Width, int Height, boolean processAlpha)\n\t{\n\t\twidth = Width; height = Height; if (width < 1) width = 1; if (height < 1) height = 1;\n\t\tif (Boolean.getBoolean("rg35xx.raw2d"))\n\t\t{\n\t\t\trg35xxInit(RG35XXCore2D.fromRGB(rgb, width, height, processAlpha)); return;\n\t\t}\n\t\tcanvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB); createGraphics();\n\t\tgc.drawRGB(rgb, 0, width, 0, 0, width, height, processAlpha); platformImage = this;\n\t}\n\n\tpublic PlatformImage(Image image, int x'''
sub_once(rel, pattern, repl, "platformimage-rgb-raw", re.S)

# Subimage + transform constructor.
pattern = r"\tpublic PlatformImage\(Image image, int x, int y, int Width, int Height, int transform\)\n\t\{.*?\n\t\tplatformImage = this;\n\t\}\n\n\tpublic void getRGB"
repl = '''\tpublic PlatformImage(Image image, int x, int y, int Width, int Height, int transform)\n\t{\n\t\tif (Boolean.getBoolean("rg35xx.raw2d") && image.platformImage.isRG35XXRaw())\n\t\t{\n\t\t\trg35xxInit(RG35XXCore2D.transform(image.platformImage.getRG35XXPixels(), image.getWidth(), image.getHeight(), x, y, Width, Height, transform)); return;\n\t\t}\n\t\tBufferedImage sub = image.platformImage.canvas.getSubimage(x, y, Width, Height);\n\t\tcanvas = transformImage(sub, transform); createGraphics(); width = (int)canvas.getWidth(); height = (int)canvas.getHeight(); platformImage = this;\n\t}\n\n\tpublic void getRGB'''
sub_once(rel, pattern, repl, "platformimage-transform-raw", re.S)

# PlatformGraphics: route image blits, drawRegion, drawRGB and text raster to
# headless buffers. Existing A4 clip/translate/fill semantics stay intact.
rel = "org/recompile/mobile/PlatformGraphics.java"
replace_once(rel, "import javax.microedition.lcdui.game.Sprite;\n", "import javax.microedition.lcdui.game.Sprite;\nimport org.recompile.rg35xx.RG35XXCore2D;\n", "platformgraphics-import-core2d")

pattern = r"\tpublic void drawImage\(Image image, int x, int y, int anchor\)\n\t\{.*?\n\t\}\n\n\tpublic void drawImage\(Image image, int x, int y\)"
repl = '''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{\n\t\tif (platformImage.isRG35XXRaw() && image.platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tx = AnchorX(x, image.getWidth(), anchor); y = AnchorY(y, image.getHeight(), anchor);\n\t\t\trg35xxBlit(image, 0, 0, image.getWidth(), image.getHeight(), 0, x, y); return;\n\t\t}\n\t\ttry { int w=image.getWidth(), h=image.getHeight(); x=AnchorX(x,w,anchor); y=AnchorY(y,h,anchor); gc.drawImage(image.platformImage.getCanvas(),x,y,null); } catch(Exception e) { }\n\t}\n\n\tpublic void drawImage(Image image, int x, int y)'''
sub_once(rel, pattern, repl, "platformgraphics-drawimage-anchor-raw", re.S)

pattern = r"\tpublic void drawImage\(Image image, int x, int y\)\n\t\{.*?\n\t\}\n\n\tpublic void drawImage2\(Image image"
repl = '''\tpublic void drawImage(Image image, int x, int y)\n\t{\n\t\tif (platformImage.isRG35XXRaw() && image.platformImage.isRG35XXRaw()) { rg35xxBlit(image,0,0,image.getWidth(),image.getHeight(),0,x,y); return; }\n\t\ttry { gc.drawImage(image.platformImage.getCanvas(), x, y, null); } catch(Exception e) { }\n\t}\n\n\tpublic void drawImage2(Image image'''
sub_once(rel, pattern, repl, "platformgraphics-drawimage-raw", re.S)

replace_once(rel,
    "\tpublic void drawImage2(Image image, int x, int y) // Internal use method called by PlatformImage\n\t{\n\t\tgc.drawImage(image.platformImage.getCanvas(), x, y, null);\n\t}\n",
    "\tpublic void drawImage2(Image image, int x, int y) // Internal use method called by PlatformImage\n\t{\n\t\tif (platformImage.isRG35XXRaw() && image.platformImage.isRG35XXRaw()) { rg35xxBlit(image,0,0,image.getWidth(),image.getHeight(),0,x,y); return; }\n\t\tgc.drawImage(image.platformImage.getCanvas(), x, y, null);\n\t}\n",
    "platformgraphics-drawimage2-raw")

pattern = r"\tpublic void drawRegion\(Image image, int subx, int suby, int subw, int subh, int transform, int x, int y, int anchor\)\n\t\{.*?\n\t\}\n\n\tpublic void drawRGB"
repl = '''\tpublic void drawRegion(Image image, int subx, int suby, int subw, int subh, int transform, int x, int y, int anchor)\n\t{\n\t\tif (subw > image.getWidth()) subw=image.getWidth(); if (subh > image.getHeight()) subh=image.getHeight();\n\t\tif (subw <= 0 || subh <= 0) return;\n\t\tif (platformImage.isRG35XXRaw() && image.platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tboolean swap = transform==Sprite.TRANS_ROT90 || transform==Sprite.TRANS_ROT270 || transform==Sprite.TRANS_MIRROR_ROT90 || transform==Sprite.TRANS_MIRROR_ROT270;\n\t\t\tint w=swap?subh:subw, h=swap?subw:subh; x=AnchorX(x,w,anchor); y=AnchorY(y,h,anchor);\n\t\t\trg35xxBlit(image,subx,suby,subw,subh,transform,x,y); return;\n\t\t}\n\t\ttry {\n\t\t\tif(transform==0) { BufferedImage sub=image.platformImage.getCanvas().getSubimage(subx,suby,subw,subh); x=AnchorX(x,subw,anchor); y=AnchorY(y,subh,anchor); gc.drawImage(sub,x,y,null); }\n\t\t\telse { PlatformImage sub=new PlatformImage(image,subx,suby,subw,subh,transform); x=AnchorX(x,sub.width,anchor); y=AnchorY(y,sub.height,anchor); gc.drawImage(sub.getCanvas(),x,y,null); }\n\t\t} catch(Exception e) { }\n\t}\n\n\tprivate void rg35xxBlit(Image image, int sx, int sy, int sw, int sh, int transform, int x, int y)\n\t{\n\t\tRG35XXCore2D.blit(platformImage.getRG35XXPixels(), platformImage.getRG35XXWidth(), platformImage.getRG35XXHeight(),\n\t\t\timage.platformImage.getRG35XXPixels(), image.getWidth(), image.getHeight(), sx, sy, sw, sh, transform,\n\t\t\tx + translateX, y + translateY, clipX, clipY, clipWidth, clipHeight);\n\t}\n\n\tpublic void drawRGB'''
sub_once(rel, pattern, repl, "platformgraphics-drawregion-raw", re.S)

pattern = r"\tpublic void drawRGB\(int\[\] rgbData, int offset, int scanlength, int x, int y, int width, int height, boolean processAlpha\)\n\t\{.*?\n\t\}\n\n\n\tpublic void drawLine"
repl = '''\tpublic void drawRGB(int[] rgbData, int offset, int scanlength, int x, int y, int width, int height, boolean processAlpha)\n\t{\n\t\tif (width < 1 || height < 1) return;\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tint[] tmp=new int[width*height];\n\t\t\tfor(int row=0;row<height;row++) for(int col=0;col<width;col++) { int v=rgbData[offset+row*scanlength+col]; tmp[row*width+col]=processAlpha?v:(0xFF000000|(v&0x00FFFFFF)); }\n\t\t\tRG35XXCore2D.blit(platformImage.getRG35XXPixels(),platformImage.getRG35XXWidth(),platformImage.getRG35XXHeight(),tmp,width,height,0,0,width,height,0,x+translateX,y+translateY,clipX,clipY,clipWidth,clipHeight); return;\n\t\t}\n\t\tif(!processAlpha) for(int i=offset;i<rgbData.length;i++) rgbData[i]=0xFF000000|(rgbData[i]&0x00FFFFFF);\n\t\tBufferedImage temp=new BufferedImage(width,height,BufferedImage.TYPE_INT_ARGB); temp.setRGB(0,0,width,height,rgbData,offset,scanlength); gc.drawImage(temp,x,y,null);\n\t}\n\n\n\tpublic void drawLine'''
sub_once(rel, pattern, repl, "platformgraphics-drawrgb-raw", re.S)

pattern = r"\tpublic void drawString\(String str, int x, int y, int anchor\)\n\t\{.*?\n\t\}\n\n\tpublic void drawSubstring"
repl = '''\tpublic void drawString(String str, int x, int y, int anchor)\n\t{\n\t\tif (str == null) return;\n\t\tif (platformImage.isRG35XXRaw()) { rg35xxDrawString(str,x,y,anchor); return; }\n\t\tx=AnchorX(x,fm.stringWidth(str),anchor);\n\t\tif((anchor&BOTTOM)>0)y-=fm.getDescent(); else if((anchor&VCENTER)>0)y-=(fm.getDescent()+fm.getAscent())/2; else if((anchor&BASELINE)==0)y+=fm.getAscent();\n\t\tgc.drawString(str,x,y);\n\t}\n\n\tprivate void rg35xxDrawString(String str, int x, int y, int anchor)\n\t{\n\t\tFont f=getFont(); int total=f.stringWidth(str); int h=f.getHeight();\n\t\tx=AnchorX(x,total,anchor); if((anchor&VCENTER)>0)y-=h/2; else if((anchor&BOTTOM)>0)y-=h; else if((anchor&BASELINE)>0)y-=f.getBaselinePosition();\n\t\tint pen=x; int scale=f.getSize()==Font.SIZE_SMALL?1:(f.getSize()==Font.SIZE_LARGE?2:1);\n\t\tfor(int n=0;n<str.length();n++) { char ch=str.charAt(n); String bits=RG35XXCore2D.glyph(ch); int cw=f.charWidth(ch); int gx0=pen;\n\t\t\tfor(int gy=0;gy<7;gy++) for(int gx=0;gx<5;gx++) if(bits.charAt(gy*5+gx)=='1') fillRect(gx0+gx*scale,y+gy*scale,scale,scale);\n\t\t\tif(f.isBold()) for(int gy=0;gy<7;gy++) for(int gx=0;gx<5;gx++) if(bits.charAt(gy*5+gx)=='1') fillRect(gx0+gx*scale+1,y+gy*scale,1,scale);\n\t\t\tif(f.isUnderlined()) fillRect(gx0,y+Math.min(h-1,7*scale+1),cw,1); pen+=cw; }\n\t}\n\n\tpublic void drawSubstring'''
sub_once(rel, pattern, repl, "platformgraphics-text-raw", re.S)

# Fail closed if the required ownership markers are absent after staging.
for rel in ["org/recompile/mobile/PlatformImage.java", "org/recompile/mobile/PlatformGraphics.java", "javax/microedition/lcdui/Font.java"]:
    text=read(rel)
    if "RG35XXCore2D" not in text or "rg35xx.raw2d" not in text:
        raise SystemExit("A5_CORE2D_FAIL ownership marker missing in %s" % rel)

with audit.open("a", encoding="utf-8") as f:
    for line in notes: f.write(line+"\n")
    f.write("SUMMARY\t*\tA5_CORE2D_OVERLAY=YES scope=headless-image-png-copy-transform-blit-font-text\n")
print("A5_CORE2D_STAGE=PASS")
print("A5_CORE2D_REWRITES=%d" % len(notes))
