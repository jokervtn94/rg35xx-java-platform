#include <stdio.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_MODULE_H

/*
 * Audit-only reproduction of the OpenJDK8u504 FreetypeFontScaler font-metric
 * calculation plus FontDesignMetrics integer rounding for the P2B identity
 * transform / 72 dpi context. This is not production runtime code.
 */

static int norm_style(int style) {
    return (style >= 0 && style <= 3) ? style : 0;
}

static float mul_fix_float_shift6(FT_Pos a, FT_Fixed b) {
    return ((float)a) * ((float)b) / 65536.0f / 64.0f;
}

static int set_interpreter_35(FT_Library lib) {
    int version = 35;
    return FT_Property_Set(lib, "truetype", "interpreter-version", &version);
}

static void emit_case(FT_Face face, int incoming_style, int size) {
    const float rounding = 0.95f;
    int normalized = norm_style(incoming_style);
    float ay, dy, ly;
    float ascent, descent, leading;
    int iascent, idescent, ileading, iheight;

    /* Font metrics use the scaler size and original strike transform. The
     * algorithmic bold/italic glyph styling does not alter these vertical
     * metrics in FreetypeFontScaler.getFontMetricsNative(). */
    if (FT_Set_Char_Size(face, 0, (FT_F26Dot6)(size * 64), 72, 72) != 0) {
        fprintf(stderr, "P2B_FT_FONT_METRICS_FAIL=FT_Set_Char_Size\n");
        exit(10);
    }

    ay = -mul_fix_float_shift6(face->ascender, face->size->metrics.y_scale);
    dy = -mul_fix_float_shift6(face->descender, face->size->metrics.y_scale);
    ly = mul_fix_float_shift6(face->height, face->size->metrics.y_scale) + ay - dy;

    /* StrikeMetrics: getAscent() = -ascentY, getDescent() = descentY,
     * getLeading() = leadingY for the identity context. */
    ascent = -ay;
    descent = dy;
    leading = ly;

    /* Exact FontDesignMetrics public integer contract. */
    iascent = (int)(rounding + ascent);
    idescent = (int)(rounding + descent);
    ileading = (int)(rounding + descent + leading) -
               (int)(rounding + descent);
    iheight = iascent + (int)(rounding + descent + leading);

    printf("P2B_FT_JDK8_FONT_METRIC STYLE=%d NORMALIZED=%d SIZE=%d HEIGHT=%d ASCENT=%d DESCENT=%d LEADING=%d\n",
           incoming_style, normalized, size, iheight, iascent, idescent, ileading);
}

int main(int argc, char **argv) {
    FT_Library lib = 0;
    FT_Face face = 0;
    int sizes[] = {12, 14, 16};
    int major = 0, minor = 0, patch = 0;
    int style, zi, cases = 0;

    if (argc != 2) {
        fprintf(stderr, "usage: %s font.ttf\n", argv[0]);
        return 2;
    }
    if (FT_Init_FreeType(&lib) != 0) return 3;
    if (set_interpreter_35(lib) != 0) return 4;
    if (FT_New_Face(lib, argv[1], 0, &face) != 0) return 5;

    FT_Library_Version(lib, &major, &minor, &patch);
    printf("P2B_FT_JDK8_FONT_METRICS_BOOT=PASS\n");
    printf("P2B_FT_LIBRARY_VERSION=%d.%d.%d\n", major, minor, patch);
    printf("P2B_FT_JDK8_FONT_METRICS_DPI=72\n");
    printf("P2B_FT_JDK8_FONT_METRICS_ROUNDING=0.95\n");

    for (style = 0; style <= 7; style++) {
        for (zi = 0; zi < 3; zi++) {
            emit_case(face, style, sizes[zi]);
            cases++;
        }
    }

    printf("P2B_FT_JDK8_FONT_METRICS_CASES=%d\n", cases);
    printf("P2B_FT_JDK8_FONT_METRICS_RESULT=PASS\n");
    printf("P2B_RUNTIME_PATCH=FORBIDDEN\n");

    FT_Done_Face(face);
    FT_Done_FreeType(lib);
    return 0;
}
