package org.recompile.mobile;

import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.midlet.MIDlet;

public final class DP4GetRGBCollisionDiagnosticMIDlet extends MIDlet implements Runnable {
    protected void startApp() {
        System.out.println("DP_R4_PRIMARY_VARIABLE=PLATFORMIMAGE_GETRGB_HEADLESS_ONLY");
        System.out.println("DP_R4_SPRITE_COLLISION_IMPLEMENTATION_CHANGE=NONE");
        new Thread(this, "dp-r4-getrgb-collision").start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private static boolean same(int[] a, int[] b) {
        if (a.length != b.length) return false;
        for (int i=0; i<a.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    public void run() {
        boolean all = true;
        try {
            int T = 0x00000000;
            int R = 0xFFFF0000;
            int G = 0xFF00FF00;

            int[] p1 = new int[] { R, T, T, T };
            int[] p2 = new int[] { G, T, T, T };

            Image i1 = Image.createRGBImage(p1, 2, 2, true);
            Image i2 = Image.createRGBImage(p2, 2, 2, true);
            System.out.println("DP_R4_IMAGES=PASS");

            int[] out = new int[4];
            try {
                i1.getRGB(out, 0, 2, 0, 0, 2, 2);
                boolean exact = same(out, p1);
                System.out.println("DP_R4_DIRECT_GETRGB_RETURN=PASS");
                System.out.println("DP_R4_DIRECT_GETRGB_EXACT=" + (exact ? "PASS" : "FAIL"));
                if (!exact) all = false;
            } catch (Throwable t) {
                all = false;
                System.out.println("DP_R4_DIRECT_GETRGB_RETURN=FAIL");
                System.out.println("DP_R4_DIRECT_GETRGB_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                t.printStackTrace();
            }

            Sprite a = new Sprite(i1);
            Sprite b = new Sprite(i2);
            a.setPosition(0, 0);
            b.setPosition(0, 0);

            boolean sameBounds = a.collidesWith(b, false);
            System.out.println("DP_R4_SAMEPOS_BOUNDING=" + (sameBounds ? "PASS" : "FAIL") + " actual=" + sameBounds);
            if (!sameBounds) all = false;

            try {
                boolean samePixel = a.collidesWith(b, true);
                boolean ok = samePixel;
                System.out.println("DP_R4_SAMEPOS_PIXEL_RETURN=PASS");
                System.out.println("DP_R4_SAMEPOS_PIXEL_EXPECT_TRUE=" + (ok ? "PASS" : "FAIL") + " actual=" + samePixel);
                if (!ok) all = false;
            } catch (Throwable t) {
                all = false;
                System.out.println("DP_R4_SAMEPOS_PIXEL_RETURN=FAIL");
                System.out.println("DP_R4_SAMEPOS_PIXEL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                t.printStackTrace();
            }

            b.setPosition(1, 0);
            boolean offsetBounds = a.collidesWith(b, false);
            System.out.println("DP_R4_OFFSET1_BOUNDING_EXPECT_TRUE=" + (offsetBounds ? "PASS" : "FAIL") + " actual=" + offsetBounds);
            if (!offsetBounds) all = false;

            try {
                boolean offsetPixel = a.collidesWith(b, true);
                boolean ok = !offsetPixel;
                System.out.println("DP_R4_OFFSET1_PIXEL_RETURN=PASS");
                System.out.println("DP_R4_OFFSET1_PIXEL_EXPECT_FALSE=" + (ok ? "PASS" : "FAIL") + " actual=" + offsetPixel);
                if (!ok) all = false;
            } catch (Throwable t) {
                all = false;
                System.out.println("DP_R4_OFFSET1_PIXEL_RETURN=FAIL");
                System.out.println("DP_R4_OFFSET1_PIXEL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                t.printStackTrace();
            }

            b.setPosition(4, 0);
            boolean farBounds = a.collidesWith(b, false);
            boolean farPixel = a.collidesWith(b, true);
            boolean farOk = !farBounds && !farPixel;
            System.out.println("DP_R4_FAR_COLLISION_EXPECT_FALSE=" + (farOk ? "PASS" : "FAIL") +
                               " bounding=" + farBounds + " pixel=" + farPixel);
            if (!farOk) all = false;

            System.out.println("DP_R4_DIAGNOSTIC_GATE=" + (all ? "PASS" : "FAIL"));
            System.out.println("DP_R4_RUNTIME_GATE=" + (all ? "PASS" : "FAIL"));
            notifyDestroyed();
            System.exit(all ? 0 : 2);
        } catch (Throwable t) {
            System.out.println("DP_R4_DIAGNOSTIC_GATE=FAIL");
            System.out.println("DP_R4_RUNTIME_GATE=FAIL");
            System.out.println("DP_R4_FATAL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(3);
        }
    }
}
