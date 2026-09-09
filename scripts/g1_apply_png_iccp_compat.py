#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

needle = 'public PlatformImage(byte[] data, int offset, int length)'
pos = s.find(needle)
if pos < 0:
    raise SystemExit('PNG COMPAT FAIL: PlatformImage byte[] constructor not found')
body = s.find('{', pos)
if body < 0:
    raise SystemExit('PNG COMPAT FAIL: constructor body not found')

# Route only the J2ME byte-array image path through a semantic PNG sanitizer.
# Non-PNG input is returned byte-for-byte. PNG iCCP is ancillary metadata and
# may be safely omitted when the old GNU Classpath ImageIO rejects ICC v4.
s = s[:body+1] + '\n\t\tdata = rg35xxStripPngICCP(data, offset, length);\n\t\toffset = 0;\n\t\tlength = data.length;' + s[body+1:]

insert = r'''

	private static byte[] rg35xxStripPngICCP(byte[] src, int off, int len) {
		try {
			if (src == null || off < 0 || len < 8 || off + len > src.length) return src;
			final byte[] sig = {(byte)137,80,78,71,13,10,26,10};
			for (int i=0; i<8; i++) if (src[off+i] != sig[i]) return copyRange(src, off, len);
			java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream(len);
			out.write(src, off, 8);
			int p = off + 8, end = off + len;
			boolean stripped = false;
			while (p + 12 <= end) {
				int n = ((src[p]&255)<<24)|((src[p+1]&255)<<16)|((src[p+2]&255)<<8)|(src[p+3]&255);
				if (n < 0 || p + 12 + n > end) return copyRange(src, off, len);
				boolean iccp = src[p+4]=='i' && src[p+5]=='C' && src[p+6]=='C' && src[p+7]=='P';
				if (!iccp) out.write(src, p, n + 12); else stripped = true;
				boolean iend = src[p+4]=='I' && src[p+5]=='E' && src[p+6]=='N' && src[p+7]=='D';
				p += n + 12;
				if (iend) break;
			}
			if (p != end) return copyRange(src, off, len);
			if (stripped) System.err.println("RG35XX-PNG-COMPAT: stripped iCCP chunk");
			return out.toByteArray();
		} catch (Throwable t) {
			return copyRange(src, off, len);
		}
	}

	private static byte[] copyRange(byte[] src, int off, int len) {
		byte[] dst = new byte[len];
		System.arraycopy(src, off, dst, 0, len);
		return dst;
	}
'''

# Insert before final class brace.
last = s.rfind('}')
if last < 0:
    raise SystemExit('PNG COMPAT FAIL: class end not found')
s = s[:last] + insert + '\n' + s[last:]
p.write_text(s, encoding='utf-8')
print('PNG COMPAT PASS:', p)
