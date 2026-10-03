#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H

static void put_be16(FILE *f, int v) {
    unsigned int u = (unsigned int)(v & 0xffff);
    fputc((int)((u >> 8) & 0xff), f);
    fputc((int)(u & 0xff), f);
}

int main(int argc, char **argv) {
    FT_Library lib = NULL;
    FT_Face face = NULL;
    int sizes[] = {12,14,16};
    int zi;
    unsigned long display_count = 0;
    if (argc != 3) { fprintf(stderr,"usage: %s font.ttf out.bin\n",argv[0]); return 2; }
    if (FT_Init_FreeType(&lib)) return 3;
    if (FT_New_Face(lib, argv[1], 0, &face)) return 4;
    FILE *out = fopen(argv[2], "wb");
    if (!out) return 5;
    printf("P2B_FT_CHARWIDTH_BOOT=PASS\n");
    for (zi=0; zi<3; zi++) {
        int size=sizes[zi];
        unsigned long cp;
        if (FT_Set_Pixel_Sizes(face,0,(FT_UInt)size)) return 6;
        for (cp=0; cp<=0xffffUL; cp++) {
            FT_UInt idx = FT_Get_Char_Index(face,(FT_ULong)cp);
            int rc = FT_Load_Char(face,(FT_ULong)cp,FT_LOAD_DEFAULT);
            long w;
            if (rc) return 7;
            w = (face->glyph->advance.x + 32) >> 6;
            if (w < -32768 || w > 32767) return 8;
            put_be16(out,(int)w);
            fputc(idx ? 1 : 0,out);
            if (idx) display_count++;
        }
        printf("P2B_FT_CHARWIDTH_SIZE=%d PASS=YES\n",size);
    }
    fclose(out);
    printf("P2B_FT_CHARWIDTH_TABLE_CASES=%lu\n",65536UL*3UL);
    printf("P2B_FT_CHARWIDTH_DISPLAYABLE_COUNT=%lu\n",display_count);
    printf("P2B_FT_CHARWIDTH_RESULT=PASS\n");
    FT_Done_Face(face);
    FT_Done_FreeType(lib);
    return 0;
}
