package org.recompile.mobile;

import java.io.File;

/** M1.9 standalone rendering acceptance entry point. */
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
        mark("M1_9E_HEADLESS_RENDER=ENABLED");

        PlatformFont.setScreenSize(640, 480);
        mark("M1_9_FONT_SIZE_END=YES");
        PlatformImage image = new PlatformImage(640, 480);
        javax.microedition.lcdui.Graphics graphics = image.getMIDPGraphics();
        int[] fb = graphics.getFrameBuffer();
        mark("M1_9E_BUFFER_LENGTH=" + fb.length);

        // Keep the M1.9D-proven software raster primitive unchanged.
        graphics.setColor(0x000000FF);
        graphics.fillRect(0, 0, 640, 480);
        graphics.setColor(0x0000FF00);
        graphics.fillRect(160, 120, 320, 240);

        int blue = fb[0];
        int green = fb[(120 * 640) + 160];
        boolean rasterPass = blue == 0xFF0000FF && green == 0xFF00FF00;
        mark("M1_9E_RASTER_BLUE=" + Integer.toHexString(blue));
        mark("M1_9E_RASTER_GREEN=" + Integer.toHexString(green));
        mark("M1_9E_RASTER_PRECHECK=" + (rasterPass ? "PASS" : "FAIL"));
        if (!rasterPass) System.exit(20);

        // Primary M1.9E variable: Java int[] -> exact M1.6-style SDL1/fbcon presenter.
        int init = M19SdlPresenter.initDisplay();
        mark("M1_9E_NATIVE_INIT_RC=" + init);
        if (init != 0) System.exit(30);
        int present = M19SdlPresenter.presentARGB(fb, 640, 480);
        mark("M1_9E_PRESENT_RC=" + present);
        if (present != 0) {
            M19SdlPresenter.shutdownDisplay();
            System.exit(31);
        }
        mark("M1_9E_SDL_PRESENTER_MARKER=PASS");
        Thread.sleep(5000L);
        M19SdlPresenter.shutdownDisplay();
        mark("M1_9E_NORMAL_EXIT=PASS");
        mark("M1_9E_DEVICE_ACCEPTANCE_MARKER=PASS");
    }
}
