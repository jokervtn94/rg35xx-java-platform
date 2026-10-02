package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import com.nokia.mid.ui.DirectGraphics;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * Diagnostic only for the remaining P1A G4/G5 DirectGraphics IO surface.
 *
 * The canonical side is the pinned Miyoo PlatformGraphics implementation.
 * The model below is intentionally small and source-derived: integer pixel
 * layout, Nokia manipulation mapping, byte gray bit order, ushort conversion,
 * offset/scanlength behavior, and the canonical byte getPixels stub.
 *
 * No runtime source is modified by this diagnostic.
 */
public final class RG35XXG4G5DirectGraphicsIODiagnostic {
    private static final int W = 14;
    private static final int H = 12;
    private static final int BG = 0xFF112233;
    private static int canonicalChecks;
    private static int rawGapChecks;

    private interface ThrowingOp { void run() throws Throwable; }

    private static final class T {
        final int[] p;
        final int w;
        final int h;
        T(int[] pixels, int width, int height) { p = pixels; w = width; h = height; }
    }

    public static void main(String[] args) {
        System.clearProperty("rg35xx.raw2d");
        probeDrawImageManipulations();
        probeDrawPixelsInt();
        probeDrawPixelsShort();
        probeDrawPixelsByte();
        probeGetPixelsInt();
        probeGetPixelsShort();
        probeGetPixelsByteStub(false);
        probeRawGaps();
        probeGetPixelsByteStub(true);
        System.clearProperty("rg35xx.raw2d");

        System.out.println("P1A_G4G5_CANONICAL_CHECK_COUNT=" + canonicalChecks);
        System.out.println("P1A_G4G5_RAW_GAP_COUNT=" + rawGapChecks);
        System.out.println("P1A_G4G5_DRAWIMAGE_MANIPULATION_MAP=MIYOO_PLATFORMIMAGE_TRANSFORMIMAGE");
        System.out.println("P1A_G4G5_DRAWPX_INT_TRANSPARENCY_FLAG=IGNORED_CANONICAL");
        System.out.println("P1A_G4G5_DRAWPX_SHORT_FALSE_TRANSPARENCY=ALPHA_CLEARED_CANONICAL");
        System.out.println("P1A_G4G5_BYTE_GRAY_HORIZONTAL_BIT_ORDER=MSB_FIRST");
        System.out.println("P1A_G4G5_BYTE_GRAY_VERTICAL_BIT_ORDER=LSB_FIRST");
        System.out.println("P1A_G4G5_GETPX_INT_SCANLENGTH=HONORED");
        System.out.println("P1A_G4G5_GETPX_SHORT_SCANLENGTH=IGNORED_CANONICAL");
        System.out.println("P1A_G4G5_GETPX_BYTE=CANONICAL_STUB_PRESERVED");
        System.out.println("P1A_G4G5_RUNTIME_CHANGE=NO");
        System.out.println("P1A_G4G5_DIAGNOSTIC_GATE=PASS");
    }

    private static void probeDrawImageManipulations() {
        int[] src = {
            0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
            0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF
        };
        int[] manip = {
            0,
            DirectGraphics.FLIP_HORIZONTAL,
            DirectGraphics.FLIP_VERTICAL,
            DirectGraphics.ROTATE_90,
            DirectGraphics.ROTATE_180,
            DirectGraphics.ROTATE_270,
            DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.FLIP_VERTICAL,
            DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.ROTATE_90
        };
        String[] names = {"NONE","FLIP_H","FLIP_V","ROT90","ROT180","ROT270","HV","H90"};
        Image image = Image.createRGBImage(src, 3, 2, true);
        for (int i = 0; i < manip.length; i++) {
            PlatformImage dst = canonicalSurface();
            PlatformGraphics g = dst.getGraphics();
            g.drawImage(image, 7, 6, Graphics.HCENTER | Graphics.VCENTER, manip[i]);
            T t = directTransform(src, 3, 2, manip[i]);
            int[] expected = blank();
            int x = 7 - t.w / 2;
            int y = 6 - t.h / 2;
            opaqueBlit(expected, W, H, t.p, t.w, t.h, x, y);
            int[] actual = pixels(dst);
            req(Arrays.equals(actual, expected), "drawImage manipulation " + names[i]);
            canonicalChecks++;
            System.out.println("G4G5_DRAWIMAGE=" + names[i] + " DIM=" + t.w + "x" + t.h + " CHECKSUM=" + hex(checksum(actual)));
        }
    }

