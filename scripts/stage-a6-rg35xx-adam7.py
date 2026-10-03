#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-adam7.py <repo-root>')
root = Path(sys.argv[1]).resolve()
path = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
text = path.read_text(encoding='utf-8')
old = '        if (interlace != 0) throw new IOException("PNG Adam7 unsupported in RG35XX raw2d");\n'
new = ('        if (interlace == 1) return decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());\n'
       '        if (interlace != 0) throw new IOException("PNG interlace method unsupported: " + interlace);\n')
count = text.count(old)
if count != 1:
    raise SystemExit('A6_ADAM7_INLINE_STAGE_FAIL expected-interlace=1 found=%d' % count)
text = text.replace(old, new, 1)
anchor = '    private static int unpackIndex(byte[] row, int x, int bits) {\n'
if text.count(anchor) != 1:
    raise SystemExit('A6_ADAM7_INLINE_STAGE_FAIL unpackIndex anchor count=%d' % text.count(anchor))
helper = r'''    private static RawImage decodeAdam7(int width, int height, int bitDepth, int colorType,
                                             byte[] palette, byte[] transparency, byte[] compressed)
            throws IOException {
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

        final int[] startX = {0, 4, 0, 2, 0, 1, 0};
        final int[] startY = {0, 0, 4, 0, 2, 0, 1};
        final int[] stepX  = {8, 8, 4, 4, 2, 2, 1};
        final int[] stepY  = {8, 8, 8, 4, 4, 2, 2};

        int expected = 0;
        for (int pass = 0; pass < 7; pass++) {
            int pw = passSize(width, startX[pass], stepX[pass]);
            int ph = passSize(height, startY[pass], stepY[pass]);
            if (pw == 0 || ph == 0) continue;
            int rowBytes = colorType == 3 ? ((pw * bitDepth + 7) / 8) : pw * channels;
            expected += (rowBytes + 1) * ph;
        }

        InflaterInputStream zin = new InflaterInputStream(new ByteArrayInputStream(compressed));
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
            int sx = startX[pass], sy = startY[pass];
            int dx = stepX[pass], dy = stepY[pass];
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
        return new RawImage(width, height, out);
    }

    private static int passSize(int size, int start, int step) {
        if (size <= start) return 0;
        return (size - start + step - 1) / step;
    }

'''
text = text.replace(anchor, helper + anchor, 1)
path.write_text(text, encoding='utf-8')
print('A6_ADAM7_INLINE_STAGE=PASS')
print('A6_ADAM7_INLINE_REWRITES=2')
print('A6_ADAM7_SEPARATE_CLASS=NO')
