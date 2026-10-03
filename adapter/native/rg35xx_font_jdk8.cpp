#include <jni.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <vector>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H
#include FT_MODULE_H
#include FT_TRUETYPE_TABLES_H

#include "LETypes.h"
#include "LEFontInstance.h"
#include "LayoutEngine.h"
#include "p2b_script_data.inc"

#define FT_MATRIX_ONE 0x10000L
#define FT_MATRIX_OBLIQUE_XY 0x0366AL

static const LETag TAG_GSUB = 0x47535542UL;
static const LETag TAG_GPOS = 0x47504F53UL;
static const LETag TAG_GDEF = 0x47444546UL;
static const LETag TAG_MORT = 0x6D6F7274UL;
static const LETag TAG_MORX = 0x6D6F7278UL;
static const LETag TAG_KERN = 0x6B65726EUL;

static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

static int norm_style(int style) { return (style >= 0 && style <= 3) ? style : 0; }

static int is_jdk_invisible_control(uint32_t cp) {
    if (cp < 0x10) return cp == 0x09 || cp == 0x0A || cp == 0x0D;
    if (cp >= 0x200C) {
        if (cp <= 0x200F) return 1;
        if (cp >= 0x2028 && cp <= 0x202E) return 1;
        if (cp >= 0x206A && cp <= 0x206F) return 1;
    }
    return 0;
}

static int is_non_simple_char(uint16_t ch) {
    if (ch >= 0xD800 && ch < 0xE000) return 1;
    int code = (int)ch;
    if (code < 0x0300 || code > 0x206F) return 0;
    if (code <= 0x036F) return 1;
    if (code < 0x0590) return 0;
    if (code <= 0x06FF) return 1;
    if (code < 0x0900) return 0;
    if (code <= 0x0E7F) return 1;
    if (code < 0x0F00) return 0;
    if (code <= 0x0FFF) return 1;
    if (code < 0x1100) return 0;
    if (code < 0x11FF) return 1;
    if (code < 0x1780) return 0;
    if (code <= 0x17FF) return 1;
    if (code < 0x200C) return 0;
    if (code <= 0x200D) return 1;
    if (code >= 0x202A && code <= 0x202E) return 1;
    if (code >= 0x206A && code <= 0x206F) return 1;
    return 0;
}

class JdkFontInstance : public LEFontInstance {
private:
    struct TableSlot { LETag tag; mutable unsigned char *data; mutable size_t len; mutable int loaded; };
    FT_Library lib;
    FT_Face face;
    int style;
    int size;
    float xppem, yppem, unitsToPointsX, unitsToPointsY, pixelsToUnitsX, pixelsToUnitsY;
    mutable void *kernPairs;
    mutable TableSlot tables[6];

    int setInterpreter35() {
        int version = 35;
        return FT_Property_Set(lib, "truetype", "interpreter-version", &version);
    }

public:
    JdkFontInstance() : lib(0), face(0), style(0), size(12), xppem(12), yppem(12),
        unitsToPointsX(0), unitsToPointsY(0), pixelsToUnitsX(0), pixelsToUnitsY(0), kernPairs(NULL) {
        tables[0].tag=TAG_GPOS; tables[1].tag=TAG_GDEF; tables[2].tag=TAG_GSUB;
        tables[3].tag=TAG_MORT; tables[4].tag=TAG_MORX; tables[5].tag=TAG_KERN;
        for (int i=0;i<6;i++){ tables[i].data=NULL; tables[i].len=0; tables[i].loaded=0; }
    }

    virtual ~JdkFontInstance() { shutdown(); }

    int init(const char *path) {
        shutdown();
        if (FT_Init_FreeType(&lib)) return 0;
        if (setInterpreter35()) { shutdown(); return 0; }
        if (FT_New_Face(lib, path, 0, &face)) { shutdown(); return 0; }
        return setCase(12,0);
    }

    void shutdown() {
        for (int i=0;i<6;i++) { free(tables[i].data); tables[i].data=NULL; tables[i].len=0; tables[i].loaded=0; }
        if (face) { FT_Done_Face(face); face=0; }
        if (lib) { FT_Done_FreeType(lib); lib=0; }
        kernPairs=NULL;
    }

