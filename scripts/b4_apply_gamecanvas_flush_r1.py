#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: b4_apply_gamecanvas_flush_r1.py <PlatformGraphics.java> <MobilePlatform.java>')

pg = pathlib.Path(sys.argv[1])
mp = pathlib.Path(sys.argv[2])
s = pg.read_text(encoding='utf-8')
m = mp.read_text(encoding='utf-8')
orig_s, orig_m = s, m

if 'RG35XX-B4-GAMECANVAS-FLUSH' in s or 'RG35XX-B4-MOBILE-FLUSH' in m:
    raise SystemExit('B4 GAMECANVAS FLUSH R1 FAIL already applied')

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit('B4 GAMECANVAS FLUSH R1 FAIL %s count=%d' % (label, n))
    return text.replace(old, new, 1)

# PlatformGraphics: bounded flush diagnostics around the actual source->frontbuffer bridge.
s = once(
    s,
    '\tprivate static int frameCount = 0;\n',
    '''\tprivate static int frameCount = 0;\n\tprivate static int rg35xxB4FlushSeq = 0;\n\n\tprivate static boolean rg35xxB4FlushLog(int seq)\n\t{\n\t\treturn seq <= 32 || (seq > 0 && (seq & (seq - 1)) == 0);\n\t}\n\n\tprivate static int rg35xxB4SparseHash(int[] data)\n\t{\n\t\tif(data == null || data.length == 0) return 0;\n\t\tint h = 0x13579BDF;\n\t\tfinal int samples = 17;\n\t\tfor(int i=0; i<samples; i++)\n\t\t{\n\t\t\tint idx = (int)(((long)i * (long)(data.length - 1)) / (samples - 1));\n\t\t\th = (h * 33) ^ data[idx];\n\t\t}\n\t\treturn h;\n\t}\n''',
    'PlatformGraphics bounded helpers'
)

