import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.midlet.MIDlet;
import javax.microedition.midlet.MIDletStateChangeException;

import com.nokia.mid.ui.DirectGraphics;
import com.nokia.mid.ui.DirectUtils;

import org.recompile.mobile.PlatformGraphics;

/**
 * One generated/non-commercial P1A graphics module exerciser.
 *
 * It intentionally uses only MIDP/Nokia graphics APIs except clearRect, which
 * is a pinned PlatformGraphics method in the locked P1A contract but is not
 * declared by the old javax.microedition.lcdui.Graphics base class.
 *
 * Any key exits. PASS/FAIL markers are emitted to stdout and rendered as a
 * simple status board so original-device evidence can capture both channels.
 */
public final class RG35XXPlatformExerciserP1A extends MIDlet {
    private P1ACanvas canvas;

    protected void startApp() throws MIDletStateChangeException {
        if (canvas == null) { canvas = new P1ACanvas(this); }
        Display.getDisplay(this).setCurrent(canvas);
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) throws MIDletStateChangeException { }

    private static final class P1ACanvas extends Canvas {
        private static final int BG = 0x00101820;
        private static final int PASS = 0x0000CC44;
        private static final int FAIL = 0x00CC2233;
        private static final int TEXT = 0x00FFFFFF;

        private final RG35XXPlatformExerciserP1A app;
        private final String[] names = new String[14];
        private final boolean[] results = new boolean[14];
        private int count;
        private int checksum = 0x13579BDF;
        private boolean overall = true;

        P1ACanvas(RG35XXPlatformExerciserP1A owner) {
            app = owner;
            setFullScreenMode(true);
            System.out.println("P1A_EXERCISER_BOOT=PASS");
            runAll();
        }

        private void runAll() {
            record("CLEAR_COPY_OVERLAP", testClearCopy());
            record("MIDP_SHAPES", testMidpShapes());
            record("DG_SHAPES_ALPHA", testDirectShapes());
            record("DG_IMAGE_MANIP", testDrawImageManipulation());
            record("DG_PIXELS_INT", testDrawPixelsInt());
            record("DG_PIXELS_SHORT", testDrawPixelsShort());
            record("DG_PIXELS_BYTE", testDrawPixelsByte());
            record("DG_GETPIXELS_INT", testGetPixelsInt());
            record("DG_GETPIXELS_SHORT", testGetPixelsShort());
            record("DG_GETPIXELS_BYTE_STUB", testGetPixelsByteStub());
            record("CLIP_TRANSLATE", testClipTranslate());
            record("ANCHOR_MATRIX", testAnchor());
            record("DEGENERATE_BOUNDS", testDegenerateBounds());
            record("ALPHA_MATRIX", testAlphaMatrix());
            System.out.println("P1A_EXERCISER_CHECKSUM=" + Integer.toHexString(checksum));
            System.out.println("P1A_EXERCISER_RESULT=" + (overall ? "PASS" : "FAIL"));
        }

        private void record(String name, boolean ok) {
            names[count] = name;
            results[count] = ok;
            count++;
            overall = overall && ok;
            checksum = checksum * 33 + name.hashCode();
            checksum = checksum * 33 + (ok ? 1 : 0);
            System.out.println("P1A_EXERCISER_" + name + "=" + (ok ? "PASS" : "FAIL"));
        }

