#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r10_apply_headless_image_normalize.py <PlatformImage.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text()

old = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\t\telse \n\t\t\t{\n\t\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t\t}\n'''
old2 = '''\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }\n\t\telse \n\t\t{\n\t\t\tcanvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);\n\t\t\tcanvas.getGraphics().drawImage(image, 0, 0, null);\n\t\t}\n'''
replacement = '''\t\tcanvas = rg35xxNormalizeDecodedImage(image);\n'''

n = s.count(old) + s.count(old2)
if n != 3:
    raise SystemExit('VC7R10 image normalization anchor count=%d expected=3' % n)
s = s.replace(old, replacement).replace(old2, replacement)

# Add imports for a dedicated checkpoint-specific log. This avoids depending on
# the native stderr redirect name from VC7R9.
import_anchor = 'import java.io.File;\n'
if s.count(import_anchor) != 1:
    raise SystemExit('VC7R10 import anchor count=%d' % s.count(import_anchor))
s = s.replace(import_anchor, import_anchor + 'import java.io.FileOutputStream;\nimport java.io.PrintStream;\n', 1)

anchor = '\tpublic PlatformImage() { }\n\n'
if s.count(anchor) != 1:
    raise SystemExit('VC7R10 helper anchor count=%d' % s.count(anchor))
helper = '''\tprivate static final String RG35XX_VC7R10_LOG = "/mnt/mmc/freej2me-vc7r10-java.log";\n\n\tprivate static void rg35xxVC7R10Log(String message)\n\t{\n\t\tPrintStream ps = null;\n\t\ttry\n\t\t{\n\t\t\tps = new PrintStream(new FileOutputStream(RG35XX_VC7R10_LOG, true));\n\t\t\tps.println(message);\n\t\t\tps.flush();\n\t\t}\n\t\tcatch(Throwable ignored)\n\t\t{\n\t\t\tSystem.err.println(message);\n\t\t}\n\t\tfinally\n\t\t{\n\t\t\tif(ps != null) { try { ps.close(); } catch(Throwable ignored) { } }\n\t\t}\n\t}\n\n\tprivate static BufferedImage rg35xxNormalizeDecodedImage(BufferedImage image)\n\t{\n\t\tif(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB)\n\t\t{\n\t\t\trg35xxVC7R10Log("RG35XX-VC7R10-IMAGE-NORMALIZE: passthrough " + image.getWidth() + "x" + image.getHeight() + " sourceType=" + image.getType());\n\t\t\treturn image;\n\t\t}\n\n\t\t/*\n\t\t * RG35XX/VC7R10: GNU Classpath headless Graphics2D cannot be trusted for\n\t\t * decoded-image normalization. The previous conversion allocated an ARGB\n\t\t * BufferedImage and called canvas.getGraphics().drawImage(...). VC7R9 device\n\t\t * evidence shows major decoded images reaching drawImage as uniform opaque\n\t\t * black. Convert through BufferedImage.getRGB instead, which reads the source\n\t\t * ColorModel/Raster directly and never enters Graphics2D.\n\t\t */\n\t\tfinal int w = image.getWidth();\n\t\tfinal int h = image.getHeight();\n\t\tfinal int[] pixels = image.getRGB(0, 0, w, h, null, 0, w);\n\t\tfinal BufferedImage normalized = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);\n\t\tfinal int[] dst = ((DataBufferInt) normalized.getRaster().getDataBuffer()).getData();\n\t\tSystem.arraycopy(pixels, 0, dst, 0, pixels.length);\n\t\tint first = pixels.length > 0 ? pixels[0] : 0;\n\t\tint mid = pixels.length > 0 ? pixels[pixels.length / 2] : 0;\n\t\tint last = pixels.length > 0 ? pixels[pixels.length - 1] : 0;\n\t\trg35xxVC7R10Log("RG35XX-VC7R10-IMAGE-NORMALIZE: direct-getRGB " + w + "x" + h + " sourceType=" + image.getType() + " first=" + Integer.toHexString(first) + " mid=" + Integer.toHexString(mid) + " last=" + Integer.toHexString(last));\n\t\treturn normalized;\n\t}\n\n'''
s = s.replace(anchor, anchor + helper, 1)

if 'canvas.getGraphics().drawImage(image, 0, 0, null);' in s:
    raise SystemExit('VC7R10 forbidden decoded-image Graphics2D conversion remains')
if s.count('rg35xxNormalizeDecodedImage(image);') != 3:
    raise SystemExit('VC7R10 normalized call count mismatch')
for required in ('RG35XX-VC7R10-IMAGE-NORMALIZE', '/mnt/mmc/freej2me-vc7r10-java.log', 'image.getRGB(0, 0, w, h, null, 0, w)'):
    if required not in s:
        raise SystemExit('VC7R10 required marker missing: '+required)

p.write_text(s, newline='\n')
print('VC7R10_PLATFORMIMAGE_PATCH=PASS')
print('VC7R10_DECODED_IMAGE_CONVERSION=BUFFEREDIMAGE_GETRGB_NO_GRAPHICS2D')
print('VC7R10_JAVA_LOG=/mnt/mmc/freej2me-vc7r10-java.log')
