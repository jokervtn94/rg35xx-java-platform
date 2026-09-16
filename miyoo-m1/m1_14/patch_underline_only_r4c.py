from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\t\tpen+=rg35xxGlyphAdvance(ch)*scale;\n\t}\n}'''
new='''\t\t// M1.14-r4C primary variable: UNDERLINE only. Draw one scale-thick rule\n\t\t// inside the 16-row cell. Keep glyph data, advance, baseline, size semantics,\n\t\t// BOLD and ITALIC implementations unchanged.\n\t\tif((font.getStyle() & Font.STYLE_UNDERLINED)!=0) {\n\t\t\tint underlineY=y+(15*scale);\n\t\t\tfillRect(pen,underlineY,rg35xxGlyphAdvance(ch)*scale,scale);\n\t\t}\n\t\tpen+=rg35xxGlyphAdvance(ch)*scale;\n\t}\n}'''
if old not in s: raise SystemExit('M1_14_R4C_UNDERLINE_PATCH=FAIL_CLOSED')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R4C_UNDERLINE_PATCH=PASS')
