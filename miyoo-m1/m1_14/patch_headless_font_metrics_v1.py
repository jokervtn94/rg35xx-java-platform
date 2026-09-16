#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s=p.read_text()
old='''\t\t\tint point = getPointSize();\n\t\t\theight = point + 2;\n\t\t\tascent = point;\n\t\t\tdescent = 2;\n\t\t\tawtFont = null;\n\t\t\tmetrics = null;\n\t\t\treturn;'''
new='''\t\t\t// M1.14-r1: report metrics matching the proven bitmap layout.\n\t\t\t// Primary variable is reported Font metrics only; raster remains untouched.\n\t\t\theight = 16;\n\t\t\tascent = 13;\n\t\t\tdescent = 3;\n\t\t\tawtFont = null;\n\t\t\tmetrics = null;\n\t\t\treturn;'''
if s.count(old)!=1: raise SystemExit('M1_14_METRICS_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s=s.replace(old,new,1)
old2='''\t\tif (metrics == null) { return (str.length() * (getPointSize() + 1)) / 2; }\n\t\treturn metrics.stringWidth(str); '''
new2='''\t\tif (metrics == null)\n\t\t{\n\t\t\tint width = 0;\n\t\t\tfor (int i=0; i<str.length(); i++)\n\t\t\t{\n\t\t\t\tchar ch=str.charAt(i);\n\t\t\t\tboolean wide=(ch>=0x3000 && ch<=0x30FF) || (ch>=0x4E00 && ch<=0x9FFF) || (ch>=0xFF00 && ch<=0xFFEF);\n\t\t\t\twidth += wide ? 12 : 8;\n\t\t\t}\n\t\t\treturn width;\n\t\t}\n\t\treturn metrics.stringWidth(str); '''
if s.count(old2)!=1: raise SystemExit('M1_14_METRICS_PATCH=FAIL_WIDTH_ANCHOR')
s=s.replace(old2,new2,1)
p.write_text(s)
print('M1_14_METRICS_PATCH=PASS')
