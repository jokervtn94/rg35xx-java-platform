#!/usr/bin/env python3
"""R2A: GNU Classpath-safe decoded image normalization.

Apply only after Clean Consolidated R1 assembly.
Keeps ImageIO and the PNG iCCP sanitizer, but removes the post-decode
Graphics2D normalization path that can silently produce black image data on
RG35XX/GNU Classpath.
"""
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: r2_apply_headless_image_normalize.py <PlatformImage.java>")

p=Path(sys.argv[1])
s=p.read_text(encoding="utf-8")
orig=s

if "RG35XX-R2A-IMAGE-NORMALIZE" in s:
    raise SystemExit("R2A IMAGE FAIL: patch already present")

old_resource='''			if(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }
			else 
			{
				canvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);
				canvas.getGraphics().drawImage(image, 0, 0, null);
			}
'''
old_plain='''		if(image.getType() == BufferedImage.TYPE_INT_ARGB || image.getType() == BufferedImage.TYPE_INT_RGB) { canvas = image; }
		else 
		{
			canvas = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);
			canvas.getGraphics().drawImage(image, 0, 0, null);
		}
'''

count=s.count(old_resource)+s.count(old_plain)
if count != 3:
    raise SystemExit("R2A IMAGE FAIL: normalization anchor count=%d expected=3" % count)

s=s.replace(old_resource, "\t\t\tcanvas = rg35xxR2ANormalizeDecodedImage(image);\n")
s=s.replace(old_plain, "\t\tcanvas = rg35xxR2ANormalizeDecodedImage(image);\n")

anchor="\tpublic PlatformImage() { }\n"
if s.count(anchor) != 1:
    raise SystemExit("R2A IMAGE FAIL: helper anchor count=%d" % s.count(anchor))

helper=r'''
	/*
	 * RG35XX-R2A-IMAGE-NORMALIZE
	 *
	 * Miyoo can safely let its modern JDK Graphics2D normalize arbitrary
	 * decoded BufferedImages. RG35XX runs JamVM/GNU Classpath, where historical
	 * device evidence showed decoded images becoming opaque black during that
	 * Graphics2D conversion. Read ARGB through BufferedImage.getRGB instead and
	 * copy directly into a TYPE_INT_ARGB DataBufferInt.
	 */
	private static int rg35xxR2AImageNormalizeSeq = 0;

	private static BufferedImage rg35xxR2ANormalizeDecodedImage(BufferedImage image)
	{
		if(image == null) return null;
		final int type = image.getType();
		if(type == BufferedImage.TYPE_INT_ARGB || type == BufferedImage.TYPE_INT_RGB)
		{
			return image;
		}

		final int w = image.getWidth();
		final int h = image.getHeight();
		if(w <= 0 || h <= 0) return image;

		final int[] pixels = image.getRGB(0, 0, w, h, null, 0, w);
		final BufferedImage normalized = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);
		final int[] dst = ((DataBufferInt) normalized.getRaster().getDataBuffer()).getData();
		System.arraycopy(pixels, 0, dst, 0, pixels.length);

		rg35xxR2AImageNormalizeSeq++;
		if(rg35xxR2AImageNormalizeSeq <= 24)
		{
			final int first = pixels.length > 0 ? pixels[0] : 0;
			final int mid = pixels.length > 0 ? pixels[pixels.length / 2] : 0;
			final int last = pixels.length > 0 ? pixels[pixels.length - 1] : 0;
			System.err.println("RG35XX-R2A-IMAGE-NORMALIZE seq=" + rg35xxR2AImageNormalizeSeq
				+ " size=" + w + "x" + h + " sourceType=" + type
				+ " first=" + Integer.toHexString(first)
				+ " mid=" + Integer.toHexString(mid)
				+ " last=" + Integer.toHexString(last));
		}
		return normalized;
	}

'''
s=s.replace(anchor,helper+anchor,1)

if s.count("rg35xxR2ANormalizeDecodedImage(image);") != 3:
    raise SystemExit("R2A IMAGE FAIL: normalize call count mismatch")
if "canvas.getGraphics().drawImage(image, 0, 0, null);" in s:
    raise SystemExit("R2A IMAGE FAIL: Graphics2D decoded-image normalization survived")
for tok in (
    "RG35XX-R2A-IMAGE-NORMALIZE",
    "image.getRGB(0, 0, w, h, null, 0, w)",
    "System.arraycopy(pixels, 0, dst, 0, pixels.length)",
    "rg35xxR2AImageNormalizeSeq <= 24",
):
    if tok not in s:
        raise SystemExit("R2A IMAGE FAIL: missing token "+tok)

# R1 PNG sanitizer must still own the three decode boundaries.
if s.count("ImageIO.read(rg35xxPngIccpCompat(stream))") != 3:
    raise SystemExit("R2A IMAGE FAIL: PNG iCCP decode boundary changed")
if "ImageIO.read(stream)" in s:
    raise SystemExit("R2A IMAGE FAIL: unguarded ImageIO boundary reappeared")

if s==orig:
    raise SystemExit("R2A IMAGE FAIL: no mutation")

p.write_text(s,encoding="utf-8",newline="\n")
print("R2A_IMAGE_NORMALIZATION_PATCH=PASS")
print("OWNER=PlatformImage")
print("DECODE=ImageIO_PLUS_R1_PNG_ICCP")
print("NORMALIZE=BufferedImage_getRGB_DIRECT_DATABUFFER")
print("GRAPHICS2D_NORMALIZE=DISABLED")
print("DIAGNOSTIC_POLICY=FIRST_24_CONVERSIONS_ONLY")
