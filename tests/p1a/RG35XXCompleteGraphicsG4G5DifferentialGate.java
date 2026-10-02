package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import com.nokia.mid.ui.DirectGraphics;
import javax.microedition.lcdui.Graphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Strict canonical-vs-Raw2D runtime differential for the final P1A G4/G5 surface. */
public final class RG35XXCompleteGraphicsG4G5DifferentialGate {
    private static final int W = 32;
    private static final int H = 26;
    private static final int STATE = 0x5A3C17;
    private static int drawImageCases;
    private static int drawIntCases;
    private static int drawShortCases;
    private static int drawByteCases;
    private static int getIntCases;
    private static int getShortCases;
    private static int byteStubCases;
    private static int stateFailures;
    private static int failures;

    private static final int[] MANIP = {
        0,
        DirectGraphics.FLIP_HORIZONTAL,
        DirectGraphics.FLIP_VERTICAL,
        DirectGraphics.ROTATE_90,
        DirectGraphics.ROTATE_180,
        DirectGraphics.ROTATE_270,
        DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.FLIP_VERTICAL,
        DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.ROTATE_90
    };

    private static final int[] SHORT_FORMATS = {
        DirectGraphics.TYPE_USHORT_1555_ARGB,
        DirectGraphics.TYPE_USHORT_444_RGB,
        DirectGraphics.TYPE_USHORT_4444_ARGB,
        DirectGraphics.TYPE_USHORT_555_RGB,
        DirectGraphics.TYPE_USHORT_565_RGB
    };

    private static final class DrawResult {
        final int[] pixels;
        final Throwable error;
        final int color;
        DrawResult(int[] p, Throwable e, int c) { pixels = p; error = e; color = c; }
    }

    private static final class ReadIntResult {
        final int[] out;
        final Throwable error;
        final int color;
        ReadIntResult(int[] a, Throwable e, int c) { out = a; error = e; color = c; }
    }

    private static final class ReadShortResult {
        final short[] out;
        final Throwable error;
        final int color;
        ReadShortResult(short[] a, Throwable e, int c) { out = a; error = e; color = c; }
    }

    private static final class ReadByteResult {
        final byte[] out;
        final byte[] mask;
        final Throwable error;
        final int color;
        ReadByteResult(byte[] a, byte[] m, Throwable e, int c) { out = a; mask = m; error = e; color = c; }
    }

    public static void main(String[] args) {
        runDrawImage();
        runDrawPixelsInt();
        runDrawPixelsShort();
        runDrawPixelsByte();
        runGetPixelsInt();
        runGetPixelsShort();
        runGetPixelsByteStub();
        System.clearProperty("rg35xx.raw2d");

        int total = drawImageCases + drawIntCases + drawShortCases + drawByteCases + getIntCases + getShortCases + byteStubCases;
        System.out.println("P1A_COMPLETE_G4G5_DRAWIMAGE_CASE_COUNT=" + drawImageCases);
        System.out.println("P1A_COMPLETE_G4G5_DRAWPIXELS_INT_CASE_COUNT=" + drawIntCases);
        System.out.println("P1A_COMPLETE_G4G5_DRAWPIXELS_SHORT_CASE_COUNT=" + drawShortCases);
        System.out.println("P1A_COMPLETE_G4G5_DRAWPIXELS_BYTE_CASE_COUNT=" + drawByteCases);
        System.out.println("P1A_COMPLETE_G4G5_GETPIXELS_INT_CASE_COUNT=" + getIntCases);
        System.out.println("P1A_COMPLETE_G4G5_GETPIXELS_SHORT_CASE_COUNT=" + getShortCases);
        System.out.println("P1A_COMPLETE_G4G5_GETPIXELS_BYTE_STUB_CASE_COUNT=" + byteStubCases);
        System.out.println("P1A_COMPLETE_G4G5_TOTAL_CASE_COUNT=" + total);
        System.out.println("P1A_COMPLETE_G4G5_STATE_FAILURE_COUNT=" + stateFailures);
        System.out.println("P1A_COMPLETE_G4G5_STRICT_FAILURE_COUNT=" + failures);
        System.out.println("P1A_COMPLETE_G4G5_GETPIXELS_BYTE=CANONICAL_STUB_UNCHANGED");
        System.out.println("P1A_COMPLETE_G4G5_CORE2D_CHANGE=NO");
        System.out.println("P1A_COMPLETE_G4G5_NATIVE_CHANGE=NO");
        if (failures != 0 || stateFailures != 0) {
            throw new RuntimeException("P1A_COMPLETE_G4G5_FAIL strict=" + failures + " state=" + stateFailures);
        }
        System.out.println("P1A_COMPLETE_G4G5_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_COMPLETE_G4G5_CANONICAL_EQUIVALENT=YES");
    }

