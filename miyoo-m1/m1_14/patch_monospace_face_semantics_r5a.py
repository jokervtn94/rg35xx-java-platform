#!/usr/bin/env python3
from pathlib import Path

# Primary variable: FACE_MONOSPACE layout semantics only.
# Keep bitmap glyph data/raster, size semantics, baseline and all style semantics unchanged.

pf=Path('upstream/src/org/recompile/mobile/PlatformFont.java')
s=pf.read_text()
old='''\t\t\t\tint rg35xxPublicScale = (size == Font.SIZE_LARGE) ? 2 : 1;\n\t\t\t\twidth += (wide ? 12 : 8) * rg35xxPublicScale;'''
new='''\t\t\t\tint rg35xxPublicScale = (size == Font.SIZE_LARGE) ? 2 : 1;\n\t\t\t\t// M1.14-r5A: MONOSPACE uses one fixed 12-cell advance for every glyph.\n\t\t\t\t// SYSTEM/PROPORTIONAL preserve the proven hybrid 8/12 contract.\n\t\t\t\twidth += ((face == Font.FACE_MONOSPACE) ? 12 : (wide ? 12 : 8)) * rg35xxPublicScale;'''
if s.count(old)!=1: raise SystemExit('M1_14_R5A_PATCH=FAIL_PUBLIC_WIDTH_ANCHOR')
s=s.replace(old,new,1)
pf.write_text(s)

pg=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
g=pg.read_text()
old2='''\tprivate int rg35xxLayoutAdvance(char ch,int scale) {\n\t\treturn (rg35xxWideChar(ch)?12:8)*scale;\n\t}'''
new2='''\tprivate int rg35xxLayoutAdvance(char ch,int scale) {\n\t\t// M1.14-r5A: only MONOSPACE changes layout advance. Raster pixels stay unchanged.\n\t\tif(font.getFace()==Font.FACE_MONOSPACE) return 12*scale;\n\t\treturn (rg35xxWideChar(ch)?12:8)*scale;\n\t}'''
if g.count(old2)!=1: raise SystemExit('M1_14_R5A_PATCH=FAIL_LAYOUT_ADVANCE_ANCHOR')
g=g.replace(old2,new2,1)
pg.write_text(g)
print('M1_14_R5A_MONOSPACE_FACE_SEMANTICS_PATCH=PASS')
