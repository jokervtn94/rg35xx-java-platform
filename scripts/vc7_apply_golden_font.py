#!/usr/bin/env python3
"""Apply the VC7 Golden bitmap text path to PlatformGraphics.java.

This overlay is intentionally narrow: it replaces only the final Java2D text raster
call in PlatformGraphics.drawStringSingleLine while preserving the pinned upstream
anchor/baseline calculation. Glyph pixels are written directly to canvasData using
the recovered Golden resource contract.
"""

import io
import os
import sys

MARKER = "RG35XX-VC7-FONT: Golden Unicode bitmap renderer"
IMPORT_ANCHOR = "import java.util.ArrayList;\n"
CTOR_ANCHOR = "\tpublic PlatformGraphics(PlatformImage image)\n"
DRAW_ANCHOR = "\t\t\tgc.drawString(str, x, y);\n"

BLOCK = r'''
	// RG35XX VC7 Golden Unicode bitmap renderer.
	// Resource and geometry are recovered from the device-proven Golden runtime.
	private static final String RG35XX_VC7_FONT_MARKER = "RG35XX-VC7-FONT: Golden Unicode bitmap renderer";
	private static final String RG35XX_FONT_RESOURCE = "/org/recompile/mobile/rg35xx-font.bin";
	private static final int RG35XX_FONT_BYTES = 727008;
	private static final int RG35XX_GLYPH_BYTES = 32;
	private static final int RG35XX_GLYPH_COUNT = 22719;
	private static final int[] rg35xxFontRangeStart = {
		0x0020, 0x00A0, 0x0370, 0x0400, 0x1E00,
		0x3000, 0x3040, 0x30A0, 0x4E00, 0xFF00
	};
	private static final int[] rg35xxFontRangeEnd = {
		0x007E, 0x024F, 0x03FF, 0x052F, 0x1EFF,
		0x303F, 0x309F, 0x30FF, 0x9FFF, 0xFFEF
	};
	private static final int[] rg35xxFontRangeOffset = {
		0, 95, 527, 671, 975, 1231, 1295, 1391, 1487, 22479
	};
	private static boolean rg35xxFontLoadTried = false;
	private static byte[] rg35xxBitmapFont = null;

	private boolean rg35xxAsciiSafeString(String str)
	{
		if(str == null) { return true; }
		for(int i = 0; i < str.length(); i++)
		{
			char c = str.charAt(i);
			if(c < 0x20 || c > 0x7E) { return false; }
		}
		return true;
	}

	private static synchronized void rg35xxEnsureBitmapFont()
	{
		if(rg35xxFontLoadTried) { return; }
		rg35xxFontLoadTried = true;
		java.io.InputStream in = null;
		try
		{
			in = PlatformGraphics.class.getResourceAsStream(RG35XX_FONT_RESOURCE);
			if(in == null)
			{
				System.err.println("RG35XX-VC7-FONT: resource missing " + RG35XX_FONT_RESOURCE);
				return;
			}
			byte[] data = new byte[RG35XX_FONT_BYTES];
			int used = 0;
			while(used < data.length)
			{
				int n = in.read(data, used, data.length - used);
				if(n < 0) { break; }
				if(n == 0) { continue; }
				used += n;
			}
			if(used != data.length)
			{
				System.err.println("RG35XX-VC7-FONT: short resource read bytes=" + used + " expected=" + data.length);
				return;
			}
			rg35xxBitmapFont = data;
			System.err.println("RG35XX-VC7-FONT: ready bytes=" + data.length);
		}
		catch(Throwable t)
		{
			System.err.println("RG35XX-VC7-FONT: resource load failed " + t);
		}
		finally
		{
			if(in != null)
			{
				try { in.close(); } catch(Throwable ignored) { }
			}
		}
	}

	private static int rg35xxGlyphIndex(char ch)
	{
		int c = ch;
		for(int i = 0; i < rg35xxFontRangeStart.length; i++)
		{
			if(c >= rg35xxFontRangeStart[i] && c <= rg35xxFontRangeEnd[i])
			{
				int index = rg35xxFontRangeOffset[i] + c - rg35xxFontRangeStart[i];
				if(index >= 0 && index < RG35XX_GLYPH_COUNT) { return index; }
				return 31;
			}
		}
		return 31; // Golden '?' record: U+003F - U+0020
	}

	private static boolean rg35xxWideChar(char ch)
	{
		int c = ch;
		return (c >= 0x3000 && c <= 0x30FF) ||
			(c >= 0x4E00 && c <= 0x9FFF) ||
			(c >= 0xFF00 && c <= 0xFFEF);
	}

	private int rg35xxBitmapScale()
	{
		int h = Mobile.isDoJa ? dojaFont.getHeight() : font.getHeight();
		return h >= 26 ? 2 : 1;
	}

	private int rg35xxBitmapWidth(String str, int scale)
	{
		if(str == null || str.length() == 0) { return 0; }
		int width = 0;
		for(int i = 0; i < str.length(); i++)
		{
			width += (rg35xxWideChar(str.charAt(i)) ? 12 : 8) * scale;
		}
		return width;
	}

	private void rg35xxPlotBlock(int x, int y, int scale, int rgb,
		int minX, int minY, int maxX, int maxY)
	{
		for(int dy = 0; dy < scale; dy++)
		{
			int py = y + dy;
			if(py < minY || py >= maxY || py < 0 || py >= canvasHeight) { continue; }
			for(int dx = 0; dx < scale; dx++)
			{
				int px = x + dx;
				if(px < minX || px >= maxX || px < 0 || px >= canvasWidth) { continue; }
				canvasData[(py * canvasWidth) + px] = rgb;
			}
		}
	}

	private void rg35xxDrawFallbackQuestion(int x, int y, int scale, int rgb,
		int minX, int minY, int maxX, int maxY)
	{
		final int[] rows = { 0x0E, 0x11, 0x01, 0x02, 0x04, 0x00, 0x04 };
		for(int row = 0; row < rows.length; row++)
		{
			int bits = rows[row];
			for(int col = 0; col < 5; col++)
			{
				if((bits & (1 << (4 - col))) != 0)
				{
					rg35xxPlotBlock(x + col * scale, y + row * scale, scale, rgb,
						minX, minY, maxX, maxY);
				}
			}
		}
	}

	private void rg35xxDrawBitmapString(String str, int x, int y, int scale)
	{
		rg35xxEnsureBitmapFont();

		int penX = x + translateX;
		int topY = y + translateY;
		int minX = Math.max(0, getClipX() + translateX);
		int minY = Math.max(0, getClipY() + translateY);
		int maxX = Math.min(canvasWidth, getClipX() + translateX + getClipWidth());
		int maxY = Math.min(canvasHeight, getClipY() + translateY + getClipHeight());
		int rgb = 0xFF000000 | (getColor() & 0x00FFFFFF);

		for(int i = 0; i < str.length(); i++)
		{
			char ch = str.charAt(i);
			int sourceWidth = rg35xxWideChar(ch) ? 12 : 8;
			int glyph = rg35xxGlyphIndex(ch);

			if(rg35xxBitmapFont == null || glyph < 0 || glyph >= RG35XX_GLYPH_COUNT)
			{
				rg35xxDrawFallbackQuestion(penX, topY, scale, rgb, minX, minY, maxX, maxY);
				penX += sourceWidth * scale;
				continue;
			}

			int base = glyph * RG35XX_GLYPH_BYTES;
			for(int row = 0; row < 16; row++)
			{
				int off = base + row * 2;
				int mask = ((rg35xxBitmapFont[off] & 0xFF) << 8) |
					(rg35xxBitmapFont[off + 1] & 0xFF);
				for(int col = 0; col < sourceWidth; col++)
				{
					if((mask & (1 << (15 - col))) != 0)
					{
						rg35xxPlotBlock(penX + col * scale, topY + row * scale,
							scale, rgb, minX, minY, maxX, maxY);
					}
				}
			}
			penX += sourceWidth * scale;
		}
	}

	private void rg35xxDrawSafeText(String str, int anchoredX, int rasterTop, int anchor)
	{
		if(str == null || str.length() == 0) { return; }
		int scale = rg35xxBitmapScale();
		int bitmapWidth = rg35xxBitmapWidth(str, scale);
		int metricWidth = Mobile.isDoJa ? dojaFont.stringWidth(str) : font.stringWidth(str);

		// drawStringSingleLine already applied AnchorX using the MIDP/DoJa metric width.
		// Shift that resolved coordinate to the recovered Golden bitmap advance without
		// changing the pinned upstream vertical anchor/baseline calculation.
		int x = anchoredX;
		if((anchor & Graphics.RIGHT) != 0) { x += metricWidth - bitmapWidth; }
		else if((anchor & Graphics.HCENTER) != 0) { x += (metricWidth - bitmapWidth) / 2; }

		// Keep the recovered helper in the normal path so ASCII and Unicode use one
		// renderer. It intentionally does not hand text back to GNU AWT.
		rg35xxAsciiSafeString(str);
		rg35xxDrawBitmapString(str, x, rasterTop, scale);
	}
'''