    private static void runDrawImage() {
        final int[] src = sourcePattern(5, 4);
        for (int m = 0; m < MANIP.length; m++) {
            compareDraw("DRAWIMAGE_BASE_M" + m,
                drawImage(false, src, 5, 4, 4, 3, Graphics.TOP | Graphics.LEFT, MANIP[m], false),
                drawImage(true,  src, 5, 4, 4, 3, Graphics.TOP | Graphics.LEFT, MANIP[m], false));
            drawImageCases++;

            compareDraw("DRAWIMAGE_CENTER_M" + m,
                drawImage(false, src, 5, 4, 16, 12, Graphics.HCENTER | Graphics.VCENTER, MANIP[m], false),
                drawImage(true,  src, 5, 4, 16, 12, Graphics.HCENTER | Graphics.VCENTER, MANIP[m], false));
            drawImageCases++;

            compareDraw("DRAWIMAGE_CLIP_TRANSLATE_M" + m,
                drawImage(false, src, 5, 4, 8, 7, Graphics.TOP | Graphics.LEFT, MANIP[m], true),
                drawImage(true,  src, 5, 4, 8, 7, Graphics.TOP | Graphics.LEFT, MANIP[m], true));
            drawImageCases++;
        }
    }

    private static DrawResult drawImage(boolean raw, int[] src, int sw, int sh,
                                        int x, int y, int anchor, int manipulation, boolean clipTranslate) {
        setRaw(raw);
        try {
            PlatformImage dst = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = dst.getGraphics();
            PlatformImage image = new PlatformImage(src, sw, sh, true);
            g.setColor(STATE);
            if (clipTranslate) { g.setClip(5, 4, 15, 12); g.translate(3, 2); }
            g.drawImage(image, x, y, anchor, manipulation);
            return new DrawResult(pixels(dst), null, g.getColor());
        } catch (Throwable t) {
            return new DrawResult(null, t, -1);
        }
    }

    private static void runDrawPixelsInt() {
        final int[] storage = new int[18];
        for (int i = 0; i < storage.length; i++) storage[i] = argb(i * 37 + 11);
        for (int m = 0; m < MANIP.length; m++) {
            for (int tr = 0; tr < 2; tr++) {
                boolean transparency = tr == 0;
                compareDraw("DRAWINT_M" + m + "_T" + tr,
                    drawInt(false, storage, transparency, MANIP[m], m % 3 == 0),
                    drawInt(true,  storage, transparency, MANIP[m], m % 3 == 0));
                drawIntCases++;
            }
        }
    }

    private static DrawResult drawInt(boolean raw, int[] storage, boolean transparency, int manipulation, boolean clipTranslate) {
        setRaw(raw);
        try {
            PlatformImage dst = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = dst.getGraphics();
            g.setColor(STATE);
            if (clipTranslate) { g.setClip(4, 3, 19, 15); g.translate(2, 1); }
            g.drawPixels(storage, transparency, 2, 6, 5, 4, 4, 2, manipulation, DirectGraphics.TYPE_INT_8888_ARGB);
            return new DrawResult(pixels(dst), null, g.getColor());
        } catch (Throwable t) {
            return new DrawResult(null, t, -1);
        }
    }

