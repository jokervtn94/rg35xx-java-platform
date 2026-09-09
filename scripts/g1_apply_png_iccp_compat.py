#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

# Device evidence proved Image.createImage() can reach PlatformImage through an
# InputStream/resource path, not only the byte[] constructor. Therefore every
# PlatformImage ImageIO.read(stream) site must pass through one centralized
# source-level compatibility decoder.
needle = 'ImageIO.read(stream)'
count = s.count(needle)
if count < 2:
    raise SystemExit('PNG COMPAT FAIL: expected multiple PlatformImage stream decode sites, found %d' % count)
s = s.replace(needle, 'rg35xxReadImage(stream)')

insert = r'''

	private static BufferedImage rg35xxReadImage(InputStream stream) throws IOException {
		if (stream == null) return null;
		ByteArrayOutputStream all = new ByteArrayOutputStream(8192);
		byte[] buf = new byte[4096];
		int n;
		while ((n = stream.read(buf)) != -1) {
			if (n > 0) all.write(buf, 0, n);
		}
		byte[] raw = all.toByteArray();
		System.err.println("RG35XX-PNG-COMPAT-V2: decode ENTER bytes=" + raw.length);
		byte[] clean = rg35xxStripPngICCP(raw, 0, raw.length);
		BufferedImage image = ImageIO.read(new ByteArrayInputStream(clean));
		System.err.println("RG35XX-PNG-COMPAT-V2: decode PASS bytes=" + clean.length);
		return image;
	}

	private static byte[] rg35xxStripPngICCP(byte[] src, int off, int len) {
		try {
			if (src == null) return null;
			if (off < 0 || len < 0 || off > src.length || off + len > src.length) return src;
			if (len < 8) return copyRange(src, off, len);
			final byte[] sig = {(byte)137,80,78,71,13,10,26,10};
			for (int i=0; i<8; i++) if (src[off+i] != sig[i]) return copyRange(src, off, len);
			System.err.println("RG35XX-PNG-COMPAT-V2: PNG detected bytes=" + len);
			ByteArrayOutputStream out = new ByteArrayOutputStream(len);
			out.write(src, off, 8);
			int cur = off + 8;
			int end = off + len;
			boolean stripped = false;
			while (cur + 12 <= end) {
				int n = ((src[cur]&255)<<24)|((src[cur+1]&255)<<16)|((src[cur+2]&255)<<8)|(src[cur+3]&255);
				if (n < 0 || cur + 12 + n > end) return copyRange(src, off, len);
				boolean iccp = src[cur+4]=='i' && src[cur+5]=='C' && src[cur+6]=='C' && src[cur+7]=='P';
				if (iccp) {
					System.err.println("RG35XX-PNG-COMPAT-V2: iCCP found bytes=" + n);
					stripped = true;
				} else {
					out.write(src, cur, n + 12);
				}
				boolean iend = src[cur+4]=='I' && src[cur+5]=='E' && src[cur+6]=='N' && src[cur+7]=='D';
				cur += n + 12;
				if (iend) break;
			}
			if (cur != end) return copyRange(src, off, len);
			if (!stripped) return copyRange(src, off, len);
			byte[] clean = out.toByteArray();
			System.err.println("RG35XX-PNG-COMPAT: stripped iCCP chunk");
			System.err.println("RG35XX-PNG-COMPAT-V2: sanitized bytes=" + clean.length);
			return clean;
		} catch (Throwable t) {
			System.err.println("RG35XX-PNG-COMPAT-V2: sanitizer FALLBACK " + t);
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

# Fail closed: all PlatformImage stream decoders must be routed through helper.
if 'ImageIO.read(stream)' in s:
    raise SystemExit('PNG COMPAT FAIL: direct ImageIO.read(stream) survived')
if s.count('rg35xxReadImage(stream)') != count:
    raise SystemExit('PNG COMPAT FAIL: not all stream decode sites were rewritten')

p.write_text(s, encoding='utf-8')
print('PNG COMPAT V2 PASS: decode sites=%d path=%s' % (count, p))
