#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformImage.java')
s = p.read_text()

old = '''\tpublic PlatformImage(Image source)\n\t{\n\t\t// Create a copy from an LCDUI Image\n\t\tif(source == null) { throw new NullPointerException("Can't load image, it is null."); }\n\n\t\t// It's safe to assume that the source image will have the same type as the destination, so instead of drawImage we can just arraycopy the source to the destination\n\t\tcanvas = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\t\tfinal int[] tempData = ((DataBufferInt) source.getCanvas().getRaster().getDataBuffer()).getData();\n\t\t\n\t\tSystem.arraycopy(tempData, 0, dataBuffer, 0, tempData.length);\n\t}'''

new = '''\tpublic PlatformImage(Image source)\n\t{\n\t\t// Create a copy from an LCDUI Image\n\t\tif(source == null) { throw new NullPointerException("Can't load image, it is null."); }\n\n\t\t// M1.16-r1.4 PRIMARY VARIABLE: headless LCDUI Image copy only.\n\t\t// The locked r1.2 dimension fallback allows source dimensions without AWT.\n\t\t// Copy the existing PlatformImage int[] backing directly and deliberately\n\t\t// avoid BufferedImage/Toolkit on RG35XX. Normal upstream behavior remains.\n\t\tif (Boolean.getBoolean("rg35xx.headless.image.probe"))\n\t\t{\n\t\t\trg35xxWidth = source.getWidth();\n\t\t\trg35xxHeight = source.getHeight();\n\t\t\tdataBuffer = new int[rg35xxWidth * rg35xxHeight];\n\t\t\tfinal int[] tempData = source.getDataBuffer();\n\t\t\tif (tempData == null || tempData.length < dataBuffer.length)\n\t\t\t{\n\t\t\t\tthrow new IllegalStateException("Headless source image has no complete pixel backing");\n\t\t\t}\n\t\t\tSystem.arraycopy(tempData, 0, dataBuffer, 0, dataBuffer.length);\n\t\t\tisMutable = false;\n\t\t\treturn;\n\t\t}\n\n\t\t// It's safe to assume that the source image will have the same type as the destination, so instead of drawImage we can just arraycopy the source to the destination\n\t\tcanvas = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\t\tfinal int[] tempData = ((DataBufferInt) source.getCanvas().getRaster().getDataBuffer()).getData();\n\t\t\n\t\tSystem.arraycopy(tempData, 0, dataBuffer, 0, tempData.length);\n\t}'''

if s.count(old) != 1:
    raise SystemExit('M1_16_R14_COPY_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_16_R14_PLATFORMIMAGE_COPY_HEADLESS_PATCH=PASS')
print('M1_16_R14_PRIMARY_VARIABLE=PLATFORMIMAGE_LCDUI_COPY_HEADLESS_ONLY')
