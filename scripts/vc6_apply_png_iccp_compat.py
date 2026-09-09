#!/usr/bin/env python3
"""VC6 PNG iCCP compatibility overlay.

Scope is deliberately narrow: patch FreeJ2ME PlatformImage source so PNG data is
sanitized at the runtime image boundary before GNU Classpath ImageIO sees it.
Only complete ancillary iCCP chunks are removed. glibj.zip is never modified.
"""
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: vc6_apply_png_iccp_compat.py <PlatformImage.java>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("VC6 PNG ICCP FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)

helper_marker = "\tpublic PlatformImage() { }\n"
helper = r'''
	/*
	 * RG35XX compatibility boundary for GNU Classpath's PNG reader.
	 *
	 * Some J2ME assets carry PNG iCCP profiles whose ICC major version is newer
	 * than the old GNU Classpath color parser accepts. PNG iCCP is ancillary, so
	 * dropping the complete iCCP chunk preserves the encoded pixel stream and
	 * lets the legacy decoder continue. No GNU Classpath classes are patched.
	 */
	private static InputStream rg35xxPngIccpCompat(InputStream input) throws IOException
	{
		if(input == null) { return null; }

		ByteArrayOutputStream rawOut = new ByteArrayOutputStream();
		byte[] temp = new byte[4096];
		int count;
		while((count = input.read(temp)) != -1) { rawOut.write(temp, 0, count); }
		byte[] raw = rawOut.toByteArray();

		if(raw.length < 8 ||
		   (raw[0] & 0xFF) != 0x89 || raw[1] != 0x50 || raw[2] != 0x4E || raw[3] != 0x47 ||
		   raw[4] != 0x0D || raw[5] != 0x0A || raw[6] != 0x1A || raw[7] != 0x0A)
		{
			return new ByteArrayInputStream(raw);
		}

		ByteArrayOutputStream clean = new ByteArrayOutputStream(raw.length);
		clean.write(raw, 0, 8);
		int pos = 8;
		boolean stripped = false;
		while(pos + 12 <= raw.length)
		{
			long chunkLength = ((long)(raw[pos] & 0xFF) << 24) |
			                   ((long)(raw[pos + 1] & 0xFF) << 16) |
			                   ((long)(raw[pos + 2] & 0xFF) << 8) |
			                   (long)(raw[pos + 3] & 0xFF);
			long totalLong = chunkLength + 12L;
			if(totalLong > Integer.MAX_VALUE || totalLong < 12L || pos + totalLong > raw.length)
			{
				return new ByteArrayInputStream(raw);
			}
			int total = (int)totalLong;
			boolean isIccp = raw[pos + 4] == 'i' && raw[pos + 5] == 'C' &&
			                 raw[pos + 6] == 'C' && raw[pos + 7] == 'P';
			if(isIccp) stripped = true;
			else clean.write(raw, pos, total);
			boolean isIend = raw[pos + 4] == 'I' && raw[pos + 5] == 'E' &&
			                 raw[pos + 6] == 'N' && raw[pos + 7] == 'D';
			pos += total;
			if(isIend) break;
		}

		if(!stripped) return new ByteArrayInputStream(raw);
		System.err.println("RG35XX-PNG-ICCP: stripped ancillary iCCP chunk");
		return new ByteArrayInputStream(clean.toByteArray());
	}

'''
once(helper_marker, helper + helper_marker, "helper insertion")

# Resource-name constructor has one extra indentation level and is unique.
once(
    "\t\t\ttry { image = ImageIO.read(stream); } \n",
    "\t\t\ttry { image = ImageIO.read(rg35xxPngIccpCompat(stream)); } \n",
    "resource ImageIO boundary")

# The InputStream and byte-array constructors intentionally have the same
# two-tab source line. Upstream pin 13ec186 must contain exactly two of them.
plain = "\t\ttry { image = ImageIO.read(stream); } \n"
guarded = "\t\ttry { image = ImageIO.read(rg35xxPngIccpCompat(stream)); } \n"
remaining = s.count(plain)
if remaining != 2:
    raise SystemExit("VC6 PNG ICCP FAIL: two-tab ImageIO boundary count=%d" % remaining)
s = s.replace(plain, guarded)

required = (
    "rg35xxPngIccpCompat",
    "RG35XX-PNG-ICCP: stripped ancillary iCCP chunk",
    "raw[pos + 4] == 'i'",
    "clean.write(raw, pos, total)",
)
for token in required:
    if token not in s:
        raise SystemExit("VC6 PNG ICCP FAIL: missing token: " + token)

if s.count("ImageIO.read(rg35xxPngIccpCompat(stream))") != 3:
    raise SystemExit("VC6 PNG ICCP FAIL: not all three image decode boundaries are guarded")
if "ImageIO.read(stream)" in s:
    raise SystemExit("VC6 PNG ICCP FAIL: unguarded ImageIO.read(stream) remains")

for forbidden in (
    "rg35xxStripPngICCP",
    "RG35XX-PNG-COMPAT-V2",
    "PNGChunk.class",
    "ProfileHeader.class",
):
    if forbidden in s:
        raise SystemExit("VC6 PNG ICCP FAIL: forbidden legacy experiment present: " + forbidden)

if s == orig:
    raise SystemExit("VC6 PNG ICCP FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("VC6 PNG ICCP SOURCE PASS:", p)
