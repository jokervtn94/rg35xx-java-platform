package org.recompile.mobile;

import javax.microedition.lcdui.Font;

/**
 * RG35XX bitmap text producer.
 *
 * The fallback glyph seed is 5x7, but the output raster now follows the active
 * MIDP Font metrics instead of imposing a fixed 8x12 advance. This keeps the
 * pixels emitted by drawString() inside the same width/height contract used by
 * stringWidth(), charWidth(), anchors, clipping and TextBox/Form layout.
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

        /* PlatformGraphics.getColor() is RGB (0xRRGGBB) on this path while
         * drawRGB(..., processAlpha=true) expects ARGB. Keep glyphs opaque. */
        final int opaqueArgb = argb | 0xFF000000;
        final int[] pixels = new int[bitmapWidth * bitmapHeight];

        int penX = 0;
        for(int i = 0; i < text.length(); i++)
        {
            final char ch = text.charAt(i);
            int advance = font.charWidth(ch);
            if(advance < 1) advance = 1;

            /* stringWidth() is authoritative for the final raster width. Clamp
             * the last cell so rounding/peer differences cannot write outside
             * the MIDP-measured line box. */
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
        final int[] rows = glyph5x7(ch);

        /* Preserve one trailing pixel as inter-glyph whitespace whenever the
         * measured MIDP advance allows it. This avoids the boxed/underlined
         * artifacts seen with edge-to-edge glyph cells while still respecting
         * proportional font advances. */
        final int glyphWidth = cellWidth > 2 ? cellWidth - 1 : cellWidth;
        final int glyphHeight = height > 3 ? height - 3 : height;
        final int glyphY = height > glyphHeight ? (height - glyphHeight) / 2 : 0;
        if(glyphWidth <= 0 || glyphHeight <= 0) return;

        for(int dy = 0; dy < glyphHeight; dy++)
        {
            final int sy = (dy * 7) / glyphHeight;
            final int bits = rows[sy];
            final int row = (glyphY + dy) * width;

            for(int dx = 0; dx < glyphWidth; dx++)
            {
                final int sx = (dx * 5) / glyphWidth;
                if((bits & (1 << (4 - sx))) == 0) continue;
                final int px = x + dx;
                if(px < 0 || px >= width) continue;
                final int idx = row + px;
                if(idx >= 0 && idx < pixels.length) pixels[idx] = argb;
            }
        }
    }

    private static int[] glyph5x7(char c)
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
