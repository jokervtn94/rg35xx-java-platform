#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\t\tfor(int n=0;n<str.length();n++) {
\t\t\tchar ch=str.charAt(n); int gi=rg35xxGlyphIndex(ch),base=gi*32;
\t\t\tfor(int row=0;row<16;row++) {
\t\t\t\tint bits=((rg35xxBitmapFont[base+row*2]&255)<<8)|(rg35xxBitmapFont[base+row*2+1]&255);
\t\t\t\tfor(int col=0;col<16;col++) if((bits & (0x8000>>>col))!=0)
\t\t\t\t\tfillRect(pen+col*scale,y+row*scale,scale,scale);
\t\t\t}
\t\t\tpen+=rg35xxLayoutAdvance(ch,scale);
\t\t}
'''
new='''\t\tfor(int n=0;n<str.length();n++) {
\t\t\tchar ch=str.charAt(n); int gi=rg35xxGlyphIndex(ch),base=gi*32;
\t\t\t// M1.13-r2 recovered raster contract: the stored cell is 16 bits wide,
\t\t\t// but drawable columns are bounded by the glyph advance (8 narrow / 12 wide).
\t\t\t// This is the only r2 variable; mapping, rows, scale and layout stay unchanged.
\t\t\tint rasterCols=rg35xxWideChar(ch)?12:8;
\t\t\tfor(int row=0;row<16;row++) {
\t\t\t\tint bits=((rg35xxBitmapFont[base+row*2]&255)<<8)|(rg35xxBitmapFont[base+row*2+1]&255);
\t\t\t\tfor(int col=0;col<rasterCols;col++) if((bits & (0x8000>>>col))!=0)
\t\t\t\t\tfillRect(pen+col*scale,y+row*scale,scale,scale);
\t\t\t}
\t\t\tpen+=rg35xxLayoutAdvance(ch,scale);
\t\t}
'''
if s.count(old)!=1: raise SystemExit('M1_13_R2_RASTER_BOUND=FAIL_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_13_R2_RASTER_BOUND=PASS')
