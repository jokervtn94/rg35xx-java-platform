package org.recompile.mobile;

import javax.microedition.lcdui.Font;

/**
 * RG35XX framebuffer text fallback.
 *
 * This deliberately avoids java.awt.Graphics2D glyph rasterization.  The target
 * JamVM/GNU Classpath headless stack can provide Font metrics, but its Java2D
 * drawGlyphVector scanline path is not reliable on the handheld.  Metrics stay
 * owned by MIDP Font; only glyph pixels are rendered here.
 */
public final class RG35XXBitmapText
{
    private RG35XXBitmapText() {}

    public static void draw(int[] dst, int width, int height,
        String text, int x, int baseline, int ascent, int fontHeight,
        Font font, int argb, int clipLeft, int clipTop, int clipRight, int clipBottom)
    {
        if(dst == null || text == null || text.length() == 0) return;

        int sy = Math.max(1, fontHeight / 7);
        int top = baseline - ascent;
        int penX = x;

        for(int i = 0; i < text.length(); i++)
        {
            char ch = text.charAt(i);
            int advance = 0;
            try { advance = font == null ? 0 : font.charWidth(ch); }
            catch(Throwable ignored) { advance = 0; }
            if(advance <= 0) advance = Math.max(6, fontHeight / 2);

            int sx = Math.max(1, (advance - 1) / 5);
            int glyphWidth = 5 * sx;
            int drawX = penX + Math.max(0, (advance - glyphWidth) / 2);
            drawGlyph(dst, width, height, ch, drawX, top, sx, sy, argb,
                clipLeft, clipTop, clipRight, clipBottom);
            penX += advance;
        }
    }

    private static void drawGlyph(int[] dst, int width, int height, char ch,
        int x, int y, int sx, int sy, int argb,
        int clipLeft, int clipTop, int clipRight, int clipBottom)
    {
        int[] rows = glyph(ch);
        for(int gy = 0; gy < 7; gy++)
        {
            int bits = rows[gy];
            for(int gx = 0; gx < 5; gx++)
            {
                if((bits & (1 << (4 - gx))) == 0) continue;
                int px0 = x + gx * sx;
                int py0 = y + gy * sy;
                for(int yy = 0; yy < sy; yy++)
                {
                    int py = py0 + yy;
                    if(py < 0 || py >= height || py < clipTop || py >= clipBottom) continue;
                    int row = py * width;
                    for(int xx = 0; xx < sx; xx++)
                    {
                        int px = px0 + xx;
                        if(px < 0 || px >= width || px < clipLeft || px >= clipRight) continue;
                        int idx = row + px;
                        dst[idx] = blend(argb, dst[idx]);
                    }
                }
            }
        }
    }

    private static int blend(int src, int dst)
    {
        int a = src >>> 24;
        if(a == 255) return src;
        if(a == 0) return dst;
        int ia = 255 - a;
        int r = (((src >> 16) & 255) * a + ((dst >> 16) & 255) * ia) / 255;
        int g = (((src >> 8) & 255) * a + ((dst >> 8) & 255) * ia) / 255;
        int b = ((src & 255) * a + (dst & 255) * ia) / 255;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    private static int[] glyph(char c)
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
            case '*': return r(0,21,14,31,14,21,0); case ' ': return r(0,0,0,0,0,0,0);
            default: return r(14,17,1,2,4,0,4);
        }
    }

    private static int[] r(int a,int b,int c,int d,int e,int f,int g)
    { return new int[]{a,b,c,d,e,f,g}; }
}