    int ready() const { return face != 0; }
    FT_Face ftFace() const { return face; }

    int setCase(int pointSize, int incomingStyle) {
        if (!face) return 0;
        size=pointSize; style=norm_style(incomingStyle);
        FT_Matrix matrix;
        matrix.xx=FT_MATRIX_ONE; matrix.xy=(style&2)?FT_MATRIX_OBLIQUE_XY:0; matrix.yx=0; matrix.yy=FT_MATRIX_ONE;
        FT_Set_Transform(face,&matrix,NULL);
        if (FT_Set_Char_Size(face,0,(FT_F26Dot6)(size*64),72,72)) return 0;
        xppem=(float)size; yppem=(float)size;
        unitsToPointsX=(float)size/(float)face->units_per_EM;
        unitsToPointsY=(float)size/(float)face->units_per_EM;
        pixelsToUnitsX=(float)face->units_per_EM/xppem;
        pixelsToUnitsY=(float)face->units_per_EM/yppem;
        return 1;
    }

    FT_UInt rawGlyph(LEUnicode32 ch) const {
        if (ch==0xFFFE || ch==0xFFFF) return 0;
        if (is_jdk_invisible_control((uint32_t)ch)) return 0xFFFF;
        return FT_Get_Char_Index(face,(FT_ULong)ch);
    }

    int loadMetricGlyph(FT_UInt glyph) const {
        FT_Int32 flags=FT_LOAD_DEFAULT|FT_LOAD_TARGET_MONO;
        if (style!=0) flags|=FT_LOAD_NO_BITMAP;
        int rc=FT_Load_Glyph(face,glyph,flags);
        if (rc) return rc;
        if (style&1) FT_GlyphSlot_Embolden(face->glyph);
        return 0;
    }

    int loadRenderGlyph(FT_UInt glyph) const {
        if (loadMetricGlyph(glyph)) return 0;
        if (FT_Render_Glyph(face->glyph,FT_RENDER_MODE_MONO)) return 0;
        return 1;
    }

    int advanceForChar(uint32_t ch) const {
        if (is_jdk_invisible_control(ch)) return 0;
        FT_UInt g=(ch==0xFFFE || ch==0xFFFF)?0:FT_Get_Char_Index(face,(FT_ULong)ch);
        if (loadMetricGlyph(g)) return 0;
        return (int)(face->glyph->advance.x >> 6);
    }

