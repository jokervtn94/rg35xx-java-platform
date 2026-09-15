#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformImage.java')
s = p.read_text()

# Device evidence: blank PlatformImage constructor is the next first failing
# boundary because BufferedImage initializes GNU Classpath GtkToolkit.
field = 'protected int[] dataBuffer;'
replacement = '''protected int[] dataBuffer;\n\n\t// M1.9B allocation-only probe metadata. Used only when the RG35XX\n\t// headless experiment is enabled; normal FreeJ2ME behavior is unchanged.\n\tprivate int rg35xxWidth = 0;\n\tprivate int rg35xxHeight = 0;'''
if s.count(field) != 1:
    raise SystemExit('M1_9B_PATCH=FAIL_FIELD_ANCHOR')
s = s.replace(field, replacement, 1)

getter_anchor = '\tpublic int[] getDataBuffer() { return dataBuffer; }'
getter_replacement = '''\tpublic int[] getDataBuffer() { return dataBuffer; }\n\n\t// M1.9C constructor probe only. Normal images keep these at zero.\n\tpublic int getRG35XXWidth() { return rg35xxWidth; }\n\tpublic int getRG35XXHeight() { return rg35xxHeight; }'''
if s.count(getter_anchor) != 1:
    raise SystemExit('M1_9C_PATCH=FAIL_GETTER_ANCHOR')
s = s.replace(getter_anchor, getter_replacement, 1)

old = '''\tpublic PlatformImage(int Width, int Height)\n\t{\n\t\t// Create blank Image\n\t\tif(Mobile.noAlphaOnBlankImages) { canvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_RGB); }\n\t\telse { canvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_ARGB); }\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\t\t\n\t\tArrays.fill(dataBuffer, 0xFFFFFFFF);\n\n\t\tisMutable = true;\n\t}'''
new = '''\tpublic PlatformImage(int Width, int Height)\n\t{\n\t\t// M1.9B PRIMARY VARIABLE: allocation-only headless probe.\n\t\t// Do not construct BufferedImage/Toolkit on RG35XX. This deliberately\n\t\t// does NOT claim rendering support; PlatformGraphics remains untouched.\n\t\tif (Boolean.getBoolean("rg35xx.headless.image.probe"))\n\t\t{\n\t\t\trg35xxWidth = Width;\n\t\t\trg35xxHeight = Height;\n\t\t\tdataBuffer = new int[Width * Height];\n\t\t\tArrays.fill(dataBuffer, 0xFFFFFFFF);\n\t\t\tisMutable = true;\n\t\t\treturn;\n\t\t}\n\n\t\t// Create blank Image\n\t\tif(Mobile.noAlphaOnBlankImages) { canvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_RGB); }\n\t\telse { canvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_ARGB); }\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\t\t\n\t\tArrays.fill(dataBuffer, 0xFFFFFFFF);\n\n\t\tisMutable = true;\n\t}'''
if s.count(old) != 1:
    raise SystemExit('M1_9B_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s = s.replace(old, new, 1)

p.write_text(s)
print('M1_9B_HEADLESS_PLATFORMIMAGE_PROBE_PATCH=PASS')
print('M1_9C_PLATFORMIMAGE_DIMENSION_ACCESS=PASS')
