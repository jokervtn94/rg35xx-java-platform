#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s = p.read_text()

old = '''\t\tif (subx < 0 || suby < 0 || subx + subw > image.getCanvas().getWidth() || suby + subh > image.getCanvas().getHeight())\n\t\t{\n\t\t\tthrow new IllegalArgumentException("Source region is out of bounds");\n\t\t}'''

new = '''\t\t// DP-R3 PRIMARY VARIABLE: use LCDUI dimensions for drawRegion bounds.\n\t\t// Headless PlatformImage intentionally has no AWT BufferedImage canvas.\n\t\tif (subx < 0 || suby < 0 || subx + subw > image.getWidth() || suby + subh > image.getHeight())\n\t\t{\n\t\t\tthrow new IllegalArgumentException("Source region is out of bounds");\n\t\t}'''

if s.count(old) != 1:
    raise SystemExit('DP_R3_DRAWREGION_PATCH=FAIL_ANCHOR')

p.write_text(s.replace(old, new, 1))
print('DP_R3_DRAWREGION_HEADLESS_BOUNDS_PATCH=PASS')
print('DP_R3_PRIMARY_VARIABLE=PLATFORMGRAPHICS_DRAWREGION_BOUNDS_ONLY')
