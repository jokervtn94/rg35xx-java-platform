#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-complete-graphics-g4g5.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")
parent = s

sig_draw_image = "\tpublic void drawImage(javax.microedition.lcdui.Image img, int x, int y, int anchor, int manipulation)\n"
sig_draw_px_b = "\tpublic void drawPixels(byte[] pixels, byte[] transparencyMask, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)\n"
sig_draw_px_i = "\tpublic void drawPixels(int[] pixels, boolean transparency, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)\n"
sig_draw_px_s = "\tpublic void drawPixels(short[] pixels, boolean transparency, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)\n"
sig_draw_poly = "\tpublic void drawPolygon(int[] xPoints, int xOffset, int[] yPoints, int yOffset, int nPoints, int argbColor)\n"
sig_get_px_b = "\tpublic void getPixels(byte[] pixels, byte[] transparencyMask, int offset, int scanlength, int x, int y, int width, int height, int format)\n"
sig_get_px_i = "\tpublic void getPixels(int[] pixels, int offset, int scanlength, int x, int y, int width, int height, int format)\n"
sig_get_px_s = "\tpublic void getPixels(short[] pixels, int offset, int scanlength, int x, int y, int width, int height, int format)\n"
sig_pixel_to_color = "\tprivate int pixelToColor(short c, int format)\n"

for sig, label in [
    (sig_draw_image, "drawImage-manip"),
    (sig_draw_px_b, "drawPixels-byte"),
    (sig_draw_px_i, "drawPixels-int"),
    (sig_draw_px_s, "drawPixels-short"),
    (sig_draw_poly, "drawPolygon-boundary"),
    (sig_get_px_b, "getPixels-byte"),
    (sig_get_px_i, "getPixels-int"),
    (sig_get_px_s, "getPixels-short"),
    (sig_pixel_to_color, "pixelToColor-boundary"),
]:
    if s.count(sig) != 1:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL %s count=%d" % (label, s.count(sig)))

# Lock the pinned Miyoo fallback semantics before changing only the Raw2D branch.
p0 = s.index(sig_draw_image)
p1 = s.index(sig_draw_px_b, p0)
p2 = s.index(sig_draw_px_i, p1)
p3 = s.index(sig_draw_px_s, p2)
p4 = s.index(sig_draw_poly, p3)
g0 = s.index(sig_get_px_b, p4)
g1 = s.index(sig_get_px_i, g0)
g2 = s.index(sig_get_px_s, g1)
g3 = s.index(sig_pixel_to_color, g2)
if not (p0 < p1 < p2 < p3 < p4 < g0 < g1 < g2 < g3):
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL method ordering")

old_draw_image = s[p0:p1]
old_draw_b = s[p1:p2]
old_draw_i = s[p2:p3]
old_draw_s = s[p3:p4]
old_get_b = s[g0:g1]
old_get_i = s[g1:g2]
old_get_s = s[g2:g3]

checks = [
    (old_draw_image, 'BufferedImage image = manipulateImage(img.platformImage.getCanvas(), manipulation);', 'drawImage canonical transform'),
    (old_draw_b, 'int[] Type1 = {0xFFFFFFFF, 0xFF000000, 0x00FFFFFF, 0x00000000};', 'byte Type1'),
    (old_draw_b, 'int ods = offset / scanlength;', 'vertical offset quotient'),
    (old_draw_b, 'c = ((pixels[tmp + xj]>>b)&1);', 'vertical LSB'),
    (old_draw_b, 'for(int j=7; j>=0; j--)', 'horizontal MSB'),
    (old_draw_i, 'temp.setRGB(0, 0, width, height, pixels, offset, scanlength);', 'int setRGB'),
    (old_draw_s, 'if(!transparency) { data[i] &=0x00FFFFFF; }', 'short false transparency quirk'),
    (old_get_b, 'System.out.println("getPixels A");', 'byte getPixels stub'),
    (old_get_i, 'canvas.getRGB(x, y, width, height, pixels, offset, scanlength);', 'int getPixels'),
    (old_get_s, 'int i = offset;', 'short getPixels contiguous'),
    (old_get_s, 'pixels[i] = colorToShortPixel(canvas.getRGB(col+x, row+y), format);', 'short conversion'),
]
for block, token, label in checks:
    if token not in block:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL canonical token %s" % label)

