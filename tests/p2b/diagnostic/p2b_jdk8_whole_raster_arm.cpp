#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H
#include FT_MODULE_H
#include FT_TRUETYPE_TABLES_H

#include "LETypes.h"
#include "LEFontInstance.h"
#include "LayoutEngine.h"

#define FT_MATRIX_ONE 0x10000L
#define FT_MATRIX_OBLIQUE_XY 0x0366AL
#define CANVAS_W 512
#define CANVAS_H 192
#define ORIGIN_X 64
#define ORIGIN_Y 112

static const LETag TAG_GSUB = 0x47535542UL;
static const LETag TAG_GPOS = 0x47504F53UL;
static const LETag TAG_GDEF = 0x47444546UL;
static const LETag TAG_MORT = 0x6D6F7274UL;
static const LETag TAG_MORX = 0x6D6F7278UL;
static const LETag TAG_KERN = 0x6B65726EUL;
static const uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
static const uint64_t FNV_PRIME  = UINT64_C(0x100000001b3);

static int norm_style(int style) {
    return (style >= 0 && style <= 3) ? style : 0;
}

static int is_jdk_invisible_control(LEUnicode32 cp) {
    if (cp < 0x10) {
        return cp == 0x09 || cp == 0x0A || cp == 0x0D;
    }
    if (cp >= 0x200C) {
        if (cp <= 0x200F) return 1;
        if (cp >= 0x2028 && cp <= 0x202E) return 1;
        if (cp >= 0x206A && cp <= 0x206F) return 1;
    }
    return 0;
}

static std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> out;
    std::string item;
    std::stringstream ss(s);
    while (std::getline(ss, item, delim)) out.push_back(item);
    if (!s.empty() && s[s.size() - 1] == delim) out.push_back("");
    return out;
}

static int to_int(const std::string &s) {
    return (int)strtol(s.c_str(), NULL, 10);
}

struct RunRec {
    int start;
    int limit;
    int script;
    int flags;
};

static std::vector<LEUnicode> parse_utf16(const std::string &hex) {
    std::vector<LEUnicode> out;
    if ((hex.size() % 4) != 0) return out;
    for (size_t i = 0; i < hex.size(); i += 4) {
        out.push_back((LEUnicode)strtoul(hex.substr(i, 4).c_str(), NULL, 16));
    }
    return out;
}

static std::vector<RunRec> parse_runs(const std::string &s) {
    std::vector<RunRec> out;
    if (s == "-" || s.empty()) return out;
    std::vector<std::string> chunks = split(s, '|');
    for (size_t i = 0; i < chunks.size(); i++) {
        std::vector<std::string> f = split(chunks[i], ':');
        if (f.size() != 4) continue;
        RunRec r;
        r.start = to_int(f[0]);
        r.limit = to_int(f[1]);
        r.script = to_int(f[2]);
        r.flags = to_int(f[3]);
        out.push_back(r);
    }
    return out;
}

static uint64_t mix32(uint64_t h, int v) {
    uint32_t u = (uint32_t)v;
    h ^= (u >> 24) & 255; h *= FNV_PRIME;
    h ^= (u >> 16) & 255; h *= FNV_PRIME;
    h ^= (u >> 8) & 255; h *= FNV_PRIME;
    h ^= u & 255; h *= FNV_PRIME;
    return h;
}

class ProbeFontInstance : public LEFontInstance {
private:
    struct TableSlot {
        LETag tag;
        mutable unsigned char *data;
        mutable size_t len;
        mutable int loaded;
    };

    FT_Library lib;
    FT_Face face;
    int style;
    int size;
    float xppem;
    float yppem;
    float unitsToPointsX;
    float unitsToPointsY;
    float pixelsToUnitsX;
    float pixelsToUnitsY;
    mutable void *kernPairs;
    mutable TableSlot tables[6];

    int setInterpreter35() {
        int version = 35;
        return FT_Property_Set(lib, "truetype", "interpreter-version", &version);
    }

    FT_UInt rawGlyph(LEUnicode32 ch) const {
        if (ch == 0xFFFE || ch == 0xFFFF) return 0;
        if (is_jdk_invisible_control(ch)) return 0xFFFF;
        return FT_Get_Char_Index(face, (FT_ULong)ch);
    }

