package org.recompile.mobile;

import javax.microedition.lcdui.Font;

/**
 * RG35XX bitmap text producer.
 *
 * M1 keeps MIDP Font metrics as the layout contract while making the fallback
 * raster less blocky on the 320x240 RG35XX display.  The 5x7 seed is rendered
 * inside explicit side/top/bottom bearings instead of stretching to almost the
 * full metric cell.  This avoids merged glyph edges and produces cleaner 2x
 * integer scaling to the 640x480 libretro output.
 */
public final class RG35XXBitmapText
{
    private RG35XXBitmapText() {}

    public static int width(String text, Font font)
    {
        if(text == null || text.length() == 0 || font == null) return 0;
        final int w = font.stringWidth(text);
        return w > 0 ? w : 0;
    }

    public static int height(Font font)
    {
        if(font == null) return 0;
        final int h = font.getHeight();
        return h > 0 ? h : 0;
    }

    public static int[] render(String text, int argb, Font font)
    {
        final int bitmapWidth = width(text, font);
        final int bitmapHeight = height(font);
        if(bitmapWidth <= 0 || bitmapHeight <= 0) return new int[0];
        if(bitmapWidth > Integer.MAX_VALUE / bitmapHeight) return new int[0];

        final int opaqueArgb = argb | 0xFF000000;
        final int[] pixels = new int[bitmapWidth * bitmapHeight];

        int penX = 0;
        for(int i = 0; i < text.length(); i++)
        {
            final char ch = text.charAt(i);
            int advance = font.charWidth(ch);
            if(advance < 1) advance = 1;

            int cellWidth = advance;
            if(penX + cellWidth > bitmapWidth) cellWidth = bitmapWidth - penX;
            if(cellWidth <= 0) break;

            drawGlyph(pixels, bitmapWidth, bitmapHeight, ch, penX, cellWidth, opaqueArgb);
            penX += advance;
            if(penX >= bitmapWidth) break;
        }
        return pixels;
    }

    private static void drawGlyph(int[] pixels, int width, int height, char ch,
                                  int x, int cellWidth, int argb)
    {
        if(ch == ' ' || cellWidth <= 0) return;

        final char base = vietnameseBase(ch);
        final long rows = glyph5x7(base);

        /* M1 raster policy:
         * - keep at least one pixel of horizontal separation for normal cells;
         * - leave vertical breathing room for Vietnamese marks and descenders;
         * - cap expansion so a 5x7 seed is not turned into a thick solid block.
         */
        final int sideBearing = cellWidth >= 6 ? 1 : 0;
        int glyphWidth = cellWidth - sideBearing * 2;
        if(glyphWidth > 6) glyphWidth = 6;
        if(glyphWidth < 1) glyphWidth = 1;

        final int topBearing = height >= 10 ? 2 : 1;
        final int bottomBearing = height >= 10 ? 2 : 1;
        int glyphHeight = height - topBearing - bottomBearing;
        if(glyphHeight > 8) glyphHeight = 8;
        if(glyphHeight < 1) glyphHeight = 1;

        final int glyphX = x + sideBearing +
            ((cellWidth - sideBearing * 2 - glyphWidth) > 0 ?
             (cellWidth - sideBearing * 2 - glyphWidth) / 2 : 0);
        final int glyphY = topBearing +
            ((height - topBearing - bottomBearing - glyphHeight) > 0 ?
             (height - topBearing - bottomBearing - glyphHeight) / 2 : 0);

        for(int dy = 0; dy < glyphHeight; dy++)
        {
            final int sy = (dy * 7) / glyphHeight;
            final int bits = (int)((rows >> ((6 - sy) * 5)) & 31L);
            final int row = (glyphY + dy) * width;

            for(int dx = 0; dx < glyphWidth; dx++)
            {
                final int sx = (dx * 5) / glyphWidth;
                if((bits & (1 << (4 - sx))) == 0) continue;
                final int px = glyphX + dx;
                if(px < 0 || px >= width) continue;
                final int idx = row + px;
                if(idx >= 0 && idx < pixels.length) pixels[idx] = argb;
            }
        }

        drawVietnameseMark(pixels, width, height, ch, glyphX, glyphWidth,
                           glyphY, glyphHeight, argb);
    }

