#!/usr/bin/env python3
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
needle = '\tpublic PlatformImage() { }\n'
if needle not in s:
    raise SystemExit('N1 FAIL: PlatformImage insertion anchor missing')
helper = r'''
	/* RG35XX N1: GNU Classpath 0.99 rejects ICC v4 profiles embedded in
	 * otherwise valid PNG files. MIDP does not expose ICC metadata, so strip
	 * only ancillary iCCP chunks before ImageIO sees the stream. Pixel chunks
	 * and all other PNG data remain byte-for-byte unchanged. */
	private static BufferedImage readImageCompat(InputStream input) throws IOException
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		byte[] buf = new byte[4096];
		int n;
		while((n = input.read(buf)) != -1) { out.write(buf, 0, n); }
		byte[] raw = out.toByteArray();
		byte[] clean = stripPngIccp(raw);
		return ImageIO.read(new ByteArrayInputStream(clean));
	}

	private static byte[] stripPngIccp(byte[] raw) throws IOException
	{
		if(raw == null || raw.length < 8 ||
		   (raw[0] & 0xff) != 0x89 || raw[1] != 0x50 || raw[2] != 0x4e || raw[3] != 0x47 ||
		   raw[4] != 0x0d || raw[5] != 0x0a || raw[6] != 0x1a || raw[7] != 0x0a) { return raw; }

		ByteArrayOutputStream out = new ByteArrayOutputStream(raw.length);
		out.write(raw, 0, 8);
		int pos = 8;
		boolean stripped = false;
		while(pos + 12 <= raw.length)
		{
			int len = ((raw[pos] & 0xff) << 24) | ((raw[pos+1] & 0xff) << 16) |
			          ((raw[pos+2] & 0xff) << 8) | (raw[pos+3] & 0xff);
			if(len < 0 || pos + 12L + len > raw.length) { return raw; }
			boolean iccp = raw[pos+4] == 'i' && raw[pos+5] == 'C' && raw[pos+6] == 'C' && raw[pos+7] == 'P';
			if(!iccp) { out.write(raw, pos, len + 12); }
			else { stripped = true; }
			pos += len + 12;
			if(raw[pos-len-8] == 'I' && raw[pos-len-7] == 'E' && raw[pos-len-6] == 'N' && raw[pos-len-5] == 'D') { break; }
		}
		if(!stripped || pos != raw.length) { return stripped && pos == raw.length ? out.toByteArray() : raw; }
		return out.toByteArray();
	}

'''
s = s.replace(needle, helper + needle, 1)
count = s.count('ImageIO.read(stream)')
if count < 3:
    raise SystemExit('N1 FAIL: expected >=3 ImageIO.read(stream) sites, got %d' % count)
s = s.replace('ImageIO.read(stream)', 'readImageCompat(stream)')
p.write_text(s, encoding='utf-8', newline='\n')
print('N1 PASS: patched PlatformImage; read sites=', count)
