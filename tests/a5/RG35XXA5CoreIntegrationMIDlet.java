package org.recompile.rg35xx.a5;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Enumeration;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.LayerManager;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.lcdui.game.TiledLayer;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.RecordEnumeration;
import javax.microedition.rms.RecordStore;
import javax.microedition.rms.RecordStoreNotFoundException;

/**
 * A5 parent integration probe. It intentionally exercises all Level-2 core
 * boundaries in one package and records every gate before returning failure.
 */
public final class RG35XXA5CoreIntegrationMIDlet extends MIDlet implements Runnable {
    private static final String STORE = "RG35XX_A5_CORE";
    private static final byte[] RMS_MARKER = new byte[] { 0x41,0x35,0x2d,0x52,0x4d,0x53,0x2d,0x50,0x45,0x52,0x53,0x49,0x53,0x54 };
    private static final int LOGICAL_W = 240;
    private static final int LOGICAL_H = 320;

    private ProbeCanvas canvas;
    private volatile boolean running;

    protected void startApp() {
        String phase = System.getProperty("rg35xx.a5.phase");
        if (phase == null) phase = "A";
        System.out.println("A5_PHASE=" + phase);
        System.out.println("A5_PRIMARY_VARIABLE=CORE_INTEGRATION_PARENT");
        if ("B".equals(phase)) {
            running = true;
            new Thread(this, "a5-rms-b").start();
            return;
        }

        canvas = new ProbeCanvas();
        canvas.setFullScreenMode(true);
        Display.getDisplay(this).setCurrent(canvas);
        running = true;
        new Thread(this, "a5-core-a").start();
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { running = false; }

    public void run() {
        String phase = System.getProperty("rg35xx.a5.phase");
        if (phase == null) phase = "A";
        if ("B".equals(phase)) {
            boolean ok = testRmsPhaseB();
            System.out.println("A5_PHASE_B_GATE=" + (ok ? "PASS" : "FAIL"));
            System.out.println("A5_NORMAL_EXIT=PASS");
            System.out.flush();
            System.exit(ok ? 0 : 2);
            return;
        }

        int passed = 0;
        int failed = 0;
        if (gate("RESIZE_CANVAS", new Test() { public void run() throws Exception { testResizeAndCanvas(); }})) passed++; else failed++;
        if (gate("RESOURCE_STREAM", new Test() { public void run() throws Exception { testResourceStream(); }})) passed++; else failed++;
        if (gate("IMAGE_RGB_ALPHA", new Test() { public void run() throws Exception { testImageRgbAlpha(); }})) passed++; else failed++;
        if (gate("IMAGE_RESOURCE_PNG", new Test() { public void run() throws Exception { testImageResourcePng(); }})) passed++; else failed++;
        if (gate("IMAGE_MUTABLE_COPY", new Test() { public void run() throws Exception { testMutableImageAndCopy(); }})) passed++; else failed++;
        if (gate("FONT_METRICS_TEXT", new Test() { public void run() throws Exception { testFontAndText(); }})) passed++; else failed++;
        if (gate("SPRITE_TRANSFORMS", new Test() { public void run() throws Exception { testSpriteTransforms(); }})) passed++; else failed++;
        if (gate("SPRITE_COLLISION", new Test() { public void run() throws Exception { testSpriteCollision(); }})) passed++; else failed++;
        if (gate("TILEDLAYER", new Test() { public void run() throws Exception { testTiledLayer(); }})) passed++; else failed++;
        if (gate("LAYERMANAGER", new Test() { public void run() throws Exception { testLayerManager(); }})) passed++; else failed++;
        if (gate("RMS_PHASE_A", new Test() { public void run() throws Exception { testRmsPhaseA(); }})) passed++; else failed++;

        System.out.println("A5_PHASE_A_PASS_COUNT=" + passed);
        System.out.println("A5_PHASE_A_FAIL_COUNT=" + failed);
        System.out.println("A5_PHASE_A_GATE=" + (failed == 0 ? "PASS" : "FAIL"));
        System.out.println("A5_NORMAL_EXIT=PASS");
        System.out.flush();
        System.exit(failed == 0 ? 0 : 2);
    }

    private interface Test { void run() throws Exception; }

    private boolean gate(String name, Test test) {
        try {
            test.run();
            System.out.println("A5_" + name + "=PASS");
            return true;
        } catch (Throwable t) {
            System.out.println("A5_" + name + "=FAIL");
            System.out.println("A5_" + name + "_EXCEPTION=" + t.getClass().getName() + ":" + String.valueOf(t.getMessage()));
            t.printStackTrace();
            return false;
        }
    }

    private static void require(boolean condition, String message) throws Exception {
        if (!condition) throw new Exception(message);
    }

    private void testResizeAndCanvas() throws Exception {
        long deadline = System.currentTimeMillis() + 2500L;
        while (running && canvas.paintCount == 0 && System.currentTimeMillis() < deadline) {
            canvas.repaint();
            try { Thread.sleep(25L); } catch (InterruptedException e) { break; }
        }
        require(canvas.getWidth() == LOGICAL_W, "canvas-width=" + canvas.getWidth());
        require(canvas.getHeight() == LOGICAL_H, "canvas-height=" + canvas.getHeight());
        require(canvas.paintCount > 0, "paint-count=0");
        System.out.println("A5_LOGICAL_LCD=" + canvas.getWidth() + "x" + canvas.getHeight());
        System.out.println("A5_CANVAS_PAINT_COUNT=" + canvas.paintCount);
    }

    private void testResourceStream() throws Exception {
        InputStream in = getClass().getResourceAsStream("/a5-resource.txt");
        require(in != null, "resource-null");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[64];
        int n;
        while ((n = in.read(buf)) >= 0) out.write(buf, 0, n);
        in.close();
        String s = new String(out.toByteArray(), "UTF-8");
        require(s.indexOf("RG35XX-A5-RESOURCE") >= 0, "resource-marker-missing");
    }

    private void testImageRgbAlpha() throws Exception {
        int[] rgb = new int[] { 0xFFFF0000, 0x8000FF00, 0x000000FF, 0xFFFFFFFF };
        Image img = Image.createRGBImage(rgb, 2, 2, true);
        require(img.getWidth() == 2 && img.getHeight() == 2, "rgb-size");
        int[] got = new int[4];
        img.getRGB(got, 0, 2, 0, 0, 2, 2);
        require((got[0] & 0x00FFFFFF) == 0x00FF0000, "rgb-red");
        require(((got[1] >>> 24) & 0xFF) == 0x80, "alpha-half");
        require(((got[2] >>> 24) & 0xFF) == 0x00, "alpha-zero");
    }

    private void testImageResourcePng() throws Exception {
        Image png = Image.createImage("/a5-pixel.png");
        require(png != null, "png-null");
        require(png.getWidth() == 1 && png.getHeight() == 1, "png-size=" + png.getWidth() + "x" + png.getHeight());
        int[] px = new int[1];
        png.getRGB(px, 0, 1, 0, 0, 1, 1);
        System.out.println("A5_PNG_PIXEL=0x" + Integer.toHexString(px[0]));
    }

    private void testMutableImageAndCopy() throws Exception {
        Image img = Image.createImage(8, 8);
        Graphics g = img.getGraphics();
        g.setColor(0x112233);
        g.fillRect(0, 0, 8, 8);
        require(pixel(img, 4, 4) == 0x112233, "mutable-pixel");
        Image copy = Image.createImage(img);
        require(copy.getWidth() == 8 && copy.getHeight() == 8, "copy-size");
        require(pixel(copy, 4, 4) == 0x112233, "copy-pixel");
    }

    private void testFontAndText() throws Exception {
        Font small = Font.getFont(Font.FACE_SYSTEM, Font.STYLE_PLAIN, Font.SIZE_SMALL);
        Font medium = Font.getFont(Font.FACE_SYSTEM, Font.STYLE_BOLD, Font.SIZE_MEDIUM);
        Font large = Font.getFont(Font.FACE_MONOSPACE, Font.STYLE_PLAIN, Font.SIZE_LARGE);
        require(small.getHeight() > 0 && medium.getHeight() > 0 && large.getHeight() > 0, "font-height");
        require(small.stringWidth("ASCII 123") > 0, "string-width");
        require(medium.charWidth('W') > 0, "char-width");

        Image target = Image.createImage(160, 60);
        Graphics g = target.getGraphics();
        g.setColor(0x000000); g.fillRect(0, 0, 160, 60);
        g.setColor(0xFFFFFF); g.setFont(medium);
        g.drawString("A5 TEXT 123", 2, 2, Graphics.TOP | Graphics.LEFT);
        int[] data = new int[160 * 60];
        target.getRGB(data, 0, 160, 0, 0, 160, 60);
        require(countNonBlack(data) > 0, "drawString-no-pixels");
        System.out.println("A5_FONT_HEIGHTS=" + small.getHeight() + "," + medium.getHeight() + "," + large.getHeight());
    }

    private static Image makeSpriteSheet() {
        int[] p = new int[4 * 3];
        for (int y = 0; y < 3; y++) {
            p[y * 4 + 0] = 0xFFFFFFFF;
            p[y * 4 + 1] = 0xFFFF0000;
            p[y * 4 + 2] = 0xFF00FF00;
            p[y * 4 + 3] = 0xFF0000FF;
        }
        return Image.createRGBImage(p, 4, 3, true);
    }

    private void testSpriteTransforms() throws Exception {
        Sprite s = new Sprite(makeSpriteSheet(), 2, 3);
        require(s.getFrameSequenceLength() == 2, "frame-count");
        int[] transforms = new int[] {
            Sprite.TRANS_NONE, Sprite.TRANS_MIRROR_ROT180, Sprite.TRANS_MIRROR,
            Sprite.TRANS_ROT180, Sprite.TRANS_MIRROR_ROT270, Sprite.TRANS_ROT90,
            Sprite.TRANS_ROT270, Sprite.TRANS_MIRROR_ROT90
        };
        for (int i = 0; i < transforms.length; i++) {
            s.setTransform(transforms[i]);
            boolean swaps = transforms[i] == Sprite.TRANS_MIRROR_ROT270 || transforms[i] == Sprite.TRANS_ROT90 ||
                            transforms[i] == Sprite.TRANS_ROT270 || transforms[i] == Sprite.TRANS_MIRROR_ROT90;
            require(s.getWidth() == (swaps ? 3 : 2), "transform-width-" + transforms[i]);
            require(s.getHeight() == (swaps ? 2 : 3), "transform-height-" + transforms[i]);
            s.setPosition(1, 1);
            Image target = Image.createImage(8, 8);
            Graphics g = target.getGraphics();
            g.setColor(0); g.fillRect(0, 0, 8, 8);
            s.paint(g);
            int[] data = new int[64];
            target.getRGB(data, 0, 8, 0, 0, 8, 8);
            require(countNonBlack(data) >= 6, "transform-paint-" + transforms[i]);
        }
        System.out.println("A5_SPRITE_TRANSFORM_COUNT=8");
    }

    private void testSpriteCollision() throws Exception {
        Sprite a = new Sprite(makeSpriteSheet(), 2, 3);
        Sprite b = new Sprite(Image.createRGBImage(new int[] {
            0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF
        }, 2, 3, true));
        a.setPosition(10, 10); b.setPosition(11, 11);
        require(a.collidesWith(b, false), "bounds-collision");
        require(a.collidesWith(b, true), "pixel-collision");
        b.setPosition(30, 30);
        require(!a.collidesWith(b, false), "bounds-noncollision");
    }

    private void testTiledLayer() throws Exception {
        Image tiles = makeSpriteSheet();
        TiledLayer t = new TiledLayer(3, 2, tiles, 2, 3);
        t.setCell(0,0,1); t.setCell(1,0,2); t.setCell(2,0,1);
        t.setCell(0,1,2); t.setCell(1,1,1); t.setCell(2,1,2);
        require(t.getCell(0,0) == 1 && t.getCell(1,0) == 2 && t.getCell(2,1) == 2, "tile-map");
        int anim = t.createAnimatedTile(1);
        t.setCell(1,1,anim);
        require(t.getAnimatedTile(anim) == 1, "tile-anim-create");
        t.setAnimatedTile(anim,2);
        require(t.getAnimatedTile(anim) == 2, "tile-anim-update");
        t.setPosition(4,5);
        require(t.getWidth() == 6 && t.getHeight() == 6, "tile-bounds");
        Image target = Image.createImage(16, 16);
        Graphics g = target.getGraphics();
        g.setColor(0); g.fillRect(0,0,16,16);
        g.setClip(4,5,4,3);
        t.paint(g);
        require(pixel(target,4,5) != 0x000000, "tile-paint");
        require(pixel(target,9,5) == 0x000000, "tile-clip-outside");
    }

    private void testLayerManager() throws Exception {
        Sprite s = new Sprite(makeSpriteSheet(), 2, 3);
        s.setPosition(2,2);
        TiledLayer t = new TiledLayer(2,2,makeSpriteSheet(),2,3);
        t.setCell(0,0,1); t.setCell(1,0,2); t.setCell(0,1,1); t.setCell(1,1,2);
        LayerManager lm = new LayerManager();
        lm.append(t);
        lm.append(s);
        require(lm.getSize() == 2, "layer-count");
        require(lm.getLayerAt(0) == t && lm.getLayerAt(1) == s, "layer-order");
        lm.setViewWindow(0,0,8,8);
        Image target = Image.createImage(16,16);
        Graphics g = target.getGraphics();
        g.setColor(0); g.fillRect(0,0,16,16);
        g.setClip(1,1,10,10);
        int x = g.getClipX(), y = g.getClipY(), w = g.getClipWidth(), h = g.getClipHeight();
        lm.paint(g,1,1);
        require(g.getClipX()==x && g.getClipY()==y && g.getClipWidth()==w && g.getClipHeight()==h, "clip-restore");
        require(countImageNonBlack(target) > 0, "layer-paint-empty");
    }

    private void testRmsPhaseA() throws Exception {
        try { RecordStore.deleteRecordStore(STORE); } catch (RecordStoreNotFoundException e) { }
        RecordStore rs = RecordStore.openRecordStore(STORE, true);
        try {
            int id1 = rs.addRecord(RMS_MARKER, 0, RMS_MARKER.length);
            byte[] second = new byte[] { 1,2,3,4 };
            int id2 = rs.addRecord(second, 0, second.length);
            byte[] updated = new byte[] { 9,8,7,6,5 };
            rs.setRecord(id2, updated, 0, updated.length);
            require(eq(RMS_MARKER, rs.getRecord(id1)), "rms-marker-read");
            require(eq(updated, rs.getRecord(id2)), "rms-update-read");
            RecordEnumeration en = rs.enumerateRecords(null, null, false);
            require(en.numRecords() == 2, "rms-enumeration-count=" + en.numRecords());
            en.destroy();
            System.out.println("A5_RMS_A_IDS=" + id1 + "," + id2);
        } finally {
            rs.closeRecordStore();
        }
    }

    private boolean testRmsPhaseB() {
        RecordStore rs = null;
        boolean ok = true;
        try {
            rs = RecordStore.openRecordStore(STORE, false);
            System.out.println("A5_RMS_B_OPEN_EXISTING=PASS");
            if (rs.getNumRecords() != 2) throw new Exception("rms-count=" + rs.getNumRecords());
            if (!eq(RMS_MARKER, rs.getRecord(1))) throw new Exception("rms-marker-mismatch");
            rs.closeRecordStore(); rs = null;
            RecordStore.deleteRecordStore(STORE);
            System.out.println("A5_RMS_B_DELETE=PASS");
            try {
                RecordStore again = RecordStore.openRecordStore(STORE, false);
                again.closeRecordStore();
                throw new Exception("rms-delete-reopen");
            } catch (RecordStoreNotFoundException expected) {
                System.out.println("A5_RMS_B_VERIFY_DELETE=PASS");
            }
            System.out.println("A5_RMS_PERSISTENCE=PASS");
        } catch (Throwable t) {
            ok = false;
            System.out.println("A5_RMS_PERSISTENCE=FAIL");
            System.out.println("A5_RMS_PHASE_B_EXCEPTION=" + t.getClass().getName() + ":" + String.valueOf(t.getMessage()));
            t.printStackTrace();
        } finally {
            try { if (rs != null) rs.closeRecordStore(); } catch (Throwable ignored) { }
        }
        return ok;
    }

    private static int pixel(Image img, int x, int y) {
        int[] p = new int[1];
        img.getRGB(p, 0, 1, x, y, 1, 1);
        return p[0] & 0x00FFFFFF;
    }

    private static int countImageNonBlack(Image img) {
        int[] p = new int[img.getWidth() * img.getHeight()];
        img.getRGB(p, 0, img.getWidth(), 0, 0, img.getWidth(), img.getHeight());
        return countNonBlack(p);
    }

    private static int countNonBlack(int[] p) {
        int n = 0;
        for (int i = 0; i < p.length; i++) if ((p[i] & 0x00FFFFFF) != 0) n++;
        return n;
    }

    private static boolean eq(byte[] a, byte[] b) {
        if (a == null || b == null || a.length != b.length) return false;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    private static final class ProbeCanvas extends Canvas {
        volatile int paintCount;
        protected void paint(Graphics g) {
            paintCount++;
            int w = getWidth(), h = getHeight();
            g.setColor(0x102040); g.fillRect(0,0,w,h);
            g.setColor(0x206020); g.fillRect(0,0,w/2,h/2);
            g.setColor(0x602020); g.fillRect(w/2,0,w-w/2,h/2);
            g.setColor(0x202060); g.fillRect(0,h/2,w/2,h-h/2);
            g.setColor(0x606020); g.fillRect(w/2,h/2,w-w/2,h-h/2);
        }
    }
}
