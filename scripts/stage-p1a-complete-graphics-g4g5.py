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

blocks = {
    "drawImage": s[p0:p1],
    "drawByte": s[p1:p2],
    "drawInt": s[p2:p3],
    "drawShort": s[p3:p4],
    "getByte": s[g0:g1],
    "getInt": s[g1:g2],
    "getShort": s[g2:g3],
}
checks = [
    ("drawImage", 'BufferedImage image = manipulateImage(img.platformImage.getCanvas(), manipulation);'),
    ("drawByte", 'int[] Type1 = {0xFFFFFFFF, 0xFF000000, 0x00FFFFFF, 0x00000000};'),
    ("drawByte", 'int ods = offset / scanlength;'),
    ("drawByte", 'c = ((pixels[tmp + xj]>>b)&1);'),
    ("drawByte", 'for(int j=7; j>=0; j--)'),
    ("drawInt", 'temp.setRGB(0, 0, width, height, pixels, offset, scanlength);'),
    ("drawShort", 'if(!transparency) { data[i] &=0x00FFFFFF; }'),
    ("getByte", 'System.out.println("getPixels A");'),
    ("getInt", 'canvas.getRGB(x, y, width, height, pixels, offset, scanlength);'),
    ("getShort", 'int i = offset;'),
    ("getShort", 'pixels[i] = colorToShortPixel(canvas.getRGB(col+x, row+y), format);'),
]
for name, token in checks:
    if token not in blocks[name]:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL canonical token %s" % token)

# G1 already reconstructed and host-accepted the exact OpenJDK8 8-bit SrcOver
# arithmetic in this same owner class. Reuse it instead of Core2D.blit, whose
# generic compositor is not bit-exact for semi-transparent DirectGraphics IO.
if "private static int rg35xxCopyAreaSourceOver(int s, int d)" not in s:
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL G1 exact SrcOver helper missing")

helper = '''\tprivate static int rg35xxDGManipulationToTransform(int manipulation)
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

\tprivate void rg35xxDGBlitExact(int[] srcPixels, int width, int height, int transform, int x, int y)
\t{
\t\tif(width <= 0 || height <= 0) return;
\t\tint[] dst = platformImage.getRG35XXPixels();
\t\tint[] src = srcPixels;
\t\tif(src == dst)
\t\t{
\t\t\tsrc = new int[srcPixels.length];
\t\t\tSystem.arraycopy(srcPixels, 0, src, 0, srcPixels.length);
\t\t}
\t\tint dstWidth = platformImage.getRG35XXWidth();
\t\tint dstHeight = platformImage.getRG35XXHeight();
\t\tint dstX = x + translateX;
\t\tint dstY = y + translateY;
\t\tint clipLeft = Math.max(0, clipX);
\t\tint clipTop = Math.max(0, clipY);
\t\tint clipRight = Math.min(dstWidth, clipX + clipWidth);
\t\tint clipBottom = Math.min(dstHeight, clipY + clipHeight);
\t\tfor(int sy = 0; sy < height; sy++)
\t\t{
\t\t\tfor(int sx = 0; sx < width; sx++)
\t\t\t{
\t\t\t\tint tx;
\t\t\t\tint ty;
\t\t\t\tswitch(transform)
\t\t\t\t{
\t\t\t\t\tcase Sprite.TRANS_NONE: tx = sx; ty = sy; break;
\t\t\t\t\tcase Sprite.TRANS_MIRROR_ROT180: tx = sx; ty = height - 1 - sy; break;
\t\t\t\t\tcase Sprite.TRANS_MIRROR: tx = width - 1 - sx; ty = sy; break;
\t\t\t\t\tcase Sprite.TRANS_ROT180: tx = width - 1 - sx; ty = height - 1 - sy; break;
\t\t\t\t\tcase Sprite.TRANS_MIRROR_ROT270: tx = sy; ty = sx; break;
\t\t\t\t\tcase Sprite.TRANS_ROT90: tx = height - 1 - sy; ty = sx; break;
\t\t\t\t\tcase Sprite.TRANS_ROT270: tx = sy; ty = width - 1 - sx; break;
\t\t\t\t\tcase Sprite.TRANS_MIRROR_ROT90: tx = height - 1 - sy; ty = width - 1 - sx; break;
\t\t\t\t\tdefault: tx = sx; ty = sy; break;
\t\t\t\t}
\t\t\t\tint dx = dstX + tx;
\t\t\t\tint dy = dstY + ty;
\t\t\t\tif(dx < clipLeft || dy < clipTop || dx >= clipRight || dy >= clipBottom) continue;
\t\t\t\tint di = dy * dstWidth + dx;
\t\t\t\tdst[di] = rg35xxCopyAreaSourceOver(src[sy * width + sx], dst[di]);
\t\t\t}
\t\t}
\t}

\tprivate void rg35xxDGBlitPacked(int[] packed, int width, int height, int manipulation, int x, int y)
\t{
\t\tint transform = rg35xxDGManipulationToTransform(manipulation);
\t\trg35xxDGBlitExact(packed, width, height, transform, x, y);
\t}

'''

