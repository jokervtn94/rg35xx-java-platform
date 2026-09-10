#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r9_apply_image_blit_probe.py <PlatformGraphics.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

if 'RG35XX-VC7R9-IMAGE-BLIT' in s:
    raise SystemExit('VC7R9 image blit probe already applied')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('VC7R9 IMAGE BLIT FAIL: %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

once('''\tprivate static int frameCount = 0;\n\tprivate static long lastFpsTime = System.nanoTime();''',
     '''\tprivate static int frameCount = 0;\n\n\t/* RG35XX-VC7R9-IMAGE-BLIT: diagnostic only; no rendering mutation. */\n\tprivate static int vc7r9ImageBlitCount = 0;\n\n\tprivate static long lastFpsTime = System.nanoTime();''',
     'probe counter')

helper = '''
\tprivate static String vc7r9Hex8(int v)
\t{
\t\tString h = Integer.toHexString(v).toUpperCase();
\t\twhile(h.length() < 8) h = "0" + h;
\t\treturn h;
\t}

\tprivate void vc7r9ProbeImage(String phase, Image image, int x, int y)
\t{
\t\tif(vc7r9ImageBlitCount >= 96 || image == null) return;
\t\ttry
\t\t{
\t\t\tint[] src = image.getDataBuffer();
\t\t\tint iw = image.getWidth();
\t\t\tint ih = image.getHeight();
\t\t\tint n = (src == null ? 0 : src.length);
\t\t\tint i0 = 0;
\t\t\tint i1 = n > 0 ? n / 4 : 0;
\t\t\tint i2 = n > 0 ? n / 2 : 0;
\t\t\tint i3 = n > 0 ? (n * 3) / 4 : 0;
\t\t\tint i4 = n > 0 ? n - 1 : 0;
\t\t\tint sampled = 0, alpha0 = 0, alpha255 = 0, varying = 0;
\t\t\tint first = 0;
\t\t\tif(n > 0)
\t\t\t{
\t\t\t\tint step = Math.max(1, n / 256);
\t\t\t\tfirst = src[0];
\t\t\t\tfor(int k = 0; k < n && sampled < 256; k += step)
\t\t\t\t{
\t\t\t\t\tint v = src[k];
\t\t\t\t\tint a = (v >>> 24) & 0xFF;
\t\t\t\t\tif(a == 0) alpha0++;
\t\t\t\t\tif(a == 255) alpha255++;
\t\t\t\t\tif(v != first) varying++;
\t\t\t\t\tsampled++;
\t\t\t\t}
\t\t\t}
\t\t\tStringBuffer b = new StringBuffer(384);
\t\t\tb.append("RG35XX-VC7R9-IMAGE-BLIT: ").append(phase)
\t\t\t .append(" call=").append(vc7r9ImageBlitCount + 1)
\t\t\t .append(" src=").append(iw).append('x').append(ih)
\t\t\t .append(" dst=").append(x).append(',').append(y)
\t\t\t .append(" translate=").append(translateX).append(',').append(translateY)
\t\t\t .append(" clip=").append(clipX).append(',').append(clipY).append(',').append(clipWidth).append(',').append(clipHeight)
\t\t\t .append(" pixels=").append(n)
\t\t\t .append(" sampleN=").append(sampled)
\t\t\t .append(" alpha0=").append(alpha0)
\t\t\t .append(" alpha255=").append(alpha255)
\t\t\t .append(" varying=").append(varying);
\t\t\tif(n > 0)
\t\t\t{
\t\t\t\tb.append(" s0=").append(vc7r9Hex8(src[i0]))
\t\t\t\t .append(" s25=").append(vc7r9Hex8(src[i1]))
\t\t\t\t .append(" s50=").append(vc7r9Hex8(src[i2]))
\t\t\t\t .append(" s75=").append(vc7r9Hex8(src[i3]))
\t\t\t\t .append(" slast=").append(vc7r9Hex8(src[i4]));
\t\t\t}
\t\t\tint dx = x + translateX;
\t\t\tint dy = y + translateY;
\t\t\tif(dx >= 0 && dy >= 0 && dx < canvasWidth && dy < canvasHeight)
\t\t\t\tb.append(" dest00=").append(vc7r9Hex8(canvasData[dy * canvasWidth + dx]));
\t\t\tSystem.err.println(b.toString());
\t\t}
\t\tcatch(Throwable t)
\t\t{
\t\t\tSystem.err.println("RG35XX-VC7R9-IMAGE-BLIT: probe-error " + t);
\t\t}
\t}

'''

once('''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
     helper + '''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
     'helper insertion')

once('''\t\t\tx = AnchorX(x, image.getWidth(), anchor);\n\t\t\ty = AnchorY(y, image.getHeight(), anchor);\n\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);''',
     '''\t\t\tx = AnchorX(x, image.getWidth(), anchor);\n\t\t\ty = AnchorY(y, image.getHeight(), anchor);\n\n\t\t\tvc7r9ProbeImage("BEFORE_DRAWIMAGE", image, x, y);\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);\n\t\t\tvc7r9ProbeImage("AFTER_DRAWIMAGE", image, x, y);\n\t\t\tvc7r9ImageBlitCount++;''',
     'drawImage probe')

once('''\t\t\t\tx = AnchorX(x, subw, anchor);\n\t\t\t\ty = AnchorY(y, subh, anchor);\n\t\t\t\tdrawRGB(image.getDataBuffer(), subx + (suby * image.getWidth()), image.getWidth(), x, y, subw, subh, true);''',
     '''\t\t\t\tx = AnchorX(x, subw, anchor);\n\t\t\t\ty = AnchorY(y, subh, anchor);\n\t\t\t\tvc7r9ProbeImage("BEFORE_DRAWREGION0", image, x, y);\n\t\t\t\tdrawRGB(image.getDataBuffer(), subx + (suby * image.getWidth()), image.getWidth(), x, y, subw, subh, true);\n\t\t\t\tvc7r9ProbeImage("AFTER_DRAWREGION0", image, x, y);\n\t\t\t\tvc7r9ImageBlitCount++;''',
     'drawRegion0 probe')

for req in ('RG35XX-VC7R9-IMAGE-BLIT', 'BEFORE_DRAWIMAGE', 'AFTER_DRAWIMAGE', 'BEFORE_DRAWREGION0', 'AFTER_DRAWREGION0', 'alpha0=', 'varying='):
    if req not in s:
        raise SystemExit('VC7R9 IMAGE BLIT FAIL missing ' + req)
if s == orig:
    raise SystemExit('VC7R9 IMAGE BLIT FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R9 JAVA IMAGE BLIT PROBE=PASS')
print('SCOPE=SOURCE_IMAGE_PIXELS,ALPHA_VARIATION,DESTINATION_BEFORE_AFTER')
print('MAX_CALLS=96')
