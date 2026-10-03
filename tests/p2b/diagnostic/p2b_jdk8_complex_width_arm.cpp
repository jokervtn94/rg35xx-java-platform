/*
 * Audit-only ARM complex-width differential. Reuse the already-proven
 * whole-raster diagnostic bridge and exact JDK8 LayoutEngine/FreeType source
 * contracts, but derive only TextLayout component terminal advance.
 */
#define main p2b_whole_raster_diagnostic_main_unused
#include "p2b_jdk8_whole_raster_arm.cpp"
#undef main

static uint32_t cw_float_bits(float v) {
    union { float f; uint32_t u; } x;
    x.f=v;
    return x.u;
}

static int derive_complex_width(ProbeFontInstance &font,
                                const std::vector<LEUnicode> &chars,
                                const std::vector<RunRec> &runs,
                                int layoutFlags,
                                float *advanceOut) {
    if (runs.empty()) return -30;
    const le_bool rtl=(layoutFlags & 1) ? TRUE : FALSE;
    float currentX=0.0f,currentY=0.0f;
    int ri=rtl ? (int)runs.size()-1 : 0;
    int stop=rtl ? -1 : (int)runs.size();
    int step=rtl ? -1 : 1;

    for(;ri!=stop;ri+=step) {
        const RunRec &r=runs[(size_t)ri];
        if(r.start<0 || r.limit<=r.start || r.limit>(int)chars.size()) return -31;
        LEErrorCode success=LE_NO_ERROR;
        LayoutEngine *engine=LayoutEngine::layoutEngineFactory(
            &font,r.script,-1,r.flags & 0x7,success);
        if(engine==NULL || LE_FAILURE(success)) return -32;

        le_int32 gc=engine->layoutChars(&chars[0],r.start,r.limit-r.start,
            (le_int32)chars.size(),rtl,currentX,currentY,success);
        if(gc<0 || LE_FAILURE(success)) { delete engine; return -33; }

        std::vector<float> pos((size_t)(gc+1)*2U);
        engine->getGlyphPositions(&pos[0],success);
        if(LE_FAILURE(success)) { delete engine; return -34; }
        currentX=pos[(size_t)gc*2U];
        currentY=pos[(size_t)gc*2U+1U];
        delete engine;
    }

    *advanceOut=currentX;
    return (int)(0.5f+currentX);
}

int main(int argc,char **argv) {
    if(argc!=4) {
        fprintf(stderr,"usage: %s font.ttf jdk-whole-raster.tsv arm-width.tsv\n",argv[0]);
        return 2;
    }

    ProbeFontInstance font(argv[1]);
    std::ifstream in(argv[2]);
    std::ofstream out(argv[3]);
    if(!in || !out) return 3;
    std::string line;
    if(!std::getline(in,line)) return 4;
    out << "CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tWIDTH_DERIVED\tADV_BITS\n";

    int cases=0,rtlCases=0;
    while(std::getline(in,line)) {
        if(line.empty()) continue;
        std::vector<std::string> c=split(line,'\t');
        if(c.size()!=16) return 5;
        if(to_int(c[5])==0) continue;

        int incomingStyle=to_int(c[1]);
        int normalized=to_int(c[2]);
        int pointSize=to_int(c[3]);
        int layoutFlags=to_int(c[14]);
        std::vector<LEUnicode> chars=parse_utf16(c[6]);
        std::vector<RunRec> runs=parse_runs(c[15]);
        if(chars.empty() || runs.empty()) return 6;
        if(norm_style(incomingStyle)!=normalized) return 7;

        font.setCase(pointSize,incomingStyle);
        float advance=0.0f;
        int width=derive_complex_width(font,chars,runs,layoutFlags,&advance);
        if(width<0) {
            fprintf(stderr,"P2B_ARM_COMPLEX_WIDTH_FAIL=%d CASE=%s\n",width,c[0].c_str());
            return 8;
        }
        if(layoutFlags & 1) rtlCases++;

        char bits[16];
        snprintf(bits,sizeof(bits),"%08X",(unsigned int)cw_float_bits(advance));
        out << c[0] << '\t' << c[1] << '\t' << c[2] << '\t' << c[3] << '\t'
            << c[4] << '\t' << width << '\t' << bits << "\n";
        cases++;
    }
    out.close();

    printf("P2B_ARM_COMPLEX_WIDTH_BOOT=PASS\n");
    printf("P2B_ARM_COMPLEX_WIDTH_CASES=%d\n",cases);
    printf("P2B_ARM_COMPLEX_WIDTH_RTL_CASES=%d\n",rtlCases);
    printf("P2B_ARM_COMPLEX_WIDTH_RESULT=PASS\n");
    printf("P2B_RUNTIME_PATCH=FORBIDDEN\n");
    return 0;
}