raw_draw_image = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw() && img != null && img.platformImage != null && img.platformImage.isRG35XXRaw())
\t\t{
\t\t\tint transform = rg35xxDGManipulationToTransform(manipulation);
\t\t\tint sw = img.getWidth();
\t\t\tint sh = img.getHeight();
\t\t\tint dw = rg35xxDGTransformSwaps(transform) ? sh : sw;
\t\t\tint dh = rg35xxDGTransformSwaps(transform) ? sw : sh;
\t\t\tx = AnchorX(x, dw, anchor);
\t\t\ty = AnchorY(y, dh, anchor);
\t\t\trg35xxDGBlitExact(img.platformImage.getRG35XXPixels(), sw, sh, transform, x, y);
\t\t\treturn;
\t\t}
'''

raw_draw_byte = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] rgType1 = {0xFFFFFFFF, 0xFF000000, 0x00FFFFFF, 0x00000000};
\t\t\tint rgc = 0;
\t\t\tint[] rgdata;
\t\t\tswitch(format)
\t\t\t{
\t\t\t\tcase -1:
\t\t\t\t\trgdata = new int[width*height];
\t\t\t\t\tint rgOds = offset / scanlength;
\t\t\t\t\tint rgOms = offset % scanlength;
\t\t\t\t\tint rgBit = rgOds % 8;
\t\t\t\t\tfor (int yj = 0; yj < height; yj++)
\t\t\t\t\t{
\t\t\t\t\t\tint rgTmp = (rgOds + yj) / 8 * scanlength + rgOms;
\t\t\t\t\t\tfor (int xj = 0; xj < width; xj++)
\t\t\t\t\t\t{
\t\t\t\t\t\t\trgc = ((pixels[rgTmp + xj] >> rgBit) & 1);
\t\t\t\t\t\t\tif(transparencyMask != null) { rgc |= (((transparencyMask[rgTmp + xj] >> rgBit) & 1) ^ 1) << 1; }
\t\t\t\t\t\t\trgdata[yj * width + xj] = rgType1[rgc];
\t\t\t\t\t\t}
\t\t\t\t\t\trgBit++;
\t\t\t\t\t\tif(rgBit > 7) rgBit = 0;
\t\t\t\t\t}
\t\t\t\t\trg35xxDGBlitPacked(rgdata, width, height, manipulation, x, y);
\t\t\t\t\treturn;
\t\t\t\tcase 1:
\t\t\t\t\trgdata = new int[pixels.length * 8];
\t\t\t\t\tfor(int rgi = (offset / 8); rgi < pixels.length; rgi++)
\t\t\t\t\t{
\t\t\t\t\t\tfor(int rgj = 7; rgj >= 0; rgj--)
\t\t\t\t\t\t{
\t\t\t\t\t\t\trgc = ((pixels[rgi] >> rgj) & 1);
\t\t\t\t\t\t\tif(transparencyMask != null) { rgc |= (((transparencyMask[rgi] >> rgj) & 1) ^ 1) << 1; }
\t\t\t\t\t\t\trgdata[rgi * 8 + (7 - rgj)] = rgType1[rgc];
\t\t\t\t\t\t}
\t\t\t\t\t}
\t\t\t\t\trg35xxDGBlitPacked(rg35xxDGPackPixels(rgdata, 0, scanlength, width, height), width, height, manipulation, x, y);
\t\t\t\t\treturn;
\t\t\t\tdefault:
\t\t\t\t\tSystem.out.println("drawPixels A : Format " + format + " Not Implemented");
\t\t\t\t\treturn;
\t\t\t}
\t\t}
'''

raw_draw_int = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] rgPacked = rg35xxDGPackPixels(pixels, offset, scanlength, width, height);
\t\t\trg35xxDGBlitPacked(rgPacked, width, height, manipulation, x, y);
\t\t\treturn;
\t\t}
'''

raw_draw_short = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] rgData = new int[pixels.length];
\t\t\tfor(int rgi = 0; rgi < pixels.length; rgi++)
\t\t\t{
\t\t\t\trgData[rgi] = pixelToColor(pixels[rgi], format);
\t\t\t\tif(!transparency) { rgData[rgi] &= 0x00FFFFFF; }
\t\t\t}
\t\t\tint[] rgPacked = rg35xxDGPackPixels(rgData, offset, scanlength, width, height);
\t\t\trg35xxDGBlitPacked(rgPacked, width, height, manipulation, x, y);
\t\t\treturn;
\t\t}
'''

