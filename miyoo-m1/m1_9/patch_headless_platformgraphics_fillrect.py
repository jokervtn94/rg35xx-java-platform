#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s = p.read_text()

# M1.9D: remove only Graphics2D dependencies reached by setColor + fillRect.
old = '''\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tcolor = (0xFF << 24) | (r<<16) | (g<<8) | b; // Alpha is ignored below, we set it just so the color variable is accurate\n\t\tgc.setColor(new Color(color));\n\t}'''
new = '''\tpublic void setColor(int r, int g, int b)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tcolor = (0xFF << 24) | (r<<16) | (g<<8) | b; // Alpha is ignored below, we set it just so the color variable is accurate\n\t\tif (!Boolean.getBoolean("rg35xx.headless.graphics.probe")) { gc.setColor(new Color(color)); }\n\t}'''
if s.count(old) != 1:
    raise SystemExit('M1_9D_PATCH=FAIL_SETCOLOR_ANCHOR')
s = s.replace(old, new, 1)

old_getters = '''\tpublic int getClipHeight() { return gc.getClipBounds().height; }\n\n\tpublic int getClipWidth() { return gc.getClipBounds().width; }\n\n\tpublic int getClipX() { return gc.getClipBounds().x; }\n\n\tpublic int getClipY() { return gc.getClipBounds().y; }'''
new_getters = '''\tpublic int getClipHeight() { return Boolean.getBoolean("rg35xx.headless.graphics.probe") ? clipHeight : gc.getClipBounds().height; }\n\n\tpublic int getClipWidth() { return Boolean.getBoolean("rg35xx.headless.graphics.probe") ? clipWidth : gc.getClipBounds().width; }\n\n\tpublic int getClipX() { return Boolean.getBoolean("rg35xx.headless.graphics.probe") ? clipX : gc.getClipBounds().x; }\n\n\tpublic int getClipY() { return Boolean.getBoolean("rg35xx.headless.graphics.probe") ? clipY : gc.getClipBounds().y; }'''
if s.count(old_getters) != 1:
    raise SystemExit('M1_9D_PATCH=FAIL_CLIP_GETTER_ANCHOR')
s = s.replace(old_getters, new_getters, 1)

p.write_text(s)
print('M1_9D_HEADLESS_SETCOLOR_FILLRECT_PATCH=PASS')
print('M1_9D_HEADLESS_CLIP_GETTERS_PATCH=PASS')
