#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/javax/microedition/lcdui/game/Sprite.java')
s = p.read_text()

old = 'image.getRGB(argbData, 0, width, xOffset, yOffset, height, width);'
new = '''// DP-R5 PRIMARY VARIABLE: pass getRGB width/height in API order.
		image.getRGB(argbData, 0, width, xOffset, yOffset, width, height);'''

if s.count(old) != 1:
    raise SystemExit('DP_R5_SPRITE_GETARGB_WH_PATCH=FAIL_ANCHOR')

p.write_text(s.replace(old, new, 1))
print('DP_R5_SPRITE_GETARGB_WH_PATCH=PASS')
print('DP_R5_PRIMARY_VARIABLE=SPRITE_GETARGBDATA_WIDTH_HEIGHT_ORDER_ONLY')