    virtual const LEFontInstance *getSubFont(const LEUnicode chars[], le_int32 *offset,
        le_int32 limit, le_int32 script, LEErrorCode &success) const {
        if (LE_FAILURE(success)) return NULL; *offset=limit; return this;
    }
    virtual const void *getFontTable(LETag tableTag) const { size_t ignored=0; return getFontTable(tableTag,ignored); }
    virtual const void *getFontTable(LETag tableTag, size_t &length) const {
        length=0;
        for(int i=0;i<6;i++) if(tables[i].tag==tableTag) {
            if(!tables[i].loaded) {
                FT_ULong len=0; tables[i].loaded=1;
                if(FT_Load_Sfnt_Table(face,(FT_ULong)tableTag,0,NULL,&len)==0 && len>0) {
                    tables[i].data=(unsigned char*)malloc((size_t)len);
                    if(tables[i].data) {
                        FT_ULong got=len;
                        if(FT_Load_Sfnt_Table(face,(FT_ULong)tableTag,0,(FT_Byte*)tables[i].data,&got)==0) tables[i].len=(size_t)got;
                        else { free(tables[i].data); tables[i].data=NULL; }
                    }
                }
            }
            length=tables[i].len; return tables[i].data;
        }
        return NULL;
    }
    virtual void *getKernPairs() const { return kernPairs; }
    virtual void setKernPairs(void *pairs) const { kernPairs=pairs; }
    virtual le_bool canDisplay(LEUnicode32 ch) const {
        if(is_jdk_invisible_control((uint32_t)ch)) return TRUE;
        if(ch==0xFFFE || ch==0xFFFF) return FALSE;
        return FT_Get_Char_Index(face,(FT_ULong)ch)!=0?TRUE:FALSE;
    }
    virtual le_int32 getUnitsPerEM() const { return (le_int32)face->units_per_EM; }
    virtual LEGlyphID mapCharToGlyph(LEUnicode32 ch,const LECharMapper *mapper) const {
        LEUnicode32 mapped=mapper->mapChar(ch);
        if(mapped==0xFFFF || mapped==0xFFFE) return 0xFFFF;
        if(mapped==0x200C || mapped==0x200D) return 1;
        return mapCharToGlyph(mapped);
    }
    virtual LEGlyphID mapCharToGlyph(LEUnicode32 ch) const { return (LEGlyphID)rawGlyph(ch); }
    virtual void getGlyphAdvance(LEGlyphID glyph, LEPoint &advance) const {
        le_uint32 g=(le_uint32)glyph;
        if((g&0xFFFEU)==0xFFFEU || loadMetricGlyph((FT_UInt)(g&0xFFFFU))!=0) { advance.fX=0; advance.fY=0; return; }
        if(face->glyph->advance.y==0) { advance.fX=(float)(face->glyph->advance.x>>6); advance.fY=0; }
        else if(face->glyph->advance.x==0) { advance.fX=0; advance.fY=(float)((-face->glyph->advance.y)>>6); }
        else { advance.fX=((float)face->glyph->advance.x)/64.0f; advance.fY=((float)-face->glyph->advance.y)/64.0f; }
    }
    virtual void getKerningAdjustment(LEPoint &adjustment) const { (void)adjustment; }
    virtual le_bool getGlyphPoint(LEGlyphID glyph,le_int32 pointNumber,LEPoint &point) const {
        le_uint32 g=(le_uint32)glyph; point.fX=0; point.fY=0;
        if((g&0xFFFEU)==0xFFFEU) return TRUE;
        FT_Int32 flags=FT_LOAD_NO_HINTING|FT_LOAD_NO_BITMAP;
        if(FT_Load_Glyph(face,(FT_UInt)(g&0xFFFFU),flags)==0) {
            if(style&1) FT_GlyphSlot_Embolden(face->glyph);
            if(face->glyph->format==FT_GLYPH_FORMAT_OUTLINE && pointNumber>=0 && pointNumber<face->glyph->outline.n_points) {
                point.fX=((float)face->glyph->outline.points[pointNumber].x)/64.0f;
                point.fY=((float)face->glyph->outline.points[pointNumber].y)/64.0f;
            }
        }
        return TRUE;
    }
    virtual float getXPixelsPerEm() const { return xppem; }
    virtual float getYPixelsPerEm() const { return yppem; }
    virtual float xUnitsToPoints(float v) const { return v*unitsToPointsX; }
    virtual float yUnitsToPoints(float v) const { return v*unitsToPointsY; }
    virtual void unitsToPoints(LEPoint &u,LEPoint &p) const { p.fX=xUnitsToPoints(u.fX); p.fY=yUnitsToPoints(u.fY); }
    virtual float xPixelsToUnits(float v) const { return v*pixelsToUnitsX; }
    virtual float yPixelsToUnits(float v) const { return v*pixelsToUnitsY; }
    virtual void pixelsToUnits(LEPoint &p,LEPoint &u) const { u.fX=xPixelsToUnits(p.fX); u.fY=yPixelsToUnits(p.fY); }
    virtual float getScaleFactorX() const { return pixelsToUnitsX; }
    virtual float getScaleFactorY() const { return pixelsToUnitsY; }
    virtual void transformFunits(float x,float y,LEPoint &p) const { p.fX=x*unitsToPointsX; p.fY=y*unitsToPointsY; }
    virtual le_int32 getAscent() const { return 0; }
    virtual le_int32 getDescent() const { return 0; }
    virtual le_int32 getLeading() const { return 0; }
};

static JdkFontInstance g_font;

struct ScriptRunRec { int start, limit, script, flags; };

static int script_get(int cp) {
    if(cp<0 || cp>=0x110000) return 0;
    int lo=0, hi=P2B_SCRIPT_PAIR_COUNT-1;
    while(lo<=hi) {
        int mid=(lo+hi)>>1;
        int start=P2B_SCRIPT_DATA[mid*2];
        int next=P2B_SCRIPT_DATA[(mid+1)*2];
        if(cp<start) hi=mid-1;
        else if(cp>=next) lo=mid+1;
        else return P2B_SCRIPT_DATA[mid*2+1];
    }
    return 0;
}

