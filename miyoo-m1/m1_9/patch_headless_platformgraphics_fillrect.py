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

# M1.9F-r6: Canvas.repaintRequest() resets the graphics object. In the
# headless RG35XX path gc is intentionally null, so keep translation,
# clip, font and stroke state in Java instead of calling Graphics2D.
old_translate = '''\tpublic void translate(int x, int y)\n\t{\n\t\ttranslateX += x;\n\t\ttranslateY += y;\n\t\tgc.translate(x, y);\n\t}'''
new_translate = '''\tpublic void translate(int x, int y)\n\t{\n\t\ttranslateX += x;\n\t\ttranslateY += y;\n\t\tif (!Boolean.getBoolean("rg35xx.headless.graphics.probe")) { gc.translate(x, y); }\n\t}'''
if s.count(old_translate) != 1:
    raise SystemExit('M1_9F_R6_PATCH=FAIL_TRANSLATE_ANCHOR')
s = s.replace(old_translate, new_translate, 1)

old_font = '''\tpublic void setFont(Font font)\n\t{\n\t\tif(font == null) { font = Font.getDefaultFont(); }\n\t\tthis.font = font;\n\t\tgc.setFont(font.awtFont);\n\t}'''
new_font = '''\tpublic void setFont(Font font)\n\t{\n\t\tif(font == null) { font = Font.getDefaultFont(); }\n\t\tthis.font = font;\n\t\tif (!Boolean.getBoolean("rg35xx.headless.graphics.probe")) { gc.setFont(font.awtFont); }\n\t}'''
if s.count(old_font) != 1:
    raise SystemExit('M1_9F_R6_PATCH=FAIL_FONT_ANCHOR')
s = s.replace(old_font, new_font, 1)

old_clip = '''\tpublic void setClip(int x, int y, int width, int height)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tif(!Mobile.isDoJa) { gc.setClip(x, y, width, height); }\n\t\telse { gc.setClip(x-getTranslateX(), y-getTranslateY(), width, height); }\n\t}'''
new_clip = '''\tpublic void setClip(int x, int y, int width, int height)\n\t{\n\t\tif(contextDisposed) { throw new UIException(UIException.ILLEGAL_STATE, "This graphics context has been disposed"); }\n\n\t\tif (Boolean.getBoolean("rg35xx.headless.graphics.probe"))\n\t\t{\n\t\t\tclipX = Mobile.isDoJa ? x-getTranslateX() : x;\n\t\t\tclipY = Mobile.isDoJa ? y-getTranslateY() : y;\n\t\t\tclipWidth = width;\n\t\t\tclipHeight = height;\n\t\t\treturn;\n\t\t}\n\n\t\tif(!Mobile.isDoJa) { gc.setClip(x, y, width, height); }\n\t\telse { gc.setClip(x-getTranslateX(), y-getTranslateY(), width, height); }\n\t}'''
if s.count(old_clip) != 1:
    raise SystemExit('M1_9F_R6_PATCH=FAIL_SETCLIP_ANCHOR')
s = s.replace(old_clip, new_clip, 1)

p.write_text(s)
print('M1_9D_HEADLESS_SETCOLOR_FILLRECT_PATCH=PASS')
print('M1_9D_HEADLESS_CLIP_GETTERS_PATCH=PASS')
print('M1_9F_R6_HEADLESS_GRAPHICS_STATE_PATCH=PASS')
