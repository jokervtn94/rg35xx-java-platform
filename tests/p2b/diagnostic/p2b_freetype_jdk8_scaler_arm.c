#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H
#include FT_MODULE_H

/* Audit-only reproduction of the OpenJDK8 FreetypeFontScaler settings used
 * by the P2B reference path. It is not production runtime code. */

static const char *samples[] = {
    "ABCxyz09", "iiiiWWWW", "Tieng Viet",
    "Ti\xE1\xBA\xBFng Vi\xE1\xBB\x87t", "\xC4\x90\xE1\xBA\xB7ng", "\xE4\xB8\xAD\xE6\x96\x87"
};

static const uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
static const uint64_t FNV_PRIME  = UINT64_C(0x100000001b3);
#define CANVAS_W 256
#define CANVAS_H 128
#define ORIGIN_X 16
#define ORIGIN_Y 64
#define FT_MATRIX_ONE 0x10000L
#define FT_MATRIX_OBLIQUE_XY 0x0366AL

static int utf8_next(const unsigned char **pp) {
    const unsigned char *p=*pp; unsigned int c;
    if (*p < 0x80) c=*p++;
    else if ((*p&0xE0)==0xC0 && p[1]) { c=((p[0]&31)<<6)|(p[1]&63); p+=2; }
    else if ((*p&0xF0)==0xE0 && p[1] && p[2]) { c=((p[0]&15)<<12)|((p[1]&63)<<6)|(p[2]&63); p+=3; }
    else { c=0xFFFD; p++; }
    *pp=p; return (int)c;
}

static int norm_style(int s) { return (s>=0 && s<=3) ? s : 0; }

static uint64_t mix32(uint64_t h, int v) {
    uint32_t u=(uint32_t)v;
    h^=(u>>24)&255; h*=FNV_PRIME;
    h^=(u>>16)&255; h*=FNV_PRIME;
    h^=(u>>8)&255; h*=FNV_PRIME;
    h^=u&255; h*=FNV_PRIME;
    return h;
}

static int set_jdk8_interpreter(FT_Library lib) {
    int version=35;
    return FT_Property_Set(lib, "truetype", "interpreter-version", &version);
}

static int set_jdk8_context(FT_Face face, int size, int style) {
    FT_Matrix matrix;
    int ns=norm_style(style);
    matrix.xx=FT_MATRIX_ONE;
    matrix.xy=(ns&2) ? FT_MATRIX_OBLIQUE_XY : 0;
    matrix.yx=0;
    matrix.yy=FT_MATRIX_ONE;
    FT_Set_Transform(face,&matrix,NULL);
    return FT_Set_Char_Size(face,0,(FT_F26Dot6)(size*64),72,72);
}

static int load_jdk8_glyph(FT_Face face, int cp, int style, int render,
                           int *advance_out) {
    int ns=norm_style(style);
    int use_sbits=(ns==0); /* AA off + FM off + identity + no algorithmic style. */
    FT_Int32 flags=FT_LOAD_DEFAULT | FT_LOAD_TARGET_MONO;
    FT_UInt glyph=FT_Get_Char_Index(face,(FT_ULong)cp);
    int rc;
    if(!use_sbits) flags |= FT_LOAD_NO_BITMAP;
    rc=FT_Load_Glyph(face,glyph,flags);
    if(rc) return rc;
    if(ns&1) FT_GlyphSlot_Embolden(face->glyph);
    if(advance_out) {
        if(face->glyph->advance.y==0) *advance_out=(int)(face->glyph->advance.x >> 6);
        else *advance_out=(int)(face->glyph->advance.x / 64);
    }
    if(render && face->glyph->format==FT_GLYPH_FORMAT_OUTLINE) {
        rc=FT_Render_Glyph(face->glyph,FT_RENDER_MODE_MONO);
    }
    return rc;
}

static int occupied(const FT_Bitmap *b, int row, int col) {
    const unsigned char *base;
    int pitch=b->pitch;
    if(pitch>=0) base=b->buffer + row*pitch;
    else base=b->buffer + (b->rows-1-row)*(-pitch);
    if(b->pixel_mode==FT_PIXEL_MODE_MONO)
        return (base[col>>3] & (0x80>>(col&7))) != 0;
    if(b->pixel_mode==FT_PIXEL_MODE_GRAY)
        return base[col] != 0;
    return 0;
}

