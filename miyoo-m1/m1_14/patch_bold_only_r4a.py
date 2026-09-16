#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\t\t\t\tfor(int col=0;col<rasterCols;col++) if((bits & (0x8000>>>col))!=0)\n\t\t\t\t\tfillRect(pen+col*scale,y+row*scale,scale,scale);'''
new='''\t\t\t\tfor(int col=0;col<rasterCols;col++) if((bits & (0x8000>>>col))!=0) {\n\t\t\t\t\tint px=pen+col*scale, py=y+row*scale;\n\t\t\t\t\tfillRect(px,py,scale,scale);\n\t\t\t\t\t// M1.14-r4A primary variable: BOLD only. Keep glyph data, advance,\n\t\t\t\t\t// baseline, size semantics and non-bold styles unchanged.\n\t\t\t\t\tif((font.getStyle() & Font.STYLE_BOLD)!=0) fillRect(px+scale,py,scale,scale);\n\t\t\t\t}'''
if s.count(old)!=1: raise SystemExit('M1_14_R4A_BOLD_PATCH=FAIL_RASTER_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R4A_BOLD_PATCH=PASS')