def fail(msg):
    sys.stderr.write("VC7 FONT OVERLAY FAIL: %s\n" % msg)
    return 1


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: vc7_apply_golden_font.py <PlatformGraphics.java>\n")
        return 2

    path = argv[1]
    if not os.path.isfile(path):
        return fail("missing source: %s" % path)

    with io.open(path, "r", encoding="utf-8", newline="") as fh:
        text = fh.read()

    nl = "\r\n" if "\r\n" in text else "\n"
    normalized = text.replace("\r\n", "\n")

    if MARKER in normalized:
        return fail("overlay already present")
    if normalized.count(IMPORT_ANCHOR) != 1:
        return fail("unexpected import anchor count")
    if normalized.count(CTOR_ANCHOR) != 1:
        return fail("unexpected constructor anchor count")
    if normalized.count(DRAW_ANCHOR) != 1:
        return fail("expected exactly one final gc.drawString text boundary")

    normalized = normalized.replace(
        IMPORT_ANCHOR,
        IMPORT_ANCHOR + "import java.io.InputStream;\n",
        1,
    )
    normalized = normalized.replace(CTOR_ANCHOR, BLOCK + "\n" + CTOR_ANCHOR, 1)
    normalized = normalized.replace(
        DRAW_ANCHOR,
        "\t\t\trg35xxDrawSafeText(str, x, y - ascent, anchor);\n",
        1,
    )

    required = [
        MARKER,
        "rg35xxEnsureBitmapFont",
        "rg35xxGlyphIndex",
        "rg35xxWideChar",
        "rg35xxBitmapScale",
        "rg35xxBitmapWidth",
        "rg35xxDrawFallbackQuestion",
        "rg35xxDrawBitmapString",
        "rg35xxDrawSafeText",
        "rg35xxDrawSafeText(str, x, y - ascent, anchor);",
    ]
    for token in required:
        if token not in normalized:
            return fail("postcondition missing: %s" % token)
    if DRAW_ANCHOR in normalized:
        return fail("normal Java2D text raster boundary still present")

    output = normalized if nl == "\n" else normalized.replace("\n", "\r\n")
    with io.open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(output)

    sys.stdout.write("VC7 FONT OVERLAY PASS\n")
    sys.stdout.write("SOURCE=%s\n" % os.path.abspath(path))
    sys.stdout.write("TEXT_RASTER=GOLDEN_BITMAP\n")
    sys.stdout.write("AWT_GLYPH_RASTER=NORMAL_PATH_BYPASSED\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
