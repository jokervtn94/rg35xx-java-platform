package org.recompile.mobile;

import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.midlet.MIDlet;

public final class DP6SpriteTransformCollisionDiagnosticMIDlet extends MIDlet implements Runnable {
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
        System.out.println("DP_R6_PRIMARY_VARIABLE=DIAGNOSTIC_ONLY_NO_RUNTIME_CHANGE");
        System.out.println("DP_R6_RUNTIME_CHANGE=NONE");
        new Thread(this, "dp-r6-transform-collision").start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    public void run() {
        boolean all = true;
        try {
            final int T = 0x00000000;
            final int O = 0xFFFF0000;

            // Non-square 3x2 source with a single opaque pixel.
            // Same transform + same position must collide at pixel level.
            // Shifting the second sprite by one x-pixel keeps bounding boxes
            // overlapping but moves the only opaque pixel, so pixel collision
            // must be false.
            Image source = Image.createRGBImage(new int[] {
                O, T, T,
                T, T, T
            }, 3, 2, true);

            System.out.println("DP_R6_SOURCE=PASS size=" + source.getWidth() + "x" + source.getHeight());

            int passed = 0;
            for (int i = 0; i < TRANSFORMS.length; i++) {
                String name = NAMES[i];
                try {
                    Sprite a = new Sprite(source);
                    Sprite b = new Sprite(source);
                    a.setTransform(TRANSFORMS[i]);
                    b.setTransform(TRANSFORMS[i]);

                    a.setPosition(0, 0);
                    b.setPosition(0, 0);

                    boolean sameBounds = a.collidesWith(b, false);
                    boolean samePixel = a.collidesWith(b, true);
                    boolean samePass = sameBounds && samePixel;
                    System.out.println("DP_R6_" + name + "_SAME_BOUNDING=" + (sameBounds ? "PASS" : "FAIL"));
                    System.out.println("DP_R6_" + name + "_SAME_PIXEL_TRUE=" + (samePixel ? "PASS" : "FAIL"));

                    b.setPosition(1, 0);
                    boolean offsetBounds = a.collidesWith(b, false);
                    boolean offsetPixel = a.collidesWith(b, true);
                    boolean offsetPass = offsetBounds && !offsetPixel;
                    System.out.println("DP_R6_" + name + "_OFFSET1_BOUNDING_TRUE=" + (offsetBounds ? "PASS" : "FAIL"));
                    System.out.println("DP_R6_" + name + "_OFFSET1_PIXEL_FALSE=" + (!offsetPixel ? "PASS" : "FAIL") + " actual=" + offsetPixel);

                    b.setPosition(10, 0);
                    boolean farBounds = a.collidesWith(b, false);
                    boolean farPixel = a.collidesWith(b, true);
                    boolean farPass = !farBounds && !farPixel;
                    System.out.println("DP_R6_" + name + "_FAR_BOUNDING_FALSE=" + (!farBounds ? "PASS" : "FAIL"));
                    System.out.println("DP_R6_" + name + "_FAR_PIXEL_FALSE=" + (!farPixel ? "PASS" : "FAIL"));

                    boolean gate = samePass && offsetPass && farPass;
                    System.out.println("DP_R6_" + name + "_GATE=" + (gate ? "PASS" : "FAIL"));
                    if (gate) passed++; else all = false;
                } catch (Throwable t) {
                    all = false;
                    System.out.println("DP_R6_" + name + "_GATE=FAIL");
                    System.out.println("DP_R6_" + name + "_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                    t.printStackTrace();
                }
            }

            System.out.println("DP_R6_TRANSFORM_COUNT=8");
            System.out.println("DP_R6_TRANSFORM_PASS_COUNT=" + passed);
            System.out.println("DP_R6_DIAGNOSTIC_GATE=" + (all && passed == 8 ? "PASS" : "FAIL"));
            System.out.println("DP_R6_RUNTIME_GATE=" + (all && passed == 8 ? "PASS" : "FAIL"));
            notifyDestroyed();
            System.exit(all && passed == 8 ? 0 : 2);
        } catch (Throwable t) {
            System.out.println("DP_R6_DIAGNOSTIC_GATE=FAIL");
            System.out.println("DP_R6_RUNTIME_GATE=FAIL");
            System.out.println("DP_R6_FATAL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(3);
        }
    }
}