        private boolean testClearCopy() {
            try {
                Image image = Image.createImage(16, 8);
                PlatformGraphics g = (PlatformGraphics) image.getGraphics();
                g.setColor(0x000000); g.fillRect(0, 0, 16, 8);
                int[] row = {
                    0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFF00,
                    0xFFFF00FF, 0xFF00FFFF, 0xFFFFFFFF, 0xFF808080
                };
                g.drawRGB(row, 0, 8, 0, 2, 8, 1, true);
                g.copyArea(0, 2, 6, 1, 1, 2, Graphics.TOP | Graphics.LEFT);
                int[] out = new int[8];
                image.getRGB(out, 0, 8, 0, 2, 8, 1);
                for (int i = 1; i <= 6; i++) { req(out[i] == row[0], "copy-live-overlap"); }
                g.clearRect(1, 2, 1, 1);
                image.getRGB(out, 0, 8, 0, 2, 8, 1);
                req((out[1] >>> 24) == 0, "clear-alpha");
                return true;
            } catch (Throwable t) { fail("CLEAR_COPY_OVERLAP", t); return false; }
        }

        private boolean testMidpShapes() {
            try {
                Image image = Image.createImage(40, 32);
                Graphics g = image.getGraphics();
                g.setColor(0x000000); g.fillRect(0, 0, 40, 32);
                g.setColor(0x00FF00);
                g.fillRoundRect(2, 2, 12, 10, 6, 6);
                req((pixel(image, 2, 2) & 0x00FFFFFF) == 0x00FF00, "fillround-canonical-fullrect");
                g.setColor(0xFF0000); g.fillTriangle(18, 2, 30, 2, 24, 14);
                req((pixel(image, 24, 6) & 0x00FFFFFF) == 0xFF0000, "filltriangle");
                g.setColor(0xFFFFFF); g.drawRoundRect(2, 18, 12, 10, 6, 6);
                g.drawArc(18, 18, 10, 10, 0, 270);
                g.fillArc(30, 18, 8, 10, 45, 180);
                req(countNonBlack(image) > 80, "shape-count");
                return true;
            } catch (Throwable t) { fail("MIDP_SHAPES", t); return false; }
        }

        private boolean testDirectShapes() {
            try {
                Image image = Image.createImage(32, 24);
                Graphics g = image.getGraphics();
                g.setColor(0x0000FF); g.fillRect(0, 0, 32, 24);
                DirectGraphics dg = DirectUtils.getDirectGraphics(g);
                int[] xs = {2, 14, 14, 2};
                int[] ys = {2, 2, 12, 12};
                dg.fillPolygon(xs, 0, ys, 0, 4, 0x80FF0000);
                int mixed = pixel(image, 6, 6) & 0x00FFFFFF;
                req(mixed != 0x0000FF && mixed != 0xFF0000, "alpha-fillpolygon");
                dg.drawPolygon(xs, 0, ys, 0, 4, 0xFFFFFFFF);
                dg.drawTriangle(17, 2, 29, 2, 23, 12, 0xFFFFFFFF);
                dg.fillTriangle(17, 14, 29, 14, 23, 22, 0xFFFF00FF);
                req((pixel(image, 23, 17) & 0x00FFFFFF) == 0xFF00FF, "dg-filltriangle");
                return true;
            } catch (Throwable t) { fail("DG_SHAPES_ALPHA", t); return false; }
        }

        private boolean testDrawImageManipulation() {
            try {
                int[] src = {
                    0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
                    0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF
                };
                Image input = Image.createRGBImage(src, 3, 2, true);
                Image dst = Image.createImage(14, 12);
                Graphics g = dst.getGraphics();
                g.setColor(0x000000); g.fillRect(0, 0, 14, 12);
                DirectGraphics dg = DirectUtils.getDirectGraphics(g);
                dg.drawImage(input, 2, 2, Graphics.TOP | Graphics.LEFT, DirectGraphics.ROTATE_90);
                int changed = 0;
                for (int y = 2; y < 5; y++) for (int x = 2; x < 4; x++) {
                    if ((pixel(dst, x, y) & 0x00FFFFFF) != 0) { changed++; }
                }
                req(changed == 6, "rot90-swapped-dimensions");
                req((pixel(dst, 4, 2) & 0x00FFFFFF) == 0, "rot90-no-spill");
                dg.drawImage(input, 6, 2, Graphics.TOP | Graphics.LEFT, DirectGraphics.FLIP_HORIZONTAL);
                dg.drawImage(input, 6, 6, Graphics.TOP | Graphics.LEFT,
                    DirectGraphics.FLIP_HORIZONTAL | DirectGraphics.ROTATE_90);
                return true;
            } catch (Throwable t) { fail("DG_IMAGE_MANIP", t); return false; }
        }