    int loadMetricGlyph(FT_UInt glyph) const {
        FT_Int32 flags = FT_LOAD_DEFAULT | FT_LOAD_TARGET_MONO;
        if (style != 0) flags |= FT_LOAD_NO_BITMAP;
        int rc = FT_Load_Glyph(face, glyph, flags);
        if (rc) return rc;
        if (style & 1) FT_GlyphSlot_Embolden(face->glyph);
        return 0;
    }

public:
    ProbeFontInstance(const char *fontPath) : lib(0), face(0), style(0), size(12),
        xppem(12), yppem(12), unitsToPointsX(0), unitsToPointsY(0),
        pixelsToUnitsX(0), pixelsToUnitsY(0), kernPairs(NULL) {
        tables[0].tag = TAG_GPOS;
        tables[1].tag = TAG_GDEF;
        tables[2].tag = TAG_GSUB;
        tables[3].tag = TAG_MORT;
        tables[4].tag = TAG_MORX;
        tables[5].tag = TAG_KERN;
        for (int i = 0; i < 6; i++) {
            tables[i].data = NULL;
            tables[i].len = 0;
            tables[i].loaded = 0;
        }
        if (FT_Init_FreeType(&lib)) exit(20);
        if (setInterpreter35()) exit(21);
        if (FT_New_Face(lib, fontPath, 0, &face)) exit(22);
        setCase(12, 0);
    }

    virtual ~ProbeFontInstance() {
        for (int i = 0; i < 6; i++) free(tables[i].data);
        if (face) FT_Done_Face(face);
        if (lib) FT_Done_FreeType(lib);
    }

    void setCase(int pointSize, int incomingStyle) {
        size = pointSize;
        style = norm_style(incomingStyle);
        FT_Matrix matrix;
        matrix.xx = FT_MATRIX_ONE;
        matrix.xy = (style & 2) ? FT_MATRIX_OBLIQUE_XY : 0;
        matrix.yx = 0;
        matrix.yy = FT_MATRIX_ONE;
        FT_Set_Transform(face, &matrix, NULL);
        if (FT_Set_Char_Size(face, 0, (FT_F26Dot6)(size * 64), 72, 72)) exit(23);
        xppem = (float)size;
        yppem = (float)size;
        unitsToPointsX = (float)size / (float)face->units_per_EM;
        unitsToPointsY = (float)size / (float)face->units_per_EM;
        pixelsToUnitsX = (float)face->units_per_EM / xppem;
        pixelsToUnitsY = (float)face->units_per_EM / yppem;
    }

    FT_UInt glyphForChar(LEUnicode32 ch) const {
        return rawGlyph(ch);
    }

    int loadRasterGlyph(FT_UInt glyph) {
        if (glyph == 0xFFFFU || glyph == 0xFFFEU) return 1;
        if (loadMetricGlyph(glyph) != 0) return 2;
        if (face->glyph->format == FT_GLYPH_FORMAT_OUTLINE) {
            if (FT_Render_Glyph(face->glyph, FT_RENDER_MODE_MONO) != 0) return 3;
        }
        return 0;
    }

    FT_GlyphSlot rasterSlot() const { return face->glyph; }

    virtual const LEFontInstance *getSubFont(const LEUnicode chars[],
        le_int32 *offset, le_int32 limit, le_int32 script,
        LEErrorCode &success) const {
        if (LE_FAILURE(success)) return NULL;
        *offset = limit;
        return this;
    }

    virtual const void *getFontTable(LETag tableTag) const {
        size_t ignored = 0;
        return getFontTable(tableTag, ignored);
    }

    virtual const void *getFontTable(LETag tableTag, size_t &length) const {
        length = 0;
        for (int i = 0; i < 6; i++) {
            if (tables[i].tag != tableTag) continue;
            if (!tables[i].loaded) {
                FT_ULong len = 0;
                tables[i].loaded = 1;
                if (FT_Load_Sfnt_Table(face, (FT_ULong)tableTag, 0, NULL, &len) != 0 || len == 0) {
                    tables[i].len = 0;
                    tables[i].data = NULL;
                } else {
                    tables[i].data = (unsigned char *)malloc((size_t)len);
                    if (tables[i].data == NULL) return NULL;
                    FT_ULong got = len;
                    if (FT_Load_Sfnt_Table(face, (FT_ULong)tableTag, 0,
                                           (FT_Byte *)tables[i].data, &got) != 0) {
                        free(tables[i].data);
                        tables[i].data = NULL;
                        tables[i].len = 0;
                    } else {
                        tables[i].len = (size_t)got;
                    }
                }
            }
            length = tables[i].len;
            return tables[i].data;
        }
        return NULL;
    }

    virtual void *getKernPairs() const { return kernPairs; }
    virtual void setKernPairs(void *pairs) const { kernPairs = pairs; }

