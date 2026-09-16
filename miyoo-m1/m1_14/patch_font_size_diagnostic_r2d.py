#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\tprivate int rg35xxBitmapScale() { return font.getHeight()>=26 ? 2 : 1; }'''
new='''\tprivate int rg35xxBitmapScale() {
\t\tint h=font.getHeight();
\t\tint scale=h>=26 ? 2 : 1;
\t\tif(Boolean.getBoolean("rg35xx.font.size.diagnostic"))
\t\t\tSystem.out.println("M1_14_R2D_RENDER_SIZE="+font.getSize()+" HEIGHT="+h+" SCALE="+scale);
\t\treturn scale;
\t}'''
if s.count(old)!=1: raise SystemExit('M1_14_R2D_PATCH=FAIL_SCALE_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R2D_DIAGNOSTIC_PATCH=PASS')
