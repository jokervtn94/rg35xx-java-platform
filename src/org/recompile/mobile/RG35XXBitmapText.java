package org.recompile.mobile;

/**
 * RG35XX fixed-cell bitmap text producer.
 *
 * Compatible reconstruction of the historical 8x12 raster path. The exact
 * old glyph resource has not been recovered. This class never touches the
 * PlatformGraphics framebuffer directly: it only builds an isolated ARGB
 * bitmap which PlatformGraphics composites through its proven drawRGB path.
 */
public final class RG35XXBitmapText
{
    public static final int CELL_WIDTH = 8;
    public static final int CELL_HEIGHT = 12;

    /* Keep the MIDP-facing 8x12 advance/height contract, but do not stretch
     * the 5x7 seed over the whole cell. Reserving side/bottom whitespace is
     * important on the RG35XX 240px display: when edge pixels from adjacent
     * cells touch, glyphs turn into the long boxed/underlined shapes seen in
     * device screenshots even though the framebuffer itself is correct. */
    private static final int GLYPH_WIDTH = 6;
    private static final int GLYPH_HEIGHT = 9;
    private static final int GLYPH_X = 1;
    private static final int GLYPH_Y = 1;

    private RG35XXBitmapText() {}

    public static int width(String text)
    {
        if(text == null || text.length() == 0) return 0;
        if(text.length() > Integer.MAX_VALUE / CELL_WIDTH) return 0;
        return text.length() * CELL_WIDTH;
    }

    public static int[] render(String text, int argb)
    {
        final int bitmapWidth = width(text);
        if(bitmapWidth <= 0) return new int[0];
        if(bitmapWidth > Integer.MAX_VALUE / CELL_HEIGHT) return new int[0];

        final int[] pixels = new int[bitmapWidth * CELL_HEIGHT];
        for(int i = 0; i < text.length(); i++)
        {
            drawGlyph8x12(pixels, bitmapWidth, text.charAt(i), i * CELL_WIDTH, argb);
        }
        return pixels;
    }

    private static void drawGlyph8x12(int[] pixels, int width, char ch, int x, int argb)
    {
        final int[] rows = glyph5x7(ch);

        /* Modest nearest-neighbour expansion inside the fixed 8x12 cell.
         * The advance remains 8 pixels, so existing PlatformFont metrics and
         * MIDP layout stay deterministic, while a one-pixel side bearing
         * prevents neighboring glyphs from merging visually. */
        for(int dy = 0; dy < GLYPH_HEIGHT; dy++)
        {
            final int sy = (dy * 7) / GLYPH_HEIGHT;
            final int bits = rows[sy];
            final int row = (GLYPH_Y + dy) * width;

            for(int dx = 0; dx < GLYPH_WIDTH; dx++)
            {
                final int sx = (dx * 5) / GLYPH_WIDTH;
                if((bits & (1 << (4 - sx))) == 0) continue;
                final int idx = row + x + GLYPH_X + dx;
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
