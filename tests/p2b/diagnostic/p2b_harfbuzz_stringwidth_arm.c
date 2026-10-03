#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb.h>
#include <hb-ft.h>

static const char *samples[] = {
    "ABCxyz09",
    "AVATAR",
    "ToTo",
    "ffi",
    "Ti\xE1\xBA\xBFng Vi\xE1\xBB\x87t",
    "Tie\xCC\x82\xCC\x81ng Vie\xCC\xA3\xCC\x82t",
    "A\xCC\x81",
    "\xD8\xB3\xD9\x84\xD8\xA7\xD9\x85",
    "\xD9\x84\xD8\xA7",
    "\xD7\xA9\xD7\x9C\xD7\x95\xD7\x9D",
    "\xE0\xA4\xA8\xE0\xA4\xAE\xE0\xA4\xB8\xE0\xA5\x8D\xE0\xA4\xA4\xE0\xA5\x87",
    "\xE0\xB8\xA0\xE0\xB8\xB2\xE0\xB8\xA9\xE0\xB8\xB2\xE0\xB9\x84\xE0\xB8\x97\xE0\xB8\xA2",
    "\xE4\xB8\xAD\xE6\x96\x87",
    "A\xE2\x80\x8D" "B"
};

static int utf8_cp_count(const char *s) {
    int n=0; const unsigned char *p=(const unsigned char*)s;
    while(*p){ if((*p&0xC0)!=0x80)n++; p++; }
    return n;
}

int main(int argc, char **argv) {
    FT_Library lib=0; FT_Face face=0; int sizes[]={12,14,16}; int zi,si;
    if(argc!=2){fprintf(stderr,"usage: %s font.ttf\n",argv[0]);return 2;}
    if(FT_Init_FreeType(&lib)) return 3;
    if(FT_New_Face(lib,argv[1],0,&face)) return 4;
    printf("P2B_HB_BOOT=PASS\n");
    printf("P2B_HB_VERSION=%s\n", hb_version_string());
    for(zi=0;zi<3;zi++) {
        if(FT_Set_Pixel_Sizes(face,0,(FT_UInt)sizes[zi])) return 5;
        for(si=0;si<(int)(sizeof(samples)/sizeof(samples[0]));si++) {
            hb_font_t *font=hb_ft_font_create_referenced(face);
            hb_buffer_t *buf=hb_buffer_create();
            unsigned int count=0,i; hb_glyph_info_t *infos; hb_glyph_position_t *pos;
            long adv26=0; int notdef=0, offsets=0;
            hb_buffer_add_utf8(buf,samples[si],-1,0,-1);
            hb_buffer_guess_segment_properties(buf);
            hb_shape(font,buf,NULL,0);
            infos=hb_buffer_get_glyph_infos(buf,&count);
            pos=hb_buffer_get_glyph_positions(buf,&count);
            for(i=0;i<count;i++) {
                adv26 += pos[i].x_advance;
                if(infos[i].codepoint==0) notdef++;
                if(pos[i].x_offset!=0 || pos[i].y_offset!=0) offsets++;
            }
            printf("P2B_HB SIZE=%d SAMPLE=%d CODEPOINTS=%d GLYPHS=%u NOTDEF=%d OFFSETS=%d DIR=%s ADV26=%ld WIDTH_ROUND=%ld\n",
                sizes[zi],si,utf8_cp_count(samples[si]),count,notdef,offsets,
                hb_direction_to_string(hb_buffer_get_direction(buf)),adv26,(adv26>=0?(adv26+32)/64:(adv26-32)/64));
            hb_buffer_destroy(buf); hb_font_destroy(font);
        }
    }
    FT_Done_Face(face); FT_Done_FreeType(lib);
    printf("P2B_HB_CASES=42\n");
    printf("P2B_HB_RESULT=PASS\n");
    return 0;
}
