#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s = p.read_text()

# M1.9D: only remove the remaining Graphics2D call from setColor(r,g,b).
# fillRect already rasterizes directly into canvasData in pinned upstream.
old = '''\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tcolor = (0xFF << 24) | (r<<16) | (g<<8) | b; // Alpha is ignored below, we set it just so the color variable is accurate\n\t\tgc.setColor(new Color(color));\n\t}'''
new = '''\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tcolor = (0xFF << 24) | (r<<16) | (g<<8) | b; // Alpha is ignored below, we set it just so the color variable is accurate\n\t\tif (!Boolean.getBoolean("rg35xx.headless.graphics.probe")) { gc.setColor(new Color(color)); }\n\t}'''
if s.count(old) != 1:
    raise SystemExit('M1_9D_PATCH=FAIL_SETCOLOR_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_9D_HEADLESS_SETCOLOR_FILLRECT_PATCH=PASS')
