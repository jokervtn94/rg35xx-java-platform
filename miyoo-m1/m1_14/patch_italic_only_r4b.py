from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='if((font.getStyle() & Font.STYLE_BOLD)!=0) fillRect(px+scale,py,scale,scale);'
new='''if((font.getStyle() & Font.STYLE_BOLD)!=0) fillRect(px+scale,py,scale,scale);\n\t\t\t// M1.14-r4B primary variable: ITALIC only. Row shear only; keep glyph data,\n\t\t\t// advance, baseline, size semantics and BOLD implementation unchanged.\n\t\t\tif((font.getStyle() & Font.STYLE_ITALIC)!=0) {\n\t\t\t\tint italicShift=((15-row)*scale)/6;\n\t\t\t\tif(italicShift>0) { fillRect(px+italicShift,py,scale,scale); fillRect(px,py,scale,scale); }\n\t\t\t}'''
if old not in s: raise SystemExit('M1_14_R4B_ITALIC_PATCH=FAIL_CLOSED')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R4B_ITALIC_PATCH=PASS')
