#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-raw-drawline-r5.py <repo-root>')
root = Path(sys.argv[1]).resolve()

pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
mp = root / 'build/a3/stage-src/org/recompile/mobile/MobilePlatform.java'

pt = pg.read_text(encoding='utf-8')
old = '''\tpublic void drawLine(int x1, int y1, int x2, int y2)\n\t{\n\t\tgc.drawLine(x1, y1, x2, y2);\n\t}\n'''
new = '''\tpublic void drawLine(int x1, int y1, int x2, int y2)\n\t{\n\t\tif(platformImage != null && platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tx1 += translateX; y1 += translateY;\n\t\t\tx2 += translateX; y2 += translateY;\n\t\t\tint[] pixels = platformImage.getRG35XXPixels();\n\t\t\tint pw = platformImage.getRG35XXWidth();\n\t\t\tint ph = platformImage.getRG35XXHeight();\n\t\t\tint argb = 0xFF000000 | (color & 0x00FFFFFF);\n\t\t\tint dx = Math.abs(x2 - x1);\n\t\t\tint sx = x1 < x2 ? 1 : -1;\n\t\t\tint dy = -Math.abs(y2 - y1);\n\t\t\tint sy = y1 < y2 ? 1 : -1;\n\t\t\tint err = dx + dy;\n\t\t\tint step = 0;\n\t\t\twhile(true)\n\t\t\t{\n\t\t\t\tboolean dottedOn = strokeStyle != DOTTED || (step & 1) == 0;\n\t\t\t\tif(dottedOn && x1 >= 0 && y1 >= 0 && x1 < pw && y1 < ph\n\t\t\t\t\t\t&& x1 >= clipX && y1 >= clipY\n\t\t\t\t\t\t&& x1 < clipX + clipWidth && y1 < clipY + clipHeight)\n\t\t\t\t{\n\t\t\t\t\tpixels[y1 * pw + x1] = argb;\n\t\t\t\t}\n\t\t\t\tif(x1 == x2 && y1 == y2) break;\n\t\t\t\tint e2 = err << 1;\n\t\t\t\tif(e2 >= dy) { err += dy; x1 += sx; }\n\t\t\t\tif(e2 <= dx) { err += dx; y1 += sy; }\n\t\t\t\tstep++;\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tgc.drawLine(x1, y1, x2, y2);\n\t}\n'''
if pt.count(old) != 1:
    raise SystemExit('A6_R5_STAGE_FAIL drawLine anchor count=%d' % pt.count(old))
pg.write_text(pt.replace(old, new, 1), encoding='utf-8')

mt = mp.read_text(encoding='utf-8')
old = '''\tpublic void keyPressed(int keycode)\n\t{\n\t\tTextField tf=Mobile.getTextField();\n'''
new = '''\tpublic void keyPressed(int keycode)\n\t{\n\t\tboolean rg35xxA6Trace = Boolean.getBoolean("rg35xx.a6.parenttrace");\n\t\tif(rg35xxA6Trace) { System.out.println("RG35XX_A6_TRACE_KEYPRESS_ENTER="+keycode); System.out.flush(); }\n\t\tTextField tf=Mobile.getTextField();\n'''
if mt.count(old) != 1:
    raise SystemExit('A6_R5_STAGE_FAIL keyPressed entry anchor')
mt = mt.replace(old, new, 1)

old = '''\t\tupdateKeyState(keycode, 1);\n\t\tif(!suppressKeyEvents)\n\t\t\tMobile.getDisplay().getCurrent().keyPressed(keycode);\n\t}\n'''
new = '''\t\tupdateKeyState(keycode, 1);\n\t\tif(rg35xxA6Trace) { System.out.println("RG35XX_A6_TRACE_KEYPRESS_STATE_DONE="+keycode); System.out.flush(); }\n\t\tif(!suppressKeyEvents)\n\t\t{\n\t\t\tif(rg35xxA6Trace) { System.out.println("RG35XX_A6_TRACE_KEYPRESS_DISPLAY_BEGIN="+keycode); System.out.flush(); }\n\t\t\tMobile.getDisplay().getCurrent().keyPressed(keycode);\n\t\t\tif(rg35xxA6Trace) { System.out.println("RG35XX_A6_TRACE_KEYPRESS_DISPLAY_RETURN="+keycode); System.out.flush(); }\n\t\t}\n\t}\n'''
if mt.count(old) != 1:
    raise SystemExit('A6_R5_STAGE_FAIL keyPressed dispatch anchor')
mp.write_text(mt.replace(old, new, 1), encoding='utf-8')

print('A6_R5_RAW_DRAWLINE_STAGE=PASS')
print('A6_R5_RAW_DRAWLINE_OWNER=RG35XX_A5_RAW2D_MISSING_PRIMITIVE')
print('A6_R5_KEYPRESS_TRACE=ENTER+STATE_DONE+DISPLAY_BEGIN+DISPLAY_RETURN')
print('A6_R5_KEYPRESS_TRACE_SEMANTIC_CHANGE=NO')
