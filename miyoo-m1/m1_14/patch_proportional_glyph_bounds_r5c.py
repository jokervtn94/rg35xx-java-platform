#!/usr/bin/env python3
from pathlib import Path

# M1.14-r5C primary variable: FACE_PROPORTIONAL advance only.
# Derive narrow-glyph advance from actual bitmap rightmost occupied column.
# Preserve glyph raster, wide 12-cell contract, baseline, size/style and r5A MONOSPACE.

pf=Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s=pf.read_text()
anchor='''\tpublic int stringWidth(String str)
\t{'''
helper='''\tprivate static byte[] rg35xxMetricFont;
\tprivate static boolean rg35xxMetricFontTried;
\tprivate static final int[] RG35XX_METRIC_RANGE_START={0x0020,0x00A0,0x0370,0x0400,0x1E00,0x3000,0x3040,0x30A0,0x4E00,0xFF00};
\tprivate static final int[] RG35XX_METRIC_RANGE_END={0x007E,0x024F,0x03FF,0x052F,0x1EFF,0x303F,0x309F,0x30FF,0x9FFF,0xFFEF};
\tprivate static final int[] RG35XX_METRIC_RANGE_OFFSET={0,95,527,671,975,1231,1295,1391,1487,22479};
\tprivate static void rg35xxEnsureMetricFont(){
\t\tif(rg35xxMetricFontTried)return; rg35xxMetricFontTried=true;
\t\ttry{java.io.InputStream in=PlatformFont.class.getResourceAsStream("/org/recompile/mobile/rg35xx-font.bin");if(in==null)return;byte[] b=new byte[727008];int off=0,n;while(off<b.length&&(n=in.read(b,off,b.length-off))>0)off+=n;in.close();if(off==b.length)rg35xxMetricFont=b;}catch(Throwable t){}
\t}
\tprivate static int rg35xxMetricGlyphIndex(char ch){int c=(int)ch;for(int i=0;i<RG35XX_METRIC_RANGE_START.length;i++)if(c>=RG35XX_METRIC_RANGE_START[i]&&c<=RG35XX_METRIC_RANGE_END[i]){int g=RG35XX_METRIC_RANGE_OFFSET[i]+c-RG35XX_METRIC_RANGE_START[i];return(g>=0&&g<22719)?g:31;}return 31;}
\tprivate static int rg35xxProportionalAdvance(char ch){
\t\tint c=(int)ch;if((c>=0x3000&&c<=0x30FF)||(c>=0x4E00&&c<=0x9FFF)||(c>=0xFF00&&c<=0xFFEF))return 12;
\t\tif(ch==' ')return 4; rg35xxEnsureMetricFont(); if(rg35xxMetricFont==null)return 8;
\t\tint base=rg35xxMetricGlyphIndex(ch)*32,right=-1;
\t\tfor(int row=0;row<16;row++){int bits=((rg35xxMetricFont[base+row*2]&255)<<8)|(rg35xxMetricFont[base+row*2+1]&255);for(int col=0;col<8;col++)if((bits&(0x8000>>>col))!=0&&col>right)right=col;}
\t\tif(right<0)return 4; int a=right+2; if(a<3)a=3; if(a>8)a=8; return a;
\t}

'''
if s.count(anchor)!=1: raise SystemExit('M1_14_R5C_PATCH=FAIL_FONT_HELPER_ANCHOR')
s=s.replace(anchor,helper+anchor,1)
old='''width += ((face == Font.FACE_MONOSPACE) ? 12 : (wide ? 12 : 8)) * rg35xxPublicScale;'''
new='''width += ((face == Font.FACE_MONOSPACE) ? 12 : ((face == Font.FACE_PROPORTIONAL) ? rg35xxProportionalAdvance(ch) : (wide ? 12 : 8))) * rg35xxPublicScale;'''
if s.count(old)!=1: raise SystemExit('M1_14_R5C_PATCH=FAIL_PUBLIC_WIDTH_ANCHOR')
s=s.replace(old,new,1);pf.write_text(s)

pg=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java');g=pg.read_text()
old2='''\tprivate int rg35xxLayoutAdvance(char ch,int scale) {
\t\t// M1.14-r5A: only MONOSPACE changes layout advance. Raster pixels stay unchanged.
\t\tif(font.getFace()==Font.FACE_MONOSPACE) return 12*scale;
\t\treturn (rg35xxWideChar(ch)?12:8)*scale;
\t}'''
new2='''\tprivate int rg35xxLayoutAdvance(char ch,int scale) {
\t\tif(font.getFace()==Font.FACE_MONOSPACE) return 12*scale;
\t\tif(font.getFace()==Font.FACE_PROPORTIONAL) return rg35xxProportionalRasterAdvance(ch)*scale;
\t\treturn (rg35xxWideChar(ch)?12:8)*scale;
\t}
\tprivate int rg35xxProportionalRasterAdvance(char ch) {
\t\tif(rg35xxWideChar(ch)) return 12;
\t\tif(ch==' ') return 4;
\t\trg35xxEnsureBitmapFont(); if(rg35xxBitmapFont==null) return 8;
\t\tint base=rg35xxGlyphIndex(ch)*32,right=-1;
\t\tfor(int row=0;row<16;row++) { int bits=((rg35xxBitmapFont[base+row*2]&255)<<8)|(rg35xxBitmapFont[base+row*2+1]&255); for(int col=0;col<8;col++) if((bits&(0x8000>>>col))!=0 && col>right) right=col; }
\t\tif(right<0) return 4; int a=right+2; if(a<3)a=3; if(a>8)a=8; return a;
\t}'''
if g.count(old2)!=1: raise SystemExit('M1_14_R5C_PATCH=FAIL_LAYOUT_ANCHOR')
g=g.replace(old2,new2,1);pg.write_text(g)
print('M1_14_R5C_PROPORTIONAL_GLYPH_BOUNDS_PATCH=PASS')
