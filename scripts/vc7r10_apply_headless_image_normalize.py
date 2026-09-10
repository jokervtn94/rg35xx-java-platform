#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r10_apply_headless_image_normalize.py <PlatformImage.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text()

old = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\t\telse \n\t\t\t{\n\t\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t\t}\n'''

# Some constructors use one less indentation level in the pinned source.
old2 = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\telse \n\t\t{\n\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t}\n'''

replacement = '''\t\tcanvas = rg35xxNormalizeDecodedImage(image);\n'''

n = s.count(old) + s.count(old2)
if n != 3:
    raise SystemExit('VC7R10 image normalization anchor count=%d expected=3' % n)
s = s.replace(old, replacement).replace(old2, replacement)

anchor = '\tpublic PlatformImage() { }\n\n'
if s.count(anchor) != 1:
    raise SystemExit('VC7R10 helper anchor count=%d' % s.count(anchor))
helper = '''\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)\n\t{\n\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB)\n\t\t{\n\t\t\treturn image;\n\t\t}\n\n\t\t/*\n\t\t * RG35XX/VC7R10: GNU Classpath headless Graphics2D cannot be trusted for\n\t\t * decoded-image normalization.  The old conversion allocated TYPE_INT_ARGB\n\t\t * and then called canvas.getGraphics().drawImage(...), which can silently\n\t\t * produce an all-black destination on the target.  Convert through\n\t\t * BufferedImage.getRGB instead; this uses the decoded image ColorModel/Raster\n\t\t * directly and never enters the Graphics2D rasterizer.\n\t\t */\n\t\tfinal int w = image.getWidth();\n\t\tfinal int h = image.getHeight();\n\t\tfinal int[] pixels = image.getRGB(0, 0, w, h, null, 0, w);\n\t\tfinal BufferedImage normalized = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);\n\t\tfinal int[] dst = ((DataBufferInt) normalized.getRaster().getDataBuffer()).getData();\n\t\tSystem.arraycopy(pixels, 0, dst, 0, pixels.length);\n\t\tSystem.err.println("RG35XX-VC7R10-IMAGE-NORMALIZE: direct getRGB " + w + "x" + h + " sourceType=" + image.getType());\n\t\treturn normalized;\n\t}\n\n'''
s = s.replace(anchor, anchor + helper, 1)

# Fail closed: the three decoded-image conversion sites must no longer use AWT drawImage.
if 'canvas.getGraphics().drawImage(image, 0, 0, null);' in s:
    raise SystemExit('VC7R10 forbidden decoded-image Graphics2D conversion remains')
if s.count('rg35xxNormalizeDecodedImage(image);') != 3:
    raise SystemExit('VC7R10 normalized call count mismatch')
if 'RG35XX-VC7R10-IMAGE-NORMALIZE' not in s:
    raise SystemExit('VC7R10 marker missing')

p.write_text(s, newline='\n')
print('VC7R10_PLATFORMIMAGE_PATCH=PASS')
print('VC7R10_DECODED_IMAGE_CONVERSION=BUFFEREDIMAGE_GETRGB_NO_GRAPHICS2D')