        private boolean testDrawPixelsInt() {
            try {
                Image image = blackImage(10, 8);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                int[] p = {0xFFFF0000,0xFF00FF00,0xFF0000FF,0xFFFFFFFF};
                dg.drawPixels(p, false, 0, 2, 3, 2, 2, 2, 0, DirectGraphics.TYPE_INT_8888_ARGB);
                req(pixel(image, 3, 2) == p[0], "int00");
                req(pixel(image, 4, 3) == p[3], "int11");
                return true;
            } catch (Throwable t) { fail("DG_PIXELS_INT", t); return false; }
        }

        private boolean testDrawPixelsShort() {
            try {
                Image image = blackImage(10, 8);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                short[] p = {(short)0xF800,(short)0x07E0,(short)0x001F,(short)0xFFFF};
                dg.drawPixels(p, true, 0, 2, 2, 2, 2, 2, 0, DirectGraphics.TYPE_USHORT_565_RGB);
                req((pixel(image, 2, 2) & 0x00FFFFFF) == 0xFF0000, "short-red");
                req((pixel(image, 3, 2) & 0x00FFFFFF) == 0x00FF00, "short-green");
                req((pixel(image, 2, 3) & 0x00FFFFFF) == 0x0000FF, "short-blue");
                return true;
            } catch (Throwable t) { fail("DG_PIXELS_SHORT", t); return false; }
        }

        private boolean testDrawPixelsByte() {
            try {
                Image image = blackImage(16, 10);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                byte[] row = {(byte)0xAA};
                dg.drawPixels(row, null, 0, 8, 2, 2, 8, 1, 0, DirectGraphics.TYPE_BYTE_1_GRAY);
                req((pixel(image, 2, 2) & 0x00FFFFFF) == 0x000000, "byte-msb-black");
                req((pixel(image, 3, 2) & 0x00FFFFFF) == 0xFFFFFF, "byte-msb-white");
                byte[] vertical = {(byte)0x01,(byte)0x00};
                dg.drawPixels(vertical, null, 0, 2, 2, 4, 2, 8, 0, DirectGraphics.TYPE_BYTE_1_GRAY_VERTICAL);
                return true;
            } catch (Throwable t) { fail("DG_PIXELS_BYTE", t); return false; }
        }

        private boolean testGetPixelsInt() {
            try {
                int[] src = {0xFFFF0000,0xFF00FF00,0xFF0000FF,0xFFFFFFFF};
                Image image = Image.createRGBImage(src, 2, 2, true);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                int[] out = new int[12];
                for (int i = 0; i < out.length; i++) out[i] = 0x12345678;
                dg.getPixels(out, 1, 4, 0, 0, 2, 2, DirectGraphics.TYPE_INT_8888_ARGB);
                req(out[1] == src[0] && out[2] == src[1], "getint-row0");
                req(out[5] == src[2] && out[6] == src[3], "getint-row1-scanlength");
                return true;
            } catch (Throwable t) { fail("DG_GETPIXELS_INT", t); return false; }
        }

