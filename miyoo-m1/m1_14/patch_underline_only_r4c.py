from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\t\t\tpen+=rg35xxLayoutAdvance(ch,scale);\n\t\t}\n\t}\n'''
new='''\t\t\t// M1.14-r4C primary variable: UNDERLINE only. Draw one scale-thick rule\n\t\t\t// inside the recovered 16-row cell. Keep glyph data, advance, baseline,\n\t\t\t// size semantics, BOLD and ITALIC implementations unchanged.\n\t\t\tif((font.getStyle() & Font.STYLE_UNDERLINED)!=0) {\n\t\t\t\tint underlineY=y+(15*scale);\n\t\t\t\tfillRect(pen,underlineY,rg35xxLayoutAdvance(ch,scale),scale);\n\t\t\t}\n\t\t\tpen+=rg35xxLayoutAdvance(ch,scale);\n\t\t}\n\t}\n'''
if s.count(old)!=1: raise SystemExit('M1_14_R4C_UNDERLINE_PATCH=FAIL_LAYOUT_ADVANCE_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R4C_UNDERLINE_PATCH=PASS')
