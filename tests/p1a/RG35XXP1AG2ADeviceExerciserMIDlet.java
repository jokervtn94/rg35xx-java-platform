package org.recompile.rg35xx.p1a.device;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.midlet.MIDlet;

/** Original-RG35XX physical module exerciser for P1A-G2A fillRoundRect only. */
public final class RG35XXP1AG2ADeviceExerciserMIDlet extends MIDlet {
    private static final int W = 28;
    private static final int H = 22;
    private boolean pass;
    private String failCase = "NONE";

    protected void startApp() {
        System.out.println("P1A_G2A_DEVICE_EXERCISER_BOOT=PASS");
        pass = runAll();
        System.out.println("P1A_G2A_DEVICE_EXERCISER_FAIL_CASE=" + failCase);
        System.out.println("P1A_G2A_DEVICE_EXERCISER_RESULT=" + (pass ? "PASS" : "FAIL"));
        System.out.println("P1A_G2A_DEVICE_PASS=NO_PENDING_PHYSICAL_REVIEW");
        System.out.flush();
        Display.getDisplay(this).setCurrent(new ResultCanvas(pass));
        Thread finisher = new Thread(new Runnable() {
            public void run() {
                try { Thread.sleep(4000L); } catch (InterruptedException e) { }
                System.out.println("P1A_G2A_DEVICE_EXERCISER_NORMAL_EXIT=PASS");
                System.out.flush();
                System.exit(pass ? 0 : 2);
            }
        }, "p1a-g2a-finish");
        finisher.start();
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    private boolean runAll() {
        if (!runCase("FILLROUNDRECT_NORMAL", fullRectCase(4, 4, 18, 12, 7, 5))) return false;
        if (!runCase("FILLROUNDRECT_OVERSIZE", fullRectCase(4, 4, 18, 12, 40, 30))) return false;
        if (!runCase("FILLROUNDRECT_ZERO_ARC", fullRectCase(4, 4, 18, 12, 0, 0))) return false;
        if (!runCase("FILLROUNDRECT_CLIP_TRANSLATE", clipTranslateCase())) return false;
        if (!runCase("FILLROUNDRECT_DEGENERATE", degenerateCase())) return false;
        if (!runCase("FILLROUNDRECT_EQUALS_FILLRECT", equalsFillRectCase())) return false;
        if (!runCase("G1_CLEAR_SENTINEL", g1ClearSentinel())) return false;
        if (!runCase("G1_COPY_SENTINEL", g1CopySentinel())) return false;
        return true;
    }

    private boolean runCase(String name, boolean ok) {
        System.out.println("P1A_G2A_DEVICE_CASE=" + name + " RESULT=" + (ok ? "PASS" : "FAIL"));
        if (!ok) failCase = name;
        return ok;
    }

    private boolean fullRectCase(int x, int y, int w, int h, int aw, int ah) {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x182838);
        g.setColor(0x3A72C4);
        g.fillRoundRect(x, y, w, h, aw, ah);
        int[] p = pixels(img);
        for (int yy = 0; yy < H; yy++) for (int xx = 0; xx < W; xx++) {
            int expected = (xx >= x && xx < x + w && yy >= y && yy < y + h) ? 0xFF3A72C4 : 0xFF182838;
            if (p[yy * W + xx] != expected) return false;
        }
        return true;
    }

    private boolean clipTranslateCase() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x202020);
        g.setClip(6, 5, 9, 7);
        g.translate(3, 2);
        g.setColor(0x55AA33);
        g.fillRoundRect(0, 0, 20, 16, 8, 6);
        int[] p = pixels(img);
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
            int expected = (x >= 6 && x < 15 && y >= 5 && y < 12) ? 0xFF55AA33 : 0xFF202020;
            if (p[y * W + x] != expected) return false;
        }
        return true;
    }

    private boolean degenerateCase() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x334455);
        g.setColor(0xCC8844);
        g.fillRoundRect(3, 3, 0, 7, 4, 4);
        g.fillRoundRect(3, 3, 7, 0, 4, 4);
        g.fillRoundRect(3, 3, -2, 7, 4, 4);
        g.fillRoundRect(3, 3, 7, -2, 4, 4);
        int[] p = pixels(img);
        for (int i = 0; i < p.length; i++) if (p[i] != 0xFF334455) return false;
        return true;
    }

    private boolean equalsFillRectCase() {
        Image a = Image.createImage(W, H);
        Image b = Image.createImage(W, H);
        Graphics ga = a.getGraphics();
        Graphics gb = b.getGraphics();
        fill(ga, 0x101820); fill(gb, 0x101820);
        ga.setColor(0x6699CC); gb.setColor(0x6699CC);
        ga.fillRoundRect(3, 4, 19, 11, 9, 7);
        gb.fillRect(3, 4, 19, 11);
        int[] pa = pixels(a), pb = pixels(b);
        if (pa.length != pb.length) return false;
        for (int i = 0; i < pa.length; i++) if (pa[i] != pb[i]) return false;
        return true;
    }

    private boolean g1ClearSentinel() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x335577);
        ((org.recompile.mobile.PlatformGraphics)g).clearRect(4, 3, 5, 4);
        int[] p = pixels(img);
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
            int expected = (x >= 4 && x < 9 && y >= 3 && y < 7) ? 0x00000000 : 0xFF335577;
            if (p[y * W + x] != expected) return false;
        }
        return true;
    }

    private boolean g1CopySentinel() {
        Image img = Image.createImage(W, H);
        Graphics g = img.getGraphics();
        fill(g, 0x111111);
        g.setColor(0xAA4422); g.fillRect(2, 2, 4, 3);
        g.copyArea(2, 2, 4, 3, 12, 8, Graphics.TOP | Graphics.LEFT);
        int[] p = pixels(img);
        for (int y = 0; y < 3; y++) for (int x = 0; x < 4; x++) {
            if (p[(8 + y) * W + (12 + x)] != 0xFFAA4422) return false;
        }
        return true;
    }

    private static void fill(Graphics g, int rgb) {
        g.translate(-g.getTranslateX(), -g.getTranslateY());
        g.setClip(0, 0, W, H);
        g.setColor(rgb); g.fillRect(0, 0, W, H);
    }

    private static int[] pixels(Image img) {
        int[] out = new int[W * H];
        img.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }

    private static final class ResultCanvas extends Canvas {
        private final boolean pass;
        ResultCanvas(boolean pass) { this.pass = pass; setFullScreenMode(true); }
        protected void paint(Graphics g) {
            g.setColor(pass ? 0x008000 : 0x800000);
            g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(0xFFFFFF);
            if (pass) {
                int y = getHeight() / 2 - 42;
                for (int i = 0; i < 4; i++) g.fillRect(getWidth() / 4, y + i * 28, getWidth() / 2, 12);
            } else {
                g.drawLine(40, 40, getWidth() - 40, getHeight() - 40);
                g.drawLine(getWidth() - 40, 40, 40, getHeight() - 40);
            }
        }
    }
}