    virtual le_bool canDisplay(LEUnicode32 ch) const {
        if (is_jdk_invisible_control(ch)) return TRUE;
        if (ch == 0xFFFE || ch == 0xFFFF) return FALSE;
        return FT_Get_Char_Index(face, (FT_ULong)ch) != 0 ? TRUE : FALSE;
    }

    virtual le_int32 getUnitsPerEM() const { return (le_int32)face->units_per_EM; }

    virtual LEGlyphID mapCharToGlyph(LEUnicode32 ch, const LECharMapper *mapper) const {
        LEUnicode32 mapped = mapper->mapChar(ch);
        if (mapped == 0xFFFF || mapped == 0xFFFE) return 0xFFFF;
        if (mapped == 0x200C || mapped == 0x200D) return 1;
        return mapCharToGlyph(mapped);
    }

    virtual LEGlyphID mapCharToGlyph(LEUnicode32 ch) const {
        return (LEGlyphID)rawGlyph(ch);
    }

    virtual void getGlyphAdvance(LEGlyphID glyph, LEPoint &advance) const {
        le_uint32 g = (le_uint32)glyph;
        if ((g & 0xFFFEU) == 0xFFFEU) {
            advance.fX = 0; advance.fY = 0; return;
        }
        if (loadMetricGlyph((FT_UInt)(g & 0xFFFFU)) != 0) {
            advance.fX = 0; advance.fY = 0; return;
        }
        if (face->glyph->advance.y == 0) {
            advance.fX = (float)(face->glyph->advance.x >> 6);
            advance.fY = 0;
        } else if (face->glyph->advance.x == 0) {
            advance.fX = 0;
            advance.fY = (float)((-face->glyph->advance.y) >> 6);
        } else {
            advance.fX = ((float)face->glyph->advance.x) / 64.0f;
            advance.fY = ((float)-face->glyph->advance.y) / 64.0f;
        }
    }

    virtual void getKerningAdjustment(LEPoint &adjustment) const { (void)adjustment; }

    virtual le_bool getGlyphPoint(LEGlyphID glyph, le_int32 pointNumber, LEPoint &point) const {
        le_uint32 g = (le_uint32)glyph;
        point.fX = 0; point.fY = 0;
        if ((g & 0xFFFEU) == 0xFFFEU) return TRUE;
        FT_Int32 flags = FT_LOAD_NO_HINTING | FT_LOAD_NO_BITMAP;
        if (FT_Load_Glyph(face, (FT_UInt)(g & 0xFFFFU), flags) == 0) {
            if (style & 1) FT_GlyphSlot_Embolden(face->glyph);
            if (face->glyph->format == FT_GLYPH_FORMAT_OUTLINE &&
                pointNumber >= 0 && pointNumber < face->glyph->outline.n_points) {
                point.fX = ((float)face->glyph->outline.points[pointNumber].x) / 64.0f;
                point.fY = ((float)face->glyph->outline.points[pointNumber].y) / 64.0f;
            }
        }
        return TRUE;
    }

    virtual float getXPixelsPerEm() const { return xppem; }
    virtual float getYPixelsPerEm() const { return yppem; }
    virtual float xUnitsToPoints(float xUnits) const { return xUnits * unitsToPointsX; }
    virtual float yUnitsToPoints(float yUnits) const { return yUnits * unitsToPointsY; }
    virtual void unitsToPoints(LEPoint &units, LEPoint &points) const {
        points.fX = xUnitsToPoints(units.fX); points.fY = yUnitsToPoints(units.fY);
    }
    virtual float xPixelsToUnits(float xPixels) const { return xPixels * pixelsToUnitsX; }
    virtual float yPixelsToUnits(float yPixels) const { return yPixels * pixelsToUnitsY; }
    virtual void pixelsToUnits(LEPoint &pixels, LEPoint &units) const {
        units.fX = xPixelsToUnits(pixels.fX); units.fY = yPixelsToUnits(pixels.fY);
    }
    virtual float getScaleFactorX() const { return pixelsToUnitsX; }
    virtual float getScaleFactorY() const { return pixelsToUnitsY; }
    virtual void transformFunits(float xFunits, float yFunits, LEPoint &pixels) const {
        pixels.fX = xFunits * unitsToPointsX; pixels.fY = yFunits * unitsToPointsY;
    }
    virtual le_int32 getAscent() const { return 0; }
    virtual le_int32 getDescent() const { return 0; }
    virtual le_int32 getLeading() const { return 0; }
};

