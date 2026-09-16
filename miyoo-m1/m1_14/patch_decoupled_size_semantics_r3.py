#!/usr/bin/env python3
from pathlib import Path

pf=Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s=pf.read_text()
old='''\t\t\t// M1.14-r1: report metrics matching the proven bitmap layout.\n\t\t\t// Primary variable is reported Font metrics only; raster remains untouched.\n\t\t\theight = 16;\n\t\t\tascent = 13;\n\t\t\tdescent = 3;'''
new='''\t\t\t// M1.14-r3: MIDP public size semantics are independent from bitmap raster scale.\n\t\t\t// Preserve the proven 13:3 baseline ratio while reporting distinct sizes.\n\t\t\tint rg35xxPublicScale = (size == Font.SIZE_LARGE) ? 2 : 1;\n\t\t\theight = 16 * rg35xxPublicScale;\n\t\t\tascent = 13 * rg35xxPublicScale;\n\t\t\tdescent = 3 * rg35xxPublicScale;'''
if s.count(old)!=1: raise SystemExit('M1_14_R3_PATCH=FAIL_FONT_METRICS_ANCHOR')
s=s.replace(old,new,1)
old2='''\t\t\t\twidth += wide ? 12 : 8;'''
new2='''\t\t\t\tint rg35xxPublicScale = (size == Font.SIZE_LARGE) ? 2 : 1;\n\t\t\t\twidth += (wide ? 12 : 8) * rg35xxPublicScale;'''
if s.count(old2)!=1: raise SystemExit('M1_14_R3_PATCH=FAIL_WIDTH_ANCHOR')
s=s.replace(old2,new2,1)
pf.write_text(s)

pg=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
g=pg.read_text()
old3='''\tprivate int rg35xxBitmapScale() { return font.getHeight()>=26 ? 2 : 1; }'''
new3='''\t// M1.14-r3: internal bitmap raster scale must not depend on public getHeight().\n\t// SIZE_LARGE uses the recovered 2x bitmap path; SMALL/MEDIUM preserve 1x.\n\tprivate int rg35xxBitmapScale() { return font.getSize()==Font.SIZE_LARGE ? 2 : 1; }'''
if g.count(old3)!=1: raise SystemExit('M1_14_R3_PATCH=FAIL_RASTER_SCALE_ANCHOR')
g=g.replace(old3,new3,1)
pg.write_text(g)
print('M1_14_R3_DECOUPLED_SIZE_SEMANTICS_PATCH=PASS')
