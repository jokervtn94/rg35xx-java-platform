#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-corpus3-cliptranslate-fix.py <repo-root>')

root = Path(sys.argv[1]).resolve()
pg = root / 'build/a3/stage-src/org/recompile/mobile/PlatformGraphics.java'
text = pg.read_text(encoding='utf-8')

old = '''\tpublic void translate(int x, int y)
\t{
\t\ttranslateX += x;
\t\ttranslateY += y;
\t\tif (platformImage.isRG35XXRaw())
\t\t{
\t\t\tclipX += x;
\t\t\tclipY += y;
\t\t\treturn;
\t\t}
\t\tgc.translate(x, y);
\t\tclipX -= x;
\t\tclipY -= y;
\t}
'''

new = '''\tpublic void translate(int x, int y)
\t{
\t\ttranslateX += x;
\t\ttranslateY += y;
\t\tif (platformImage.isRG35XXRaw())
\t\t{
\t\t\t// RG35XX raw clipX/clipY are device-space coordinates:
\t\t\t// setClip/clipRect convert user coordinates with +translate and
\t\t\t// raw raster paths convert destinations with +translate.
\t\t\t// Moving the stored clip again here double-applies translation.
\t\t\treturn;
\t\t}
\t\tgc.translate(x, y);
\t\tclipX -= x;
\t\tclipY -= y;
\t}
'''

count = text.count(old)
if count != 1:
    raise SystemExit('A6_CORPUS3_CLIPTRANSLATE_STAGE_FAIL translate anchor count=%d' % count)

pg.write_text(text.replace(old, new, 1), encoding='utf-8')
print('A6_CORPUS3_CLIPTRANSLATE_STAGE=PASS')
print('A6_CORPUS3_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_TRANSLATE_CLIP_DOUBLE_SHIFT')
print('A6_CORPUS3_DELTA=RAW_TRANSLATE_PRESERVE_DEVICE_CLIP')
