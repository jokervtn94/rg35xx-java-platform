#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\tprivate int rg35xxBitmapWidth(String str) {
\t\tint scale=rg35xxBitmapScale(),w=0;
\t\tfor(int i=0;i<str.length();i++) w+=(rg35xxWideChar(str.charAt(i))?12:8)*scale;
\t\treturn w;
\t}

\tprivate void rg35xxDrawBitmapString(String str,int x,int y,int anchor) {
\t\trg35xxEnsureBitmapFont();
\t\tif(rg35xxBitmapFont==null) { rg35xxDrawAscii(str,x,y,anchor); return; }
\t\tint scale=rg35xxBitmapScale();
\t\tint w=rg35xxBitmapWidth(str),h=16*scale;
\t\tx=AnchorX(x,w,anchor);
\t\tif((anchor & Graphics.VCENTER)>0) y-=h/2;
\t\telse if((anchor & Graphics.BOTTOM)>0) y-=h;
\t\telse if((anchor & Graphics.BASELINE)>0) y-=h;
\t\tint pen=x;
'''
new='''\t// M1.13-r1: Miyoo-inspired separation of bitmap pixels from layout geometry.
\t// Raster stays exactly M1.12-r4E. Only advance/string width and vertical anchor
\t// geometry live in this layer. Do not use FontMetrics to rescale glyph pixels.
\tprivate int rg35xxLayoutAdvance(char ch,int scale) {
\t\treturn (rg35xxWideChar(ch)?12:8)*scale;
\t}

\tprivate int rg35xxBitmapWidth(String str) {
\t\tint scale=rg35xxBitmapScale(),w=0;
\t\tfor(int i=0;i<str.length();i++) w+=rg35xxLayoutAdvance(str.charAt(i),scale);
\t\treturn w;
\t}

\tprivate int rg35xxLayoutAscent(int scale) { return 13*scale; }
\tprivate int rg35xxLayoutDescent(int scale) { return 3*scale; }
\tprivate int rg35xxLayoutLineHeight(int scale) { return rg35xxLayoutAscent(scale)+rg35xxLayoutDescent(scale); }

\tprivate int rg35xxLayoutTopY(int y,int anchor,int scale) {
\t\tint ascent=rg35xxLayoutAscent(scale);
\t\tint descent=rg35xxLayoutDescent(scale);
\t\tint line=rg35xxLayoutLineHeight(scale);
\t\tif((anchor & Graphics.BASELINE)>0) return y-ascent;
\t\tif((anchor & Graphics.BOTTOM)>0) return y-line;
\t\tif((anchor & Graphics.VCENTER)>0) return y-(line/2);
\t\treturn y;
\t}

\tprivate void rg35xxDrawBitmapString(String str,int x,int y,int anchor) {
\t\trg35xxEnsureBitmapFont();
\t\tif(rg35xxBitmapFont==null) { rg35xxDrawAscii(str,x,y,anchor); return; }
\t\tint scale=rg35xxBitmapScale();
\t\tint w=rg35xxBitmapWidth(str);
\t\tx=AnchorX(x,w,anchor);
\t\ty=rg35xxLayoutTopY(y,anchor,scale);
\t\tint pen=x;
'''
if s.count(old)!=1: raise SystemExit('M1_13_LAYOUT_PATCH=FAIL_LAYOUT_ANCHOR')
s=s.replace(old,new,1)
old2='''\t\t\tpen+=(rg35xxWideChar(ch)?12:8)*scale;
'''
new2='''\t\t\tpen+=rg35xxLayoutAdvance(ch,scale);
'''
if s.count(old2)!=1: raise SystemExit('M1_13_LAYOUT_PATCH=FAIL_ADVANCE_ANCHOR')
s=s.replace(old2,new2,1)
p.write_text(s)
print('M1_13_HYBRID_LAYOUT_PATCH=PASS')
