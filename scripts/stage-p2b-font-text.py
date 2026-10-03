#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-p2b-font-text.py <repo-root>')
root = Path(sys.argv[1]).resolve()
core = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
stage = root / 'build/a3/stage-src'
font = stage / 'javax/microedition/lcdui/Font.java'
pg = stage / 'org/recompile/mobile/PlatformGraphics.java'
for p in (core, font, pg):
    if not p.is_file():
        raise SystemExit('P2B_FONT_TEXT_STAGE_FAIL missing=' + str(p))

# Exact accepted P2A markers. P2B may only replace the provisional font/text owner.
ct = core.read_text(encoding='utf-8')
required = [
    'public static int fontHeight(int size)',
    'public static int charWidth(char ch, int size, int face, int style)',
    'public static String glyph(char ch)',
    'private static RawImage decodeAdam7('
]
for marker in required:
    if ct.count(marker) != 1:
        raise SystemExit('P2B_FONT_TEXT_STAGE_FAIL core-marker=%r count=%d' % (marker, ct.count(marker)))
if 'import java.io.File;\n' not in ct:
    ct = ct.replace('import java.io.ByteArrayInputStream;\n', 'import java.io.ByteArrayInputStream;\nimport java.io.File;\n', 1)
start = ct.index('    public static int fontHeight(int size) {')
end = ct.index('    public static RawImage decodePng(InputStream in) throws IOException {', start)
backend = r'''    private static volatile boolean fontBackendReady;
    private static int[] fontMetricCache12;
    private static int[] fontMetricCache14;
    private static int[] fontMetricCache16;

    private static int fontPointSize(int size) {
        if (size == 8) return 12;   // MIDP SIZE_SMALL
        if (size == 16) return 16;  // MIDP SIZE_LARGE
        return 14;                  // MIDP SIZE_MEDIUM/default
    }

    private static synchronized void ensureFontBackend() {
        if (fontBackendReady) return;
        String explicit = System.getProperty("rg35xx.font.native.path");
        String dir = System.getProperty("rg35xx.native.dir");
        if (explicit != null && explicit.length() > 0) {
            System.load(explicit);
        } else if (dir != null && dir.length() > 0) {
            System.load(new File(dir, "librg35xx_font.so").getAbsolutePath());
        } else {
            System.loadLibrary("rg35xx_font");
        }
        String fontPath = System.getProperty("rg35xx.font.path");
        if (fontPath == null || fontPath.length() == 0) {
            fontPath = dir != null && dir.length() > 0
                    ? new File(dir, "font.ttf").getAbsolutePath() : "font.ttf";
        }
        if (fontInitNative(fontPath) != 1) {
            throw new UnsatisfiedLinkError("RG35XX P2B font backend init failed: " + fontPath);
        }
        fontBackendReady = true;
    }

    private static native int fontInitNative(String path);
    private static native int[] fontMetricsNative(int pointSize);
    private static native int fontCharWidthNative(int ch, int pointSize, int style);
    private static native int fontStringWidthNative(String str, int pointSize, int style);
    private static native int[] fontRasterNative(String str, int pointSize, int style);

    private static int[] fontMetricsFor(int size) {
        ensureFontBackend();
        int point = fontPointSize(size);
        int[] cached = point == 12 ? fontMetricCache12 : (point == 16 ? fontMetricCache16 : fontMetricCache14);
        if (cached == null) {
            cached = fontMetricsNative(point);
            if (cached == null || cached.length < 4) throw new IllegalStateException("RG35XX P2B metrics unavailable");
            if (point == 12) fontMetricCache12 = cached;
            else if (point == 16) fontMetricCache16 = cached;
            else fontMetricCache14 = cached;
        }
        return cached;
    }

    public static int fontHeight(int size) { return fontMetricsFor(size)[0]; }
    public static int fontAscent(int size) { return fontMetricsFor(size)[1]; }
    public static int fontDescent(int size) { return fontMetricsFor(size)[2]; }

    public static int charWidth(char ch, int size, int face, int style) {
        ensureFontBackend();
        return fontCharWidthNative((int)ch, fontPointSize(size), style);
    }

    public static int stringWidth(String str, int size, int face, int style) {
        if (str == null) return 0;
        ensureFontBackend();
        return fontStringWidthNative(str, fontPointSize(size), style);
    }

    /** Whole-string mono raster description. Format: [advance,count,x0,y0,x1,y1,...]. */
    public static int[] textRaster(String str, int size, int face, int style) {
        if (str == null) return new int[] {0, 0};
        ensureFontBackend();
        int[] out = fontRasterNative(str, fontPointSize(size), style);
        if (out == null || out.length < 2 || out.length != 2 + out[1] * 2) {
            throw new IllegalStateException("RG35XX P2B raster contract invalid");
        }
        return out;
    }

'''
ct = ct[:start] + backend + ct[end:]
core.write_text(ct, encoding='utf-8')

ft = font.read_text(encoding='utf-8')
old_baseline = '\tpublic int getBaselinePosition() { return fm == null ? RG35XXCore2D.fontAscent(size) : convertSize(size); }'
if ft.count(old_baseline) != 1:
    raise SystemExit('P2B_FONT_TEXT_STAGE_FAIL Font baseline count=%d' % ft.count(old_baseline))
ft = ft.replace(old_baseline, '\tpublic int getBaselinePosition() { return convertSize(size); }', 1)
font.write_text(ft, encoding='utf-8')

pt = pg.read_text(encoding='utf-8')
pat = re.compile(r'\tprivate void rg35xxDrawString\(String str, int x, int y, int anchor\)\n\t\{.*?\n\t\}\n', re.S)
if len(pat.findall(pt)) != 1:
    raise SystemExit('P2B_FONT_TEXT_STAGE_FAIL PlatformGraphics rg35xxDrawString count=%d' % len(pat.findall(pt)))
repl = '''\tprivate void rg35xxDrawString(String str, int x, int y, int anchor)\n\t{\n\t\tif(str==null) return;\n\t\tFont f=getFont();\n\t\tint total=f.stringWidth(str);\n\t\tint ascent=RG35XXCore2D.fontAscent(f.getSize());\n\t\tint descent=RG35XXCore2D.fontDescent(f.getSize());\n\t\tx=AnchorX(x,total,anchor);\n\t\tif((anchor&BOTTOM)>0)y-=descent;\n\t\telse if((anchor&VCENTER)>0)y-=(descent+ascent)/2;\n\t\telse if((anchor&BASELINE)>0)y=y;\n\t\telse y+=ascent;\n\t\tint[] raster=RG35XXCore2D.textRaster(str,f.getSize(),f.getFace(),f.getStyle());\n\t\tfor(int i=0;i<raster[1];i++) fillRect(x+raster[2+i*2],y+raster[3+i*2],1,1);\n\t}\n'''
pt = pat.sub(repl, pt, count=1)
pg.write_text(pt, encoding='utf-8')

print('P2B_FONT_TEXT_STAGE=PASS')
print('P2B_FONT_TEXT_OWNER=RG35XX_GRAPHICS_BOUNDARY')
print('P2B_FONT_BASELINE_SEMANTICS=MIYOO_CONVERT_SIZE')
print('P2B_FONT_TEXT_WHOLE_STRING_RASTER=YES')
print('P2B_FONT_TEXT_CLIP_COLOR_ANCHOR_OWNER=PLATFORMGRAPHICS')
print('P2B_FONT_TEXT_NONOWNER_NATIVE_CHANGE=NO')
print('P2B_FONT_TEXT_GAME_SPECIFIC_CODE=NO')
print('P2B_FONT_TEXT_A9_PARENT=NO')