static const int paired_chars[] = {
    0x0028,0x0029,0x003c,0x003e,0x005b,0x005d,0x007b,0x007d,0x00ab,0x00bb,
    0x2018,0x2019,0x201c,0x201d,0x2039,0x203a,0x3008,0x3009,0x300a,0x300b,
    0x300c,0x300d,0x300e,0x300f,0x3010,0x3011,0x3014,0x3015,0x3016,0x3017,
    0x3018,0x3019,0x301a,0x301b
};

static int pair_index(int ch) {
    for(size_t i=0;i<sizeof(paired_chars)/sizeof(paired_chars[0]);i++) if(paired_chars[i]==ch) return (int)i;
    return -1;
}
static int same_script(int a,int b) { return a==b || a<=1 || b<=1; }
static int mark_type(int cp) {
    int lo=0, hi=P2B_MARK_RANGE_COUNT-1;
    while(lo<=hi){ int m=(lo+hi)>>1; int a=P2B_MARK_RANGES[m*2], b=P2B_MARK_RANGES[m*2+1]; if(cp<a)hi=m-1; else if(cp>b)lo=m+1; else return 1; }
    return 0;
}

static uint32_t next_codepoint(const std::vector<uint16_t>& t,int &p,int limit) {
    uint32_t ch=t[(size_t)p++];
    if(ch>=0xD800 && ch<0xDC00 && p<limit) {
        uint32_t lo=t[(size_t)p];
        if(lo>=0xDC00 && lo<0xE000) { p++; return ((ch-0xD800)<<10)+(lo-0xDC00)+0x10000; }
    }
    return ch;
}

static void script_runs(const std::vector<uint16_t>& text,std::vector<ScriptRunRec>& out) {
    const int limit=(int)text.size(); int pos=0; std::vector<int> stack;
    while(pos<limit) {
        int runStart=pos, runScript=0, startSP=(int)stack.size();
        while(pos<limit) {
            int before=pos; uint32_t ch=next_codepoint(text,pos,limit); int sc=script_get((int)ch); int pi=(sc==0)?pair_index((int)ch):-1;
            if(pi>=0) {
                if((pi&1)==0) { stack.push_back(pi); stack.push_back(runScript); }
                else if(!stack.empty()) {
                    int want=pi&~1; int found=-1;
                    for(int s=(int)stack.size()-2;s>=0;s-=2) if(stack[(size_t)s]==want){found=s;break;}
                    if(found>=0) { sc=stack[(size_t)found+1]; stack.resize((size_t)found+2); }
                }
            }
            if(same_script(runScript,sc)) {
                if(runScript<=1 && sc>1) {
                    runScript=sc;
                    while(startSP<(int)stack.size()) { if(startSP+1<(int)stack.size()) stack[(size_t)startSP+1]=runScript; startSP+=2; }
                }
                if(pi>0 && (pi&1)!=0 && stack.size()>=2) stack.resize(stack.size()-2);
            } else { pos=before; break; }
        }
        int flags=0;
        for(int i=runStart;i<pos;i++) {
            uint32_t cp=text[(size_t)i];
            if(cp>=0xD800 && cp<0xDC00 && i+1<pos) { uint32_t q=text[(size_t)i+1]; if(q>=0xDC00&&q<0xE000){cp=((cp-0xD800)<<10)+(q-0xDC00)+0x10000;i++;} }
            if(mark_type((int)cp)) { flags|=4; break; }
        }
        ScriptRunRec r; r.start=runStart; r.limit=pos; r.script=runScript; r.flags=flags; out.push_back(r);
    }
}