static void run_case(FT_Face face, const char *s, int style,
                     int *out_width, int *ink,
                     int *x0, int *y0, int *x1, int *y1, uint64_t *fp) {
    const unsigned char *p=(const unsigned char*)s;
    unsigned char canvas[CANVAS_W*CANVAS_H];
    int pen=0,row,col,xx,yy;
    memset(canvas,0,sizeof(canvas));
    while(*p) {
        int cp=utf8_next(&p),adv=0;
        if(load_jdk8_glyph(face,cp,style,1,&adv)!=0) continue;
        {
            FT_GlyphSlot g=face->glyph;
            int gx=pen+g->bitmap_left;
            int gy=-g->bitmap_top;
            for(row=0;row<(int)g->bitmap.rows;row++) {
                for(col=0;col<(int)g->bitmap.width;col++) {
                    if(occupied(&g->bitmap,row,col)) {
                        int x=ORIGIN_X+gx+col;
                        int y=ORIGIN_Y+gy+row;
                        if(x>=0 && x<CANVAS_W && y>=0 && y<CANVAS_H)
                            canvas[y*CANVAS_W+x]=1;
                    }
                }
            }
        }
        pen += adv;
    }
    *ink=0; *x0=*y0=99999; *x1=*y1=-99999; *fp=FNV_OFFSET;
    for(yy=0;yy<CANVAS_H;yy++) for(xx=0;xx<CANVAS_W;xx++) {
        if(canvas[yy*CANVAS_W+xx]) {
            int rx=xx-ORIGIN_X, ry=yy-ORIGIN_Y;
            (*ink)++;
            if(rx<*x0)*x0=rx; if(rx>*x1)*x1=rx;
            if(ry<*y0)*y0=ry; if(ry>*y1)*y1=ry;
            *fp=mix32(*fp,rx); *fp=mix32(*fp,ry);
        }
    }
    if(*ink==0) *x0=*y0=*x1=*y1=-1;
    *out_width=pen;
}

int main(int argc,char **argv) {
    FT_Library lib=0; FT_Face face=0;
    int sizes[]={12,14,16};
    int style,zi,si;
    if(argc!=2){fprintf(stderr,"usage: %s font.ttf\n",argv[0]);return 2;}
    if(FT_Init_FreeType(&lib))return 3;
    if(set_jdk8_interpreter(lib)!=0){fprintf(stderr,"interpreter-version=35 unavailable\n");return 4;}
    if(FT_New_Face(lib,argv[1],0,&face))return 5;
    printf("P2B_FT_JDK8_SCALER_BOOT=PASS\n");
    printf("P2B_FT_JDK8_INTERPRETER=35\n");
    printf("P2B_FT_JDK8_AA=OFF\n");
    printf("P2B_FT_JDK8_FM=OFF\n");
    printf("P2B_FT_JDK8_DPI=72\n");
    for(style=0;style<=7;style++) for(zi=0;zi<3;zi++) {
        int size=sizes[zi];
        if(set_jdk8_context(face,size,style))return 6;
        for(si=0;si<6;si++) {
            int width,ink,x0,y0,x1,y1; uint64_t fp;
            run_case(face,samples[si],style,&width,&ink,&x0,&y0,&x1,&y1,&fp);
            printf("P2B_FT_RASTER_FP VARIANT=JDK8SCALER STYLE=%d NORMALIZED=%d SIZE=%d SAMPLE=%d WIDTH=%d INK=%d BOUNDS=%d,%d,%d,%d FP=%016llx\n",
                   style,norm_style(style),size,si,width,ink,x0,y0,x1,y1,
                   (unsigned long long)fp);
        }
    }
    FT_Done_Face(face); FT_Done_FreeType(lib);
    printf("P2B_FT_JDK8_SCALER_CASES=144\n");
    printf("P2B_FT_JDK8_SCALER_RESULT=PASS\n");
    return 0;
}