    private static char vietnameseBase(char c)
    {
        if("ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬàáảãạăằắẳẵặâầấẩẫậ".indexOf(c) >= 0) return 'A';
        if("ÈÉẺẼẸÊỀẾỂỄỆèéẻẽẹêềếểễệ".indexOf(c) >= 0) return 'E';
        if("ÌÍỈĨỊìíỉĩị".indexOf(c) >= 0) return 'I';
        if("ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢòóỏõọôồốổỗộơờớởỡợ".indexOf(c) >= 0) return 'O';
        if("ÙÚỦŨỤƯỪỨỬỮỰùúủũụưừứửữự".indexOf(c) >= 0) return 'U';
        if("ỲÝỶỸỴỳýỷỹỵ".indexOf(c) >= 0) return 'Y';
        if(c == 'Đ' || c == 'đ') return 'D';
        return c;
    }

    private static int toneMark(char c)
    {
        if("ÁẮẤÉẾÍÓỐỚÚỨÝáắấéếíóốớúứý".indexOf(c) >= 0) return 1; /* acute */
        if("ÀẰẦÈỀÌÒỒỜÙỪỲàằầèềìòồờùừỳ".indexOf(c) >= 0) return 2; /* grave */
        if("ẢẲẨẺỂỈỎỔỞỦỬỶảẳẩẻểỉỏổởủửỷ".indexOf(c) >= 0) return 3; /* hook */
        if("ÃẴẪẼỄĨÕỖỠŨỮỸãẵẫẽễĩõỗỡũữỹ".indexOf(c) >= 0) return 4; /* tilde */
        if("ẠẶẬẸỆỊỌỘỢỤỰỴạặậẹệịọộợụựỵ".indexOf(c) >= 0) return 5; /* dot */
        return 0;
    }

    private static int shapeMark(char c)
    {
        if("ĂẰẮẲẴẶăằắẳẵặ".indexOf(c) >= 0) return 1; /* breve */
        if("ÂẦẤẨẪẬÊỀẾỂỄỆÔỒỐỔỖỘâầấẩẫậêềếểễệôồốổỗộ".indexOf(c) >= 0) return 2; /* circumflex */
        if("ƠỜỚỞỠỢƯỪỨỬỮỰơờớởỡợưừứửữự".indexOf(c) >= 0) return 3; /* horn */
        if(c == 'Đ' || c == 'đ') return 4; /* crossbar */
        return 0;
    }

    private static void putPixel(int[] pixels, int width, int height,
                                 int x, int y, int argb)
    {
        if(x < 0 || y < 0 || x >= width || y >= height) return;
        final int idx = y * width + x;
        if(idx >= 0 && idx < pixels.length) pixels[idx] = argb;
    }

    private static void drawVietnameseMark(int[] pixels, int width, int height,
                                           char ch, int gx, int gw,
                                           int gy, int gh, int argb)
    {
        final int shape = shapeMark(ch);
        final int tone = toneMark(ch);
        final int cx = gx + gw / 2;

        if(shape == 4) {
            final int y = gy + gh / 2;
            for(int x = gx; x < gx + gw; x++) putPixel(pixels, width, height, x, y, argb);
        } else if(shape == 1 && gy >= 1) {
            putPixel(pixels, width, height, cx - 1, gy - 1, argb);
            putPixel(pixels, width, height, cx, gy, argb);
            putPixel(pixels, width, height, cx + 1, gy - 1, argb);
        } else if(shape == 2 && gy >= 1) {
            putPixel(pixels, width, height, cx - 1, gy, argb);
            putPixel(pixels, width, height, cx, gy - 1, argb);
            putPixel(pixels, width, height, cx + 1, gy, argb);
        } else if(shape == 3) {
            putPixel(pixels, width, height, gx + gw - 1, gy, argb);
            putPixel(pixels, width, height, gx + gw - 1, gy + 1, argb);
        }

        if(tone == 0) return;
        if(tone == 5) {
            putPixel(pixels, width, height, cx, gy + gh + 1, argb);
            return;
        }

        final int ty = gy >= 2 ? gy - 2 : 0;
        if(tone == 1) {
            putPixel(pixels, width, height, cx, ty + 1, argb);
            putPixel(pixels, width, height, cx + 1, ty, argb);
        } else if(tone == 2) {
            putPixel(pixels, width, height, cx, ty + 1, argb);
            putPixel(pixels, width, height, cx - 1, ty, argb);
        } else if(tone == 3) {
            putPixel(pixels, width, height, cx - 1, ty, argb);
            putPixel(pixels, width, height, cx, ty, argb);
            putPixel(pixels, width, height, cx, ty + 1, argb);
        } else if(tone == 4) {
            putPixel(pixels, width, height, cx - 1, ty + 1, argb);
            putPixel(pixels, width, height, cx, ty, argb);
            putPixel(pixels, width, height, cx + 1, ty + 1, argb);
        }
    }