old_entry = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\n\t\ttry\n\t\t{\n\t\t\tfastBlit = !Mobile.funLightsEnabled;\n'''
new_entry = '''\tpublic void flushGraphics(PlatformImage image, int x, int y, int width, int height)\n\t{\n\t\t// called by MobilePlatform.flushGraphics/repaint\n\n\t\ttry\n\t\t{\n\t\t\tfinal int rg35xxSeq = ++rg35xxB4FlushSeq;\n\t\t\tfinal boolean rg35xxLog = rg35xxB4FlushLog(rg35xxSeq);\n\t\t\tfinal int[] rg35xxSrc = (image == null ? null : image.getDataBuffer());\n\t\t\tfinal int rg35xxSrcHashBefore = rg35xxB4SparseHash(rg35xxSrc);\n\t\t\tfinal int rg35xxDstHashBefore = rg35xxB4SparseHash(canvasData);\n\t\t\tif(rg35xxLog)\n\t\t\t{\n\t\t\t\tSystem.err.println("RG35XX-B4-GAMECANVAS-FLUSH stage=PG_BEFORE seq=" + rg35xxSeq\n\t\t\t\t\t+ " srcImageId=" + (image == null ? 0 : System.identityHashCode(image))\n\t\t\t\t\t+ " srcDataId=" + (rg35xxSrc == null ? 0 : System.identityHashCode(rg35xxSrc))\n\t\t\t\t\t+ " dstImageId=" + (baseImage == null ? 0 : System.identityHashCode(baseImage))\n\t\t\t\t\t+ " dstDataId=" + (canvasData == null ? 0 : System.identityHashCode(canvasData))\n\t\t\t\t\t+ " alias=" + (rg35xxSrc == canvasData)\n\t\t\t\t\t+ " rect=" + x + "," + y + "," + width + "," + height\n\t\t\t\t\t+ " canvas=" + canvasWidth + "x" + canvasHeight\n\t\t\t\t\t+ " srcHash=" + Integer.toHexString(rg35xxSrcHashBefore)\n\t\t\t\t\t+ " dstHashBefore=" + Integer.toHexString(rg35xxDstHashBefore));\n\t\t\t}\n\n\t\t\tfastBlit = !Mobile.funLightsEnabled;\n'''
s = once(s, old_entry, new_entry, 'PlatformGraphics flush entry')

old_alias = '''\t\t\tif(fastBlit && image.getDataBuffer() == canvasData)\n\t\t\t{\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn; // No need to copy anything, they're already the same\n\t\t\t}\n'''
new_alias = '''\t\t\tif(fastBlit && image.getDataBuffer() == canvasData)\n\t\t\t{\n\t\t\t\tif(rg35xxLog)\n\t\t\t\t{\n\t\t\t\t\tSystem.err.println("RG35XX-B4-GAMECANVAS-FLUSH stage=PG_ALIAS_RETURN seq=" + rg35xxSeq\n\t\t\t\t\t\t+ " dataId=" + System.identityHashCode(canvasData)\n\t\t\t\t\t\t+ " hash=" + Integer.toHexString(rg35xxB4SparseHash(canvasData)));\n\t\t\t\t}\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn; // No need to copy anything, they're already the same\n\t\t\t}\n'''
s = once(s, old_alias, new_alias, 'PlatformGraphics alias fast path')

old_full = '''\t\t\t\tSystem.arraycopy(image.getDataBuffer(), 0, canvasData, 0, canvasWidth*canvasHeight);\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn;\n'''
new_full = '''\t\t\t\tSystem.arraycopy(image.getDataBuffer(), 0, canvasData, 0, canvasWidth*canvasHeight);\n\t\t\t\tif(rg35xxLog)\n\t\t\t\t{\n\t\t\t\t\tSystem.err.println("RG35XX-B4-GAMECANVAS-FLUSH stage=PG_FULLCOPY_DONE seq=" + rg35xxSeq\n\t\t\t\t\t\t+ " srcHash=" + Integer.toHexString(rg35xxB4SparseHash(rg35xxSrc))\n\t\t\t\t\t\t+ " dstHash=" + Integer.toHexString(rg35xxB4SparseHash(canvasData))\n\t\t\t\t\t\t+ " equalHash=" + (rg35xxB4SparseHash(rg35xxSrc) == rg35xxB4SparseHash(canvasData)));\n\t\t\t\t}\n\t\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t\t\treturn;\n'''
s = once(s, old_full, new_full, 'PlatformGraphics full copy')

old_exit = '''\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\t// Games can try to render offscreen even at the correct resolution, so this makes more sense as a debug log\n'''
new_exit = '''\t\t\tif(rg35xxLog)\n\t\t\t{\n\t\t\t\tSystem.err.println("RG35XX-B4-GAMECANVAS-FLUSH stage=PG_COPY_DONE seq=" + rg35xxSeq\n\t\t\t\t\t+ " srcHash=" + Integer.toHexString(rg35xxB4SparseHash(rg35xxSrc))\n\t\t\t\t\t+ " dstHash=" + Integer.toHexString(rg35xxB4SparseHash(canvasData)));\n\t\t\t}\n\t\t\tif(!MobilePlatform.showFPS.equals("Off")) { showFPS(); }\n\t\t}\n\t\tcatch (Exception e)\n\t\t{\n\t\t\t// Games can try to render offscreen even at the correct resolution, so this makes more sense as a debug log\n'''
s = once(s, old_exit, new_exit, 'PlatformGraphics flush exit')

# MobilePlatform: bounded high-level bridge evidence, including current LCD frontbuffer identity.
field_anchor = '\tpublic static Runnable painter, postDraw;\n'
if m.count(field_anchor) != 1:
    raise SystemExit('B4 GAMECANVAS FLUSH R1 FAIL MobilePlatform field anchor count=%d' % m.count(field_anchor))
m = m.replace(
    field_anchor,
    field_anchor + '''\tprivate static int rg35xxB4MobileFlushSeq = 0;\n\n\tprivate static boolean rg35xxB4MobileFlushLog(int seq)\n\t{\n\t\treturn seq <= 32 || (seq > 0 && (seq & (seq - 1)) == 0);\n\t}\n''',
    1
)

old_mobile = '''\tpublic final void flushGraphics(PlatformImage img, int x, int y, int width, int height)\n\t{\n\t\tif(!Mobile.isPaused && !appTerminated)\n\t\t{\n'''
new_mobile = '''\tpublic final void flushGraphics(PlatformImage img, int x, int y, int width, int height)\n\t{\n\t\tfinal int rg35xxSeq = ++rg35xxB4MobileFlushSeq;\n\t\tfinal boolean rg35xxLog = rg35xxB4MobileFlushLog(rg35xxSeq);\n\t\tif(rg35xxLog)\n\t\t{\n\t\t\tint[] rg35xxSrc = (img == null ? null : img.getDataBuffer());\n\t\t\tint[] rg35xxFront = (lcdFrontbuffer == null ? null : lcdFrontbuffer.getDataBuffer());\n\t\t\tSystem.err.println("RG35XX-B4-MOBILE-FLUSH stage=ENTER seq=" + rg35xxSeq\n\t\t\t\t+ " srcImageId=" + (img == null ? 0 : System.identityHashCode(img))\n\t\t\t\t+ " srcDataId=" + (rg35xxSrc == null ? 0 : System.identityHashCode(rg35xxSrc))\n\t\t\t\t+ " frontImageId=" + (lcdFrontbuffer == null ? 0 : System.identityHashCode(lcdFrontbuffer))\n\t\t\t\t+ " frontDataId=" + (rg35xxFront == null ? 0 : System.identityHashCode(rg35xxFront))\n\t\t\t\t+ " alias=" + (rg35xxSrc == rg35xxFront)\n\t\t\t\t+ " rect=" + x + "," + y + "," + width + "," + height\n\t\t\t\t+ " paused=" + Mobile.isPaused + " terminated=" + appTerminated);\n\t\t}\n\t\tif(!Mobile.isPaused && !appTerminated)\n\t\t{\n'''
m = once(m, old_mobile, new_mobile, 'MobilePlatform flush entry')

for token in (
    'RG35XX-B4-GAMECANVAS-FLUSH stage=PG_BEFORE',
    'RG35XX-B4-GAMECANVAS-FLUSH stage=PG_ALIAS_RETURN',
    'RG35XX-B4-GAMECANVAS-FLUSH stage=PG_FULLCOPY_DONE',
    'RG35XX-B4-GAMECANVAS-FLUSH stage=PG_COPY_DONE',
    'RG35XX-B4-MOBILE-FLUSH stage=ENTER',
    'rg35xxB4SparseHash',
    'seq <= 32 || (seq > 0 && (seq & (seq - 1)) == 0)'
):
    if token not in s + m:
        raise SystemExit('B4 GAMECANVAS FLUSH R1 FAIL missing token: ' + token)

if s == orig_s or m == orig_m:
    raise SystemExit('B4 GAMECANVAS FLUSH R1 FAIL no mutation')

pg.write_text(s, encoding='utf-8', newline='\n')
mp.write_text(m, encoding='utf-8', newline='\n')
print('B4_GAMECANVAS_FLUSH_R1_PATCH=PASS')
print('PRIMARY_VARIABLE=BOUNDED_GAMECANVAS_TO_FRONTBUFFER_CONTENT_OBSERVABILITY_ONLY')
print('LOG_POLICY=FIRST_32_AND_POWER_OF_TWO')
print('BEHAVIOR_CHANGE=NONE')
