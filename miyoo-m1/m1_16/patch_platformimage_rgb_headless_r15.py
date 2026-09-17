#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/PlatformImage.java')
s = p.read_text()
old = '''\tpublic PlatformImage(int[] rgb, int Width, int Height, boolean processAlpha)\n\t{\n\t\t// createRGBImage (Data is ARGB pixel data)\n\t\tcanvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_ARGB);\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\tfor(int j = 0; j < Height; j++) \n\t\t{\n\t\t\tfor(int i = 0; i < Width; i++) \n\t\t\t{\n\t\t\t\tdataBuffer[j*Width + i] = (processAlpha ? rgb[j*Width + i] : rgb[j*Width + i] | 0xFF000000);\n\t\t\t}\n\t\t}\n\t}'''
new = '''\tpublic PlatformImage(int[] rgb, int Width, int Height, boolean processAlpha)\n\t{\n\t\t// createRGBImage (Data is ARGB pixel data)\n\t\t// M1.16-r1.5 PRIMARY VARIABLE: RGB-image headless allocation only.\n\t\t// Avoid BufferedImage/Toolkit on RG35XX while preserving the upstream\n\t\t// per-pixel processAlpha semantics and immutable Image behavior.\n\t\tif (Boolean.getBoolean("rg35xx.headless.image.probe"))\n\t\t{\n\t\t\tif (rgb == null) { throw new NullPointerException("RGB data is null"); }\n\t\t\tif (Width <= 0 || Height <= 0 || rgb.length < Width * Height)\n\t\t\t{\n\t\t\t\tthrow new IllegalArgumentException("Invalid RGB image dimensions/data");\n\t\t\t}\n\t\t\trg35xxWidth = Width;\n\t\t\trg35xxHeight = Height;\n\t\t\tdataBuffer = new int[Width * Height];\n\t\t\tfor(int j = 0; j < Height; j++)\n\t\t\t{\n\t\t\t\tfor(int i = 0; i < Width; i++)\n\t\t\t\t{\n\t\t\t\t\tdataBuffer[j*Width + i] = (processAlpha ? rgb[j*Width + i] : rgb[j*Width + i] | 0xFF000000);\n\t\t\t\t}\n\t\t\t}\n\t\t\tisMutable = false;\n\t\t\treturn;\n\t\t}\n\n\t\tcanvas = new BufferedImage(Width, Height, BufferedImage.TYPE_INT_ARGB);\n\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();\n\n\t\tfor(int j = 0; j < Height; j++) \n\t\t{\n\t\t\tfor(int i = 0; i < Width; i++) \n\t\t\t{\n\t\t\t\tdataBuffer[j*Width + i] = (processAlpha ? rgb[j*Width + i] : rgb[j*Width + i] | 0xFF000000);\n\t\t\t}\n\t\t}\n\t}'''
if s.count(old) != 1:
    raise SystemExit('M1_16_R15_RGB_PATCH=FAIL_CONSTRUCTOR_ANCHOR')
s = s.replace(old, new, 1)
p.write_text(s)
print('M1_16_R15_PLATFORMIMAGE_RGB_HEADLESS_PATCH=PASS')
print('M1_16_R15_PRIMARY_VARIABLE=PLATFORMIMAGE_RGB_HEADLESS_ONLY')
