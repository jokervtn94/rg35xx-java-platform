#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb.h>
#include <hb-ft.h>

static int hexval(int c) {
    if(c>='0'&&c<='9')return c-'0';
    if(c>='A'&&c<='F')return c-'A'+10;
    if(c>='a'&&c<='f')return c-'a'+10;
    return -1;
}
static int parse_hex4(const char *s) {
    int i,v=0,h;
    for(i=0;i<4;i++){h=hexval((unsigned char)s[i]); if(h<0)return -1; v=(v<<4)|h;}
    return v;
}
static void shape(FT_Face face, const uint32_t *cps, int n, long *adv26, unsigned int *glyphs,
                  int *notdef, int *offsets, hb_direction_t *dir) {
    hb_font_t *font=hb_ft_font_create_referenced(face);
    hb_buffer_t *buf=hb_buffer_create();
    hb_glyph_info_t *info; hb_glyph_position_t *pos; unsigned int count=0,i;
    *adv26=0;*notdef=0;*offsets=0;
    hb_buffer_add_utf32(buf,cps,n,0,n);
    hb_buffer_guess_segment_properties(buf);
    hb_shape(font,buf,NULL,0);
    info=hb_buffer_get_glyph_infos(buf,&count); pos=hb_buffer_get_glyph_positions(buf,&count);
    for(i=0;i<count;i++) {
        *adv26 += pos[i].x_advance;
        if(info[i].codepoint==0)(*notdef)++;
        if(pos[i].x_offset!=0 || pos[i].y_offset!=0)(*offsets)++;
    }
    *glyphs=count; *dir=hb_buffer_get_direction(buf);
    hb_buffer_destroy(buf); hb_font_destroy(font);
}
static long jround26(long v) {
    /* Math.round(v / 64.0) == floor(v/64 + .5), including negatives. */
    if(v>=0)return (v+32)/64;
    return -(((-v)+31)/64);
}
int main(int argc,char **argv) {
    FT_Library lib=0; FT_Face face=0; FILE *in=0,*out=0; char line[64]; int sizes[]={12,14,16}; int triggers=0,cases=0;
    if(argc!=4){fprintf(stderr,"usage: %s font.ttf trigger.txt out.tsv\n",argv[0]);return 2;}
    if(FT_Init_FreeType(&lib))return 3;
    if(FT_New_Face(lib,argv[1],0,&face))return 4;
    in=fopen(argv[2],"rb"); if(!in)return 5;
    out=fopen(argv[3],"wb"); if(!out){fclose(in);return 6;}
    fprintf(out,"CP\tSIZE\tFULL_ADV26\tFULL_WIDTH_ROUND\tADDITIVE_ADV26\tDELTA26\tDELTA_ROUND\tFULL_GLYPHS\tFULL_NOTDEF\tFULL_OFFSETS\tDIR\n");
    while(fgets(line,sizeof(line),in)) {
        int cp=parse_hex4(line); int zi;
        if(cp<0)continue; triggers++;
        for(zi=0;zi<3;zi++) {
            uint32_t full[3],single[1]; long fullAdv=0,addAdv=0,a=0; unsigned int g=0,sg=0; int nd=0,off=0,snd=0,soff=0; hb_direction_t d=HB_DIRECTION_INVALID,sd;
            if(FT_Set_Pixel_Sizes(face,0,(FT_UInt)sizes[zi]))return 7;
            full[0]='A';full[1]=(uint32_t)cp;full[2]='B';
            shape(face,full,3,&fullAdv,&g,&nd,&off,&d);
            single[0]='A'; shape(face,single,1,&a,&sg,&snd,&soff,&sd); addAdv+=a;
            single[0]=(uint32_t)cp; shape(face,single,1,&a,&sg,&snd,&soff,&sd); addAdv+=a;
            single[0]='B'; shape(face,single,1,&a,&sg,&snd,&soff,&sd); addAdv+=a;
            fprintf(out,"%04X\t%d\t%ld\t%ld\t%ld\t%ld\t%ld\t%u\t%d\t%d\t%s\n",
                cp,sizes[zi],fullAdv,jround26(fullAdv),addAdv,fullAdv-addAdv,jround26(fullAdv-addAdv),g,nd,off,hb_direction_to_string(d));
            cases++;
        }
    }
    fclose(out);fclose(in);FT_Done_Face(face);FT_Done_FreeType(lib);
    printf("P2B_HB_COMPLEX_BOOT=PASS\n");
    printf("P2B_HB_VERSION=%s\n",hb_version_string());
    printf("P2B_HB_COMPLEX_TRIGGER_UNITS=%d\n",triggers);
    printf("P2B_HB_COMPLEX_CASES=%d\n",cases);
    printf("P2B_HB_COMPLEX_RESULT=PASS\n");
    return 0;
}