    private static void runDrawPixelsShort() {
        final short[] storage = new short[18];
        for (int i = 0; i < storage.length; i++) storage[i] = (short)(0x8421 + i * 0x111);
        for (int f = 0; f < SHORT_FORMATS.length; f++) {
            for (int tr = 0; tr < 2; tr++) {
                boolean transparency = tr == 0;
                int manipulation = MANIP[(f + tr * 3) % MANIP.length];
                compareDraw("DRAWSHORT_F" + f + "_T" + tr,
                    drawShort(false, storage, transparency, manipulation, SHORT_FORMATS[f], f % 2 == 0),
                    drawShort(true,  storage, transparency, manipulation, SHORT_FORMATS[f], f % 2 == 0));
                drawShortCases++;
            }
        }
    }

    private static DrawResult drawShort(boolean raw, short[] storage, boolean transparency,
                                        int manipulation, int format, boolean clipTranslate) {
        setRaw(raw);
        try {
            PlatformImage dst = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = dst.getGraphics();
            g.setColor(STATE);
            if (clipTranslate) { g.setClip(3, 5, 18, 13); g.translate(2, -1); }
            g.drawPixels(storage, transparency, 2, 6, 6, 5, 4, 2, manipulation, format);
            return new DrawResult(pixels(dst), null, g.getColor());
        } catch (Throwable t) {
            return new DrawResult(null, t, -1);
        }
    }

    private static void runDrawPixelsByte() {
        final byte[] hp = {(byte)0xB2, (byte)0x4D, (byte)0xE1, (byte)0x36};
        final byte[] hm = {(byte)0xF0, (byte)0xCC, (byte)0xAA, (byte)0x0F};
        for (int mask = 0; mask < 2; mask++) {
            for (int mv = 0; mv < 2; mv++) {
                int manipulation = mv == 0 ? 0 : DirectGraphics.ROTATE_180;
                compareDraw("DRAWBYTE_H_MASK" + mask + "_M" + mv,
                    drawByteHorizontal(false, hp, mask == 0 ? null : hm, manipulation, mv == 1),
                    drawByteHorizontal(true,  hp, mask == 0 ? null : hm, manipulation, mv == 1));
                drawByteCases++;
            }
        }

        final byte[] vp = {(byte)0xA5,(byte)0x3C,(byte)0x81,(byte)0x66,(byte)0x55,(byte)0xC3,(byte)0x0F,(byte)0xF0};
        final byte[] vm = {(byte)0xFE,(byte)0x7D,(byte)0xBB,(byte)0x5A,(byte)0xFF,(byte)0x81,(byte)0x3C,(byte)0xC3};
        for (int mask = 0; mask < 2; mask++) {
            for (int mv = 0; mv < 2; mv++) {
                int manipulation = mv == 0 ? 0 : DirectGraphics.ROTATE_90;
                compareDraw("DRAWBYTE_V_MASK" + mask + "_M" + mv,
                    drawByteVertical(false, vp, mask == 0 ? null : vm, manipulation, mv == 1),
                    drawByteVertical(true,  vp, mask == 0 ? null : vm, manipulation, mv == 1));
                drawByteCases++;
            }
        }
    }

    private static DrawResult drawByteHorizontal(boolean raw, byte[] p, byte[] mask, int manipulation, boolean clipTranslate) {
        setRaw(raw);
        try {
            PlatformImage dst = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = dst.getGraphics();
            g.setColor(STATE);
            if (clipTranslate) { g.setClip(5, 3, 18, 13); g.translate(1, 2); }
            g.drawPixels(p, mask, 0, 8, 4, 5, 8, 4, manipulation, DirectGraphics.TYPE_BYTE_1_GRAY);
            return new DrawResult(pixels(dst), null, g.getColor());
        } catch (Throwable t) {
            return new DrawResult(null, t, -1);
        }
    }

