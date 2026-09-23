package org.recompile.mobile;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.lcdui.game.TiledLayer;
import javax.microedition.midlet.MIDlet;

public final class DP9TiledLayerDiagnosticMIDlet extends MIDlet implements Runnable {
    private static final int RUNNING = 0;
    private static final int PASS = 1;
    private static final int FAIL = 2;

    private static final int[] TRANSFORMS = new int[] {
        Sprite.TRANS_NONE,
        Sprite.TRANS_ROT90,
        Sprite.TRANS_ROT180,
        Sprite.TRANS_ROT270,
        Sprite.TRANS_MIRROR,
        Sprite.TRANS_MIRROR_ROT90,
        Sprite.TRANS_MIRROR_ROT180,
        Sprite.TRANS_MIRROR_ROT270
    };

    private static final String[] NAMES = new String[] {
        "NONE", "ROT90", "ROT180", "ROT270",
        "MIRROR", "MIRROR_ROT90", "MIRROR_ROT180", "MIRROR_ROT270"
    };

    private volatile int visualState = RUNNING;
    private StatusCanvas canvas;

    protected void startApp() {
        System.out.println("DP_R9_PRIMARY_VARIABLE=DIAGNOSTIC_ONLY_NO_RUNTIME_CHANGE");
        System.out.println("DP_R9_RUNTIME_CHANGE=NONE");
        canvas = new StatusCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        new Thread(this, "dp-r9-tiledlayer").start();
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

    private static int pixel(int[] data, int width, int x, int y) {
        return data[y * width + x];
    }

    private static boolean sameRGB(int actual, int expected) {
        return (actual & 0x00FFFFFF) == (expected & 0x00FFFFFF)
            && ((actual >>> 24) & 0xFF) != 0;
    }

    private static void marker(String name, boolean pass) {
        System.out.println(name + "=" + (pass ? "PASS" : "FAIL"));
    }

    private boolean testTiledLayerRendering() {
        boolean ok = true;
        final int R = 0xFFFF0000;
        final int G = 0xFF00FF00;

        try {
            Image tileSet = Image.createRGBImage(new int[] {
                R, R, G, G,
                R, R, G, G
            }, 4, 2, true);

            TiledLayer layer = new TiledLayer(3, 2, tileSet, 2, 2);
            int anim = layer.createAnimatedTile(1);

            layer.setCell(0, 0, 1);
            layer.setCell(1, 0, 2);
            layer.setCell(2, 0, 0);
            layer.setCell(0, 1, anim);
            layer.setCell(1, 1, 0);
            layer.setCell(2, 1, 2);

            boolean dimensions = layer.getColumns() == 3
                && layer.getRows() == 2
                && layer.getCellWidth() == 2
                && layer.getCellHeight() == 2
                && layer.getWidth() == 6
                && layer.getHeight() == 4;
            marker("DP_R9_TILE_DIMENSIONS", dimensions);
            ok &= dimensions;

            boolean cells = layer.getCell(0, 0) == 1
                && layer.getCell(1, 0) == 2
                && layer.getCell(2, 0) == 0
                && layer.getCell(0, 1) == anim
                && layer.getAnimatedTile(anim) == 1;
            marker("DP_R9_TILE_CELL_STATE", cells);
            ok &= cells;

            layer.setPosition(1, 1);
            Image target = Image.createImage(8, 6);
            layer.paint(target.getGraphics());
            int[] p = target.getDataBuffer();

            boolean staticRender = sameRGB(pixel(p, 8, 1, 1), R)
                && sameRGB(pixel(p, 8, 3, 1), G)
                && !sameRGB(pixel(p, 8, 5, 1), R)
                && !sameRGB(pixel(p, 8, 5, 1), G)
                && sameRGB(pixel(p, 8, 1, 3), R)
                && sameRGB(pixel(p, 8, 5, 3), G);
            marker("DP_R9_TILE_RENDER_STATIC_TRANSPARENT", staticRender);
            ok &= staticRender;

            layer.setAnimatedTile(anim, 2);
            boolean animatedState = layer.getAnimatedTile(anim) == 2;
            marker("DP_R9_TILE_ANIMATED_STATE", animatedState);
            ok &= animatedState;

            Image target2 = Image.createImage(8, 6);
            layer.paint(target2.getGraphics());
            int[] p2 = target2.getDataBuffer();
            boolean animatedRender = sameRGB(pixel(p2, 8, 1, 3), G);
            marker("DP_R9_TILE_ANIMATED_RENDER", animatedRender);
            ok &= animatedRender;

            System.out.println("DP_R9_TILE_RENDER_GATE=" + (ok ? "PASS" : "FAIL"));
        } catch (Throwable t) {
            ok = false;
            System.out.println("DP_R9_TILE_RENDER_GATE=FAIL");
            System.out.println("DP_R9_TILE_RENDER_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }
        return ok;
    }

    private int testSpriteTiledLayerCollision() {
        int passed = 0;
        try {
            final int O = 0xFFFFFFFF;
            final int T = 0x00000000;

            Image opaqueTile = Image.createRGBImage(new int[] {
                O, O, O,
                O, O, O,
                O, O, O
            }, 3, 3, true);

            TiledLayer collisionLayer = new TiledLayer(2, 1, opaqueTile, 3, 3);
            collisionLayer.setCell(0, 0, 1);
            collisionLayer.setCell(1, 0, 0);
            collisionLayer.setPosition(0, 0);

            Image spriteImage = Image.createRGBImage(new int[] {
                O, T, T,
                T, T, T
            }, 3, 2, true);

            for (int i = 0; i < TRANSFORMS.length; i++) {
                String name = NAMES[i];
                boolean gate = true;
                try {
                    Sprite s = new Sprite(spriteImage);
                    s.setTransform(TRANSFORMS[i]);
                    s.setPosition(0, 0);

                    boolean sameBounding = s.collidesWith(collisionLayer, false);
                    boolean samePixel = s.collidesWith(collisionLayer, true);
                    marker("DP_R9_" + name + "_TILE_SAME_BOUNDING_TRUE", sameBounding);
                    marker("DP_R9_" + name + "_TILE_SAME_PIXEL_TRUE", samePixel);
                    gate &= sameBounding && samePixel;

                    s.setPosition(3, 0);
                    boolean emptyBounding = s.collidesWith(collisionLayer, false);
                    boolean emptyPixel = s.collidesWith(collisionLayer, true);
                    marker("DP_R9_" + name + "_TILE_EMPTYCELL_BOUNDING_FALSE", !emptyBounding);
                    marker("DP_R9_" + name + "_TILE_EMPTYCELL_PIXEL_FALSE", !emptyPixel);
                    gate &= !emptyBounding && !emptyPixel;

                    s.setPosition(10, 0);
                    boolean farBounding = s.collidesWith(collisionLayer, false);
                    boolean farPixel = s.collidesWith(collisionLayer, true);
                    marker("DP_R9_" + name + "_TILE_FAR_BOUNDING_FALSE", !farBounding);
                    marker("DP_R9_" + name + "_TILE_FAR_PIXEL_FALSE", !farPixel);
                    gate &= !farBounding && !farPixel;

                    System.out.println("DP_R9_" + name + "_TILE_COLLISION_GATE=" + (gate ? "PASS" : "FAIL"));
                    if (gate) passed++;
                } catch (Throwable t) {
                    System.out.println("DP_R9_" + name + "_TILE_COLLISION_GATE=FAIL");
                    System.out.println("DP_R9_" + name + "_TILE_COLLISION_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                    t.printStackTrace();
                }
            }
        } catch (Throwable t) {
            System.out.println("DP_R9_TILE_COLLISION_SETUP=FAIL");
            System.out.println("DP_R9_TILE_COLLISION_FATAL=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
        }

        System.out.println("DP_R9_TILE_COLLISION_TRANSFORM_COUNT=8");
        System.out.println("DP_R9_TILE_COLLISION_PASS_COUNT=" + passed);
        System.out.println("DP_R9_TILE_COLLISION_GATE=" + (passed == 8 ? "PASS" : "FAIL"));
        return passed;
    }

    public void run() {
        boolean renderPass = testTiledLayerRendering();
        int collisionPassCount = testSpriteTiledLayerCollision();
        boolean all = renderPass && collisionPassCount == 8;

        System.out.println("DP_R9_DIAGNOSTIC_GATE=" + (all ? "PASS" : "FAIL"));
        System.out.println("DP_R9_RUNTIME_GATE=" + (all ? "PASS" : "FAIL"));

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
