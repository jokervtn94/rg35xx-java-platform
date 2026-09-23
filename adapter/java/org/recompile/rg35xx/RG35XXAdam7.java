package org.recompile.rg35xx;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.InflaterInputStream;

/** RG35XX-only Adam7 PNG backing used by the A6 real-game adapter path. */
public final class RG35XXAdam7 {
    private RG35XXAdam7() { }

    private static final int[] START_X = {0, 4, 0, 2, 0, 1, 0};
    private static final int[] START_Y = {0, 0, 4, 0, 2, 0, 1};
    private static final int[] STEP_X  = {8, 8, 4, 4, 2, 2, 1};
    private static final int[] STEP_Y  = {8, 8, 8, 4, 4, 2, 2};

    public static RG35XXCore2D.RawImage decode(byte[] png) throws IOException {
        if (png == null || png.length < 8 || png[0] != (byte)0x89 || png[1] != 0x50 || png[2] != 0x4E || png[3] != 0x47) {
            throw new IOException("RG35XX Adam7: invalid PNG");
        }
        int pos = 8;
        int width = 0, height = 0, bitDepth = -1, colorType = -1, interlace = -1;
        byte[] palette = null, transparency = null;
        ByteArrayOutputStream idat = new ByteArrayOutputStream();
        while (pos + 12 <= png.length) {
            int len = readInt(png, pos); pos += 4;
            if (len < 0 || pos + 4 + len + 4 > png.length) throw new IOException("RG35XX Adam7: bad PNG chunk");
            String type = new String(png, pos, 4, "ISO-8859-1"); pos += 4;
            if ("IHDR".equals(type)) {
                width = readInt(png, pos); height = readInt(png, pos + 4);
                bitDepth = png[pos + 8] & 0xFF;
                colorType = png[pos + 9] & 0xFF;
                interlace = png[pos + 12] & 0xFF;
            } else if ("PLTE".equals(type)) {
                palette = new byte[len]; System.arraycopy(png, pos, palette, 0, len);
            } else if ("tRNS".equals(type)) {
                transparency = new byte[len]; System.arraycopy(png, pos, transparency, 0, len);
            } else if ("IDAT".equals(type)) {
                idat.write(png, pos, len);
            } else if ("IEND".equals(type)) {
                break;
            }
            pos += len + 4;
        }
        if (width <= 0 || height <= 0) throw new IOException("RG35XX Adam7: PNG missing IHDR");
        if (interlace != 1) throw new IOException("RG35XX Adam7: interlace method is not 1");
        if (bitDepth != 8 && !(colorType == 3 && (bitDepth == 1 || bitDepth == 2 || bitDepth == 4))) {
            throw new IOException("RG35XX Adam7: bit depth unsupported: " + bitDepth);
        }
        int channels;
        switch (colorType) {
            case 0: channels = 1; break;
            case 2: channels = 3; break;
            case 3: channels = 1; break;
            case 4: channels = 2; break;
            case 6: channels = 4; break;
            default: throw new IOException("RG35XX Adam7: color type unsupported: " + colorType);
        }
        if (colorType == 3 && palette == null) throw new IOException("RG35XX Adam7: indexed PNG missing PLTE");

        int expected = 0;
        for (int pass = 0; pass < 7; pass++) {
            int pw = passSize(width, START_X[pass], STEP_X[pass]);
            int ph = passSize(height, START_Y[pass], STEP_Y[pass]);
            if (pw == 0 || ph == 0) continue;
            int rowBytes = colorType == 3 ? ((pw * bitDepth + 7) / 8) : pw * channels;
            expected += (rowBytes + 1) * ph;
        }

        InflaterInputStream zin = new InflaterInputStream(new ByteArrayInputStream(idat.toByteArray()));
        byte[] packed = new byte[expected];
        int got = 0;
        while (got < packed.length) {
            int n = zin.read(packed, got, packed.length - got);
            if (n < 0) break;
            got += n;
        }
        zin.close();
        if (got != packed.length) throw new IOException("RG35XX Adam7: short PNG inflate " + got + "/" + packed.length);

        int[] out = new int[width * height];
        int p = 0;
        int bpp = colorType == 3 ? 1 : channels;
        for (int pass = 0; pass < 7; pass++) {
            int sx = START_X[pass], sy = START_Y[pass];
            int dx = STEP_X[pass], dy = STEP_Y[pass];
            int pw = passSize(width, sx, dx);
            int ph = passSize(height, sy, dy);
            if (pw == 0 || ph == 0) continue;
            int rowBytes = colorType == 3 ? ((pw * bitDepth + 7) / 8) : pw * channels;
            byte[] prev = new byte[rowBytes];
            byte[] cur = new byte[rowBytes];
            for (int py = 0; py < ph; py++) {
                int filter = packed[p++] & 0xFF;
                System.arraycopy(packed, p, cur, 0, rowBytes); p += rowBytes;
                unfilter(cur, prev, filter, bpp);
                int dstY = sy + py * dy;
                for (int px = 0; px < pw; px++) {
                    int argb;
                    if (colorType == 3) {
                        int index = unpackIndex(cur, px, bitDepth);
                        int po = index * 3;
                        if (po + 2 >= palette.length) throw new IOException("RG35XX Adam7: palette index");
                        int a = transparency != null && index < transparency.length ? transparency[index] & 0xFF : 255;
                        int r = palette[po] & 0xFF, g = palette[po + 1] & 0xFF, b = palette[po + 2] & 0xFF;
                        argb = (a << 24) | (r << 16) | (g << 8) | b;
                    } else {
                        int o = px * channels;
                        int r, g, b, a = 255;
                        if (colorType == 0) { r = g = b = cur[o] & 0xFF; }
                        else if (colorType == 2) { r = cur[o] & 0xFF; g = cur[o + 1] & 0xFF; b = cur[o + 2] & 0xFF; }
                        else if (colorType == 4) { r = g = b = cur[o] & 0xFF; a = cur[o + 1] & 0xFF; }
                        else { r = cur[o] & 0xFF; g = cur[o + 1] & 0xFF; b = cur[o + 2] & 0xFF; a = cur[o + 3] & 0xFF; }
                        argb = (a << 24) | (r << 16) | (g << 8) | b;
                    }
                    int dstX = sx + px * dx;
                    out[dstY * width + dstX] = argb;
                }
                byte[] tmp = prev; prev = cur; cur = tmp;
            }
        }
        if (p != packed.length) throw new IOException("RG35XX Adam7: inflate accounting mismatch " + p + "/" + packed.length);
        return new RG35XXCore2D.RawImage(width, height, out);
    }

    private static int passSize(int size, int start, int step) {
        if (size <= start) return 0;
        return (size - start + step - 1) / step;
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
                default: throw new IOException("RG35XX Adam7: PNG filter unsupported: " + filter);
            }
            row[i] = (byte)(val & 0xFF);
        }
    }

    private static int paeth(int a, int b, int c) {
        int p = a + b - c;
        int pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        return pa <= pb && pa <= pc ? a : (pb <= pc ? b : c);
    }

    private static int readInt(byte[] b, int p) {
        return ((b[p] & 0xFF) << 24) | ((b[p + 1] & 0xFF) << 16) | ((b[p + 2] & 0xFF) << 8) | (b[p + 3] & 0xFF);
    }
}
