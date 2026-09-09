#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

needle = 'public PlatformImage(byte[] imageData, int imageOffset, int imageLength, boolean mutable)'
pos = s.find(needle)
if pos < 0:
    raise SystemExit('PNG COMPAT FAIL: pinned PlatformImage byte[] constructor not found')
body = s.find('{', pos)
if body < 0:
    raise SystemExit('PNG COMPAT FAIL: constructor body not found')

# Route only the J2ME byte-array image path through a semantic PNG sanitizer.
# Non-PNG input is copied byte-for-byte. PNG iCCP is ancillary metadata and
# may be omitted when GNU Classpath ImageIO rejects ICC v4.
s = s[:body+1] + '\n\t\timageData = rg35xxStripPngICCP(imageData, imageOffset, imageLength);\n\t\timageOffset = 0;\n\t\timageLength = imageData.length;' + s[body+1:]

insert = r'''

	private static byte[] rg35xxStripPngICCP(byte[] src, int off, int len) {
		try {
			if (src == null || off < 0 || len < 8 || off + len > src.length) return copyRange(src, off, len);
			final byte[] sig = {(byte)137,80,78,71,13,10,26,10};
			for (int i=0; i<8; i++) if (src[off+i] != sig[i]) return copyRange(src, off, len);
			ByteArrayOutputStream out = new ByteArrayOutputStream(len);
			out.write(src, off, 8);
			int cur = off + 8;
			int end = off + len;
			boolean stripped = false;
			while (cur + 12 <= end) {
				int n = ((src[cur]&255)<<24)|((src[cur+1]&255)<<16)|((src[cur+2]&255)<<8)|(src[cur+3]&255);
				if (n < 0 || cur + 12 + n > end) return copyRange(src, off, len);
				boolean iccp = src[cur+4]=='i' && src[cur+5]=='C' && src[cur+6]=='C' && src[cur+7]=='P';
				if (!iccp) out.write(src, cur, n + 12); else stripped = true;
				boolean iend = src[cur+4]=='I' && src[cur+5]=='E' && src[cur+6]=='N' && src[cur+7]=='D';
				cur += n + 12;
				if (iend) break;
			}
			if (cur != end) return copyRange(src, off, len);
			if (stripped) System.err.println("RG35XX-PNG-COMPAT: stripped iCCP chunk");
			return out.toByteArray();
		} catch (Throwable t) {
			return copyRange(src, off, len);
		}
	}

	private static byte[] copyRange(byte[] src, int off, int len) {
		if (src == null) return null;
		if (off < 0 || len < 0 || off > src.length || off + len > src.length) return src;
		byte[] dst = new byte[len];
		System.arraycopy(src, off, dst, 0, len);
		return dst;
	}
'''

last = s.rfind('}')
if last < 0:
    raise SystemExit('PNG COMPAT FAIL: class end not found')
s = s[:last] + insert + '\n' + s[last:]
p.write_text(s, encoding='utf-8')
print('PNG COMPAT PASS:', p)
