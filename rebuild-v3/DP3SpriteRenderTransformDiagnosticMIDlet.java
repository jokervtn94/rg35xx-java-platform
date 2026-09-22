package org.recompile.mobile;

import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.midlet.MIDlet;

public final class DP3SpriteRenderTransformDiagnosticMIDlet extends MIDlet implements Runnable {
    private static final int[] COLORS = new int[] {
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF
    };

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

    protected void startApp() {
        System.out.println("DP_R3_PRIMARY_VARIABLE=SPRITE_PAINT_DRAWREGION_TRANSFORM_PATH");
        System.out.println("DP_R3_SPRITE_IMPLEMENTATION_CHANGE=NONE");
        System.out.println("DP_R3_TRANSFORM_RENDERER_CHANGE=NONE");
        new Thread(this, "dp-r3-sprite-render").start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private static boolean isSourceColor(int pixel) {
        for (int i = 0; i < COLORS.length; i++) {
            if (pixel == COLORS[i]) return true;
        }
        return false;
    }

    private static int countSourceColors(int[] pixels) {
        int count = 0;
        for (int i = 0; i < pixels.length; i++) {
            if (isSourceColor(pixels[i])) count++;
        }
        return count;
    }

    private static boolean hasEveryColorExactlyOnce(int[] pixels) {
        for (int c = 0; c < COLORS.length; c++) {
            int count = 0;
            for (int i = 0; i < pixels.length; i++) {
                if (pixels[i] == COLORS[c]) count++;
            }
            if (count != 1) return false;
        }
        return true;
    }

    public void run() {
        boolean all = true;
        try {
            Image source = Image.createRGBImage(COLORS, 3, 2, true);
            System.out.println("DP_R3_SOURCE_IMAGE=PASS");
            System.out.println("DP_R3_SOURCE_SIZE=" + source.getWidth() + "x" + source.getHeight());

            for (int i = 0; i < TRANSFORMS.length; i++) {
                String name = NAMES[i];
                try {
                    Image target = Image.createImage(8, 8);
                    Graphics g = target.getGraphics();

                    Sprite sprite = new Sprite(source);
                    sprite.setTransform(TRANSFORMS[i]);
                    sprite.setPosition(2, 2);

                    int expectedW = (TRANSFORMS[i] == Sprite.TRANS_ROT90 ||
                                     TRANSFORMS[i] == Sprite.TRANS_ROT270 ||
                                     TRANSFORMS[i] == Sprite.TRANS_MIRROR_ROT90 ||
                                     TRANSFORMS[i] == Sprite.TRANS_MIRROR_ROT270) ? 2 : 3;
                    int expectedH = (expectedW == 2) ? 3 : 2;

                    boolean dimensions = sprite.getWidth() == expectedW && sprite.getHeight() == expectedH;
                    System.out.println("DP_R3_" + name + "_DIMENSIONS=" + (dimensions ? "PASS" : "FAIL") +
                                       " actual=" + sprite.getWidth() + "x" + sprite.getHeight() +
                                       " expected=" + expectedW + "x" + expectedH);

                    sprite.paint(g);
                    System.out.println("DP_R3_" + name + "_PAINT_RETURN=PASS");

                    int[] targetPixels = target.getDataBuffer();
                    int painted = countSourceColors(targetPixels);
                    boolean colors = painted == 6 && hasEveryColorExactlyOnce(targetPixels);

                    System.out.println("DP_R3_" + name + "_PAINTED_SOURCE_PIXELS=" + painted);
                    System.out.println("DP_R3_" + name + "_COLOR_PRESERVATION=" + (colors ? "PASS" : "FAIL"));

                    boolean gate = dimensions && colors;
                    System.out.println("DP_R3_" + name + "_GATE=" + (gate ? "PASS" : "FAIL"));
                    if (!gate) all = false;
                } catch (Throwable t) {
                    all = false;
                    System.out.println("DP_R3_" + name + "_PAINT_RETURN=FAIL");
                    System.out.println("DP_R3_" + name + "_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                    t.printStackTrace();
                }
            }

            System.out.println("DP_R3_TRANSFORM_COUNT=8");
            System.out.println("DP_R3_DIAGNOSTIC_GATE=" + (all ? "PASS" : "FAIL"));
            System.out.println("DP_R3_RUNTIME_GATE=" + (all ? "PASS" : "FAIL"));
            notifyDestroyed();
            System.exit(all ? 0 : 2);
        } catch (Throwable t) {
            System.out.println("DP_R3_DIAGNOSTIC_GATE=FAIL");
            System.out.println("DP_R3_RUNTIME_GATE=FAIL");
            System.out.println("DP_R3_FATAL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(3);
        }
    }
}
