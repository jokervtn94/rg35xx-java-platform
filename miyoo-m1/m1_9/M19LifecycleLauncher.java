package org.recompile.mobile;

import java.io.File;

/** M1.9 standalone real MIDP Canvas acceptance entry point. */
public final class M19LifecycleLauncher {
    private M19LifecycleLauncher() {}

    private static void mark(String value) {
        System.out.println(value); System.out.flush();
        System.err.println(value); System.err.flush();
    }

    public static void main(String[] args) throws Exception {
        mark("M1_9_MAIN_ENTER=YES");
        if (args.length != 1) System.exit(2);
        File midletJar = new File(args[0]);
        if (!midletJar.isFile()) System.exit(3);

        System.setProperty("rg35xx.headless.font", "true");
        System.setProperty("rg35xx.headless.image.probe", "true");
        System.setProperty("rg35xx.headless.graphics.probe", "true");
        mark("M1_9D_HEADLESS_RENDER=ENABLED");

        PlatformFont.setScreenSize(640, 480);
        mark("M1_9_FONT_SIZE_END=YES");
        PlatformImage image = new PlatformImage(640, 480);
        javax.microedition.lcdui.Graphics graphics = image.getMIDPGraphics();
        int[] fb = graphics.getFrameBuffer();
        mark("M1_9D_BUFFER_LENGTH=" + fb.length);

        // Primary variable: MIDP setColor + fillRect only.
        graphics.setColor(0x00FF00);
        graphics.fillRect(10, 20, 30, 40);

        int inside = fb[(20 * 640) + 10];
        int inside2 = fb[(59 * 640) + 39];
        int outside = fb[(19 * 640) + 10];
        int outside2 = fb[(60 * 640) + 40];
        mark("M1_9D_PIXEL_INSIDE_1=" + Integer.toHexString(inside));
        mark("M1_9D_PIXEL_INSIDE_2=" + Integer.toHexString(inside2));
        mark("M1_9D_PIXEL_OUTSIDE_1=" + Integer.toHexString(outside));
        mark("M1_9D_PIXEL_OUTSIDE_2=" + Integer.toHexString(outside2));

        boolean pass = inside == 0xFF00FF00 && inside2 == 0xFF00FF00 &&
                       outside == 0xFFFFFFFF && outside2 == 0xFFFFFFFF;
        mark("M1_9D_SETCOLOR_FILLRECT=" + (pass ? "PASS" : "FAIL"));
        if (!pass) System.exit(20);
        mark("M1_9D_RENDER_ACCEPTANCE_MARKER=PASS");
        mark("M1_9D_STOP_BEFORE_SDL_PRESENTER=YES");
    }
}
