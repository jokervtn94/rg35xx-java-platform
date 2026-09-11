#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r14_apply_gamecanvas_flush_probe.py <PlatformGraphics.java> <MobilePlatform.java>')

pg = pathlib.Path(sys.argv[1])
mp = pathlib.Path(sys.argv[2])
s = pg.read_text(encoding='utf-8')
m = mp.read_text(encoding='utf-8')
orig_s, orig_m = s, m

if 'RG35XX-VC7R14-FLUSH-BRIDGE' in s or 'RG35XX-VC7R14-MOBILE-FLUSH' in m:
    raise SystemExit('VC7R14 probe already applied')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('VC7R14 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

s = once(s,
'''\tprivate static int frameCount = 0;\n''',
'''\tprivate static int frameCount = 0;\n\tprivate static int vc7r14FlushCount = 0;\n''',
'counter')

old = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\n\t\ttry\n\t\t{\n\t\t\tfastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'''
new = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\n\t\ttry\n\t\t{\n\t\t\tvc7r14FlushCount++;\n\t\t\tfinal int[] vc7r14Src = (image == null ? null : image.getDataBuffer());\n\t\t\tfinal boolean vc7r14Log = vc7r14FlushCount <= 128 || (width == canvasWidth && height == canvasHeight);\n\t\t\tif(vc7r14Log)\n\t\t\t{\n\t\t\t\tint sn = (vc7r14Src == null ? 0 : vc7r14Src.length);\n\t\t\t\tint dn = (canvasData == null ? 0 : canvasData.length);\n\t\t\t\tint s0 = sn > 0 ? vc7r14Src[0] : 0;\n\t\t\t\tint sm = sn > 0 ? vc7r14Src[sn/2] : 0;\n\t\t\t\tint sl = sn > 0 ? vc7r14Src[sn-1] : 0;\n\t\t\t\tint d0 = dn > 0 ? canvasData[0] : 0;\n\t\t\t\tint dm = dn > 0 ? canvasData[dn/2] : 0;\n\t\t\t\tint dl = dn > 0 ? canvasData[dn-1] : 0;\n\t\t\t\tSystem.err.println("RG35XX-VC7R14-FLUSH-BRIDGE: BEFORE n=" + vc7r14FlushCount\n\t\t\t\t\t+ " dstImageId=" + System.identityHashCode(baseImage)\n\t\t\t\t\t+ " dstDataId=" + System.identityHashCode(canvasData)\n\t\t\t\t\t+ " srcImageId=" + System.identityHashCode(image)\n\t\t\t\t\t+ " srcDataId=" + System.identityHashCode(vc7r14Src)\n\t\t\t\t\t+ " rect=" + x + "," + y + "," + width + "," + height\n\t\t\t\t\t+ " canvas=" + canvasWidth + "x" + canvasHeight\n\t\t\t\t\t+ " s=" + Integer.toHexString(s0) + "," + Integer.toHexString(sm) + "," + Integer.toHexString(sl)\n\t\t\t\t\t+ " d=" + Integer.toHexString(d0) + "," + Integer.toHexString(dm) + "," + Integer.toHexString(dl));\n\t\t\t}\n\n\t\t\tfastBlit = (/*!Mobile.renderLCDMask || */ Mobile.maskIndex == 0) && !Mobile.funLightsEnabled;'''
s = once(s, old, new, 'flush entry')

old = '''\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\t// Games can try to render offscreen even at the correct resolution, so this makes more sense as a debug log'''
new = '''\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\tif(vc7r14Log)\n\t\t\t{\n\t\t\t\tint dn = (canvasData == null ? 0 : canvasData.length);\n\t\t\t\tint d0 = dn > 0 ? canvasData[0] : 0;\n\t\t\t\tint dm = dn > 0 ? canvasData[dn/2] : 0;\n\t\t\t\tint dl = dn > 0 ? canvasData[dn-1] : 0;\n\t\t\t\tSystem.err.println("RG35XX-VC7R14-FLUSH-BRIDGE: AFTER n=" + vc7r14FlushCount\n\t\t\t\t\t+ " dstDataId=" + System.identityHashCode(canvasData)\n\t\t\t\t\t+ " d=" + Integer.toHexString(d0) + "," + Integer.toHexString(dm) + "," + Integer.toHexString(dl));\n\t\t\t}\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\tSystem.err.println("RG35XX-VC7R14-FLUSH-BRIDGE: ERROR " + e);\n\t\t\t// Games can try to render offscreen even at the correct resolution, so this makes more sense as a debug log'''
s = once(s, old, new, 'flush exit')

# The full-canvas fast path returns early, so add an explicit AFTER marker there too.
old = '''\t\t\t\tSystem.arraycopy(image.getDataBuffer(), 0, canvasData, 0, canvasWidth*canvasHeight);\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn;'''
new = '''\t\t\t\tSystem.arraycopy(image.getDataBuffer(), 0, canvasData, 0, canvasWidth*canvasHeight);\n\t\t\t\tif(vc7r14Log)\n\t\t\t\t{\n\t\t\t\t\tint dn = canvasData.length;\n\t\t\t\t\tSystem.err.println("RG35XX-VC7R14-FLUSH-BRIDGE: FULLCOPY n=" + vc7r14FlushCount\n\t\t\t\t\t\t+ " srcDataId=" + System.identityHashCode(image.getDataBuffer())\n\t\t\t\t\t\t+ " dstDataId=" + System.identityHashCode(canvasData)\n\t\t\t\t\t\t+ " d=" + Integer.toHexString(canvasData[0]) + "," + Integer.toHexString(canvasData[dn/2]) + "," + Integer.toHexString(canvasData[dn-1]));\n\t\t\t\t}\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn;'''
s = once(s, old, new, 'full copy')

m = once(m,
'''\tpublic final void flushGraphics(PlatformImage img, int x, int y, int width, int height)\n\t{\n\t\tif(!Mobile.isPaused && !appTerminated)''',
'''\tpublic final void flushGraphics(PlatformImage img, int x, int y, int width, int height)\n\t{\n\t\tSystem.err.println("RG35XX-VC7R14-MOBILE-FLUSH: ENTER srcImageId=" + System.identityHashCode(img)\n\t\t\t+ " srcDataId=" + System.identityHashCode(img == null ? null : img.getDataBuffer())\n\t\t\t+ " frontImageId=" + System.identityHashCode(lcdFrontbuffer)\n\t\t\t+ " frontDataId=" + System.identityHashCode(lcdFrontbuffer == null ? null : lcdFrontbuffer.getDataBuffer())\n\t\t\t+ " rect=" + x + "," + y + "," + width + "," + height\n\t\t\t+ " paused=" + Mobile.isPaused + " terminated=" + appTerminated);\n\t\tif(!Mobile.isPaused && !appTerminated)''',
'mobile flush entry')

for req in ('RG35XX-VC7R14-FLUSH-BRIDGE', 'FULLCOPY', 'RG35XX-VC7R14-MOBILE-FLUSH'):
    if req not in s + m:
        raise SystemExit('VC7R14 missing marker ' + req)
if s == orig_s or m == orig_m:
    raise SystemExit('VC7R14 no mutation')

pg.write_text(s, encoding='utf-8', newline='\n')
mp.write_text(m, encoding='utf-8', newline='\n')
print('VC7R14_GAMECANVAS_FLUSH_PROBE=PASS')
print('SCOPE=MOBILE_FLUSH_ENTRY,PLATFORMGRAPHICS_FLUSH_BEFORE,FULLCOPY,AFTER,DATA_IDENTITIES')
