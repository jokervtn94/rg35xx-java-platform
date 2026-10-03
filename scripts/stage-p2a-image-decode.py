#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-p2a-image-decode.py <repo-root>')

root = Path(sys.argv[1]).resolve()
path = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
text = path.read_text(encoding='utf-8')

start_sig = '    public static RawImage decodePng(InputStream in) throws IOException {\n'
end_sig = '    private static int unpackIndex(byte[] row, int x, int bits) {\n'

if text.count(start_sig) != 1 or text.count(end_sig) != 1:
    raise SystemExit('P2A_IMAGE_STAGE_FAIL decoder anchors start=%d end=%d' %
                     (text.count(start_sig), text.count(end_sig)))

# P2A must be layered on the exact accepted P1A materialization, which includes
# the accepted A6 Adam7 overlay. The audit branch is evidence only, never parent.
required = [
    'if (interlace == 1) return decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());',
    'private static RawImage decodeAdam7(int width, int height, int bitDepth, int colorType,',
    'private static int passSize(int size, int start, int step) {'
]
for marker in required:
    if text.count(marker) != 1:
        raise SystemExit('P2A_IMAGE_STAGE_FAIL accepted-parent-marker=%r count=%d' %
                         (marker, text.count(marker)))

start = text.index(start_sig)
end = text.index(end_sig, start)