struct LayoutResult { std::vector<le_uint32> glyphs; std::vector<float> pos; float advance; };
static int layout_complex(const std::vector<uint16_t>& u,int size,int style,LayoutResult& lr) {
    if(!g_font.setCase(size,style)) return 0;
    std::vector<LEUnicode> chars(u.size()); for(size_t i=0;i<u.size();i++) chars[i]=(LEUnicode)u[i];
    std::vector<ScriptRunRec> runs; script_runs(u,runs); float cx=0,cy=0;
    for(size_t ri=0;ri<runs.size();ri++) {
        ScriptRunRec r=runs[ri]; LEErrorCode success=LE_NO_ERROR;
        LayoutEngine *engine=LayoutEngine::layoutEngineFactory(&g_font,r.script,-1,r.flags&7,success);
        if(!engine || LE_FAILURE(success)) { delete engine; return 0; }
        le_int32 gc=engine->layoutChars(&chars[0],r.start,r.limit-r.start,(le_int32)chars.size(),FALSE,cx,cy,success);
        if(gc<0 || LE_FAILURE(success)) { delete engine; return 0; }
        std::vector<le_uint32> gs((size_t)gc); std::vector<float> ps((size_t)(gc+1)*2U);
        if(gc>0) engine->getGlyphs(&gs[0],0,success); engine->getGlyphPositions(&ps[0],success);
        if(LE_FAILURE(success)) { delete engine; return 0; }
        for(le_int32 i=0;i<gc;i++){ lr.glyphs.push_back(gs[(size_t)i]); lr.pos.push_back(ps[(size_t)i*2]); lr.pos.push_back(ps[(size_t)i*2+1]); }
        cx=ps[(size_t)gc*2]; cy=ps[(size_t)gc*2+1]; delete engine;
    }
    lr.advance=cx; return 1;
}

static void bitmap_points(std::vector<int>& pts,int originX,int originY,FT_Bitmap *bm) {
    int pitch=bm->pitch; const unsigned char *base=bm->buffer;
    for(int y=0;y<(int)bm->rows;y++) {
        const unsigned char *row=pitch>=0?base+y*pitch:base+((int)bm->rows-1-y)*(-pitch);
        for(int x=0;x<(int)bm->width;x++) if(row[x>>3]&(0x80>>(x&7))) { pts.push_back(originX+x); pts.push_back(originY+y); }
    }
}

static int simple_width(const std::vector<uint16_t>& u,int size,int style) {
    if(!g_font.setCase(size,style)) return 0; int w=0;
    for(size_t i=0;i<u.size();i++) w+=g_font.advanceForChar((uint32_t)u[i]);
    return w;
}

static int has_complex(const std::vector<uint16_t>& u) { for(size_t i=0;i<u.size();i++) if(is_non_simple_char(u[i])) return 1; return 0; }

static void simple_raster(const std::vector<uint16_t>& u,int size,int style,std::vector<int>& pts,int& advance) {
    g_font.setCase(size,style); int pen=0;
    for(size_t i=0;i<u.size();i++) {
        uint32_t cp=u[i]; if(is_jdk_invisible_control(cp)) continue;
        FT_UInt glyph=(cp==0xFFFE||cp==0xFFFF)?0:FT_Get_Char_Index(g_font.ftFace(),(FT_ULong)cp);
        if(g_font.loadRenderGlyph(glyph)) {
            FT_GlyphSlot slot=g_font.ftFace()->glyph;
            bitmap_points(pts,pen+slot->bitmap_left,-slot->bitmap_top,&slot->bitmap);
            pen+=(int)(slot->advance.x>>6);
        }
    }
    advance=pen;
}

static void complex_raster(const std::vector<uint16_t>& u,int size,int style,std::vector<int>& pts,int& advance) {
    LayoutResult lr; if(!layout_complex(u,size,style,lr)){advance=0;return;} g_font.setCase(size,style);
    for(size_t i=0;i<lr.glyphs.size();i++) {
        le_uint32 raw=lr.glyphs[i]; if((raw&0xFFFEU)==0xFFFEU) continue;
        FT_UInt glyph=(FT_UInt)(raw&0xFFFFU); if(glyph==1) continue;
        if(g_font.loadRenderGlyph(glyph)) {
            FT_GlyphSlot slot=g_font.ftFace()->glyph;
            int ox=(int)floor(lr.pos[i*2]+0.5f)+slot->bitmap_left;
            int oy=(int)floor(lr.pos[i*2+1]+0.5f)-slot->bitmap_top;
            bitmap_points(pts,ox,oy,&slot->bitmap);
        }
    }
    advance=(int)floor(lr.advance+0.5f);
}

