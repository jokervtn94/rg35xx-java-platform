#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-p1a-g1-clear-copyarea.py <repo-root>')
root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
core = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
if not pg.is_file():
    raise SystemExit('P1A_G1_STAGE_FAIL staged PlatformGraphics missing')
if not core.is_file():
    raise SystemExit('P1A_G1_STAGE_FAIL RG35XXCore2D missing')
text = pg.read_text(encoding='utf-8')

old_clear = '''\tpublic void clearRect(int x, int y, int width, int height)\n\t{\n\t\tgc.clearRect(x, y, width, height);\n\t}\n'''
new_clear = '''\tpublic void clearRect(int x, int y, int width, int height)\n\t{\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tif (width <= 0 || height <= 0) { return; }\n\t\t\tint px = x + translateX;\n\t\t\tint py = y + translateY;\n\t\t\tint left = Math.max(px, Math.max(clipX, 0));\n\t\t\tint top = Math.max(py, Math.max(clipY, 0));\n\t\t\tint right = Math.min(px + width, Math.min(clipX + clipWidth, platformImage.getRG35XXWidth()));\n\t\t\tint bottom = Math.min(py + height, Math.min(clipY + clipHeight, platformImage.getRG35XXHeight()));\n\t\t\tif (left >= right || top >= bottom) { return; }\n\t\t\tint[] dst = platformImage.getRG35XXPixels();\n\t\t\tint stride = platformImage.getRG35XXWidth();\n\t\t\tfor (int row = top; row < bottom; row++)\n\t\t\t{\n\t\t\t\tArrays.fill(dst, row * stride + left, row * stride + right, 0x00000000);\n\t\t\t}\n\t\t\treturn;\n\t\t}\n\t\tgc.clearRect(x, y, width, height);\n\t}\n'''

old_copy = '''\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n\t{\n\t\tx = AnchorX(x, subw, anchor);\n\t\ty = AnchorY(y, subh, anchor);\n\n\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n\t\tgc.drawImage(sub, x, y, null);\n\t}\n'''
new_copy = '''\tpublic void copyArea(int subx, int suby, int subw, int subh, int x, int y, int anchor)\n\t{\n\t\tx = AnchorX(x, subw, anchor);\n\t\ty = AnchorY(y, subh, anchor);\n\n\t\tif (platformImage.isRG35XXRaw())\n\t\t{\n\t\t\tRG35XXCore2D.copyAreaAliased(platformImage.getRG35XXPixels(),\n\t\t\t\tplatformImage.getRG35XXWidth(), platformImage.getRG35XXHeight(),\n\t\t\t\tsubx, suby, subw, subh, x + translateX, y + translateY,\n\t\t\t\tclipX, clipY, clipWidth, clipHeight);\n\t\t\treturn;\n\t\t}\n\n\t\tBufferedImage sub = canvas.getSubimage(subx, suby, subw, subh);\n\n\t\tgc.drawImage(sub, x, y, null);\n\t}\n'''

for label, old, new in [('clearRect', old_clear, new_clear), ('copyArea', old_copy, new_copy)]:
    count = text.count(old)
    if count != 1:
        raise SystemExit('P1A_G1_STAGE_FAIL %s anchor count=%d' % (label, count))
    text = text.replace(old, new, 1)

for required in ['platformImage.isRG35XXRaw()', 'RG35XXCore2D.copyAreaAliased(', 'Arrays.fill(']:
    if required not in text:
        raise SystemExit('P1A_G1_STAGE_FAIL PlatformGraphics marker missing: ' + required)
pg.write_text(text, encoding='utf-8')

# Evidence from differential run 36941065871: canonical BufferedImage.getSubimage()
# shares the destination raster. A forward/down-right overlap therefore observes
# writes made earlier in the same draw. Existing Core2D.blit snapshots the source
# and cannot reproduce this canonical quirk. Add one narrow raster helper that
# deliberately reads and writes the same array in Java2D's observed top-to-bottom,
# left-to-right order while retaining existing source-over and destination clip.
c = core.read_text(encoding='utf-8')
anchor = '''    /** Source-over ARGB blit with clipping and an optional MIDP transform. */\n    public static void blit(int[] dst, int dstWidth, int dstHeight,\n'''
helper = '''    /**\n     * Canonical PlatformGraphics.copyArea backing for a self-aliased raw surface.\n     * Pinned Aweigit uses BufferedImage.getSubimage(), which is a shared-raster\n     * view, followed by Graphics2D.drawImage(). Differential evidence shows the\n     * aliased draw observes earlier writes in top-to-bottom/left-to-right order.\n     * Do not replace this with a snapshot/memmove implementation.\n     */\n    public static void copyAreaAliased(int[] pixels, int imageWidth, int imageHeight,\n                                       int srcX, int srcY, int width, int height,\n                                       int dstX, int dstY,\n                                       int clipX, int clipY, int clipWidth, int clipHeight) {\n        if (srcX < 0 || srcY < 0 || width <= 0 || height <= 0\n                || srcX + width > imageWidth || srcY + height > imageHeight) {\n            throw new IllegalArgumentException("subimage bounds");\n        }\n        int left = Math.max(dstX, Math.max(clipX, 0));\n        int top = Math.max(dstY, Math.max(clipY, 0));\n        int right = Math.min(dstX + width, Math.min(clipX + clipWidth, imageWidth));\n        int bottom = Math.min(dstY + height, Math.min(clipY + clipHeight, imageHeight));\n        if (right <= left || bottom <= top) return;\n        for (int y = top; y < bottom; y++) {\n            int sy = srcY + (y - dstY);\n            for (int x = left; x < right; x++) {\n                int sx = srcX + (x - dstX);\n                int si = sy * imageWidth + sx;\n                int di = y * imageWidth + x;\n                pixels[di] = sourceOver(pixels[si], pixels[di]);\n            }\n        }\n    }\n\n    /** Source-over ARGB blit with clipping and an optional MIDP transform. */\n    public static void blit(int[] dst, int dstWidth, int dstHeight,\n'''
if c.count(anchor) != 1:
    raise SystemExit('P1A_G1_STAGE_FAIL Core2D blit anchor count=%d' % c.count(anchor))
c = c.replace(anchor, helper, 1)
if c.count('public static void copyAreaAliased(') != 1:
    raise SystemExit('P1A_G1_STAGE_FAIL Core2D helper count')
core.write_text(c, encoding='utf-8')

print('P1A_G1_STAGE=PASS')
print('P1A_G1_OWNER=RG35XX_GRAPHICS_BOUNDARY')
print('P1A_G1_METHODS=clearRect,copyArea')
print('P1A_G1_CORE2D_DELTA=copyAreaAliased_ONLY')
print('P1A_G1_COPYAREA_ALIAS_ORDER=TOP_TO_BOTTOM_LEFT_TO_RIGHT')
print('P1A_G1_GAME_SPECIFIC_CODE=NO')
