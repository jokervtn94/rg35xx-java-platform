package org.recompile.rg35xx.p1a.device;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.midlet.MIDlet;

import org.recompile.mobile.PlatformGraphics;

/**
 * Original-RG35XX physical exerciser for P1A-G1 only.
 * Scope: PlatformGraphics.clearRect + Graphics.copyArea.
 * No commercial-game behavior is used as an acceptance condition.
 */
public final class RG35XXP1AG1DeviceExerciserMIDlet extends MIDlet {
    private static final int W = 20;
    private static final int H = 16;
    private boolean pass;
    private String failCase = "NONE";

    protected void startApp() {
        System.out.println("P1A_G1_DEVICE_EXERCISER_BOOT=PASS");
        pass = runAll();
        System.out.println("P1A_G1_DEVICE_EXERCISER_FAIL_CASE=" + failCase);
        System.out.println("P1A_G1_DEVICE_EXERCISER_RESULT=" + (pass ? "PASS" : "FAIL"));
        System.out.println("P1A_G1_DEVICE_PASS=NO_PENDING_PHYSICAL_REVIEW");
        System.out.flush();

        Display.getDisplay(this).setCurrent(new ResultCanvas(pass));
        Thread finisher = new Thread(new Runnable() {
            public void run() {
                try { Thread.sleep(4000L); } catch (InterruptedException e) { }
                System.out.println("P1A_G1_DEVICE_EXERCISER_NORMAL_EXIT=PASS");
                System.out.flush();
                System.exit(pass ? 0 : 2);
            }
        }, "p1a-g1-finish");
        finisher.start();
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    private boolean runAll() {
        if (!runCase("CLEAR_BASIC", testClearBasic())) return false;
        if (!runCase("CLEAR_CLIP_TRANSLATE", testClearClipTranslate())) return false;
        if (!runCase("CLEAR_DEGENERATE", testClearDegenerate())) return false;
        if (!runCase("COPY_BASIC", testCopyBasic())) return false;
        if (!runCase("COPY_ANCHOR", testCopyAnchor())) return false;
        if (!runCase("COPY_CLIP_TRANSLATE", testCopyClipTranslate())) return false;
        if (!runCase("COPY_OVERLAP_RIGHT_LIVE", testCopyOverlapRightLive())) return false;
        if (!runCase("COPY_OVERLAP_DOWN_LIVE", testCopyOverlapDownLive())) return false;
        if (!runCase("COPY_TRANSPARENT_SOURCE", testCopyTransparentSource())) return false;
        return true;
    }

    private boolean runCase(String name, boolean ok) {
        System.out.println("P1A_G1_DEVICE_CASE=" + name + " RESULT=" + (ok ? "PASS" : "FAIL"));
        if (!ok) failCase = name;
        return ok;
    }

    private boolean testClearBasic() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x315579);
        platform(g).clearRect(5, 4, 6, 5);
        int[] p = pixels(img);
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                int expected = (x >= 5 && x < 11 && y >= 4 && y < 9) ? 0x00000000 : 0xFF315579;
                if (p[y * W + x] != expected) return false;
            }
        }
        return true;
    }

    private boolean testClearClipTranslate() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x224466);
        g.setClip(5, 4, 8, 6);
        g.translate(3, 2);
        platform(g).clearRect(0, 0, W, H);
        int[] p = pixels(img);
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                int expected = (x >= 5 && x < 13 && y >= 4 && y < 10) ? 0x00000000 : 0xFF224466;
                if (p[y * W + x] != expected) return false;
            }
        }
        return true;
    }

    private boolean testClearDegenerate() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x556677);
        platform(g).clearRect(3, 3, 0, 5);
        platform(g).clearRect(3, 3, 5, 0);
        platform(g).clearRect(3, 3, -2, 5);
        platform(g).clearRect(3, 3, 5, -2);
        int[] p = pixels(img);
        for (int i = 0; i < p.length; i++) if (p[i] != 0xFF556677) return false;
        return true;
    }

    private boolean testCopyBasic() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x101010);
        g.setColor(0xCC4422); g.fillRect(2, 3, 4, 3);
        g.setColor(0x33AA66); g.fillRect(3, 4, 1, 1);
        int[] before = pixels(img);
        g.copyArea(2, 3, 4, 3, 10, 5, Graphics.TOP | Graphics.LEFT);
        int[] after = pixels(img);
        for (int y = 0; y < 3; y++) {
            for (int x = 0; x < 4; x++) {
                if (after[(5 + y) * W + (10 + x)] != before[(3 + y) * W + (2 + x)]) return false;
            }
        }
        return true;
    }

    private boolean testCopyAnchor() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x181818);
        g.setColor(0xAA3300); g.fillRect(2, 2, 4, 3);
        int[] before = pixels(img);
        g.copyArea(2, 2, 4, 3, 15, 11, Graphics.RIGHT | Graphics.BOTTOM);
        int[] after = pixels(img);
        int dx = 11;
        int dy = 8;
        for (int y = 0; y < 3; y++) {
            for (int x = 0; x < 4; x++) {
                if (after[(dy + y) * W + (dx + x)] != before[(2 + y) * W + (2 + x)]) return false;
            }
        }
        return true;
    }

    private boolean testCopyClipTranslate() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x202020);
        g.setColor(0xC04020); g.fillRect(2, 2, 4, 3);
        g.setClip(9, 6, 3, 2);
        g.translate(2, 1);
        g.copyArea(2, 2, 4, 3, 7, 5, Graphics.TOP | Graphics.LEFT);
        int[] p = pixels(img);
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                if (x >= 9 && x < 12 && y >= 6 && y < 8) {
                    if (p[y * W + x] != 0xFFC04020) return false;
                } else if (x >= 9 && x < 13 && y >= 6 && y < 9) {
                    if (p[y * W + x] != 0xFF202020) return false;
                }
            }
        }
        return true;
    }

    private boolean testCopyOverlapRightLive() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x000000);
        int[] colors = {0x112233, 0x223344, 0x334455, 0x445566, 0x556677};
        for (int x = 0; x < colors.length; x++) {
            g.setColor(colors[x]); g.fillRect(x, 0, 1, 1);
        }
        g.copyArea(0, 0, 4, 1, 1, 0, Graphics.TOP | Graphics.LEFT);
        int[] p = pixels(img);
        int first = 0xFF112233;
        if (p[0] != first) return false;
        for (int x = 1; x <= 4; x++) if (p[x] != first) return false;
        return true;
    }

    private boolean testCopyOverlapDownLive() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x000000);
        int[] colors = {0x102030, 0x304050, 0x506070, 0x708090, 0x90A0B0};
        for (int y = 0; y < colors.length; y++) {
            g.setColor(colors[y]); g.fillRect(0, y, 1, 1);
        }
        g.copyArea(0, 0, 1, 4, 0, 1, Graphics.TOP | Graphics.LEFT);
        int[] p = pixels(img);
        int first = 0xFF102030;
        if (p[0] != first) return false;
        for (int y = 1; y <= 4; y++) if (p[y * W] != first) return false;
        return true;
    }

    private boolean testCopyTransparentSource() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x204080);
        platform(g).clearRect(1, 1, 4, 3);
        g.setColor(0xF06020); g.fillRect(2, 2, 1, 1);
        g.copyArea(1, 1, 4, 3, 8, 1, Graphics.TOP | Graphics.LEFT);
        int[] p = pixels(img);
        for (int y = 0; y < 3; y++) {
            for (int x = 0; x < 4; x++) {
                int v = p[(1 + y) * W + (8 + x)];
                if (x == 1 && y == 1) {
                    if (v != 0xFFF06020) return false;
                } else {
                    if (v != 0xFF204080) return false;
                }
            }
        }
        return true;
    }

    private static PlatformGraphics platform(Graphics g) {
        return (PlatformGraphics) g;
    }

    private static void fill(Graphics g, int rgb) {
        g.setClip(0, 0, W, H);
        g.translate(-g.getTranslateX(), -g.getTranslateY());
        g.setColor(rgb);
        g.fillRect(0, 0, W, H);
    }

    private static int[] pixels(Image img) {
        int[] out = new int[W * H];
        img.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }

    private static final class ResultCanvas extends Canvas {
        private final boolean pass;
        ResultCanvas(boolean pass) {
            this.pass = pass;
            setFullScreenMode(true);
        }
        protected void paint(Graphics g) {
            g.setColor(pass ? 0x008000 : 0x800000);
            g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(0xFFFFFF);
            if (pass) {
                int y = getHeight() / 2 - 30;
                g.fillRect(getWidth() / 4, y, getWidth() / 2, 12);
                g.fillRect(getWidth() / 4, y + 24, getWidth() / 2, 12);
                g.fillRect(getWidth() / 4, y + 48, getWidth() / 2, 12);
            } else {
                g.drawLine(40, 40, getWidth() - 40, getHeight() - 40);
                g.drawLine(getWidth() - 40, 40, 40, getHeight() - 40);
            }
        }
    }
}