    private static void probeDrawPixelsInt() {
        int[] storage = new int[12];
        Arrays.fill(storage, 0xFF010101);
        storage[1] = 0xFFFF0000; storage[2] = 0xFF00FF00; storage[3] = 0xFF0000FF;
        storage[6] = 0xFFFFFF00; storage[7] = 0xFFFF00FF; storage[8] = 0xFF00FFFF;

        PlatformImage dst = canonicalSurface();
        dst.getGraphics().drawPixels(storage, true, 1, 5, 3, 2, 3, 2,
                                     DirectGraphics.ROTATE_90, DirectGraphics.TYPE_INT_8888_ARGB);
        int[] packed = {storage[1],storage[2],storage[3],storage[6],storage[7],storage[8]};
        T t = directTransform(packed, 3, 2, DirectGraphics.ROTATE_90);
        int[] expected = blank();
        opaqueBlit(expected, W, H, t.p, t.w, t.h, 3, 2);
        req(Arrays.equals(pixels(dst), expected), "drawPixels int offset/scanlength/manipulation");
        canonicalChecks++;

        int[] alpha = {0x803366CC};
        PlatformImage a = canonicalSurface();
        PlatformImage b = canonicalSurface();
        a.getGraphics().drawPixels(alpha, true, 0, 1, 4, 4, 1, 1, 0, DirectGraphics.TYPE_INT_8888_ARGB);
        b.getGraphics().drawPixels(alpha, false, 0, 1, 4, 4, 1, 1, 0, DirectGraphics.TYPE_INT_8888_ARGB);
        req(Arrays.equals(pixels(a), pixels(b)), "drawPixels int transparency flag ignored");
        canonicalChecks++;
        System.out.println("G4G5_DRAWPX_INT_CHECKSUM=" + hex(checksum(pixels(dst))) + " TRANSPARENCY_EQ=true");
    }

    private static void probeDrawPixelsShort() {
        int[] formats = {
            DirectGraphics.TYPE_USHORT_1555_ARGB,
            DirectGraphics.TYPE_USHORT_444_RGB,
            DirectGraphics.TYPE_USHORT_4444_ARGB,
            DirectGraphics.TYPE_USHORT_555_RGB,
            DirectGraphics.TYPE_USHORT_565_RGB
        };
        short[][] values = {
            {(short)0xFC00,(short)0x83E0,(short)0x801F},
            {(short)0x0F00,(short)0x00F0,(short)0x000F},
            {(short)0xFF00,(short)0xF0F0,(short)0xF00F},
            {(short)0x7C00,(short)0x03E0,(short)0x001F},
            {(short)0xF800,(short)0x07E0,(short)0x001F}
        };
        for (int f = 0; f < formats.length; f++) {
            PlatformImage dst = canonicalSurface();
            dst.getGraphics().drawPixels(values[f], true, 0, 3, 2, 3, 3, 1, 0, formats[f]);
            int[] actual = pixels(dst);
            for (int x = 0; x < 3; x++) {
                int expected = shortToColor(values[f][x], formats[f]);
                req(actual[3 * W + 2 + x] == expected, "drawPixels short format=" + formats[f] + " x=" + x);
            }
            canonicalChecks++;
            System.out.println("G4G5_DRAWPX_SHORT_FORMAT=" + formats[f] + " CHECKSUM=" + hex(checksum(actual)));
        }

        PlatformImage transparentFalse = canonicalSurface();
        transparentFalse.getGraphics().drawPixels(values[4], false, 0, 3, 2, 3, 3, 1, 0, DirectGraphics.TYPE_USHORT_565_RGB);
        req(Arrays.equals(pixels(transparentFalse), blank()), "drawPixels short false transparency clears alpha");
        canonicalChecks++;
    }

