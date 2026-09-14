#!/usr/bin/env python3
"""Apply only the real-device-proven graphics semantics, without VC7R diagnostic probes.

Order prerequisite:
  VC6 clean foundation -> VC7R2 proven dynamic logical view -> this script.

Mutations:
  1. PlatformImage decoded-image normalization avoids GNU Classpath headless Graphics2D.
  2. Libretro frame transport always binds the current frontbuffer object+data atomically.
  3. PlatformGraphics LCD mask is applied only when renderLCDMask is enabled.

No logging/probe counters are added here.
"""
from pathlib import Path
import sys

if len(sys.argv) != 4:
    raise SystemExit("usage: from_zero_apply_proven_graphics.py <Libretro.java> <PlatformImage.java> <PlatformGraphics.java>")

libretro = Path(sys.argv[1])
platform_image = Path(sys.argv[2])
platform_graphics = Path(sys.argv[3])


def replace_once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit("FROM_ZERO GRAPHICS FAIL %s count=%d" % (label, n))
    return text.replace(old, new, 1)

# ---------------------------------------------------------------------------
# 1) Headless-safe decoded image normalization.
# ---------------------------------------------------------------------------
s = platform_image.read_text(encoding="utf-8")
orig = s
old1 = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\t\telse \n\t\t\t{\n\t\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t\t}\n'''
old2 = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\telse \n\t\t{\n\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t}\n'''
count = s.count(old1) + s.count(old2)
if count != 3:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL image-normalize anchors=%d expected=3" % count)
s = s.replace(old1, '\t\tcanvas = rg35xxNormalizeDecodedImage(image);\n')
s = s.replace(old2, '\t\tcanvas = rg35xxNormalizeDecodedImage(image);\n')
anchor = '\tpublic PlatformImage() { }\n\n'
if s.count(anchor) != 1:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL PlatformImage helper anchor")
helper = '''\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)\n\t{\n\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB)\n\t\t{\n\t\t\treturn image;\n\t\t}\n\t\tfinal int w = image.getWidth();\n\t\tfinal int h = image.getHeight();\n\t\tfinal int[] pixels = image.getRGB(0, 0, w, h, null, 0, w);\n\t\tfinal BufferedImage normalized = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);\n\t\tfinal int[] dst = ((DataBufferInt) normalized.getRaster().getDataBuffer()).getData();\n\t\tSystem.arraycopy(pixels, 0, dst, 0, pixels.length);\n\t\treturn normalized;\n\t}\n\n'''
s = s.replace(anchor, anchor + helper, 1)
if 'canvas.getGraphics().drawImage(image, 0, 0, null);' in s:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL headless normalization Graphics2D survived")
if s == orig:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL no PlatformImage mutation")
platform_image.write_text(s, encoding="utf-8", newline="\n")

# ---------------------------------------------------------------------------
# 2) Canonical current-frontbuffer transport binding, production/no probe logs.
# ---------------------------------------------------------------------------
s = libretro.read_text(encoding="utf-8")
orig = s
s = replace_once(s,
    'import org.recompile.mobile.MobilePlatform;\n',
    'import org.recompile.mobile.MobilePlatform;\nimport org.recompile.mobile.PlatformImage;\n',
    'PlatformImage import')
s = replace_once(s,
'''\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n''',
'''\t\t\t\t\t\t\t\trg35xxRequestCurrentFrame();\n''',
    'normal frame request')
s = replace_once(s,
'''\t\t\t\t\t\t\t\t\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, lcdData,\n\t\t\t\t\t\t\t\t\t\t\tMobile.getPlatform().getLcdFrontbuffer());\n''',
'''\t\t\t\t\t\t\t\t\t\trg35xxSendCurrentControlFrame();\n''',
    'control frame request')

# VC7R2 helper is already present here. Rebind even when size did not change,
# because MobilePlatform.load() may recreate the frontbuffer at the same WxH.
keep_old = '''\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " keep " + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t}\n\n'''
keep_new = '''\t\telse\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R2-VIEW: " + phase + " keep " + lcdWidth + "x" + lcdHeight);\n\t\t}\n\t\trg35xxRebindCurrentFrontbuffer();\n\t}\n\n'''
s = replace_once(s, keep_old, keep_new, 'same-size rebind')
helper_anchor = '\tprivate void settingsChanged()\n\t{\n'
if s.count(helper_anchor) != 1:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL settingsChanged anchor")
helpers = '''\tprivate void rg35xxRebindCurrentFrontbuffer()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front != null) lcdData = front.getDataBuffer();\n\t}\n\n\tprivate void rg35xxRequestCurrentFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tlcdData = current;\n\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n\tprivate void rg35xxSendCurrentControlFrame()\n\t{\n\t\tPlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();\n\t\tif(front == null) return;\n\t\tint[] current = front.getDataBuffer();\n\t\tlcdData = current;\n\t\trg35xxFrames.sendControlFrame(lcdWidth, lcdHeight, current, front);\n\t}\n\n'''
s = s.replace(helper_anchor, helpers + helper_anchor, 1)
if 'requestFrame(lcdWidth, lcdHeight, lcdData' in s or 'sendControlFrame(lcdWidth, lcdHeight, lcdData' in s:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL stale framebuffer transport survived")
if s == orig:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL no Libretro mutation")
libretro.write_text(s, encoding="utf-8", newline="\n")

# ---------------------------------------------------------------------------
# 3) LCD mask gate. No VC7R14 counter dependency and no per-frame logs.
# ---------------------------------------------------------------------------
s = platform_graphics.read_text(encoding="utf-8")
orig = s
s = replace_once(s,
    'fastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;',
    'fastBlit = (!Mobile.renderLCDMask || Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;',
    'fastBlit LCD mask gate')
s = replace_once(s,
    'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & Mobile.lcdMaskColors[Mobile.maskIndex]; //(Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);',
    'canvasData[destRowIndex + i] = image.getDataBuffer()[srcRowIndex + i] & (Mobile.renderLCDMask ? Mobile.lcdMaskColors[Mobile.maskIndex] : 0xFFFFFFFF);',
    'slow LCD mask gate')
if s == orig:
    raise SystemExit("FROM_ZERO GRAPHICS FAIL no PlatformGraphics mutation")
platform_graphics.write_text(s, encoding="utf-8", newline="\n")

print("FROM_ZERO_PROVEN_GRAPHICS=PASS")
print("HEADLESS_IMAGE_NORMALIZE=GETRGB_NO_GRAPHICS2D")
print("FRAME_TRANSPORT_BINDING=CURRENT_FRONTBUFFER")
print("LCD_MASK=GATED_BY_RENDERLCDMASK")
print("DIAGNOSTIC_PROBES=NOT_ADMITTED")