        private boolean testGetPixelsShort() {
            try {
                int[] src = {0xFFFF0000,0xFF00FF00,0xFF0000FF,0xFFFFFFFF};
                Image image = Image.createRGBImage(src, 2, 2, true);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                short[] out = new short[10];
                for (int i = 0; i < out.length; i++) out[i] = (short)0x2222;
                dg.getPixels(out, 2, 7, 0, 0, 2, 2, DirectGraphics.TYPE_USHORT_565_RGB);
                req((out[2] & 0xFFFF) == 0xF800, "getshort-red");
                req((out[3] & 0xFFFF) == 0x07E0, "getshort-green");
                req((out[4] & 0xFFFF) == 0x001F, "getshort-contiguous-row1");
                req((out[5] & 0xFFFF) == 0xFFFF, "getshort-white");
                req((out[9] & 0xFFFF) == 0x2222, "getshort-scanlength-ignored");
                return true;
            } catch (Throwable t) { fail("DG_GETPIXELS_SHORT", t); return false; }
        }

        private boolean testGetPixelsByteStub() {
            try {
                Image image = blackImage(8, 8);
                DirectGraphics dg = DirectUtils.getDirectGraphics(image.getGraphics());
                byte[] out = {0x55,0x55,0x55,0x55};
                byte[] mask = {0x33,0x33,0x33,0x33};
                dg.getPixels(out, mask, 0, 4, 0, 0, 4, 1, DirectGraphics.TYPE_BYTE_1_GRAY);
                for (int i = 0; i < out.length; i++) {
                    req(out[i] == 0x55 && mask[i] == 0x33, "byte-stub-unchanged");
                }
                return true;
            } catch (Throwable t) { fail("DG_GETPIXELS_BYTE_STUB", t); return false; }
        }

        private boolean testClipTranslate() {
            try {
                Image image = blackImage(16, 16);
                Graphics g = image.getGraphics();
                g.setClip(4, 4, 6, 6);
                g.translate(2, 1);
                g.setColor(0xFFFFFF); g.fillRect(0, 0, 10, 10);
                req((pixel(image, 4, 4) & 0x00FFFFFF) == 0xFFFFFF, "clip-in");
                req((pixel(image, 3, 4) & 0x00FFFFFF) == 0x000000, "clip-left");
                req((pixel(image, 9, 9) & 0x00FFFFFF) == 0xFFFFFF, "clip-bottom-in");
                req((pixel(image, 10, 10) & 0x00FFFFFF) == 0x000000, "clip-out");
                return true;
            } catch (Throwable t) { fail("CLIP_TRANSLATE", t); return false; }
        }

        private boolean testAnchor() {
            try {
                Image image = blackImage(16, 16);
                Graphics g = image.getGraphics();
                g.setColor(0xFF0000); g.fillRect(0, 0, 2, 2);
                g.copyArea(0, 0, 2, 2, 10, 10, Graphics.RIGHT | Graphics.BOTTOM);
                req((pixel(image, 8, 8) & 0x00FFFFFF) == 0xFF0000, "copy-anchor-right-bottom");
                req((pixel(image, 10, 10) & 0x00FFFFFF) == 0x000000, "copy-anchor-bound");
                return true;
            } catch (Throwable t) { fail("ANCHOR_MATRIX", t); return false; }
        }

        private boolean testDegenerateBounds() {
            try {
                Image image = blackImage(20, 20);
                Graphics g = image.getGraphics();
                g.setColor(0xFFFFFF);
                g.drawArc(5,5,-1,10,0,90); g.fillArc(5,5,10,-1,0,90);
                g.drawRoundRect(5,5,-1,8,4,4); g.fillTriangle(-8,-8,-2,-8,-5,-2);
                DirectGraphics dg = DirectUtils.getDirectGraphics(g);
                dg.drawTriangle(-10,-10,-5,-10,-8,-5,0xFFFFFFFF);
                int[] xs = {-10,-5,-5,-10}; int[] ys = {-10,-10,-5,-5};
                dg.fillPolygon(xs,0,ys,0,4,0xFFFFFFFF);
                req(countNonBlack(image) == 0, "bounds-no-visible-write");
                return true;
            } catch (Throwable t) { fail("DEGENERATE_BOUNDS", t); return false; }
        }