    private static void probeDrawPixelsByte() {
        byte[] horizontal = {(byte)0xB2};
        PlatformImage h = canonicalSurface();
        h.getGraphics().drawPixels(horizontal, null, 0, 8, 2, 3, 8, 1, 0, DirectGraphics.TYPE_BYTE_1_GRAY);
        int[] hp = pixels(h);
        for (int x = 0; x < 8; x++) {
            int bit = (horizontal[0] >> (7 - x)) & 1;
            int expected = bit == 0 ? 0xFFFFFFFF : 0xFF000000;
            req(hp[3 * W + 2 + x] == expected, "byte gray horizontal x=" + x);
        }
        canonicalChecks++;

        byte[] vertical = {(byte)0xA5,(byte)0x3C,(byte)0x81};
        PlatformImage v = canonicalSurface();
        v.getGraphics().drawPixels(vertical, null, 0, 3, 4, 2, 3, 8, 0, DirectGraphics.TYPE_BYTE_1_GRAY_VERTICAL);
        int[] vp = pixels(v);
        for (int y = 0; y < 8; y++) {
            for (int x = 0; x < 3; x++) {
                int bit = (vertical[x] >> y) & 1;
                int expected = bit == 0 ? 0xFFFFFFFF : 0xFF000000;
                req(vp[(2 + y) * W + 4 + x] == expected, "byte gray vertical x=" + x + " y=" + y);
            }
        }
        canonicalChecks++;
        System.out.println("G4G5_DRAWPX_BYTE_H=" + hex(checksum(hp)) + " V=" + hex(checksum(vp)));
    }

