#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformImage.java')
s = p.read_text()

old = '''\tpublic void getRGB(int[] rgbData, int offset, int scanlength, int x, int y, int width, int height) \n\t{\n\t\tif (width <= 0 || height <= 0) { return; } // No pixels to copy\n\n\t\tif (rgbData == null) { throw new NullPointerException("Can't use getRGB, as the returned image is null."); }\n\t\tif (x < 0 || y < 0 || x + width > canvas.getWidth() || y + height > canvas.getHeight()) \n\t\t{\n\t\t\tthrow new IllegalArgumentException("getRGB Requested area exceeds bounds of the image");\n\t\t}\n\t\tif (Math.abs(scanlength) < width) \n\t\t{\n\t\t\tthrow new IllegalArgumentException("scanlength must be >= width");\n\t\t}\n\n\t\t// Copy the data into rgbData, taking scanlength into account\n\t\tfor (int row = 0; row < height; row++) \n\t\t{\n\t\t\tint sourceIndex = (y + row) * canvas.getWidth() + x;\n\t\t\tint destIndex = offset + row * scanlength;\n\t\n\t\t\tSystem.arraycopy(dataBuffer, sourceIndex, rgbData, destIndex, width);\n\t\t}\n\t}'''

new = '''\tpublic void getRGB(int[] rgbData, int offset, int scanlength, int x, int y, int width, int height) \n\t{\n\t\tif (width <= 0 || height <= 0) { return; } // No pixels to copy\n\n\t\tif (rgbData == null) { throw new NullPointerException("Can't use getRGB, as the returned image is null."); }\n\n\t\t// DP-R4 PRIMARY VARIABLE: headless getRGB backing only.\n\t\t// Preserve normal AWT behavior when canvas exists; otherwise use the\n\t\t// already device-proven headless dimensions plus int[] pixel backing.\n\t\tint imageWidth;\n\t\tint imageHeight;\n\t\tif (canvas != null)\n\t\t{\n\t\t\timageWidth = canvas.getWidth();\n\t\t\timageHeight = canvas.getHeight();\n\t\t}\n\t\telse if (Boolean.getBoolean("rg35xx.headless.image.probe"))\n\t\t{\n\t\t\timageWidth = rg35xxWidth;\n\t\t\timageHeight = rg35xxHeight;\n\t\t\tif (dataBuffer == null || dataBuffer.length < imageWidth * imageHeight)\n\t\t\t\t{ throw new IllegalStateException("Headless image has no complete pixel backing"); }\n\t\t}\n\t\telse\n\t\t{\n\t\t\tthrow new IllegalStateException("PlatformImage has no backing canvas");\n\t\t}\n\n\t\tif (x < 0 || y < 0 || x + width > imageWidth || y + height > imageHeight) \n\t\t{\n\t\t\tthrow new IllegalArgumentException("getRGB Requested area exceeds bounds of the image");\n\t\t}\n\t\tif (Math.abs(scanlength) < width) \n\t\t{\n\t\t\tthrow new IllegalArgumentException("scanlength must be >= width");\n\t\t}\n\n\t\tfor (int row = 0; row < height; row++) \n\t\t{\n\t\t\tint sourceIndex = (y + row) * imageWidth + x;\n\t\t\tint destIndex = offset + row * scanlength;\n\t\t\tSystem.arraycopy(dataBuffer, sourceIndex, rgbData, destIndex, width);\n\t\t}\n\t}'''

if s.count(old) != 1:
    raise SystemExit('DP_R4_GETRGB_PATCH=FAIL_ANCHOR')

p.write_text(s.replace(old, new, 1))
print('DP_R4_PLATFORMIMAGE_GETRGB_HEADLESS_PATCH=PASS')
print('DP_R4_PRIMARY_VARIABLE=PLATFORMIMAGE_GETRGB_HEADLESS_ONLY')