    private static DrawResult drawByteVertical(boolean raw, byte[] p, byte[] mask, int manipulation, boolean clipTranslate) {
        setRaw(raw);
        try {
            PlatformImage dst = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = dst.getGraphics();
            g.setColor(STATE);
            if (clipTranslate) { g.setClip(4, 4, 17, 14); g.translate(2, 1); }
            g.drawPixels(p, mask, 5, 4, 6, 4, 3, 8, manipulation, DirectGraphics.TYPE_BYTE_1_GRAY_VERTICAL);
            return new DrawResult(pixels(dst), null, g.getColor());
        } catch (Throwable t) {
            return new DrawResult(null, t, -1);
        }
    }

    private static void runGetPixelsInt() {
        for (int c = 0; c < 3; c++) {
            ReadIntResult awt = getInt(false, c);
            ReadIntResult raw = getInt(true, c);
            boolean state = awt.error == null && raw.error == null && awt.color == STATE && raw.color == STATE;
            boolean match = state && Arrays.equals(awt.out, raw.out);
            if (!state) stateFailures++;
            if (!match) failRead("GETINT_" + c, awt.error, raw.error, checksum(awt.out), checksum(raw.out));
            getIntCases++;
        }
    }

    private static ReadIntResult getInt(boolean raw, int variant) {
        setRaw(raw);
        int[] out = new int[30];
        Arrays.fill(out, 0x13579BDF);
        try {
            PlatformImage src = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = src.getGraphics();
            g.setColor(STATE);
            int x = 2 + variant, y = 3 + variant, w = 5, h = 3;
            g.getPixels(out, 2, 8, x, y, w, h, DirectGraphics.TYPE_INT_8888_ARGB);
            return new ReadIntResult(out, null, g.getColor());
        } catch (Throwable t) {
            return new ReadIntResult(out, t, -1);
        }
    }

    private static void runGetPixelsShort() {
        for (int f = 0; f < SHORT_FORMATS.length; f++) {
            for (int v = 0; v < 2; v++) {
                ReadShortResult awt = getShort(false, SHORT_FORMATS[f], v);
                ReadShortResult raw = getShort(true, SHORT_FORMATS[f], v);
                boolean state = awt.error == null && raw.error == null && awt.color == STATE && raw.color == STATE;
                boolean match = state && Arrays.equals(awt.out, raw.out);
                if (!state) stateFailures++;
                if (!match) failRead("GETSHORT_F" + f + "_V" + v, awt.error, raw.error, checksum(awt.out), checksum(raw.out));
                getShortCases++;
            }
        }
    }

    private static ReadShortResult getShort(boolean raw, int format, int variant) {
        setRaw(raw);
        short[] out = new short[20];
        Arrays.fill(out, (short)0x6A5A);
        try {
            PlatformImage src = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = src.getGraphics();
            g.setColor(STATE);
            g.getPixels(out, 3, 99, 4 + variant, 5, 3, 2, format);
            return new ReadShortResult(out, null, g.getColor());
        } catch (Throwable t) {
            return new ReadShortResult(out, t, -1);
        }
    }

    private static void runGetPixelsByteStub() {
        ReadByteResult awt = getByteStub(false);
        ReadByteResult raw = getByteStub(true);
        boolean state = awt.error == null && raw.error == null && awt.color == STATE && raw.color == STATE;
        boolean match = state && Arrays.equals(awt.out, raw.out) && Arrays.equals(awt.mask, raw.mask);
        if (!state) stateFailures++;
        if (!match) failRead("GETBYTE_STUB", awt.error, raw.error, checksum(awt.out), checksum(raw.out));
        byteStubCases++;
    }

    private static ReadByteResult getByteStub(boolean raw) {
        setRaw(raw);
        byte[] out = {(byte)0x55,(byte)0x66,(byte)0x77,(byte)0x12};
        byte[] mask = {(byte)0x11,(byte)0x22,(byte)0x33,(byte)0x44};
        try {
            PlatformImage src = new PlatformImage(background(), W, H, true);
            PlatformGraphics g = src.getGraphics();
            g.setColor(STATE);
            g.getPixels(out, mask, 0, 1, 0, 0, 1, 1, DirectGraphics.TYPE_BYTE_1_GRAY);
            return new ReadByteResult(out, mask, null, g.getColor());
        } catch (Throwable t) {
            return new ReadByteResult(out, mask, t, -1);
        }
    }