    private static void probeGetPixelsInt() {
        PlatformImage src = patternedCanonicalSurface();
        int sentinel = 0x13579BDF;
        int[] out = new int[16];
        Arrays.fill(out, sentinel);
        src.getGraphics().getPixels(out, 2, 5, 3, 4, 3, 2, DirectGraphics.TYPE_INT_8888_ARGB);
        int[] p = pixels(src);
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 3; x++) {
                req(out[2 + y * 5 + x] == p[(4 + y) * W + 3 + x], "getPixels int payload");
            }
        }
        req(out[0] == sentinel && out[1] == sentinel && out[5] == sentinel && out[6] == sentinel,
            "getPixels int offset/scanlength guards");
        canonicalChecks++;
        System.out.println("G4G5_GETPX_INT_CHECKSUM=" + hex(checksum(out)));
    }

    private static void probeGetPixelsShort() {
        int[] formats = {
            DirectGraphics.TYPE_USHORT_1555_ARGB,
            DirectGraphics.TYPE_USHORT_444_RGB,
            DirectGraphics.TYPE_USHORT_4444_ARGB,
            DirectGraphics.TYPE_USHORT_555_RGB,
            DirectGraphics.TYPE_USHORT_565_RGB
        };
        PlatformImage src = patternedCanonicalSurface();
        int[] p = pixels(src);
        for (int f = 0; f < formats.length; f++) {
            short sentinel = (short)0x6A5A;
            short[] out = new short[12];
            Arrays.fill(out, sentinel);
            src.getGraphics().getPixels(out, 2, 99, 3, 4, 2, 2, formats[f]);
            int k = 2;
            for (int y = 0; y < 2; y++) {
                for (int x = 0; x < 2; x++) {
                    short expected = colorToShort(p[(4 + y) * W + 3 + x], formats[f]);
                    req(out[k++] == expected, "getPixels short format=" + formats[f]);
                }
            }
            req(out[6] == sentinel && out[7] == sentinel, "getPixels short ignores scanlength and writes contiguous");
            canonicalChecks++;
            System.out.println("G4G5_GETPX_SHORT_FORMAT=" + formats[f] + " CHECKSUM=" + hex(checksum(out)));
        }
    }

    private static void probeGetPixelsByteStub(boolean raw) {
        if (raw) System.setProperty("rg35xx.raw2d", "true"); else System.clearProperty("rg35xx.raw2d");
        PlatformImage src = raw ? new PlatformImage(W, H) : patternedCanonicalSurface();
        byte[] out = {(byte)0x55,(byte)0x66,(byte)0x77};
        byte[] mask = {(byte)0x11,(byte)0x22,(byte)0x33};
        byte[] outBefore = (byte[])out.clone();
        byte[] maskBefore = (byte[])mask.clone();
        src.getGraphics().getPixels(out, mask, 0, 1, 0, 0, 1, 1, DirectGraphics.TYPE_BYTE_1_GRAY);
        req(Arrays.equals(out, outBefore) && Arrays.equals(mask, maskBefore), "getPixels byte canonical stub raw=" + raw);
        if (raw) rawGapChecks++; else canonicalChecks++;
        System.out.println("G4G5_GETPX_BYTE_STUB_RAW=" + raw + " PRESERVED=true");
    }

    private static void probeRawGaps() {
        System.setProperty("rg35xx.raw2d", "true");
        expectRawGap("DRAWIMAGE", new ThrowingOp() {
            public void run() {
                PlatformImage dst = new PlatformImage(W, H);
                PlatformImage src = new PlatformImage(3, 2);
                int[] sp = src.getRG35XXPixels();
                for (int i = 0; i < sp.length; i++) sp[i] = 0xFF010203 + i;
                dst.getGraphics().drawImage(src, 2, 2, Graphics.TOP | Graphics.LEFT, 0);
            }
        });
        expectRawGap("DRAWPIXELS_BYTE", new ThrowingOp() {
            public void run() {
                PlatformImage dst = new PlatformImage(W, H);
                dst.getGraphics().drawPixels(new byte[]{(byte)0xAA}, null, 0, 8, 1, 1, 8, 1, 0, DirectGraphics.TYPE_BYTE_1_GRAY);
            }
        });
        expectRawGap("DRAWPIXELS_INT", new ThrowingOp() {
            public void run() {
                PlatformImage dst = new PlatformImage(W, H);
                dst.getGraphics().drawPixels(new int[]{0xFFFFFFFF}, true, 0, 1, 1, 1, 1, 1, 0, DirectGraphics.TYPE_INT_8888_ARGB);
            }
        });
        expectRawGap("DRAWPIXELS_SHORT", new ThrowingOp() {
            public void run() {
                PlatformImage dst = new PlatformImage(W, H);
                dst.getGraphics().drawPixels(new short[]{(short)0xFFFF}, true, 0, 1, 1, 1, 1, 1, 0, DirectGraphics.TYPE_USHORT_565_RGB);
            }
        });
        expectRawGap("GETPIXELS_INT", new ThrowingOp() {
            public void run() {
                PlatformImage src = new PlatformImage(W, H);
                src.getGraphics().getPixels(new int[1], 0, 1, 0, 0, 1, 1, DirectGraphics.TYPE_INT_8888_ARGB);
            }
        });
        expectRawGap("GETPIXELS_SHORT", new ThrowingOp() {
            public void run() {
                PlatformImage src = new PlatformImage(W, H);
                src.getGraphics().getPixels(new short[1], 0, 1, 0, 0, 1, 1, DirectGraphics.TYPE_USHORT_565_RGB);
            }
        });
        System.clearProperty("rg35xx.raw2d");
    }

    private static void expectRawGap(String name, ThrowingOp op) {
        Throwable got = null;
        try { op.run(); } catch (Throwable t) { got = t; }
        req(got != null, "expected current Raw2D gap " + name);
        rawGapChecks++;
        System.out.println("G4G5_RAW_GAP=" + name + " THROWABLE=" + got.getClass().getName());
    }

    private static PlatformImage canonicalSurface() {
        System.clearProperty("rg35xx.raw2d");
        PlatformImage p = new PlatformImage(W, H);
        PlatformGraphics g = p.getGraphics();
        g.setColor(BG);
        g.fillRect(0, 0, W, H);
        return p;
    }

    private static PlatformImage patternedCanonicalSurface() {
        PlatformImage p = canonicalSurface();
        int[] data = new int[W * H];
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                data[y * W + x] = 0xFF000000 | ((x * 17 & 0xFF) << 16) | ((y * 23 & 0xFF) << 8) | ((x * 7 + y * 11) & 0xFF);
            }
        }
        p.getGraphics().drawRGB(data, 0, W, 0, 0, W, H, true);
        return p;
    }

    private static int[] blank() {
        int[] p = new int[W * H];
        Arrays.fill(p, BG);
        return p;
    }

    private static int[] pixels(PlatformImage image) {
        int[] p = new int[W * H];
        image.getRGB(p, 0, W, 0, 0, W, H);
        return p;
    }

    private static T directTransform(int[] src, int w, int h, int manipulation) {
        if (manipulation == DirectGraphics.FLIP_HORIZONTAL) return spriteTransform(src, w, h, Sprite.TRANS_MIRROR);
        if (manipulation == DirectGraphics.FLIP_VERTICAL) return spriteTransform(src, w, h, Sprite.TRANS_MIRROR_ROT180);
        if (manipulation == DirectGraphics.ROTATE_90) return spriteTransform(src, w, h, Sprite.TRANS_ROT270);
        if (manipulation == DirectGraphics.ROTATE_180) return spriteTransform(src, w, h, Sprite.TRANS_ROT180);
        if (manipulation == DirectGraphics.ROTATE_270) return spriteTransform(src, w, h, Sprite.TRANS_ROT90);
        if (manipulation == (DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.FLIP_VERTICAL)) return spriteTransform(src, w, h, Sprite.TRANS_ROT180);
        if (manipulation == (DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.ROTATE_90)) {
            T a = spriteTransform(src, w, h, Sprite.TRANS_MIRROR);
            return spriteTransform(a.p, a.w, a.h, Sprite.TRANS_ROT270);
        }
        return new T((int[])src.clone(), w, h);
    }

    private static T spriteTransform(int[] src, int w, int h, int transform) {
        boolean swap = transform == Sprite.TRANS_MIRROR_ROT270 || transform == Sprite.TRANS_ROT90 ||
                       transform == Sprite.TRANS_ROT270 || transform == Sprite.TRANS_MIRROR_ROT90;
        int ow = swap ? h : w;
        int oh = swap ? w : h;
        int[] out = new int[ow * oh];
        for (int sy = 0; sy < h; sy++) {
            for (int sx = 0; sx < w; sx++) {
                int dx;
                int dy;
                switch (transform) {
                    case Sprite.TRANS_NONE: dx = sx; dy = sy; break;
                    case Sprite.TRANS_MIRROR_ROT180: dx = sx; dy = h - 1 - sy; break;
                    case Sprite.TRANS_MIRROR: dx = w - 1 - sx; dy = sy; break;
                    case Sprite.TRANS_ROT180: dx = w - 1 - sx; dy = h - 1 - sy; break;
                    case Sprite.TRANS_MIRROR_ROT270: dx = sy; dy = sx; break;
                    case Sprite.TRANS_ROT90: dx = h - 1 - sy; dy = sx; break;
                    case Sprite.TRANS_ROT270: dx = sy; dy = w - 1 - sx; break;
                    case Sprite.TRANS_MIRROR_ROT90: dx = h - 1 - sy; dy = w - 1 - sx; break;
                    default: throw new RuntimeException("bad sprite transform " + transform);
                }
                out[dy * ow + dx] = src[sy * w + sx];
            }
        }
        return new T(out, ow, oh);
    }

    private static void opaqueBlit(int[] dst, int dw, int dh, int[] src, int sw, int sh, int dx, int dy) {
        for (int y = 0; y < sh; y++) {
            int yy = dy + y;
            if (yy < 0 || yy >= dh) continue;
            for (int x = 0; x < sw; x++) {
                int xx = dx + x;
                if (xx < 0 || xx >= dw) continue;
                int s = src[y * sw + x];
                if (((s >>> 24) & 0xFF) == 255) dst[yy * dw + xx] = s;
            }
        }
    }

    private static int shortToColor(short c, int format) {
        int a = 0xFF, r = 0, g = 0, b = 0;
        if (format == DirectGraphics.TYPE_USHORT_1555_ARGB) {
            a = ((c >> 15) & 1) * 0xFF; r = (c >> 10) & 0x1F; g = (c >> 5) & 0x1F; b = c & 0x1F;
            r = (r << 3) | (r >> 2); g = (g << 3) | (g >> 2); b = (b << 3) | (b >> 2);
        } else if (format == DirectGraphics.TYPE_USHORT_444_RGB) {
            r = (c >> 8) & 0xF; g = (c >> 4) & 0xF; b = c & 0xF;
            r = (r << 4) | r; g = (g << 4) | g; b = (b << 4) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_4444_ARGB) {
            a = (c >> 12) & 0xF; r = (c >> 8) & 0xF; g = (c >> 4) & 0xF; b = c & 0xF;
            a = (a << 4) | a; r = (r << 4) | r; g = (g << 4) | g; b = (b << 4) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_555_RGB) {
            r = (c >> 10) & 0x1F; g = (c >> 5) & 0x1F; b = c & 0x1F;
            r = (r << 3) | (r >> 2); g = (g << 3) | (g >> 2); b = (b << 3) | (b >> 2);
        } else if (format == DirectGraphics.TYPE_USHORT_565_RGB) {
            r = (c >> 11) & 0x1F; g = (c >> 5) & 0x3F; b = c & 0x1F;
            r = (r << 3) | (r >> 2); g = (g << 2) | (g >> 4); b = (b << 3) | (b >> 2);
        }
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    private static short colorToShort(int c, int format) {
        int a = 0, r = 0, g = 0, b = 0, out = 0;
        if (format == DirectGraphics.TYPE_USHORT_1555_ARGB) {
            a = c >>> 31; r = (c >> 19) & 0x1F; g = (c >> 11) & 0x1F; b = (c >> 3) & 0x1F;
            out = (a << 15) | (r << 10) | (g << 5) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_444_RGB) {
            r = (c >> 20) & 0xF; g = (c >> 12) & 0xF; b = (c >> 4) & 0xF;
            out = (r << 8) | (g << 4) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_4444_ARGB) {
            a = (c >>> 28) & 0xF; r = (c >> 20) & 0xF; g = (c >> 12) & 0xF; b = (c >> 4) & 0xF;
            out = (a << 12) | (r << 8) | (g << 4) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_555_RGB) {
            r = (c >> 19) & 0x1F; g = (c >> 11) & 0x1F; b = (c >> 3) & 0x1F;
            out = (r << 10) | (g << 5) | b;
        } else if (format == DirectGraphics.TYPE_USHORT_565_RGB) {
            r = (c >> 19) & 0x1F; g = (c >> 10) & 0x3F; b = (c >> 3) & 0x1F;
            out = (r << 11) | (g << 5) | b;
        }
        return (short)out;
    }

    private static long checksum(int[] a) {
        long h = 1469598103934665603L;
        for (int i = 0; i < a.length; i++) { h ^= (a[i] & 0xFFFFFFFFL); h *= 1099511628211L; }
        return h;
    }

    private static long checksum(short[] a) {
        long h = 1469598103934665603L;
        for (int i = 0; i < a.length; i++) { h ^= (a[i] & 0xFFFFL); h *= 1099511628211L; }
        return h;
    }

    private static String hex(long v) { return Long.toHexString(v); }

    private static void req(boolean ok, String what) {
        if (!ok) throw new RuntimeException("P1A_G4G5_DIAGNOSTIC_FAIL=" + what);
    }
}