helper = r'''\tprivate static int rg35xxDGManipulationToTransform(int manipulation)
\t{
\t\tfinal int HV = DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.FLIP_VERTICAL;
\t\tfinal int H90 = DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.ROTATE_90;
\t\tswitch(manipulation)
\t\t{
\t\t\tcase DirectGraphics.FLIP_HORIZONTAL: return Sprite.TRANS_MIRROR;
\t\t\tcase DirectGraphics.FLIP_VERTICAL: return Sprite.TRANS_MIRROR_ROT180;
\t\t\tcase DirectGraphics.ROTATE_90: return Sprite.TRANS_ROT270;
\t\t\tcase DirectGraphics.ROTATE_180: return Sprite.TRANS_ROT180;
\t\t\tcase DirectGraphics.ROTATE_270: return Sprite.TRANS_ROT90;
\t\t\tcase HV: return Sprite.TRANS_ROT180;
\t\t\tcase H90: return Sprite.TRANS_MIRROR_ROT270;
\t\t\tcase 0: return Sprite.TRANS_NONE;
\t\t\tdefault:
\t\t\t\tSystem.out.println("manipulateImage "+manipulation+" not defined");
\t\t\t\treturn Sprite.TRANS_NONE;
\t\t}
\t}

\tprivate static boolean rg35xxDGTransformSwaps(int transform)
\t{
\t\treturn transform == Sprite.TRANS_MIRROR_ROT270 || transform == Sprite.TRANS_ROT90 ||
\t\t\ttransform == Sprite.TRANS_ROT270 || transform == Sprite.TRANS_MIRROR_ROT90;
\t}

\tprivate static int[] rg35xxDGPackPixels(int[] pixels, int offset, int scanlength, int width, int height)
\t{
\t\tint[] packed = new int[width * height];
\t\tfor(int row = 0; row < height; row++)
\t\t{
\t\t\tSystem.arraycopy(pixels, offset + row * scanlength, packed, row * width, width);
\t\t}
\t\treturn packed;
\t}

\tprivate void rg35xxDGBlitPacked(int[] packed, int width, int height, int manipulation, int x, int y)
\t{
\t\tPlatformImage temp = new PlatformImage(packed, width, height, true);
\t\tint transform = rg35xxDGManipulationToTransform(manipulation);
\t\trg35xxBlit(temp, 0, 0, width, height, transform, x, y);
\t}

'''

new_draw_image = r'''\tpublic void drawImage(javax.microedition.lcdui.Image img, int x, int y, int anchor, int manipulation)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw() && img != null && img.platformImage != null && img.platformImage.isRG35XXRaw())
\t\t{
\t\t\tint transform = rg35xxDGManipulationToTransform(manipulation);
\t\t\tint sw = img.getWidth();
\t\t\tint sh = img.getHeight();
\t\t\tint dw = rg35xxDGTransformSwaps(transform) ? sh : sw;
\t\t\tint dh = rg35xxDGTransformSwaps(transform) ? sw : sh;
\t\t\tx = AnchorX(x, dw, anchor);
\t\t\ty = AnchorY(y, dh, anchor);
\t\t\trg35xxBlit(img, 0, 0, sw, sh, transform, x, y);
\t\t\treturn;
\t\t}
\t\t// Pinned Miyoo fallback, unchanged.
\t\tBufferedImage image = manipulateImage(img.platformImage.getCanvas(), manipulation);
\t\tx = AnchorX(x, image.getWidth(), anchor);
\t\ty = AnchorY(y, image.getHeight(), anchor);
\t\tdrawImage2(image, x, y);
\t\t//drawImage2Test(image, x, y);
\t}

'''