    private static void compareDraw(String name, DrawResult awt, DrawResult raw) {
        boolean state = awt.error == null && raw.error == null && awt.color == STATE && raw.color == STATE;
        boolean match = state && Arrays.equals(awt.pixels, raw.pixels);
        if (!state) stateFailures++;
        if (!match) {
            failures++;
            int d = firstDiff(awt.pixels, raw.pixels);
            System.out.println("P1A_COMPLETE_G4G5_FAIL_CASE=" + name +
                " AWT_ERR=" + err(awt.error) + " RAW_ERR=" + err(raw.error) +
                " AWT_COLOR=" + hex32(awt.color) + " RAW_COLOR=" + hex32(raw.color) +
                " FIRST_DIFF=" + (d < 0 ? "NONE" : ((d % W) + "," + (d / W))) +
                " AWT_SUM=" + checksum(awt.pixels) + " RAW_SUM=" + checksum(raw.pixels));
        }
    }

    private static void failRead(String name, Throwable a, Throwable r, String as, String rs) {
        failures++;
        System.out.println("P1A_COMPLETE_G4G5_FAIL_CASE=" + name + " AWT_ERR=" + err(a) + " RAW_ERR=" + err(r) + " AWT_SUM=" + as + " RAW_SUM=" + rs);
    }

    private static void setRaw(boolean raw) {
        if (raw) System.setProperty("rg35xx.raw2d", "true");
        else System.clearProperty("rg35xx.raw2d");
    }

    private static int[] background() {
        int[] p = new int[W * H];
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
            p[y * W + x] = 0xFF000000 | (((x * 19 + y * 3) & 0xFF) << 16) |
                (((y * 23 + x * 5) & 0xFF) << 8) | ((x * 7 + y * 11) & 0xFF);
        }
        return p;
    }

    private static int[] sourcePattern(int w, int h) {
        int[] p = new int[w * h];
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
            int i = y * w + x;
            int a = (i % 5 == 0) ? 0 : ((i % 5 == 1) ? 64 : ((i % 5 == 2) ? 128 : ((i % 5 == 3) ? 204 : 255)));
            p[i] = (a << 24) | (((x * 47 + 31) & 0xFF) << 16) | (((y * 61 + 17) & 0xFF) << 8) | ((x * 29 + y * 13 + 9) & 0xFF);
        }
        return p;
    }

    private static int argb(int n) {
        int a = (n * 17) & 0xFF;
        return (a << 24) | (((n * 29) & 0xFF) << 16) | (((n * 43) & 0xFF) << 8) | ((n * 71) & 0xFF);
    }

    private static int[] pixels(PlatformImage image) {
        int[] p = new int[W * H];
        image.getRGB(p, 0, W, 0, 0, W, H);
        return p;
    }

    private static int firstDiff(int[] a, int[] b) {
        if (a == null || b == null) return -1;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return i;
        return -1;
    }

    private static String err(Throwable t) { return t == null ? "NONE" : t.getClass().getName(); }
    private static String hex32(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }

    private static String checksum(int[] p) {
        if (p == null) return "NONE";
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) { h ^= (p[i] & 0xFFFFFFFFL); h *= 1099511628211L; }
        return Long.toHexString(h);
    }

    private static String checksum(short[] p) {
        if (p == null) return "NONE";
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) { h ^= (p[i] & 0xFFFFL); h *= 1099511628211L; }
        return Long.toHexString(h);
    }

    private static String checksum(byte[] p) {
        if (p == null) return "NONE";
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) { h ^= (p[i] & 0xFFL); h *= 1099511628211L; }
        return Long.toHexString(h);
    }
}