replacement = r'''    public static RawImage decodePng(InputStream in) throws IOException {
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
        validatePngFormat(bitDepth, colorType);
        if (interlace == 1) return decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());
        if (interlace != 0) throw new IOException("PNG interlace method unsupported: " + interlace);

        int rowBytes = pngRowBytes(width, bitDepth, colorType);
        int bpp = pngFilterBpp(bitDepth, colorType);
        int packedLength = checkedPackedLength(rowBytes, height, "PNG");
        InflaterInputStream zin = new InflaterInputStream(new ByteArrayInputStream(idat.toByteArray()));
        byte[] packed = new byte[packedLength];
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
            for (int x = 0; x < width; x++) {
                out[y * width + x] = decodePngPixel(cur, x, bitDepth, colorType, palette, transparency);
            }
            byte[] tmp = prev; prev = cur; cur = tmp;
        }
        return new RawImage(width, height, out);
    }

    private static RawImage decodeAdam7(int width, int height, int bitDepth, int colorType,
                                             byte[] palette, byte[] transparency, byte[] compressed)
            throws IOException {
        validatePngFormat(bitDepth, colorType);
        final int[] startX = {0, 4, 0, 2, 0, 1, 0};
        final int[] startY = {0, 0, 4, 0, 2, 0, 1};
        final int[] stepX  = {8, 8, 4, 4, 2, 2, 1};
        final int[] stepY  = {8, 8, 8, 4, 4, 2, 2};

        long expectedLong = 0L;
        for (int pass = 0; pass < 7; pass++) {
            int pw = passSize(width, startX[pass], stepX[pass]);
            int ph = passSize(height, startY[pass], stepY[pass]);
            if (pw == 0 || ph == 0) continue;
            int rowBytes = pngRowBytes(pw, bitDepth, colorType);
            expectedLong += ((long)rowBytes + 1L) * (long)ph;
            if (expectedLong > Integer.MAX_VALUE) throw new IOException("RG35XX Adam7: inflated data too large");
        }

        InflaterInputStream zin = new InflaterInputStream(new ByteArrayInputStream(compressed));
        byte[] packed = new byte[(int)expectedLong];
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
        int bpp = pngFilterBpp(bitDepth, colorType);
        for (int pass = 0; pass < 7; pass++) {
            int sx = startX[pass], sy = startY[pass];
            int dx = stepX[pass], dy = stepY[pass];
            int pw = passSize(width, sx, dx);
            int ph = passSize(height, sy, dy);
            if (pw == 0 || ph == 0) continue;
            int rowBytes = pngRowBytes(pw, bitDepth, colorType);
            byte[] prev = new byte[rowBytes];
            byte[] cur = new byte[rowBytes];
            for (int py = 0; py < ph; py++) {
                int filter = packed[p++] & 0xFF;
                System.arraycopy(packed, p, cur, 0, rowBytes); p += rowBytes;
                unfilter(cur, prev, filter, bpp);
                int dstY = sy + py * dy;
                for (int px = 0; px < pw; px++) {
                    int dstX = sx + px * dx;
                    out[dstY * width + dstX] = decodePngPixel(cur, px, bitDepth, colorType, palette, transparency);
                }
                byte[] tmp = prev; prev = cur; cur = tmp;
            }
        }
        if (p != packed.length) throw new IOException("RG35XX Adam7: inflate accounting mismatch " + p + "/" + packed.length);
        return new RawImage(width, height, out);
    }

    private static int passSize(int size, int start, int step) {
        if (size <= start) return 0;
        return (size - start + step - 1) / step;
    }

    private static void validatePngFormat(int bitDepth, int colorType) throws IOException {
        boolean valid;
        switch (colorType) {
            case 0: valid = bitDepth == 1 || bitDepth == 2 || bitDepth == 4 || bitDepth == 8 || bitDepth == 16; break;
            case 2: valid = bitDepth == 8 || bitDepth == 16; break;
            case 3: valid = bitDepth == 1 || bitDepth == 2 || bitDepth == 4 || bitDepth == 8; break;
            case 4: valid = bitDepth == 8 || bitDepth == 16; break;
            case 6: valid = bitDepth == 8 || bitDepth == 16; break;
            default: throw new IOException("PNG color type unsupported: " + colorType);
        }
        if (!valid) throw new IOException("PNG bit depth unsupported for color type " + colorType + ": " + bitDepth);
    }

    private static int pngChannels(int colorType) throws IOException {
        switch (colorType) {
            case 0: return 1;
            case 2: return 3;
            case 3: return 1;
            case 4: return 2;
            case 6: return 4;
            default: throw new IOException("PNG color type unsupported: " + colorType);
        }
    }

    private static int pngRowBytes(int width, int bitDepth, int colorType) throws IOException {
        long bits = (long)width * (long)pngChannels(colorType) * (long)bitDepth;
        long bytes = (bits + 7L) >>> 3;
        if (bytes > Integer.MAX_VALUE) throw new IOException("PNG row too large");
        return (int)bytes;
    }

    private static int pngFilterBpp(int bitDepth, int colorType) throws IOException {
        int bits = pngChannels(colorType) * bitDepth;
        int bytes = (bits + 7) >>> 3;
        return bytes < 1 ? 1 : bytes;
    }

    private static int checkedPackedLength(int rowBytes, int height, String label) throws IOException {
        long length = ((long)rowBytes + 1L) * (long)height;
        if (length > Integer.MAX_VALUE) throw new IOException(label + " inflated data too large");
        return (int)length;
    }

    private static int decodePngPixel(byte[] row, int x, int bitDepth, int colorType,
                                      byte[] palette, byte[] transparency) throws IOException {
        if (colorType == 0) {
            int sample = readPngSample(row, x, bitDepth);
            int gray = bitDepth < 8
                    ? scaleSampleTo8(sample, (1 << bitDepth) - 1)
                    : linearGrayToSrgb8(sample, bitDepth == 8 ? 255 : 65535);
            return 0xFF000000 | (gray << 16) | (gray << 8) | gray;
        }
        if (colorType == 2) {
            int base = x * 3;
            int r = componentTo8(readPngSample(row, base, bitDepth), bitDepth);
            int g = componentTo8(readPngSample(row, base + 1, bitDepth), bitDepth);
            int b = componentTo8(readPngSample(row, base + 2, bitDepth), bitDepth);
            return 0xFF000000 | (r << 16) | (g << 8) | b;
        }
        if (colorType == 3) {
            if (palette == null) throw new IOException("indexed PNG missing PLTE");
            int index = unpackIndex(row, x, bitDepth);
            int po = index * 3;
            if (po + 2 >= palette.length) throw new IOException("palette index");
            int a = transparency != null && index < transparency.length ? transparency[index] & 0xFF : 255;
            int r = palette[po] & 0xFF, g = palette[po + 1] & 0xFF, b = palette[po + 2] & 0xFF;
            return (a << 24) | (r << 16) | (g << 8) | b;
        }
        if (colorType == 4) {
            int base = x * 2;
            int graySample = readPngSample(row, base, bitDepth);
            int gray = linearGrayToSrgb8(graySample, bitDepth == 8 ? 255 : 65535);
            int a = componentTo8(readPngSample(row, base + 1, bitDepth), bitDepth);
            return (a << 24) | (gray << 16) | (gray << 8) | gray;
        }
        int base = x * 4;
        int r = componentTo8(readPngSample(row, base, bitDepth), bitDepth);
        int g = componentTo8(readPngSample(row, base + 1, bitDepth), bitDepth);
        int b = componentTo8(readPngSample(row, base + 2, bitDepth), bitDepth);
        int a = componentTo8(readPngSample(row, base + 3, bitDepth), bitDepth);
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    private static int readPngSample(byte[] row, int sampleIndex, int bitDepth) throws IOException {
        if (bitDepth == 1 || bitDepth == 2 || bitDepth == 4) {
            int perByte = 8 / bitDepth;
            int shift = (perByte - 1 - (sampleIndex % perByte)) * bitDepth;
            return ((row[sampleIndex / perByte] & 0xFF) >>> shift) & ((1 << bitDepth) - 1);
        }
        if (bitDepth == 8) return row[sampleIndex] & 0xFF;
        if (bitDepth == 16) {
            int o = sampleIndex * 2;
            return ((row[o] & 0xFF) << 8) | (row[o + 1] & 0xFF);
        }
        throw new IOException("PNG sample bit depth unsupported: " + bitDepth);
    }

    private static int componentTo8(int sample, int bitDepth) {
        if (bitDepth == 8) return sample;
        return scaleSampleTo8(sample, 65535);
    }

    private static int scaleSampleTo8(int sample, int max) {
        return (int)((((long)sample) * 255L + ((long)max / 2L)) / (long)max);
    }

    private static int linearGrayToSrgb8(int sample, int max) {
        double linear = ((double)sample) / ((double)max);
        double srgb;
        if (linear <= 0.0031308d) srgb = 12.92d * linear;
        else srgb = 1.055d * Math.pow(linear, 1.0d / 2.4d) - 0.055d;
        int out = (int)Math.round(srgb * 255.0d);
        if (out < 0) return 0;
        if (out > 255) return 255;
        return out;
    }

'''

new_text = text[:start] + replacement + text[end:]
path.write_text(new_text, encoding='utf-8')
print('P2A_IMAGE_STAGE=PASS')
print('P2A_IMAGE_OWNER=RG35XXCore2D.decodePng/decodeAdam7')
print('P2A_IMAGE_ACCEPTED_ADAM7_PARENT=YES')
print('P2A_IMAGE_NONINDEXED_TRNS_CANONICAL_LIMITATION=RETAINED')
print('P2A_IMAGE_OTHER_CORE2D_METHODS_CHANGE=NO')
print('P2A_IMAGE_NATIVE_CHANGE=NO')
print('P2A_IMAGE_GAME_SPECIFIC_CODE=NO')
print('P2A_IMAGE_A9_PARENT=NO')
