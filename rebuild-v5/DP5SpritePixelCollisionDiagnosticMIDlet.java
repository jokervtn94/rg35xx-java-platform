package org.recompile.mobile;

import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.midlet.MIDlet;

public final class DP5SpritePixelCollisionDiagnosticMIDlet extends MIDlet implements Runnable {
    protected void startApp() {
        System.out.println("DP_R5_PRIMARY_VARIABLE=SPRITE_GETARGBDATA_WIDTH_HEIGHT_ORDER_ONLY");
        System.out.println("DP_R5_PLATFORMIMAGE_IMPLEMENTATION_CHANGE=NONE");
        System.out.println("DP_R5_OTHER_SPRITE_IMPLEMENTATION_CHANGE=NONE");
        new Thread(this, "dp-r5-sprite-collision").start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private static void require(String marker, boolean condition) {
        System.out.println(marker + "=" + (condition ? "PASS" : "FAIL"));
        if (!condition) throw new RuntimeException(marker);
    }

    public void run() {
        try {
            final int T = 0x00000000;
            final int R = 0xFFFF0000;
            final int G = 0xFF00FF00;
            final int B = 0xFF0000FF;

            // 2x2 case. At offset x=1 the overlap is 1x2 (non-square).
            Image aImg = Image.createRGBImage(new int[] {
                R, T,
                T, T
            }, 2, 2, true);
            Image bImg = Image.createRGBImage(new int[] {
                G, T,
                T, T
            }, 2, 2, true);

            Sprite a = new Sprite(aImg);
            Sprite b = new Sprite(bImg);

            a.setPosition(0, 0);
            require("DP_R5_SAMEPOS_BOUNDING_TRUE", a.collidesWith(b, false));
            require("DP_R5_SAMEPOS_PIXEL_TRUE", a.collidesWith(b, true));

            b.setPosition(1, 0);
            require("DP_R5_OFFSET1_BOUNDING_TRUE", a.collidesWith(b, false));
            require("DP_R5_OFFSET1_PIXEL_FALSE", !a.collidesWith(b, true));

            b.setPosition(4, 0);
            require("DP_R5_FAR_BOUNDING_FALSE", !a.collidesWith(b, false));
            require("DP_R5_FAR_PIXEL_FALSE", !a.collidesWith(b, true));

            // Explicit 3x2 rectangular images.
            Image cImg = Image.createRGBImage(new int[] {
                R, T, B,
                T, T, T
            }, 3, 2, true);
            Image dImg = Image.createRGBImage(new int[] {
                G, T, B,
                T, T, T
            }, 3, 2, true);

            Sprite c = new Sprite(cImg);
            Sprite d = new Sprite(dImg);

            // x-offset => 2x2 overlap. Opaque pixels do not coincide.
            c.setPosition(0, 0);
            d.setPosition(1, 0);
            require("DP_R5_RECT_X_PIXEL_FALSE", !c.collidesWith(d, true));

            // y-offset => 3x1 overlap. Lower source row is transparent.
            d.setPosition(0, 1);
            require("DP_R5_RECT_Y_PIXEL_FALSE", !c.collidesWith(d, true));

            System.out.println("DP_R5_NON_SQUARE_OVERLAPS=2");
            System.out.println("DP_R5_DIAGNOSTIC_GATE=PASS");
            System.out.println("DP_R5_RUNTIME_GATE=PASS");
            notifyDestroyed();
            System.exit(0);
        } catch (Throwable t) {
            System.out.println("DP_R5_DIAGNOSTIC_GATE=FAIL");
            System.out.println("DP_R5_RUNTIME_GATE=FAIL");
            System.out.println("DP_R5_FATAL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(2);
        }
    }
}
