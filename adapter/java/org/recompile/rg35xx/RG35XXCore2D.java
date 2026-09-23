package org.recompile.rg35xx;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.InflaterInputStream;

/**
 * RG35XX-only headless backing helpers used by the staged A5 core2D overlay.
 * J2ME ownership/semantics remain in the pinned Aweigit classes; this helper
 * only replaces desktop AWT image/font backing when rg35xx.raw2d=true.
 */
public final class RG35XXCore2D {
    private RG35XXCore2D() { }

    public static final class RawImage {
        public final int width;
        public final int height;
        public final int[] pixels;
        public RawImage(int width, int height, int[] pixels) {
            this.width = width;
            this.height = height;
            this.pixels = pixels;
        }
    }

    public static RawImage fromRGB(int[] rgb, int width, int height, boolean processAlpha) {
        int[] out = new int[width * height];
        for (int i = 0; i < out.length; i++) {
            int p = rgb[i];
            out[i] = processAlpha ? p : (0xFF000000 | (p & 0x00FFFFFF));
        }
        return new RawImage(width, height, out);
    }

    public static RawImage copy(int[] src, int width, int height) {
        int[] out = new int[width * height];
        System.arraycopy(src, 0, out, 0, out.length);
        return new RawImage(width, height, out);
    }

    public static RawImage transform(int[] src, int srcWidth, int srcHeight,
                                     int x, int y, int width, int height, int transform) {
        boolean swap = transform == 4 || transform == 5 || transform == 6 || transform == 7;
        int outWidth = swap ? height : width;
        int outHeight = swap ? width : height;
        int[] out = new int[outWidth * outHeight];
        for (int sy = 0; sy < height; sy++) {
            for (int sx = 0; sx < width; sx++) {
                int dx;
                int dy;
                switch (transform) {
                    case 0: dx = sx; dy = sy; break;                         // TRANS_NONE
                    case 1: dx = sx; dy = height - 1 - sy; break;            // TRANS_MIRROR_ROT180
                    case 2: dx = width - 1 - sx; dy = sy; break;             // TRANS_MIRROR
                    case 3: dx = width - 1 - sx; dy = height - 1 - sy; break;// TRANS_ROT180
                    case 4: dx = sy; dy = sx; break;                          // TRANS_MIRROR_ROT270
                    case 5: dx = height - 1 - sy; dy = sx; break;             // TRANS_ROT90
                    case 6: dx = sy; dy = width - 1 - sx; break;              // TRANS_ROT270
                    case 7: dx = height - 1 - sy; dy = width - 1 - sx; break; // TRANS_MIRROR_ROT90
                    default: throw new IllegalArgumentException("bad transform " + transform);
                }
                out[dy * outWidth + dx] = src[(y + sy) * srcWidth + (x + sx)];
            }
        }
        return new RawImage(outWidth, outHeight, out);
    }