new_draw_b = r'''\tpublic void drawPixels(byte[] pixels, byte[] transparencyMask, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] Type1 = {0xFFFFFFFF, 0xFF000000, 0x00FFFFFF, 0x00000000};
\t\t\tint c = 0;
\t\t\tint[] data;
\t\t\tswitch(format)
\t\t\t{
\t\t\t\tcase -1: // TYPE_BYTE_1_GRAY_VERTICAL
\t\t\t\t\tdata = new int[width*height];
\t\t\t\t\tint ods = offset / scanlength;
\t\t\t\t\tint oms = offset % scanlength;
\t\t\t\t\tint b = ods % 8;
\t\t\t\t\tfor (int yj = 0; yj < height; yj++)
\t\t\t\t\t{
\t\t\t\t\t\tint tmp = (ods + yj) / 8 * scanlength+oms;
\t\t\t\t\t\tfor (int xj = 0; xj < width; xj++)
\t\t\t\t\t\t{
\t\t\t\t\t\t\tc = ((pixels[tmp + xj]>>b)&1);
\t\t\t\t\t\t\tif(transparencyMask!=null) { c |= (((transparencyMask[tmp + xj]>>b)&1)^1)<<1; }
\t\t\t\t\t\t\tdata[(yj*width)+xj] = Type1[c];
\t\t\t\t\t\t}
\t\t\t\t\t\tb++;
\t\t\t\t\t\tif(b>7) b=0;
\t\t\t\t\t}
\t\t\t\t\trg35xxDGBlitPacked(data, width, height, manipulation, x, y);
\t\t\t\t\treturn;
\n\t\t\t\tcase 1: // TYPE_BYTE_1_GRAY
\t\t\t\t\tdata = new int[pixels.length*8];
\t\t\t\t\tfor(int i=(offset/8); i<pixels.length; i++)
\t\t\t\t\t{
\t\t\t\t\t\tfor(int j=7; j>=0; j--)
\t\t\t\t\t\t{
\t\t\t\t\t\t\tc = ((pixels[i]>>j)&1);
\t\t\t\t\t\t\tif(transparencyMask!=null) { c |= (((transparencyMask[i]>>j)&1)^1)<<1; }
\t\t\t\t\t\t\tdata[(i*8)+(7-j)] = Type1[c];
\t\t\t\t\t\t}
\t\t\t\t\t}
\t\t\t\t\trg35xxDGBlitPacked(rg35xxDGPackPixels(data, 0, scanlength, width, height), width, height, manipulation, x, y);
\t\t\t\t\treturn;
\n\t\t\t\tdefault:
\t\t\t\t\tSystem.out.println("drawPixels A : Format " + format + " Not Implemented");
\t\t\t\t\treturn;
\t\t\t}
\t\t}
\t\t// Pinned Miyoo fallback, unchanged.
\t\tint[] Type1 = {0xFFFFFFFF, 0xFF000000, 0x00FFFFFF, 0x00000000};
\t\tint c = 0;
\t\tint[] data;
\t\tBufferedImage temp;
\t\tswitch(format)
\t\t{
\t\t\tcase -1: // TYPE_BYTE_1_GRAY_VERTICAL // used by Monkiki's Castles
\t\t\t\tdata = new int[width*height];
\t\t\t\tint ods = offset / scanlength;
\t\t\t\tint oms = offset % scanlength;
\t\t\t\tint b = ods % 8; //Bit offset in a byte
\t\t\t\tfor (int yj = 0; yj < height; yj++)
\t\t\t\t{
\t\t\t\t\tint ypos = yj * width;
\t\t\t\t\tint tmp = (ods + yj) / 8 * scanlength+oms;
\t\t\t\t\tfor (int xj = 0; xj < width; xj++)
\t\t\t\t\t{
\t\t\t\t\t\tc = ((pixels[tmp + xj]>>b)&1);
\t\t\t\t\t\tif(transparencyMask!=null) { c |= (((transparencyMask[tmp + xj]>>b)&1)^1)<<1; }
\t\t\t\t\t\tdata[(yj*width)+xj] = Type1[c];
\t\t\t\t\t}
\t\t\t\t\tb++;
\t\t\t\t\tif(b>7) b=0;
\t\t\t\t}
\n\t\t\t\ttemp = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
\t\t\t\ttemp.setRGB(0, 0, width, height, data, 0, width);
\t\t\t\tgc.drawImage(manipulateImage(temp, manipulation), x, y, null);
\t\t\tbreak;
\n\t\t\tcase 1: // TYPE_BYTE_1_GRAY // used by Monkiki's Castles
\t\t\t\tdata = new int[pixels.length*8];
\n\t\t\t\tfor(int i=(offset/8); i<pixels.length; i++)
\t\t\t\t{
\t\t\t\t\tfor(int j=7; j>=0; j--)
\t\t\t\t\t{
\t\t\t\t\t\tc = ((pixels[i]>>j)&1);
\t\t\t\t\t\tif(transparencyMask!=null) { c |= (((transparencyMask[i]>>j)&1)^1)<<1; }
\t\t\t\t\t\tdata[(i*8)+(7-j)] = Type1[c];
\t\t\t\t\t}
\t\t\t\t}
\t\t\t\ttemp = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
\t\t\t\ttemp.setRGB(0, 0, width, height, data, 0, scanlength);
\t\t\t\tgc.drawImage(manipulateImage(temp, manipulation), x, y, null);
\t\t\tbreak;
\n\t\t\tdefault: System.out.println("drawPixels A : Format " + format + " Not Implemented");
\t\t}
\t}

'''