    private static long glyph5x7(char c)
    {
        if(c >= 'a' && c <= 'z') c = (char)(c - 32);
        switch(c)
        {
            case 'A': return r(14,17,17,31,17,17,17); case 'B': return r(30,17,17,30,17,17,30);
            case 'C': return r(14,17,16,16,16,17,14); case 'D': return r(30,17,17,17,17,17,30);
            case 'E': return r(31,16,16,30,16,16,31); case 'F': return r(31,16,16,30,16,16,16);
            case 'G': return r(14,17,16,23,17,17,15); case 'H': return r(17,17,17,31,17,17,17);
            case 'I': return r(31,4,4,4,4,4,31); case 'J': return r(7,2,2,2,18,18,12);
            case 'K': return r(17,18,20,24,20,18,17); case 'L': return r(16,16,16,16,16,16,31);
            case 'M': return r(17,27,21,21,17,17,17); case 'N': return r(17,25,21,19,17,17,17);
            case 'O': return r(14,17,17,17,17,17,14); case 'P': return r(30,17,17,30,16,16,16);
            case 'Q': return r(14,17,17,17,21,18,13); case 'R': return r(30,17,17,30,20,18,17);
            case 'S': return r(15,16,16,14,1,1,30); case 'T': return r(31,4,4,4,4,4,4);
            case 'U': return r(17,17,17,17,17,17,14); case 'V': return r(17,17,17,17,17,10,4);
            case 'W': return r(17,17,17,21,21,21,10); case 'X': return r(17,17,10,4,10,17,17);
            case 'Y': return r(17,17,10,4,4,4,4); case 'Z': return r(31,1,2,4,8,16,31);
            case '0': return r(14,17,19,21,25,17,14); case '1': return r(4,12,4,4,4,4,14);
            case '2': return r(14,17,1,2,4,8,31); case '3': return r(30,1,1,14,1,1,30);
            case '4': return r(2,6,10,18,31,2,2); case '5': return r(31,16,16,30,1,1,30);
            case '6': return r(14,16,16,30,17,17,14); case '7': return r(31,1,2,4,8,8,8);
            case '8': return r(14,17,17,14,17,17,14); case '9': return r(14,17,17,15,1,1,14);
            case '-': return r(0,0,0,31,0,0,0); case '_': return r(0,0,0,0,0,0,31);
            case '.': return r(0,0,0,0,0,12,12); case ',': return r(0,0,0,0,0,12,8);
            case ':': return r(0,12,12,0,12,12,0); case ';': return r(0,12,12,0,12,8,16);
            case '/': return r(1,2,2,4,8,8,16); case '\\': return r(16,8,8,4,2,2,1);
            case '+': return r(0,4,4,31,4,4,0); case '=': return r(0,31,0,31,0,0,0);
            case '(': return r(2,4,8,8,8,4,2); case ')': return r(8,4,2,2,2,4,8);
            case '[': return r(14,8,8,8,8,8,14); case ']': return r(14,2,2,2,2,2,14);
            case '!': return r(4,4,4,4,4,0,4); case '?': return r(14,17,1,2,4,0,4);
            case '#': return r(10,31,10,10,31,10,0); case '%': return r(17,2,4,8,16,17,0);
            case '*': return r(0,21,14,31,14,21,0); case ' ': return 0L;
            default: return r(14,17,1,2,4,0,4);
        }
    }

    private static long r(int a,int b,int c,int d,int e,int f,int g)
    {
        return ((long)(a & 31) << 30) | ((long)(b & 31) << 25) |
               ((long)(c & 31) << 20) | ((long)(d & 31) << 15) |
               ((long)(e & 31) << 10) | ((long)(f & 31) << 5) |
               (long)(g & 31);
    }
}
