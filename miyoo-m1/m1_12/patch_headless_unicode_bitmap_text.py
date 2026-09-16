#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
needle='''\tprivate void drawStringSingleLine(String str, int x, int y, int anchor)\n\t{\n'''
insert='''\t// M1.12-r4E EXPERIMENTAL Unicode bitmap backend.
\t// Recovered historical contract: 22719 glyphs, 32 bytes/glyph,
\t// 16 rows x 16 bits, narrow/wide advance 8/12, scale 1/2.
\tprivate static byte[] rg35xxBitmapFont;
\tprivate static boolean rg35xxBitmapFontTried;
\tprivate static final int[] RG35XX_RANGE_START={0x0020,0x00A0,0x0370,0x0400,0x1E00,0x3000,0x3040,0x30A0,0x4E00,0xFF00};
\tprivate static final int[] RG35XX_RANGE_END={0x007E,0x024F,0x03FF,0x052F,0x1EFF,0x303F,0x309F,0x30FF,0x9FFF,0xFFEF};
\tprivate static final int[] RG35XX_RANGE_OFFSET={0,95,527,671,975,1231,1295,1391,1487,22479};

\tprivate static void rg35xxEnsureBitmapFont() {
\t\tif(rg35xxBitmapFontTried) return;
\t\trg35xxBitmapFontTried=true;
\t\ttry {
\t\t\tjava.io.InputStream in=PlatformGraphics.class.getResourceAsStream("/org/recompile/mobile/rg35xx-font.bin");
\t\t\tif(in==null) { System.out.println("M1_12_R4E_FONT_RESOURCE=NOT_FOUND"); return; }
\t\t\tbyte[] b=new byte[727008]; int off=0,n;
\t\t\twhile(off<b.length && (n=in.read(b,off,b.length-off))>0) off+=n;
\t\t\tin.close();
\t\t\tif(off!=727008) { System.out.println("M1_12_R4E_FONT_RESOURCE=BAD_SIZE:"+off); return; }
\t\t\trg35xxBitmapFont=b;
\t\t\tSystem.out.println("M1_12_R4E_FONT_RESOURCE=LOADED_EXPERIMENTAL bytes="+off);
\t\t} catch(Throwable t) { System.out.println("M1_12_R4E_FONT_RESOURCE=FAIL:"+t.getClass().getName()); }
\t}

\tprivate static int rg35xxGlyphIndex(char ch) {
\t\tint c=(int)ch;
\t\tfor(int i=0;i<RG35XX_RANGE_START.length;i++) if(c>=RG35XX_RANGE_START[i] && c<=RG35XX_RANGE_END[i]) {
\t\t\tint g=RG35XX_RANGE_OFFSET[i]+c-RG35XX_RANGE_START[i];
\t\t\treturn (g>=0 && g<22719)?g:31;
\t\t}
\t\treturn 31;
\t}

\tprivate static boolean rg35xxWideChar(char ch) {
\t\tint c=(int)ch;
\t\treturn (c>=0x3000 && c<=0x30FF)||(c>=0x4E00 && c<=0x9FFF)||(c>=0xFF00 && c<=0xFFEF);
\t}

\tprivate int rg35xxBitmapScale() { return font.getHeight()>=26 ? 2 : 1; }

\tprivate int rg35xxBitmapWidth(String str) {
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
\t\tfor(int n=0;n<str.length();n++) {
\t\t\tchar ch=str.charAt(n); int gi=rg35xxGlyphIndex(ch),base=gi*32;
\t\t\tfor(int row=0;row<16;row++) {
\t\t\t\tint bits=((rg35xxBitmapFont[base+row*2]&255)<<8)|(rg35xxBitmapFont[base+row*2+1]&255);
\t\t\t\tfor(int col=0;col<16;col++) if((bits & (0x8000>>>col))!=0)
\t\t\t\t\tfillRect(pen+col*scale,y+row*scale,scale,scale);
\t\t\t}
\t\t\tpen+=(rg35xxWideChar(ch)?12:8)*scale;
\t\t}
\t}

\tprivate void rg35xxDrawSafeText(String str,int x,int y,int anchor) {
\t\trg35xxDrawBitmapString(str,x,y,anchor);
\t}

'''
if s.count(needle)!=1: raise SystemExit('M1_12_R4E_PATCH=FAIL_METHOD_ANCHOR')
s=s.replace(needle,insert+needle,1)
old='''if (Boolean.getBoolean("rg35xx.headless.graphics.probe")) { rg35xxDrawAscii(str, x, y, anchor); return; }'''
new='''if (Boolean.getBoolean("rg35xx.headless.graphics.probe")) { rg35xxDrawSafeText(str, x, y, anchor); return; }'''
if s.count(old)!=1: raise SystemExit('M1_12_R4E_PATCH=FAIL_HOOK_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_12_R4E_UNICODE_PATCH=PASS')
