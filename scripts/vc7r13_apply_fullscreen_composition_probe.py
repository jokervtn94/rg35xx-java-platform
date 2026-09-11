#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r13_apply_fullscreen_composition_probe.py <PlatformGraphics.java> <PlatformImage.java>')

g = pathlib.Path(sys.argv[1])
i = pathlib.Path(sys.argv[2])
s = g.read_text(encoding='utf-8')
u = i.read_text(encoding='utf-8')
orig_s, orig_u = s, u

if 'RG35XX-VC7R13-FULLSCREEN' in s or 'RG35XX-VC7R13-IMAGE-CREATE' in u:
    raise SystemExit('VC7R13 probe already applied')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('VC7R13 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

# Bounded counters beside existing VC7R11 fields.
s = once(s,
'''\tprivate static int vc7r11DrawRgbCount = 0;\n''',
'''\tprivate static int vc7r11DrawRgbCount = 0;\n\t/* RG35XX-VC7R13-FULLSCREEN: diagnostic only; no rendering mutation. */\n\tprivate static int vc7r13FullscreenCount = 0;\n''',
'graphics counter')

helper = '''
\tprivate static String vc7r13Hex8(int v)
\t{
\t\tString h = Integer.toHexString(v).toUpperCase();
\t\twhile(h.length() < 8) h = "0" + h;
\t\treturn h;
\t}

\tprivate static String vc7r13Stack()
\t{
\t\ttry
\t\t{
\t\t\tStackTraceElement[] st = new Throwable().getStackTrace();
\t\t\tStringBuffer b = new StringBuffer(192);
\t\t\tfor(int n = 2; n < st.length && n < 8; n++)
\t\t\t{
\t\t\t\tif(b.length() > 0) b.append(" <- ");
\t\t\t\tb.append(st[n].getClassName()).append('.').append(st[n].getMethodName()).append(':').append(st[n].getLineNumber());
\t\t\t}
\t\t\treturn b.toString();
\t\t}
\t\tcatch(Throwable t) { return "stack-error:" + t; }
\t}

\tprivate void vc7r13ProbeFullscreen(String phase, Image image, int x, int y)
\t{
\t\tif(image == null || vc7r13FullscreenCount >= 48) return;
\t\tint iw = image.getWidth();
\t\tint ih = image.getHeight();
\t\tif(iw != canvasWidth || ih != canvasHeight || x + translateX != 0 || y + translateY != 0) return;
\t\ttry
\t\t{
\t\t\tint[] src = image.getDataBuffer();
\t\t\tint n = src == null ? 0 : src.length;
\t\t\tint[] pts = new int[]{0, n > 0 ? n/4 : 0, n > 0 ? n/2 : 0, n > 0 ? (n*3)/4 : 0, n > 0 ? n-1 : 0};
\t\t\tint varying = 0, alpha0 = 0, alpha255 = 0;
\t\t\tint first = n > 0 ? src[0] : 0;
\t\t\tint sampled = 0;
\t\t\tif(n > 0)
\t\t\t{
\t\t\t\tint step = Math.max(1, n / 512);
\t\t\t\tfor(int k = 0; k < n && sampled < 512; k += step)
\t\t\t\t{
\t\t\t\t\tint v = src[k];
\t\t\t\t\tif(v != first) varying++;
\t\t\t\t\tint a = (v >>> 24) & 0xFF;
\t\t\t\t\tif(a == 0) alpha0++;
\t\t\t\t\tif(a == 255) alpha255++;
\t\t\t\t\tsampled++;
\t\t\t\t}
\t\t\t}
\t\t\tStringBuffer b = new StringBuffer(640);
\t\t\tb.append("RG35XX-VC7R13-FULLSCREEN: ").append(phase)
\t\t\t .append(" n=").append(vc7r13FullscreenCount + 1)
\t\t\t .append(" gfxId=").append(System.identityHashCode(this))
\t\t\t .append(" dstImageId=").append(System.identityHashCode(baseImage))
\t\t\t .append(" dstDataId=").append(System.identityHashCode(canvasData))
\t\t\t .append(" srcImageId=").append(System.identityHashCode(image))
\t\t\t .append(" srcDataId=").append(System.identityHashCode(src))
\t\t\t .append(" size=").append(iw).append('x').append(ih)
\t\t\t .append(" sampled=").append(sampled)
\t\t\t .append(" varying=").append(varying)
\t\t\t .append(" alpha0=").append(alpha0)
\t\t\t .append(" alpha255=").append(alpha255);
\t\t\tif(n > 0)
\t\t\t{
\t\t\t\tb.append(" s0=").append(vc7r13Hex8(src[pts[0]]))
\t\t\t\t .append(" s25=").append(vc7r13Hex8(src[pts[1]]))
\t\t\t\t .append(" s50=").append(vc7r13Hex8(src[pts[2]]))
\t\t\t\t .append(" s75=").append(vc7r13Hex8(src[pts[3]]))
\t\t\t\t .append(" slast=").append(vc7r13Hex8(src[pts[4]]));
\t\t\t}
\t\t\tif(canvasData != null && canvasData.length > 0)
\t\t\t{
\t\t\t\tint dn = canvasData.length;
\t\t\t\tb.append(" d0=").append(vc7r13Hex8(canvasData[0]))
\t\t\t\t .append(" d50=").append(vc7r13Hex8(canvasData[dn/2]))
\t\t\t\t .append(" dlast=").append(vc7r13Hex8(canvasData[dn-1]));
\t\t\t}
\t\t\tb.append(" stack=").append(vc7r13Stack());
\t\t\tSystem.err.println(b.toString());
\t\t}
\t\tcatch(Throwable t) { System.err.println("RG35XX-VC7R13-FULLSCREEN: probe-error " + t); }
\t}

'''

s = once(s,
'''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
helper + '''\tpublic void drawImage(Image image, int x, int y, int anchor)\n\t{''',
'fullscreen helper insertion')

# VC7R9 already surrounds drawRGB in drawImage. Add the full-screen probe around that exact admitted block.
s = once(s,
'''\t\t\tvc7r9ProbeImage("BEFORE_DRAWIMAGE", image, x, y);\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);\n\t\t\tvc7r9ProbeImage("AFTER_DRAWIMAGE", image, x, y);\n\t\t\tvc7r9ImageBlitCount++;''',
'''\t\t\tvc7r9ProbeImage("BEFORE_DRAWIMAGE", image, x, y);\n\t\t\tvc7r13ProbeFullscreen("BEFORE", image, x, y);\n\t\t\tdrawRGB(image.getDataBuffer(), 0, image.getWidth(), x, y, image.getWidth(), image.getHeight(), true);\n\t\t\tvc7r13ProbeFullscreen("AFTER", image, x, y);\n\t\t\tif(image.getWidth() == canvasWidth && image.getHeight() == canvasHeight && x + translateX == 0 && y + translateY == 0) vc7r13FullscreenCount++;\n\t\t\tvc7r9ProbeImage("AFTER_DRAWIMAGE", image, x, y);\n\t\t\tvc7r9ImageBlitCount++;''',
'fullscreen drawImage probe')

# Instrument mutable/full-screen PlatformImage creation paths with bounded stack traces.
# Insert common diagnostic state after is2bpp.
u = once(u,
'''\tprivate boolean is2bpp = false; // SIEMENS: False = 1bpp, True = 2bpp\n''',
'''\tprivate boolean is2bpp = false; // SIEMENS: False = 1bpp, True = 2bpp\n\n\t/* RG35XX-VC7R13-IMAGE-CREATE: diagnostic only. */\n\tprivate static int vc7r13CreateCount = 0;\n\tprivate void vc7r13Created(String kind)\n\t{\n\t\tif(vc7r13CreateCount >= 48 || canvas == null || dataBuffer == null) return;\n\t\tint w = canvas.getWidth(), h = canvas.getHeight();\n\t\tif(!((w == Mobile.lcdWidth && h == Mobile.lcdHeight) || (w >= 240 && h >= 240))) return;\n\t\tvc7r13CreateCount++;\n\t\tStringBuffer st = new StringBuffer(192);\n\t\tStackTraceElement[] trace = new Throwable().getStackTrace();\n\t\tfor(int n = 2; n < trace.length && n < 8; n++)\n\t\t{\n\t\t\tif(st.length() > 0) st.append(" <- ");\n\t\t\tst.append(trace[n].getClassName()).append('.').append(trace[n].getMethodName()).append(':').append(trace[n].getLineNumber());\n\t\t}\n\t\tSystem.err.println("RG35XX-VC7R13-IMAGE-CREATE: n=" + vc7r13CreateCount + " kind=" + kind\n\t\t\t+ " imageId=" + System.identityHashCode(this) + " dataId=" + System.identityHashCode(dataBuffer)\n\t\t\t+ " size=" + w + "x" + h + " mutable=" + isMutable + " stack=" + st.toString());\n\t}\n''',
'image create state')

# Blank mutable constructor: call after mutability is established.
u = once(u,
'''\t\tisMutable = true;\n\t}\n\n\tpublic PlatformImage(int Width, int Height, int ARGBcolor)''',
'''\t\tisMutable = true;\n\t\tvc7r13Created("blank");\n\t}\n\n\tpublic PlatformImage(int Width, int Height, int ARGBcolor)''',
'blank constructor probe')

# ARGB fill constructor.
u = once(u,
'''\t\tArrays.fill(dataBuffer, ARGBcolor);\n\n\t\tisMutable = true;\n\t}\n\n\tpublic PlatformImage(String name) throws IOException''',
'''\t\tArrays.fill(dataBuffer, ARGBcolor);\n\n\t\tisMutable = true;\n\t\tvc7r13Created("blank-color");\n\t}\n\n\tpublic PlatformImage(String name) throws IOException''',
'blank color constructor probe')

# createRGBImage path.
u = once(u,
'''\t\tfor(int j = 0; j < Height; j++) \n\t\t{\n\t\t\tfor(int i = 0; i < Width; i++) \n\t\t\t{\n\t\t\t\tdataBuffer[j*Width + i] = (processAlpha ? rgb[j*Width + i] : rgb[j*Width + i] | 0xFF000000);\n\t\t\t}\n\t\t}\n\t}\n\n\tpublic PlatformImage(Image image, int x, int y, int Width, int Height, int transform)''',
'''\t\tfor(int j = 0; j < Height; j++) \n\t\t{\n\t\t\tfor(int i = 0; i < Width; i++) \n\t\t\t{\n\t\t\t\tdataBuffer[j*Width + i] = (processAlpha ? rgb[j*Width + i] : rgb[j*Width + i] | 0xFF000000);\n\t\t\t}\n\t\t}\n\t\tvc7r13Created("createRGBImage");\n\t}\n\n\tpublic PlatformImage(Image image, int x, int y, int Width, int Height, int transform)''',
'createRGB constructor probe')

for req in ('RG35XX-VC7R13-FULLSCREEN', 'BEFORE', 'AFTER', 'srcImageId=', 'dstDataId=', 'stack='):
    if req not in s:
        raise SystemExit('VC7R13 FAIL missing graphics marker ' + req)
for req in ('RG35XX-VC7R13-IMAGE-CREATE', 'kind=', 'createRGBImage'):
    if req not in u:
        raise SystemExit('VC7R13 FAIL missing image marker ' + req)
if s == orig_s or u == orig_u:
    raise SystemExit('VC7R13 FAIL no mutation')

g.write_text(s, encoding='utf-8', newline='\n')
i.write_text(u, encoding='utf-8', newline='\n')
print('VC7R13_FULLSCREEN_COMPOSITION_PROBE=PASS')
print('SCOPE=FULLSCREEN_SOURCE_DEST_FINGERPRINTS,IDENTITIES,STACKS,LARGE_IMAGE_CREATION')
