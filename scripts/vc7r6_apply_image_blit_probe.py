#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r6_apply_image_blit_probe.py <PlatformGraphics.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

if 'RG35XX-VC7R6-IMAGE-BLIT' in s:
    raise SystemExit('VC7R6 image blit probe already applied')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('VC7R6 IMAGE BLIT FAIL: %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

once('''\tprivate static int frameCount = 0;\n\tprivate static long lastFpsTime = System.nanoTime();''',
     '''\tprivate static int frameCount = 0;\n\n\t/* RG35XX-VC7R6-IMAGE-BLIT: diagnostic only; no rendering mutation. */\n\tprivate static int vc7r6ImageBlitCount = 0;\n\n\tprivate static long lastFpsTime = System.nanoTime();''',
     'probe counter')

helper = r'''
	private static String vc7r6Hex8(int v)
	{
		String h = Integer.toHexString(v).toUpperCase();
		while(h.length() < 8) h = "0" + h;
		return h;
	}

	private void vc7r6ProbeImage(String phase, Image image, int x, int y)
	{
		if(vc7r6ImageBlitCount >= 64 || image == null) return;
		try
		{
			int[] src = image.getDataBuffer();
			int iw = image.getWidth();
			int ih = image.getHeight();
			int n = (src == null ? 0 : src.length);
			int i0 = 0;
			int i1 = n > 0 ? n / 4 : 0;
			int i2 = n > 0 ? n / 2 : 0;
			int i3 = n > 0 ? (n * 3) / 4 : 0;
			int i4 = n > 0 ? n - 1 : 0;
			StringBuffer b = new StringBuffer(256);
			b.append("RG35XX-VC7R6-IMAGE-BLIT: ").append(phase)
			 .append(" call=").append(vc7r6ImageBlitCount + 1)
			 .append(" src=").append(iw).append('x').append(ih)
			 .append(" dst=").append(x).append(',').append(y)
			 .append(" translate=").append(translateX).append(',').append(translateY)
			 .append(" pixels=").append(n);
			if(n > 0)
			{
				b.append(" s0=").append(vc7r6Hex8(src[i0]))
				 .append(" s25=").append(vc7r6Hex8(src[i1]))
				 .append(" s50=").append(vc7r6Hex8(src[i2]))
				 .append(" s75=").append(vc7r6Hex8(src[i3]))
				 .append(" slast=").append(vc7r6Hex8(src[i4]));
			}
			int dx = x + translateX;
			int dy = y + translateY;
			if(dx >= 0 && dy >= 0 && dx < canvasWidth && dy < canvasHeight)
				b.append(" dest00=").append(vc7r6Hex8(canvasData[dy * canvasWidth + dx]));
			System.err.println(b.toString());
		}
		catch(Throwable t)
		{
			System.err.println("RG35XX-VC7R6-IMAGE-BLIT: probe-error " + t);
		}
	}

'''

once('''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
     helper + '''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
     'helper insertion')

once('''\t\t\tx = AnchorX(x, image.getWidth(), anchor);\n\t\t\ty = AnchorY(y, image.getHeight(), anchor);\n\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);''',
     '''\t\t\tx = AnchorX(x, image.getWidth(), anchor);\n\t\t\ty = AnchorY(y, image.getHeight(), anchor);\n\n\t\t\tvc7r6ProbeImage("BEFORE_DRAWIMAGE", image, x, y);\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);\n\t\t\tvc7r6ProbeImage("AFTER_DRAWIMAGE", image, x, y);\n\t\t\tvc7r6ImageBlitCount++;''',
     'drawImage probe')

once('''\t\t\t\tx = AnchorX(x, subw, anchor);\n\t\t\t\ty = AnchorY(y, subh, anchor);\n\t\t\t\tdrawRGB(image.getDataBuffer(), subx + (suby * image.getWidth()), image.getWidth(), x, y, subw, subh, true);''',
     '''\t\t\t\tx = AnchorX(x, subw, anchor);\n\t\t\t\ty = AnchorY(y, subh, anchor);\n\t\t\t\tvc7r6ProbeImage("BEFORE_DRAWREGION0", image, x, y);\n\t\t\t\tdrawRGB(image.getDataBuffer(), subx + (suby * image.getWidth()), image.getWidth(), x, y, subw, subh, true);\n\t\t\t\tvc7r6ProbeImage("AFTER_DRAWREGION0", image, x, y);\n\t\t\t\tvc7r6ImageBlitCount++;''',
     'drawRegion0 probe')

for req in ('RG35XX-VC7R6-IMAGE-BLIT', 'BEFORE_DRAWIMAGE', 'AFTER_DRAWIMAGE', 'BEFORE_DRAWREGION0', 'AFTER_DRAWREGION0'):
    if req not in s:
        raise SystemExit('VC7R6 IMAGE BLIT FAIL missing ' + req)
if s == orig:
    raise SystemExit('VC7R6 IMAGE BLIT FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R6 JAVA IMAGE BLIT PROBE=PASS')
print('SCOPE=SOURCE_IMAGE_PIXELS,DESTINATION_BEFORE_AFTER')
print('MAX_CALLS=64')