static int occupied(const FT_Bitmap *b, int row, int col) {
    const unsigned char *base;
    int pitch = b->pitch;
    if (pitch >= 0) base = b->buffer + row * pitch;
    else base = b->buffer + (b->rows - 1 - row) * (-pitch);
    if (b->pixel_mode == FT_PIXEL_MODE_MONO) return (base[col >> 3] & (0x80 >> (col & 7))) != 0;
    if (b->pixel_mode == FT_PIXEL_MODE_GRAY) return base[col] != 0;
    return 0;
}

static void paint_slot(unsigned char *canvas, FT_GlyphSlot g, float px, float py) {
    int gx = (int)floor(px + 0.5f + (float)g->bitmap_left);
    int gy = (int)floor(py + 0.5f - (float)g->bitmap_top);
    for (int row = 0; row < (int)g->bitmap.rows; row++) {
        for (int col = 0; col < (int)g->bitmap.width; col++) {
            if (!occupied(&g->bitmap, row, col)) continue;
            int x = ORIGIN_X + gx + col;
            int y = ORIGIN_Y + gy + row;
            if (x >= 0 && x < CANVAS_W && y >= 0 && y < CANVAS_H) canvas[y * CANVAS_W + x] = 1;
        }
    }
}

static void fingerprint(const unsigned char *canvas, int *ink, int *x0, int *y0,
                        int *x1, int *y1, uint64_t *fp) {
    *ink = 0; *x0 = *y0 = 99999; *x1 = *y1 = -99999; *fp = FNV_OFFSET;
    for (int y = 0; y < CANVAS_H; y++) {
        for (int x = 0; x < CANVAS_W; x++) {
            if (!canvas[y * CANVAS_W + x]) continue;
            int rx = x - ORIGIN_X, ry = y - ORIGIN_Y;
            (*ink)++;
            if (rx < *x0) *x0 = rx; if (rx > *x1) *x1 = rx;
            if (ry < *y0) *y0 = ry; if (ry > *y1) *y1 = ry;
            *fp = mix32(*fp, rx); *fp = mix32(*fp, ry);
        }
    }
    if (*ink == 0) *x0 = *y0 = *x1 = *y1 = -1;
}

static int render_direct(ProbeFontInstance &font, const std::vector<LEUnicode> &chars,
                         unsigned char *canvas) {
    int pen = 0;
    for (size_t i = 0; i < chars.size(); i++) {
        FT_UInt glyph = font.glyphForChar((LEUnicode32)chars[i]);
        if (glyph == 0xFFFFU || glyph == 0xFFFEU) continue;
        if (font.loadRasterGlyph(glyph) != 0) return -1000;
        FT_GlyphSlot g = font.rasterSlot();
        paint_slot(canvas, g, (float)pen, 0.0f);
        if (g->advance.y == 0) pen += (int)(g->advance.x >> 6);
        else pen += (int)(g->advance.x / 64);
    }
    return pen;
}