static std::vector<uint16_t> jstring_u16(JNIEnv *env,jstring s) {
    std::vector<uint16_t> out; if(!s) return out; jsize n=env->GetStringLength(s); const jchar *p=env->GetStringChars(s,NULL);
    if(!p) return out; out.resize((size_t)n); for(jsize i=0;i<n;i++) out[(size_t)i]=(uint16_t)p[i]; env->ReleaseStringChars(s,p); return out;
}

extern "C" JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXCore2D_fontInitNative(JNIEnv *env,jclass,jstring path) {
    if(!path) return 0; const char *p=env->GetStringUTFChars(path,NULL); if(!p) return 0;
    pthread_mutex_lock(&g_lock); int ok=g_font.init(p); pthread_mutex_unlock(&g_lock); env->ReleaseStringUTFChars(path,p); return ok?1:0;
}

extern "C" JNIEXPORT jintArray JNICALL Java_org_recompile_rg35xx_RG35XXCore2D_fontMetricsNative(JNIEnv *env,jclass,jint pointSize) {
    jint vals[4]={0,0,0,0}; pthread_mutex_lock(&g_lock);
    if(g_font.ready() && g_font.setCase((int)pointSize,0)) {
        FT_Face f=g_font.ftFace();
        float asc=((float)FT_MulFix(f->ascender,f->size->metrics.y_scale))/65536.0f/64.0f*65536.0f;
        float desc=-((float)FT_MulFix(f->descender,f->size->metrics.y_scale))/64.0f;
        asc=((float)FT_MulFix(f->ascender,f->size->metrics.y_scale))/64.0f;
        float line=((float)FT_MulFix(f->height,f->size->metrics.y_scale))/64.0f;
        float lead=line-asc-desc;
        int ia=(int)(0.95f+asc); int id=(int)(0.95f+desc); int tail=(int)(0.95f+desc+lead);
        vals[0]=ia+tail; vals[1]=ia; vals[2]=id; vals[3]=tail-id;
    }
    pthread_mutex_unlock(&g_lock); jintArray a=env->NewIntArray(4); if(a) env->SetIntArrayRegion(a,0,4,vals); return a;
}

extern "C" JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXCore2D_fontCharWidthNative(JNIEnv*,jclass,jint ch,jint pointSize,jint style) {
    pthread_mutex_lock(&g_lock); int w=0; if(g_font.ready()&&g_font.setCase((int)pointSize,(int)style)) w=g_font.advanceForChar((uint32_t)ch); pthread_mutex_unlock(&g_lock); return (jint)w;
}

extern "C" JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXCore2D_fontStringWidthNative(JNIEnv *env,jclass,jstring s,jint pointSize,jint style) {
    std::vector<uint16_t> u=jstring_u16(env,s); pthread_mutex_lock(&g_lock); int w=0;
    if(g_font.ready()) {
        if(has_complex(u)) { LayoutResult lr; if(layout_complex(u,(int)pointSize,(int)style,lr)) w=(int)floor(lr.advance+0.5f); }
        else w=simple_width(u,(int)pointSize,(int)style);
    }
    pthread_mutex_unlock(&g_lock); return (jint)w;
}

extern "C" JNIEXPORT jintArray JNICALL Java_org_recompile_rg35xx_RG35XXCore2D_fontRasterNative(JNIEnv *env,jclass,jstring s,jint pointSize,jint style) {
    std::vector<uint16_t> u=jstring_u16(env,s); std::vector<int> pts; int advance=0; pthread_mutex_lock(&g_lock);
    if(g_font.ready()) { if(has_complex(u)) complex_raster(u,(int)pointSize,(int)style,pts,advance); else simple_raster(u,(int)pointSize,(int)style,pts,advance); }
    pthread_mutex_unlock(&g_lock);
    jint count=(jint)(pts.size()/2); std::vector<jint> out(2+pts.size()); out[0]=(jint)advance; out[1]=count;
    for(size_t i=0;i<pts.size();i++) out[i+2]=(jint)pts[i]; jintArray a=env->NewIntArray((jsize)out.size()); if(a&&!out.empty()) env->SetIntArrayRegion(a,0,(jsize)out.size(),&out[0]); return a;
}
