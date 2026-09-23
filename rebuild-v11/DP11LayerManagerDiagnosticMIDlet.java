package org.recompile.mobile;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Layer;
import javax.microedition.lcdui.game.LayerManager;
import javax.microedition.midlet.MIDlet;

public final class DP11LayerManagerDiagnosticMIDlet extends MIDlet implements Runnable {
    private static final int RUNNING = 0;
    private static final int PASS = 1;
    private static final int FAIL = 2;

    private volatile int visualState = RUNNING;
    private StatusCanvas canvas;

    protected void startApp() {
        System.out.println("DP_R11_PRIMARY_VARIABLE=DIAGNOSTIC_ONLY_NO_RUNTIME_CHANGE");
        System.out.println("DP_R11_RUNTIME_CHANGE=NONE");
        canvas = new StatusCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        new Thread(this, "dp-r11-layermanager").start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private final class StatusCanvas extends Canvas {
        protected void paint(Graphics g) {
            int w = getWidth();
            int h = getHeight();
            g.setColor(0x000080);
            g.fillRect(0, 0, w, h);

            if (visualState == RUNNING) g.setColor(0xFFFF00);
            else if (visualState == PASS) g.setColor(0x00FF00);
            else g.setColor(0xFF0000);

            int bw = Math.max(24, w / 3);
            int bh = Math.max(24, h / 3);
            g.fillRect((w - bw) / 2, (h - bh) / 2, bw, bh);
        }
    }

    private static final class SolidLayer extends Layer {
        private final int color;

        SolidLayer(int width, int height, int color) {
            super(width, height);
            this.color = color;
        }

        public void paint(Graphics g) {
            g.setColor(color);
            g.fillRect(getX(), getY(), getWidth(), getHeight());
        }
    }

    private static void marker(String name, boolean pass) {
        System.out.println(name + "=" + (pass ? "PASS" : "FAIL"));
    }

    private static int pixel(int[] data, int width, int x, int y) {
        return data[y * width + x];
    }

    private static boolean sameRGB(int actual, int expected) {
        return (actual & 0x00FFFFFF) == (expected & 0x00FFFFFF)
            && ((actual >>> 24) & 0xFF) != 0;
    }

    private static Image blank(int w, int h, int rgb) {
        Image image = Image.createImage(w, h);
        Graphics g = image.getGraphics();
        g.setColor(rgb);
        g.fillRect(0, 0, w, h);
        return image;
    }

    private boolean testListOperations() {
        boolean ok = true;
        try {
            SolidLayer a = new SolidLayer(2, 2, 0x00FF00);
            SolidLayer b = new SolidLayer(2, 2, 0xFF0000);
            SolidLayer c = new SolidLayer(2, 2, 0x0000FF);

            LayerManager lm = new LayerManager();
            lm.append(a);
            lm.append(b);
            lm.append(c);

            boolean append = lm.getSize() == 3
                && lm.getLayerAt(0) == a
                && lm.getLayerAt(1) == b
                && lm.getLayerAt(2) == c;
            marker("DP_R11_LIST_APPEND_ORDER", append);
            ok &= append;

            lm.insert(c, 0);
            boolean insert = lm.getSize() == 3
                && lm.getLayerAt(0) == c
                && lm.getLayerAt(1) == a
                && lm.getLayerAt(2) == b;
            marker("DP_R11_LIST_INSERT_EXISTING_REORDER", insert);
            ok &= insert;

            lm.remove(a);
            boolean remove = lm.getSize() == 2
                && lm.getLayerAt(0) == c
                && lm.getLayerAt(1) == b;
            marker("DP_R11_LIST_REMOVE", remove);
            ok &= remove;

            boolean badIndex = false;
            try { lm.getLayerAt(2); }
            catch (IndexOutOfBoundsException expected) { badIndex = true; }
            marker("DP_R11_LIST_BAD_INDEX_THROWS", badIndex);
            ok &= badIndex;

            System.out.println("DP_R11_LIST_GATE=" + (ok ? "PASS" : "FAIL"));
        } catch (Throwable t) {
            ok = false;
            System.out.println("DP_R11_LIST_GATE=FAIL");
            System.out.println("DP_R11_LIST_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }
        return ok;
    }

    private boolean testZOrderAndVisibility() {
        boolean ok = true;
        final int BLACK = 0x000000;
        final int RED = 0xFF0000;
        final int GREEN = 0x00FF00;

        try {
            SolidLayer front = new SolidLayer(4, 4, GREEN);
            SolidLayer back = new SolidLayer(4, 4, RED);
            front.setPosition(1, 1);
            back.setPosition(1, 1);

            LayerManager lm = new LayerManager();
            lm.setViewWindow(0, 0, 8, 8);
            lm.append(front);
            lm.append(back);

            Image target = blank(8, 8, BLACK);
            lm.paint(target.getGraphics(), 0, 0);
            boolean frontWins = sameRGB(pixel(target.getDataBuffer(), 8, 2, 2), 0xFF000000 | GREEN);
            marker("DP_R11_ZORDER_INDEX0_FRONT", frontWins);
            ok &= frontWins;

            front.setVisible(false);
            Image target2 = blank(8, 8, BLACK);
            lm.paint(target2.getGraphics(), 0, 0);
            boolean hidden = sameRGB(pixel(target2.getDataBuffer(), 8, 2, 2), 0xFF000000 | RED);
            marker("DP_R11_VISIBILITY_HIDDEN_FRONT", hidden);
            ok &= hidden;

            front.setVisible(true);
            lm.insert(back, 0);
            Image target3 = blank(8, 8, BLACK);
            lm.paint(target3.getGraphics(), 0, 0);
            boolean reordered = sameRGB(pixel(target3.getDataBuffer(), 8, 2, 2), 0xFF000000 | RED);
            marker("DP_R11_ZORDER_INSERT_REORDER", reordered);
            ok &= reordered;

            System.out.println("DP_R11_ZORDER_GATE=" + (ok ? "PASS" : "FAIL"));
        } catch (Throwable t) {
            ok = false;
            System.out.println("DP_R11_ZORDER_GATE=FAIL");
            System.out.println("DP_R11_ZORDER_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }
        return ok;
    }

    private boolean testViewWindow() {
        boolean ok = true;
        final int BLACK = 0x000000;
        final int BLUE = 0x0000FF;

        try {
            SolidLayer world = new SolidLayer(8, 8, BLUE);
            world.setPosition(0, 0);

            LayerManager lm = new LayerManager();
            lm.append(world);
            lm.setViewWindow(2, 1, 2, 3);

            Image target = blank(10, 8, BLACK);
            Graphics g = target.getGraphics();
            lm.paint(g, 4, 2);
            int[] p = target.getDataBuffer();

            boolean inside = sameRGB(pixel(p, 10, 4, 2), 0xFF000000 | BLUE)
                && sameRGB(pixel(p, 10, 5, 4), 0xFF000000 | BLUE);
            marker("DP_R11_VIEWWINDOW_DESTINATION_INSIDE", inside);
            ok &= inside;

            boolean clipped = sameRGB(pixel(p, 10, 3, 2), 0xFF000000 | BLACK)
                && sameRGB(pixel(p, 10, 6, 2), 0xFF000000 | BLACK)
                && sameRGB(pixel(p, 10, 4, 1), 0xFF000000 | BLACK)
                && sameRGB(pixel(p, 10, 4, 5), 0xFF000000 | BLACK);
            marker("DP_R11_VIEWWINDOW_CLIP_OUTSIDE", clipped);
            ok &= clipped;

            System.out.println("DP_R11_VIEWWINDOW_GATE=" + (ok ? "PASS" : "FAIL"));
        } catch (Throwable t) {
            ok = false;
            System.out.println("DP_R11_VIEWWINDOW_GATE=FAIL");
            System.out.println("DP_R11_VIEWWINDOW_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }
        return ok;
    }

    private boolean testGraphicsStateRestore() {
        boolean ok = true;
        try {
            SolidLayer layer = new SolidLayer(3, 3, 0x00FFFF);
            LayerManager lm = new LayerManager();
            lm.append(layer);
            lm.setViewWindow(0, 0, 2, 2);

            Image target = blank(10, 10, 0x000000);
            Graphics g = target.getGraphics();
            g.translate(1, 2);
            g.setClip(1, 1, 5, 4);

            int tx = g.getTranslateX();
            int ty = g.getTranslateY();
            int cx = g.getClipX();
            int cy = g.getClipY();
            int cw = g.getClipWidth();
            int ch = g.getClipHeight();

            lm.paint(g, 3, 4);

            boolean translation = g.getTranslateX() == tx && g.getTranslateY() == ty;
            marker("DP_R11_GRAPHICS_TRANSLATION_RESTORED", translation);
            ok &= translation;

            boolean clip = g.getClipX() == cx
                && g.getClipY() == cy
                && g.getClipWidth() == cw
                && g.getClipHeight() == ch;
            marker("DP_R11_GRAPHICS_CLIP_RESTORED", clip);
            ok &= clip;

            boolean invalidView = false;
            try { lm.setViewWindow(0, 0, -1, 1); }
            catch (IllegalArgumentException expected) { invalidView = true; }
            marker("DP_R11_NEGATIVE_VIEWWINDOW_THROWS", invalidView);
            ok &= invalidView;

            System.out.println("DP_R11_GRAPHICS_STATE_GATE=" + (ok ? "PASS" : "FAIL"));
        } catch (Throwable t) {
            ok = false;
            System.out.println("DP_R11_GRAPHICS_STATE_GATE=FAIL");
            System.out.println("DP_R11_GRAPHICS_STATE_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }
        return ok;
    }

    public void run() {
        boolean list = testListOperations();
        boolean z = testZOrderAndVisibility();
        boolean view = testViewWindow();
        boolean state = testGraphicsStateRestore();
        boolean all = list && z && view && state;

        System.out.println("DP_R11_DIAGNOSTIC_GATE=" + (all ? "PASS" : "FAIL"));
        System.out.println("DP_R11_RUNTIME_GATE=" + (all ? "PASS" : "FAIL"));

        visualState = all ? PASS : FAIL;
        try {
            canvas.repaint();
            canvas.serviceRepaints();
            Thread.sleep(1800);
        } catch (Throwable ignored) {}

        notifyDestroyed();
        System.exit(all ? 0 : 2);
    }
}