new_draw_i = r'''\tpublic void drawPixels(int[] pixels, boolean transparency, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] packed = rg35xxDGPackPixels(pixels, offset, scanlength, width, height);
\t\t\trg35xxDGBlitPacked(packed, width, height, manipulation, x, y);
\t\t\treturn;
\t\t}
\t\t// Pinned Miyoo fallback, unchanged; transparency is intentionally ignored.
\t\tBufferedImage temp = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
\t\ttemp.setRGB(0, 0, width, height, pixels, offset, scanlength);
\t\tBufferedImage temp2 = manipulateImage(temp, manipulation);
\t\tgc.drawImage(temp2, x, y, null);
\t}

'''

new_draw_s = r'''\tpublic void drawPixels(short[] pixels, boolean transparency, int offset, int scanlength, int x, int y, int width, int height, int manipulation, int format)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] data = new int[pixels.length];
\t\t\tfor(int i=0; i<pixels.length; i++)
\t\t\t{
\t\t\t\tdata[i] = pixelToColor(pixels[i], format);
\t\t\t\tif(!transparency) { data[i] &=0x00FFFFFF; }
\t\t\t}
\t\t\tint[] packed = rg35xxDGPackPixels(data, offset, scanlength, width, height);
\t\t\trg35xxDGBlitPacked(packed, width, height, manipulation, x, y);
\t\t\treturn;
\t\t}
\t\t// Pinned Miyoo fallback, unchanged.
\t\tint[] data = new int[pixels.length];
\t\tfor(int i=0; i<pixels.length; i++)
\t\t{
\t\t\tdata[i] = pixelToColor(pixels[i], format);
\t\t\tif(!transparency) { data[i] &=0x00FFFFFF; }
\t\t}
\n\t\tBufferedImage temp = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
\t\ttemp.setRGB(0, 0, width, height, data, offset, scanlength);
\t\tgc.drawImage(manipulateImage(temp, manipulation), x, y, null);
\t}

'''

# Preserve byte getPixels verbatim. Only int and short gain raw framebuffer backing.
new_get_i = r'''\tpublic void getPixels(int[] pixels, int offset, int scanlength, int x, int y, int width, int height, int format)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] src = platformImage.getRG35XXPixels();
\t\t\tint stride = platformImage.getRG35XXWidth();
\t\t\tfor(int row=0; row<height; row++)
\t\t\t{
\t\t\t\tSystem.arraycopy(src, (y + row) * stride + x, pixels, offset + row * scanlength, width);
\t\t\t}
\t\t\treturn;
\t\t}
\t\tcanvas.getRGB(x, y, width, height, pixels, offset, scanlength);
\t}

'''