    /** Source-over ARGB blit with clipping and an optional MIDP transform. */
    public static void blit(int[] dst, int dstWidth, int dstHeight,
                            int[] src, int srcWidth, int srcHeight,
                            int srcX, int srcY, int width, int height, int transform,
                            int dstX, int dstY,
                            int clipX, int clipY, int clipWidth, int clipHeight) {
        RawImage r = transform == 0
                ? subRaw(src, srcWidth, srcHeight, srcX, srcY, width, height)
                : transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);
        int left = Math.max(dstX, Math.max(clipX, 0));
        int top = Math.max(dstY, Math.max(clipY, 0));
        int right = Math.min(dstX + r.width, Math.min(clipX + clipWidth, dstWidth));
        int bottom = Math.min(dstY + r.height, Math.min(clipY + clipHeight, dstHeight));
        if (right <= left || bottom <= top) return;
        for (int y = top; y < bottom; y++) {
            int sy = y - dstY;
            int di = y * dstWidth + left;
            int si = sy * r.width + (left - dstX);
            for (int x = left; x < right; x++, di++, si++) {
                dst[di] = sourceOver(r.pixels[si], dst[di]);
            }
        }
    }

    private static RawImage subRaw(int[] src, int srcWidth, int srcHeight,
                                   int x, int y, int width, int height) {
        if (x < 0 || y < 0 || width < 0 || height < 0 || x + width > srcWidth || y + height > srcHeight) {
            throw new IllegalArgumentException("subimage bounds");
        }
        int[] out = new int[width * height];
        for (int row = 0; row < height; row++) {
            System.arraycopy(src, (y + row) * srcWidth + x, out, row * width, width);
        }
        return new RawImage(width, height, out);
    }

    private static int sourceOver(int s, int d) {
        int sa = (s >>> 24) & 0xFF;
        if (sa == 0) return d;
        if (sa == 255) return s;
        int da = (d >>> 24) & 0xFF;
        int inv = 255 - sa;
        int outA255 = sa * 255 + da * inv;
        if (outA255 == 0) return 0;
        int oa = (outA255 + 127) / 255;
        int sr = (s >>> 16) & 0xFF, sg = (s >>> 8) & 0xFF, sb = s & 0xFF;
        int dr = (d >>> 16) & 0xFF, dg = (d >>> 8) & 0xFF, db = d & 0xFF;
        int r = (sr * sa * 255 + dr * da * inv + outA255 / 2) / outA255;
        int g = (sg * sa * 255 + dg * da * inv + outA255 / 2) / outA255;
        int b = (sb * sa * 255 + db * da * inv + outA255 / 2) / outA255;
        return (oa << 24) | (r << 16) | (g << 8) | b;
    }

    public static int fontHeight(int size) {
        if (size == 8) return 10;   // SIZE_SMALL
        if (size == 16) return 18;  // SIZE_LARGE
        return 14;                  // SIZE_MEDIUM
    }

    public static int fontAscent(int size) { return fontHeight(size) - 3; }
    public static int fontDescent(int size) { return 3; }

    public static int charWidth(char ch, int size, int face, int style) {
        if (ch == 0) return 0;
        boolean wide = (ch >= 0x3000 && ch <= 0x30FF) ||
                       (ch >= 0x3400 && ch <= 0x9FFF) ||
                       (ch >= 0xAC00 && ch <= 0xD7AF) ||
                       (ch >= 0xFF00 && ch <= 0xFFEF);
        int base = size == 8 ? 6 : (size == 16 ? 10 : 8);
        return wide ? Math.max(base, fontHeight(size) - 2) : base;
    }

    public static int stringWidth(String str, int size, int face, int style) {
        if (str == null) return 0;
        int width = 0;
        for (int i = 0; i < str.length(); i++) width += charWidth(str.charAt(i), size, face, style);
        return width;
    }

    /** 5x7 device-proven ASCII bitmap patterns; unknown glyphs use a box. */
    public static String glyph(char ch) {
        ch = Character.toUpperCase(ch);
        switch (ch) {
            case 'A': return "01110100011000111111100011000110001";
            case 'B': return "11110100011000111110100011000111110";
            case 'C': return "01111100001000010000100001000001111";
            case 'D': return "11110100011000110001100011000111110";
            case 'E': return "11111100001000011110100001000011111";
            case 'F': return "11111100001000011110100001000010000";
            case 'G': return "01111100001000010111100011000101111";
            case 'H': return "10001100011000111111100011000110001";
            case 'I': return "11111001000010000100001000010011111";
            case 'J': return "00111000100001000010000101001001100";
            case 'K': return "10001100101010011000101001001010001";
            case 'L': return "10000100001000010000100001000011111";
            case 'M': return "10001110111010110101100011000110001";
            case 'N': return "10001110011010110011100011000110001";
            case 'O': return "01110100011000110001100011000101110";
            case 'P': return "11110100011000111110100001000010000";
            case 'Q': return "01110100011000110001101011001001101";
            case 'R': return "11110100011000111110101001001010001";
            case 'S': return "01111100001000001110000010000111110";
            case 'T': return "11111001000010000100001000010000100";
            case 'U': return "10001100011000110001100011000101110";
            case 'V': return "10001100011000110001100010101000100";
            case 'W': return "10001100011000110101101011010101010";
            case 'X': return "10001100010101000100010101000110001";
            case 'Y': return "10001100010101000100001000010000100";
            case 'Z': return "11111000010001000100010001000011111";
            case '0': return "01110100011001110101110011000101110";
            case '1': return "00100011000010000100001000010001110";
            case '2': return "01110100010000100010001000100011111";
            case '3': return "11110000010000101110000010000111110";
            case '4': return "00010001100101010010111110001000010";
            case '5': return "11111100001000011110000010000111110";
            case '6': return "01110100001000011110100011000101110";
            case '7': return "11111000010001000100010000100001000";
            case '8': return "01110100011000101110100011000101110";
            case '9': return "01110100011000101111000010000101110";
            case '-': return "00000000000000011111000000000000000";
            case '.': return "00000000000000000000000000011000110";
            case ':': return "00000001000000000000001000000000000";
            case ' ': return "00000000000000000000000000000000000";
            default:  return "11111100011000110001100011000111111";
        }
    }

    public static RawImage decodePng(InputStream in) throws IOException {
        byte[] png = readAll(in);
        if (png.length < 8 || png[0] != (byte)0x89 || png[1] != 0x50 || png[2] != 0x4E || png[3] != 0x47) {
            throw new IOException("RG35XX raw2d: unsupported image format (PNG required)");
        }
        int pos = 8;
        int width = 0, height = 0, bitDepth = -1, colorType = -1, interlace = -1;
        byte[] palette = null, transparency = null;
        ByteArrayOutputStream idat = new ByteArrayOutputStream();
        while (pos + 12 <= png.length) {
            int len = readInt(png, pos); pos += 4;
            if (len < 0 || pos + 4 + len + 4 > png.length) throw new IOException("bad PNG chunk");
            String type = new String(png, pos, 4, "ISO-8859-1"); pos += 4;
            if ("IHDR".equals(type)) {
                width = readInt(png, pos); height = readInt(png, pos + 4);
                bitDepth = png[pos + 8] & 0xFF; colorType = png[pos + 9] & 0xFF; interlace = png[pos + 12] & 0xFF;
            } else if ("PLTE".equals(type)) {
                palette = new byte[len]; System.arraycopy(png, pos, palette, 0, len);
            } else if ("tRNS".equals(type)) {
                transparency = new byte[len]; System.arraycopy(png, pos, transparency, 0, len);
            } else if ("IDAT".equals(type)) {
                idat.write(png, pos, len);
            } else if ("IEND".equals(type)) {
                break;
            }
            pos += len + 4; // payload + CRC
        }
        if (width <= 0 || height <= 0) throw new IOException("PNG missing IHDR");
        if (interlace != 0) throw new IOException("PNG Adam7 unsupported in RG35XX raw2d");
        if (bitDepth != 8 && !(colorType == 3 && (bitDepth == 1 || bitDepth == 2 || bitDepth == 4))) {
            throw new IOException("PNG bit depth unsupported: " + bitDepth);
        }
        int channels;
        switch (colorType) {
            case 0: channels = 1; break;
            case 2: channels = 3; break;
            case 3: channels = 1; break;
            case 4: channels = 2; break;
            case 6: channels = 4; break;
            default: throw new IOException("PNG color type unsupported: " + colorType);
        }
        int rowBytes = colorType == 3 ? ((width * bitDepth + 7) / 8) : width * channels;
        int bpp = colorType == 3 ? 1 : channels;
        InflaterInputStream zin = new InflaterInputStream(new ByteArrayInputStream(idat.toByteArray()));
        byte[] packed = new byte[(rowBytes + 1) * height];
        int got = 0;
        while (got < packed.length) {
            int n = zin.read(packed, got, packed.length - got);
            if (n < 0) break;
            got += n;
        }
        zin.close();
        if (got != packed.length) throw new IOException("short PNG inflate " + got + "/" + packed.length);
        byte[] prev = new byte[rowBytes];
        byte[] cur = new byte[rowBytes];
        int[] out = new int[width * height];
        int p = 0;
        for (int y = 0; y < height; y++) {
            int filter = packed[p++] & 0xFF;
            System.arraycopy(packed, p, cur, 0, rowBytes); p += rowBytes;
            unfilter(cur, prev, filter, bpp);
            if (colorType == 3) {
                if (palette == null) throw new IOException("indexed PNG missing PLTE");
                for (int x = 0; x < width; x++) {
                    int index = unpackIndex(cur, x, bitDepth);
                    int po = index * 3;
                    if (po + 2 >= palette.length) throw new IOException("palette index");
                    int a = (transparency != null && index < transparency.length) ? transparency[index] & 0xFF : 255;
                    int r = palette[po] & 0xFF, g = palette[po + 1] & 0xFF, b = palette[po + 2] & 0xFF;
                    out[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
                }
            } else {
                int o = 0;
                for (int x = 0; x < width; x++) {
                    int r, g, b, a = 255;
                    if (colorType == 0) { r = g = b = cur[o++] & 0xFF; }
                    else if (colorType == 2) { r = cur[o++] & 0xFF; g = cur[o++] & 0xFF; b = cur[o++] & 0xFF; }
                    else if (colorType == 4) { r = g = b = cur[o++] & 0xFF; a = cur[o++] & 0xFF; }
                    else { r = cur[o++] & 0xFF; g = cur[o++] & 0xFF; b = cur[o++] & 0xFF; a = cur[o++] & 0xFF; }
                    out[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
                }
            }
            byte[] tmp = prev; prev = cur; cur = tmp;
        }
        return new RawImage(width, height, out);
    }

    private static int unpackIndex(byte[] row, int x, int bits) {
        if (bits == 8) return row[x] & 0xFF;
        int perByte = 8 / bits;
        int shift = (perByte - 1 - (x % perByte)) * bits;
        return ((row[x / perByte] & 0xFF) >>> shift) & ((1 << bits) - 1);
    }

    private static void unfilter(byte[] row, byte[] prev, int filter, int bpp) throws IOException {
        for (int i = 0; i < row.length; i++) {
            int raw = row[i] & 0xFF;
            int a = i >= bpp ? row[i - bpp] & 0xFF : 0;
            int b = prev[i] & 0xFF;
            int c = i >= bpp ? prev[i - bpp] & 0xFF : 0;
            int val;
            switch (filter) {
                case 0: val = raw; break;
                case 1: val = raw + a; break;
                case 2: val = raw + b; break;
                case 3: val = raw + ((a + b) >>> 1); break;
                case 4: val = raw + paeth(a, b, c); break;
                default: throw new IOException("PNG filter unsupported: " + filter);
            }
            row[i] = (byte)(val & 0xFF);
        }
    }

    private static int paeth(int a, int b, int c) {
        int p = a + b - c;
        int pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        return pa <= pb && pa <= pc ? a : (pb <= pc ? b : c);
    }

    private static byte[] readAll(InputStream in) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        while ((n = in.read(buf)) >= 0) if (n > 0) out.write(buf, 0, n);
        return out.toByteArray();
    }

    private static int readInt(byte[] b, int p) {
        return ((b[p] & 0xFF) << 24) | ((b[p + 1] & 0xFF) << 16) | ((b[p + 2] & 0xFF) << 8) | (b[p + 3] & 0xFF);
    }
}