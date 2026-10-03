#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_MODULE_H

/* Audit-only reproduction of JDK8 TrueTypeGlyphMapper/CMap control wrapping
 * plus FreetypeFontScaler AA-off/FM-off advance semantics. */

static void put_be16(FILE *f, int v) {
    unsigned int u=(unsigned int)(v & 0xffff);
    fputc((u>>8)&255,f); fputc(u&255,f);
}

static int is_jdk_invisible_control(unsigned long cp) {
    if (cp < 0x10UL) {
        return cp==0x09UL || cp==0x0aUL || cp==0x0dUL;
    }
    if (cp >= 0x200cUL) {
        if (cp <= 0x200fUL) return 1;
        if (cp >= 0x2028UL && cp <= 0x202eUL) return 1;
        if (cp >= 0x206aUL && cp <= 0x206fUL) return 1;
    }
    return 0;
}

static int set_jdk8_interpreter(FT_Library lib) {
    int version=35;
    return FT_Property_Set(lib,"truetype","interpreter-version",&version);
}

int main(int argc,char **argv) {
    FT_Library lib=0; FT_Face face=0; FILE *out;
    int sizes[]={12,14,16}; int zi; unsigned long display_count=0;
    if(argc!=3){fprintf(stderr,"usage: %s font.ttf out.bin\n",argv[0]);return 2;}
    if(FT_Init_FreeType(&lib))return 3;
    if(set_jdk8_interpreter(lib)!=0)return 4;
    if(FT_New_Face(lib,argv[1],0,&face))return 5;
    out=fopen(argv[2],"wb"); if(!out)return 6;
    printf("P2B_FT_JDK8_CHARWIDTH_BOOT=PASS\n");
    printf("P2B_FT_JDK8_CHARWIDTH_INTERPRETER=35\n");
    for(zi=0;zi<3;zi++) {
        int size=sizes[zi]; unsigned long cp;
        if(FT_Set_Char_Size(face,0,(FT_F26Dot6)(size*64),72,72))return 7;
        for(cp=0;cp<=0xffffUL;cp++) {
            int width,display;
            if(is_jdk_invisible_control(cp)) {
                /* CMap returns INVISIBLE_GLYPH_ID; FileFontStrike advance=0;
                 * mapper.canDisplay() is true because invisible != missing(0). */
                width=0; display=1;
            } else {
                FT_UInt idx=FT_Get_Char_Index(face,(FT_ULong)cp);
                FT_Int32 flags=FT_LOAD_DEFAULT|FT_LOAD_TARGET_MONO;
                if(FT_Load_Glyph(face,idx,flags))return 8;
                /* OpenJDK8 FM-off FreetypeFontScaler truncates 26.6 advance. */
                width=(int)(face->glyph->advance.x >> 6);
                display=(idx != 0);
            }
            if(width < -32768 || width > 32767)return 9;
            put_be16(out,width); fputc(display?1:0,out);
            if(display)display_count++;
        }
        printf("P2B_FT_JDK8_CHARWIDTH_SIZE=%d PASS=YES\n",size);
    }
    fclose(out);
    FT_Done_Face(face); FT_Done_FreeType(lib);
    printf("P2B_FT_JDK8_CHARWIDTH_TABLE_CASES=%lu\n",65536UL*3UL);
    printf("P2B_FT_JDK8_CHARWIDTH_DISPLAYABLE_COUNT=%lu\n",display_count);
    printf("P2B_FT_JDK8_CHARWIDTH_RESULT=PASS\n");
    return 0;
}
