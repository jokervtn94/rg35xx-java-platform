#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H

static const char *samples[] = {
    "ABCxyz09", "iiiiWWWW", "Tieng Viet",
    "Ti\xE1\xBA\xBFng Vi\xE1\xBB\x87t", "\xC4\x90\xE1\xBA\xB7ng", "\xE4\xB8\xAD\xE6\x96\x87"
};

static int utf8_next(const unsigned char **pp) {
    const unsigned char *p = *pp;
    unsigned int c;
    if (*p < 0x80) { c = *p++; }
    else if ((*p & 0xE0) == 0xC0 && p[1]) {
        c = ((p[0] & 0x1F) << 6) | (p[1] & 0x3F); p += 2;
    } else if ((*p & 0xF0) == 0xE0 && p[1] && p[2]) {
        c = ((p[0] & 0x0F) << 12) | ((p[1] & 0x3F) << 6) | (p[2] & 0x3F); p += 3;
    } else { c = 0xFFFD; p++; }
    *pp = p;
    return (int)c;
}

static int style_normalized(int style) {
    return (style >= 0 && style <= 3) ? style : 0;
}

static int load_glyph(FT_Face face, int cp, int style, int render) {
    FT_Int32 flags = FT_LOAD_DEFAULT;
    int rc = FT_Load_Char(face, (FT_ULong)cp, flags);
    if (rc) return rc;
    style = style_normalized(style);
    if (style & 1) FT_GlyphSlot_Embolden(face->glyph);
    if (style & 2) FT_GlyphSlot_Oblique(face->glyph);
    if (render) rc = FT_Render_Glyph(face->glyph, FT_RENDER_MODE_NORMAL);
    return rc;
}

static long string_width(FT_Face face, const char *s, int style) {
    const unsigned char *p = (const unsigned char *)s;
    long total = 0;
    while (*p) {
        int cp = utf8_next(&p);
        if (load_glyph(face, cp, style, 0) != 0) return -1;
        total += face->glyph->advance.x;
    }
    return (total + 32) >> 6;
}

static void display_mask(FT_Face face, const char *s, char *out, size_t out_cap) {
    const unsigned char *p = (const unsigned char *)s;
    size_t n = 0;
    int first = 1;
    if (out_cap) out[0] = 0;
    while (*p) {
        int cp = utf8_next(&p);
        int has = FT_Get_Char_Index(face, (FT_ULong)cp) != 0;
        if (!first && n + 1 < out_cap) out[n++] = ',';
        if (n + 1 < out_cap) out[n++] = has ? '1' : '0';
        first = 0;
    }
    if (n < out_cap) out[n] = 0;
}

static void raster_stats(FT_Face face, const char *s, int style,
                         long *ink_pixels, long *alpha_sum,
                         int *min_x, int *min_y, int *max_x, int *max_y) {
    const unsigned char *p = (const unsigned char *)s;
    int pen_x = 0;
    *ink_pixels = 0; *alpha_sum = 0;
    *min_x = 99999; *min_y = 99999; *max_x = -99999; *max_y = -99999;
    while (*p) {
        int cp = utf8_next(&p);
        if (load_glyph(face, cp, style, 1) != 0) continue;
        FT_GlyphSlot g = face->glyph;
        int gx = pen_x + g->bitmap_left;
        int gy = -g->bitmap_top;
        int row, col;
        for (row = 0; row < (int)g->bitmap.rows; row++) {
            for (col = 0; col < (int)g->bitmap.width; col++) {
                unsigned char a = g->bitmap.buffer[row * g->bitmap.pitch + col];
                if (a) {
                    int x = gx + col, y = gy + row;
                    (*ink_pixels)++;
                    *alpha_sum += a;
                    if (x < *min_x) *min_x = x;
                    if (x > *max_x) *max_x = x;
                    if (y < *min_y) *min_y = y;
                    if (y > *max_y) *max_y = y;
                }
            }
        }
        pen_x += (int)((g->advance.x + 32) >> 6);
    }
    if (*ink_pixels == 0) { *min_x = *min_y = *max_x = *max_y = -1; }
}

int main(int argc, char **argv) {
    FT_Library lib = NULL;
    FT_Face face = NULL;
    int sizes[] = {12,14,16};
    int style, zi, si;
    if (argc != 2) { fprintf(stderr, "usage: %s font.ttf\n", argv[0]); return 2; }
    if (FT_Init_FreeType(&lib)) return 3;
    if (FT_New_Face(lib, argv[1], 0, &face)) return 4;
    printf("P2B_FT_DIAGNOSTIC_BOOT=PASS\n");
    printf("P2B_FT_FAMILY=%s\n", face->family_name ? face->family_name : "NULL");
    printf("P2B_FT_STYLE_NAME=%s\n", face->style_name ? face->style_name : "NULL");
    printf("P2B_FT_NUM_GLYPHS=%ld\n", (long)face->num_glyphs);
    printf("P2B_FT_UNITS_PER_EM=%u\n", (unsigned)face->units_per_EM);
    for (style = 0; style <= 7; style++) {
        for (zi = 0; zi < 3; zi++) {
            int sz = sizes[zi];
            if (FT_Set_Pixel_Sizes(face, 0, (FT_UInt)sz)) return 5;
            printf("P2B_FT_STYLE=%d NORMALIZED=%d SIZE=%d HEIGHT=%ld ASCENT=%ld DESCENT=%ld\n",
                   style, style_normalized(style), sz,
                   (long)((face->size->metrics.height + 32) >> 6),
                   (long)((face->size->metrics.ascender + 32) >> 6),
                   (long)((-face->size->metrics.descender + 32) >> 6));
            for (si = 0; si < 6; si++) {
                char mask[128]; long ink, sum; int x0,y0,x1,y1;
                display_mask(face, samples[si], mask, sizeof(mask));
                raster_stats(face, samples[si], style, &ink, &sum, &x0,&y0,&x1,&y1);
                printf("P2B_FT_STYLE=%d SIZE=%d SAMPLE=%d WIDTH=%ld DISPLAY=%s INK=%ld ALPHA_SUM=%ld BOUNDS=%d,%d,%d,%d\n",
                       style, sz, si, string_width(face, samples[si], style), mask,
                       ink, sum, x0,y0,x1,y1);
            }
        }
    }
    FT_Done_Face(face); FT_Done_FreeType(lib);
    printf("P2B_FT_DIAGNOSTIC_RESULT=PASS\n");
    return 0;
}
