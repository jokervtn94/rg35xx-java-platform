#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s=p.read_text()
old='''\t\tif (Boolean.getBoolean("rg35xx.headless.font"))
\t\t{
\t\t\tint point = getPointSize();
\t\t\theight = point + 2;
\t\t\tascent = point;
\t\t\tdescent = 2;
\t\t\tawtFont = null;
\t\t\tmetrics = null;
\t\t\treturn;
\t\t}
'''
new='''\t\tif (Boolean.getBoolean("rg35xx.headless.font"))
\t\t{
\t\t\t// M1.14-r1: report the geometry of the proven bitmap backend.
\t\t\t// Raster pixels are unchanged: 16 rows, narrow advance 8, wide 12.
\t\t\theight = 16;
\t\t\tascent = 13;
\t\t\tdescent = 3;
\t\t\tawtFont = null;
\t\t\tmetrics = null;
\t\t\treturn;
\t\t}
'''
if s.count(old)!=1: raise SystemExit('M1_14_METRICS_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s=s.replace(old,new,1)
old2='''\t\tif (metrics == null) { return (str.length() * (getPointSize() + 1)) / 2; }
\t\treturn metrics.stringWidth(str); '''
new2='''\t\tif (metrics == null) {
\t\t\tint w=0;
\t\t\tfor(int i=0;i<str.length();i++) {
\t\t\t\tchar ch=str.charAt(i);
\t\t\t\tboolean wide=(ch>=0x3000 && ch<=0x30FF) || (ch>=0x4E00 && ch<=0x9FFF) || (ch>=0xFF00 && ch<=0xFFEF);
\t\t\t\tw += wide ? 12 : 8;
\t\t\t}
\t\t\treturn w;
\t\t}
\t\treturn metrics.stringWidth(str); '''
if s.count(old2)!=1: raise SystemExit('M1_14_METRICS_PATCH=FAIL_WIDTH_ANCHOR')
s=s.replace(old2,new2,1)
p.write_text(s)
print('M1_14_HEADLESS_BITMAP_METRICS_PATCH=PASS')