new_get_s = r'''\tpublic void getPixels(short[] pixels, int offset, int scanlength, int x, int y, int width, int height, int format)
\t{
\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] src = platformImage.getRG35XXPixels();
\t\t\tint stride = platformImage.getRG35XXWidth();
\t\t\tint i = offset;
\t\t\tfor(int row=0; row<height; row++)
\t\t\t{
\t\t\t\tfor (int col=0; col<width; col++)
\t\t\t\t{
\t\t\t\t\tpixels[i] = colorToShortPixel(src[(row+y) * stride + (col+x)], format);
\t\t\t\t\ti++;
\t\t\t\t}
\t\t\t}
\t\t\treturn;
\t\t}
\t\tint i = offset;
\t\tfor(int row=0; row<height; row++)
\t\t{
\t\t\tfor (int col=0; col<width; col++)
\t\t\t{
\t\t\t\tpixels[i] = colorToShortPixel(canvas.getRGB(col+x, row+y), format);
\t\t\t\ti++;
\t\t\t}
\t\t}
\t}

'''

# Replace G4 block and G5 int/short block while retaining the D6 draw-vector tail byte-for-byte.
s = s[:p0] + helper + new_draw_image + new_draw_b + new_draw_i + new_draw_s + s[p4:]

# Re-locate G5 after the G4 insertion.
g0 = s.index(sig_get_px_b)
g1 = s.index(sig_get_px_i, g0)
g2 = s.index(sig_get_px_s, g1)
g3 = s.index(sig_pixel_to_color, g2)
byte_stub_now = s[g0:g1]
if byte_stub_now != old_get_b:
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL byte getPixels stub drift")
s = s[:g1] + new_get_i + new_get_s + s[g3:]

# Fail closed on owner/scope and known semantics.
required = [
    "private static int rg35xxDGManipulationToTransform(int manipulation)",
    "case DirectGraphics.ROTATE_90: return Sprite.TRANS_ROT270;",
    "case H90: return Sprite.TRANS_MIRROR_ROT270;",
    "rg35xxBlit(img, 0, 0, sw, sh, transform, x, y);",
    "int ods = offset / scanlength;",
    "c = ((pixels[tmp + xj]>>b)&1);",
    "for(int j=7; j>=0; j--)",
    "if(!transparency) { data[i] &=0x00FFFFFF; }",
    "System.arraycopy(src, (y + row) * stride + x, pixels, offset + row * scanlength, width);",
    "pixels[i] = colorToShortPixel(src[(row+y) * stride + (col+x)], format);",
]
for token in required:
    if token not in s:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL missing token %s" % token)

if s.count('System.out.println("getPixels A");') != parent.count('System.out.println("getPixels A");'):
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL byte getPixels stub marker changed")
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if s.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL game-specific marker delta %s" % forbidden)

pg.write_text(s, encoding="utf-8")
print("P1A_COMPLETE_G4G5_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_COMPLETE_G4_CHANGED_METHODS=DirectGraphics.drawImage_manipulation,drawPixels_byte,drawPixels_int,drawPixels_short")
print("P1A_COMPLETE_G5_CHANGED_METHODS=DirectGraphics.getPixels_int,getPixels_short")
print("P1A_COMPLETE_G5_GETPIXELS_BYTE=CANONICAL_STUB_UNCHANGED")
print("P1A_COMPLETE_G4_BACKEND=EXISTING_A5_RAW_PLATFORMIMAGE_PLUS_RG35XXBLIT")
print("P1A_COMPLETE_G5_BACKEND=RAW_PLATFORMIMAGE_FRAMEBUFFER_READ")
print("P1A_COMPLETE_CORE2D_CHANGE=NO")
print("P1A_COMPLETE_NATIVE_CHANGE=NO")
print("P1A_COMPLETE_G4G5_STAGE=PASS")
