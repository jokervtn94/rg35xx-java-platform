#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-p1a-g1-clear-copyarea.py <repo-root>')
root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
if not pg.is_file():
    raise SystemExit('P1A_G1_STAGE_FAIL staged PlatformGraphics missing')
text = pg.read_text(encoding='utf-8')

old_clear = '''\tpublic void clearRect(int x, int y, int width, int height)\n\t{\n\t\tgc.clearRect(x, y, width, height);\n\t}\n'''
new_clear = '''\tpublic void clearRect(int x, int y, int width, int height)\n\t{\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tif (width <= 0 || height <= 0) { return; }\n\t\t\tint px = x + translateX;\n\t\t\tint py = y + translateY;\n\t\t\tint left = Math.max(px, Math.max(clipX, 0));\n\t\t\tint top = Math.max(py, Math.max(clipY, 0));\n\t\t\tint right = Math.min(px + width, Math.min(clipX + clipWidth, platformImage.getRG35XXWidth()));\n\t\t\tint bottom = Math.min(py + height, Math.min(clipY + clipHeight, platformImage.getRG35XXHeight()));\n\t\t\tif (left >= right || top >= bottom) { return; }\n\t\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\t\tint stride = platformImage.getRG35XXWidth();\n\t\t\tfor (int row = top; row < bottom; row++)\n\t\t\t{\n\t\t\t\tArrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tgc.clearRect(x, y, width, height);\n\t}\n'''

old_copy = '''\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n\t{\n\t\tx = AnchorX(x, subw, anchor);\n\t\ty = AnchorY(y, subh, anchor);\n\n\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n\t\tgc.drawImage(sub, x, y, null);\n\t}\n'''
new_copy = '''\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n\t{\n\t\tx = AnchorX(x, subw, anchor);\n\t\ty = AnchorY(y, subh, anchor);\n\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tRG35XXCore2D.blit(platformImage.getRG35XXPixels(), platformImage.getRG35XXWidth(), platformImage.getRG35XXHeight(),\n\t\t\t\tplatformImage.getRG35XXPixels(), platformImage.getRG35XXWidth(), platformImage.getRG35XXHeight(),\n\t\t\t\tsubx, suby, subw, subh, 0, x + translateX, y + translateY, clipX, clipY, clipWidth, clipHeight);\n\t\t\treturn;\n\t\t}\n\n\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n\t\tgc.drawImage(sub, x, y, null);\n\t}\n'''

for label, old, new in [('clearRect', old_clear, new_clear), ('copyArea', old_copy, new_copy)]:
    count = text.count(old)
    if count != 1:
        raise SystemExit('P1A_G1_STAGE_FAIL %s anchor count=%d' % (label, count))
    text = text.replace(old, new, 1)

# Fail closed: no other ownership surface is introduced by this stage.
for required in ['platformImage.isRG35XXRaw()', 'RG35XXCore2D.blit(', 'Arrays.fill(']:
    if required not in text:
        raise SystemExit('P1A_G1_STAGE_FAIL marker missing: ' + required)

pg.write_text(text, encoding='utf-8')
print('P1A_G1_STAGE=PASS')
print('P1A_G1_OWNER=RG35XX_GRAPHICS_BOUNDARY')
print('P1A_G1_METHODS=clearRect,copyArea')
print('P1A_G1_CORE2D_DELTA=NONE')
print('P1A_G1_GAME_SPECIFIC_CODE=NO')