raw_get_int = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] rgSrc = platformImage.getRG35XXPixels();
\t\t\tint rgStride = platformImage.getRG35XXWidth();
\t\t\tfor(int rgRow = 0; rgRow < height; rgRow++)
\t\t\t{
\t\t\t\tSystem.arraycopy(rgSrc, (y + rgRow) * rgStride + x, pixels, offset + rgRow * scanlength, width);
\t\t\t}
\t\t\treturn;
\t\t}
'''

raw_get_short = '''\t\tif(platformImage != null && platformImage.isRG35XXRaw())
\t\t{
\t\t\tint[] rgSrc = platformImage.getRG35XXPixels();
\t\t\tint rgStride = platformImage.getRG35XXWidth();
\t\t\tint rgi = offset;
\t\t\tfor(int rgRow = 0; rgRow < height; rgRow++)
\t\t\t{
\t\t\t\tfor (int rgCol = 0; rgCol < width; rgCol++)
\t\t\t\t{
\t\t\t\t\tpixels[rgi] = colorToShortPixel(rgSrc[(rgRow + y) * rgStride + (rgCol + x)], format);
\t\t\t\t\trgi++;
\t\t\t\t}
\t\t\t}
\t\t\treturn;
\t\t}
'''

s = s[:p0] + helper + s[p0:]

def inject_body(text, sig, code, label):
    pos = text.index(sig)
    brace = text.index("\t{\n", pos + len(sig))
    body = brace + len("\t{\n")
    if body <= pos:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL body %s" % label)
    return text[:body] + code + text[body:]

s = inject_body(s, sig_draw_image, raw_draw_image, "drawImage")
s = inject_body(s, sig_draw_px_b, raw_draw_byte, "drawPixels-byte")
s = inject_body(s, sig_draw_px_i, raw_draw_int, "drawPixels-int")
s = inject_body(s, sig_draw_px_s, raw_draw_short, "drawPixels-short")
s = inject_body(s, sig_get_px_i, raw_get_int, "getPixels-int")
s = inject_body(s, sig_get_px_s, raw_get_short, "getPixels-short")

ng0 = s.index(sig_get_px_b)
ng1 = s.index(sig_get_px_i, ng0)
if s[ng0:ng1] != blocks["getByte"]:
    raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL byte getPixels stub drift")

required = [
    "private void rg35xxDGBlitExact(int[] srcPixels, int width, int height, int transform, int x, int y)",
    "dst[di] = rg35xxCopyAreaSourceOver(src[sy * width + sx], dst[di]);",
    "case DirectGraphics.ROTATE_90: return Sprite.TRANS_ROT270;",
    "case Sprite.TRANS_ROT270: tx = sy; ty = width - 1 - sx; break;",
    "rg35xxDGBlitExact(img.platformImage.getRG35XXPixels(), sw, sh, transform, x, y);",
    "int rgOds = offset / scanlength;",
    "rgc = ((pixels[rgTmp + xj] >> rgBit) & 1);",
    "for(int rgj = 7; rgj >= 0; rgj--)",
    "if(!transparency) { rgData[rgi] &= 0x00FFFFFF; }",
    "System.arraycopy(rgSrc, (y + rgRow) * rgStride + x, pixels, offset + rgRow * scanlength, width);",
    "pixels[rgi] = colorToShortPixel(rgSrc[(rgRow + y) * rgStride + (rgCol + x)], format);",
]
for token in required:
    if token not in s:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL missing token %s" % token)

for name, token in checks:
    if token not in s:
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL fallback lost %s" % token)
for forbidden in ["Asphalt", "God of War", "Vua Cuop Bien", "Vua Cướp Biển"]:
    if s.count(forbidden) != parent.count(forbidden):
        raise SystemExit("P1A_COMPLETE_G4G5_STAGE_FAIL game-specific marker delta %s" % forbidden)

pg.write_text(s, encoding="utf-8")
print("P1A_COMPLETE_G4G5_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_COMPLETE_G4_CHANGED_METHODS=DirectGraphics.drawImage_manipulation,drawPixels_byte,drawPixels_int,drawPixels_short")
print("P1A_COMPLETE_G5_CHANGED_METHODS=DirectGraphics.getPixels_int,getPixels_short")
print("P1A_COMPLETE_G5_GETPIXELS_BYTE=CANONICAL_STUB_UNCHANGED")
print("P1A_COMPLETE_G4_BACKEND=RAW_TRANSFORM_PLUS_G1_EXACT_8BIT_SRCOVER")
print("P1A_COMPLETE_G5_BACKEND=RAW_PLATFORMIMAGE_FRAMEBUFFER_READ")
print("P1A_COMPLETE_CORE2D_CHANGE=NO")
print("P1A_COMPLETE_NATIVE_CHANGE=NO")
print("P1A_COMPLETE_G4G5_STAGE=PASS")
