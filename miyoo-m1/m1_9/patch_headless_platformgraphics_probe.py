#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s = p.read_text()

old = '''\tpublic PlatformGraphics(PlatformImage image)\n\t{\n\t\tthis.baseImage = image;\n\t\tcanvas = image.getCanvas();\n\t\tgc = canvas.createGraphics();\n\n\t\tcanvasWidth = canvas.getWidth();\n\t\tcanvasHeight = canvas.getHeight();\n\n\t\tcanvasData = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\t// This command is always required for MascotCapsuleV3 command lists, and DoJa does not initialize it.\n\t\tmcv3commands.add(Graphics3D.COMMAND_LIST_VERSION_1_0);\n\n\t\tsetClip(0, 0, canvasWidth, canvasHeight);\n\t\tgc.setFont(font.awtFont);\n\t\tsetColor(color);\n\n\t\tgc.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);\n\t}'''

new = '''\tpublic PlatformGraphics(PlatformImage image)\n\t{\n\t\tthis.baseImage = image;\n\n\t\t// M1.9C PRIMARY VARIABLE: constructor-only headless probe.\n\t\t// Reuse the M1.9B int[] backing store and deliberately avoid\n\t\t// BufferedImage.createGraphics()/Graphics2D/Toolkit. Rendering methods\n\t\t// remain untouched and are NOT accepted by this checkpoint.\n\t\tif (Boolean.getBoolean("rg35xx.headless.graphics.probe"))\n\t\t{\n\t\t\tcanvas = null;\n\t\t\tgc = null;\n\t\t\tcanvasData = image.getDataBuffer();\n\t\t\tcanvasWidth = image.getRG35XXWidth();\n\t\t\tcanvasHeight = image.getRG35XXHeight();\n\t\t\tmcv3commands.add(Graphics3D.COMMAND_LIST_VERSION_1_0);\n\t\t\tclipX = 0; clipY = 0; clipWidth = canvasWidth; clipHeight = canvasHeight;\n\t\t\treturn;\n\t\t}\n\n\t\tcanvas = image.getCanvas();\n\t\tgc = canvas.createGraphics();\n\n\t\tcanvasWidth = canvas.getWidth();\n\t\tcanvasHeight = canvas.getHeight();\n\n\t\tcanvasData = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\t// This command is always required for MascotCapsuleV3 command lists, and DoJa does not initialize it.\n\t\tmcv3commands.add(Graphics3D.COMMAND_LIST_VERSION_1_0);\n\n\t\tsetClip(0, 0, canvasWidth, canvasHeight);\n\t\tgc.setFont(font.awtFont);\n\t\tsetColor(color);\n\n\t\tgc.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);\n\t}'''

if s.count(old) != 1:
    raise SystemExit('M1_9C_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_9C_HEADLESS_PLATFORMGRAPHICS_PROBE_PATCH=PASS')