static int render_complex(ProbeFontInstance &font, const std::vector<LEUnicode> &chars,
                          const std::vector<RunRec> &runs, int layoutFlags,
                          unsigned char *canvas) {
    if (runs.empty()) return 30;
    const le_bool rtl = (layoutFlags & 1) ? TRUE : FALSE;
    std::vector<le_uint32> allGlyphs;
    std::vector<float> allPos;
    float currentX = 0.0f, currentY = 0.0f;

    int ri = rtl ? (int)runs.size() - 1 : 0;
    int stop = rtl ? -1 : (int)runs.size();
    int step = rtl ? -1 : 1;
    for (; ri != stop; ri += step) {
        const RunRec &r = runs[(size_t)ri];
        if (r.start < 0 || r.limit <= r.start || r.limit > (int)chars.size()) return 31;
        LEErrorCode success = LE_NO_ERROR;
        LayoutEngine *engine = LayoutEngine::layoutEngineFactory(&font, r.script, -1, r.flags & 0x7, success);
        if (engine == NULL || LE_FAILURE(success)) return 32;
        le_int32 gc = engine->layoutChars(&chars[0], r.start, r.limit - r.start,
            (le_int32)chars.size(), rtl, currentX, currentY, success);
        if (gc < 0 || LE_FAILURE(success)) { delete engine; return 33; }
        std::vector<le_uint32> glyphs((size_t)gc);
        std::vector<float> pos((size_t)(gc + 1) * 2U);
        if (gc > 0) engine->getGlyphs(&glyphs[0], 0, success);
        engine->getGlyphPositions(&pos[0], success);
        if (LE_FAILURE(success)) { delete engine; return 34; }
        for (le_int32 i = 0; i < gc; i++) {
            allGlyphs.push_back(glyphs[(size_t)i]);
            allPos.push_back(pos[(size_t)i * 2U]);
            allPos.push_back(pos[(size_t)i * 2U + 1U]);
        }
        currentX = pos[(size_t)gc * 2U];
        currentY = pos[(size_t)gc * 2U + 1U];
        delete engine;
    }

    for (size_t i = 0; i < allGlyphs.size(); i++) {
        le_uint32 gid = allGlyphs[i];
        if ((gid & 0xFFFEU) == 0xFFFEU) continue;
        if (font.loadRasterGlyph((FT_UInt)(gid & 0xFFFFU)) != 0) return 35;
        paint_slot(canvas, font.rasterSlot(), allPos[i * 2U], allPos[i * 2U + 1U]);
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s font.ttf reference.tsv arm.tsv\n", argv[0]);
        return 2;
    }
    ProbeFontInstance font(argv[1]);
    std::ifstream in(argv[2]);
    std::ofstream out(argv[3]);
    if (!in || !out) return 3;
    std::string line;
    if (!std::getline(in, line)) return 4;
    out << "CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tDRAW_COMPLEX\tUTF16HEX\tWIDTH_DERIVED\tINK\tX0\tY0\tX1\tY1\tFP\tLAYOUT_FLAGS\tRUNS\n";

    int cases = 0, directCases = 0, complexCases = 0, rtlCases = 0;
    while (std::getline(in, line)) {
        if (line.empty()) continue;
        std::vector<std::string> c = split(line, '\t');
        if (c.size() != 16) {
            fprintf(stderr, "P2B_WHOLE_RASTER_ARM_PARSE_FAIL=columns:%u\n", (unsigned)c.size());
            return 5;
        }
        int incomingStyle = to_int(c[1]);
        int normalized = to_int(c[2]);
        int pointSize = to_int(c[3]);
        int complex = to_int(c[5]);
        int layoutFlags = to_int(c[14]);
        std::vector<LEUnicode> chars = parse_utf16(c[6]);
        std::vector<RunRec> runs = parse_runs(c[15]);
        if (chars.empty()) return 6;
        if (norm_style(incomingStyle) != normalized) return 7;
        if (complex && runs.empty()) return 8;
        if (!complex && !runs.empty()) return 9;

        font.setCase(pointSize, incomingStyle);
        unsigned char canvas[CANVAS_W * CANVAS_H];
        memset(canvas, 0, sizeof(canvas));
        int widthDerived = -1;
        if (!complex) {
            widthDerived = render_direct(font, chars, canvas);
            if (widthDerived < 0) return 10;
            directCases++;
        } else {
            int rc = render_complex(font, chars, runs, layoutFlags, canvas);
            if (rc != 0) { fprintf(stderr, "P2B_WHOLE_RASTER_ARM_COMPLEX_FAIL=%d CASE=%s\n", rc, c[0].c_str()); return 11; }
            complexCases++;
            if (layoutFlags & 1) rtlCases++;
        }

        int ink, x0, y0, x1, y1; uint64_t fp;
        fingerprint(canvas, &ink, &x0, &y0, &x1, &y1, &fp);
        char fphex[32];
        snprintf(fphex, sizeof(fphex), "%llx", (unsigned long long)fp);
        out << c[0] << '\t' << c[1] << '\t' << c[2] << '\t' << c[3] << '\t'
            << c[4] << '\t' << c[5] << '\t' << c[6] << '\t' << widthDerived << '\t'
            << ink << '\t' << x0 << '\t' << y0 << '\t' << x1 << '\t' << y1 << '\t'
            << fphex << '\t' << c[14] << '\t' << c[15] << "\n";
        cases++;
    }
    out.close();
    printf("P2B_ARM_WHOLE_RASTER_BOOT=PASS\n");
    printf("P2B_ARM_WHOLE_RASTER_CASES=%d\n", cases);
    printf("P2B_ARM_WHOLE_RASTER_DIRECT_CASES=%d\n", directCases);
    printf("P2B_ARM_WHOLE_RASTER_COMPLEX_CASES=%d\n", complexCases);
    printf("P2B_ARM_WHOLE_RASTER_RTL_CASES=%d\n", rtlCases);
    printf("P2B_ARM_WHOLE_RASTER_RESULT=PASS\n");
    printf("P2B_RUNTIME_PATCH=FORBIDDEN\n");
    return 0;
}