        private boolean testAlphaMatrix() {
            try {
                Image image = Image.createImage(20, 20);
                Graphics g = image.getGraphics();
                g.setColor(0x0000FF); g.fillRect(0, 0, 20, 20);
                DirectGraphics dg = DirectUtils.getDirectGraphics(g);
                dg.fillTriangle(2,2,18,2,10,18,0x80FF0000);
                int p = pixel(image, 10, 8) & 0x00FFFFFF;
                req(p != 0x0000FF && p != 0xFF0000, "alpha-src-over");
                return true;
            } catch (Throwable t) { fail("ALPHA_MATRIX", t); return false; }
        }

        protected void paint(Graphics g) {
            g.setColor(BG); g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(overall ? PASS : FAIL); g.fillRect(0, 0, getWidth(), 18);
            g.setColor(TEXT); g.drawString("P1A GRAPHICS " + (overall ? "PASS" : "FAIL"), 4, 2, Graphics.TOP | Graphics.LEFT);
            int y = 22;
            for (int i = 0; i < count; i++) {
                g.setColor(results[i] ? PASS : FAIL); g.fillRect(4, y + 2, 8, 8);
                g.setColor(TEXT); g.drawString(names[i], 16, y, Graphics.TOP | Graphics.LEFT);
                y += 15;
            }
            drawVisualMatrix(g, Math.max(y + 2, 236));
            g.setColor(TEXT);
            g.drawString("ANY KEY: EXIT", 4, getHeight() - 14, Graphics.TOP | Graphics.LEFT);
        }

        private void drawVisualMatrix(Graphics g, int y0) {
            if (y0 > getHeight() - 55) y0 = getHeight() - 55;
            g.setClip(0, y0, getWidth(), 50);
            g.setColor(0x203040); g.fillRect(0, y0, getWidth(), 50);
            g.setColor(0x00FF00); g.fillRoundRect(4, y0 + 4, 28, 18, 8, 8);
            g.setColor(0xFFFFFF); g.drawRoundRect(36, y0 + 4, 28, 18, 8, 8);
            g.setColor(0xFF8800); g.fillTriangle(70, y0 + 22, 84, y0 + 4, 98, y0 + 22);
            g.setColor(0x00AAFF); g.drawArc(104, y0 + 3, 24, 20, 0, 300);
            g.setColor(0xAA44FF); g.fillArc(134, y0 + 3, 24, 20, 30, 220);
            DirectGraphics dg = DirectUtils.getDirectGraphics(g);
            int[] xs = {166,184,190,174}; int[] ys = {y0+4,y0+2,y0+20,y0+22};
            dg.drawPolygon(xs,0,ys,0,4,0xFFFFFFFF);
            dg.fillTriangle(198,y0+22,212,y0+4,226,y0+22,0x80FF0055);
            g.setClip(0, 0, getWidth(), getHeight());
        }

        public void keyPressed(int keyCode) { app.notifyDestroyed(); }

        private static Image blackImage(int w, int h) {
            Image image = Image.createImage(w, h);
            Graphics g = image.getGraphics();
            g.setColor(0x000000); g.fillRect(0, 0, w, h);
            return image;
        }

        private static int pixel(Image image, int x, int y) {
            int[] p = new int[1];
            image.getRGB(p, 0, 1, x, y, 1, 1);
            return p[0];
        }

        private static int countNonBlack(Image image) {
            int w = image.getWidth(), h = image.getHeight();
            int[] p = new int[w * h];
            image.getRGB(p, 0, w, 0, 0, w, h);
            int n = 0;
            for (int i = 0; i < p.length; i++) if ((p[i] & 0x00FFFFFF) != 0) n++;
            return n;
        }

        private static void req(boolean ok, String label) {
            if (!ok) throw new RuntimeException(label);
        }

        private static void fail(String group, Throwable t) {
            System.out.println("P1A_EXERCISER_FAILURE=" + group + ":" + t.toString());
            t.printStackTrace();
        }
    }
}
