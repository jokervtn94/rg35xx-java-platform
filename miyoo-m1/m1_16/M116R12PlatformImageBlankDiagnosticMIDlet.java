package org.recompile.mobile;

import javax.microedition.lcdui.Image;
import javax.microedition.midlet.MIDlet;

public final class M116R12PlatformImageBlankDiagnosticMIDlet extends MIDlet implements Runnable {
    protected void startApp() {
        System.out.println("M1_16_R12_PRIMARY_VARIABLE=BLANK_PLATFORMIMAGE_DIMENSIONS_ONLY");
        System.out.println("M1_16_R12_PLATFORMIMAGE_IMPLEMENTATION_CHANGE=GETWIDTH_GETHEIGHT_HEADLESS_FALLBACK_ONLY");
        System.out.println("M1_16_R12_SPRITE_CHANGE=NONE");
        System.out.println("M1_16_R12_RENDERER_CHANGE=NONE");
        new Thread(this, "m116-r12").start();
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private static void require(boolean ok, String gate) throws Exception {
        if (!ok) throw new Exception(gate);
        System.out.println(gate + "=PASS");
    }

    public void run() {
        try {
            Image a = Image.createImage(16, 8);
            require(a != null, "M1_16_R12_CREATE_BLANK");
            require(a.isMutable(), "M1_16_R12_MUTABLE");
            require(a.getWidth() == 16, "M1_16_R12_WIDTH");
            require(a.getHeight() == 8, "M1_16_R12_HEIGHT");
            require(a.getGraphics() != null, "M1_16_R12_GET_GRAPHICS");
            System.out.println("M1_16_R12_DIMENSION_GATE=PASS");
            System.out.println("M1_16_R12_RUNTIME_GATE=PASS");
            notifyDestroyed();
            System.exit(0);
        } catch (Throwable t) {
            System.out.println("M1_16_R12_DIMENSION_GATE=FAIL");
            System.out.println("M1_16_R12_RUNTIME_GATE=FAIL");
            System.out.println("M1_16_R12_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(2);
        }
    }
}
