#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformImage.java')
s = p.read_text()

old_w = '\tpublic int getWidth() { return canvas.getWidth(); }'
new_w = '''\tpublic int getWidth() {
\t\t// M1.16-r1.2: the locked RG35XX allocation-only blank-image path
\t\t// intentionally has no AWT BufferedImage canvas. Preserve normal behavior
\t\t// when canvas exists; otherwise expose the dimensions recorded by M1.9B.
\t\tif (canvas != null) { return canvas.getWidth(); }
\t\tif (Boolean.getBoolean("rg35xx.headless.image.probe")) { return rg35xxWidth; }
\t\tthrow new IllegalStateException("PlatformImage has no backing canvas");
\t}'''
old_h = '\tpublic int getHeight() { return canvas.getHeight(); }'
new_h = '''\tpublic int getHeight() {
\t\tif (canvas != null) { return canvas.getHeight(); }
\t\tif (Boolean.getBoolean("rg35xx.headless.image.probe")) { return rg35xxHeight; }
\t\tthrow new IllegalStateException("PlatformImage has no backing canvas");
\t}'''

if s.count(old_w) != 1:
    raise SystemExit('M1_16_R12_PATCH=FAIL_WIDTH_ANCHOR')
if s.count(old_h) != 1:
    raise SystemExit('M1_16_R12_PATCH=FAIL_HEIGHT_ANCHOR')
s = s.replace(old_w, new_w, 1).replace(old_h, new_h, 1)
p.write_text(s)
print('M1_16_R12_PLATFORMIMAGE_BLANK_DIMENSIONS_PATCH=PASS')
