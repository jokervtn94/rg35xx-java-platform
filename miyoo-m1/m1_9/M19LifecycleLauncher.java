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
        mark("M1_9_ARG_COUNT=" + args.length);
        if (args.length != 1) { mark("M1_9_LIFECYCLE_USAGE=launcher <acceptance-midlet.jar>"); System.exit(2); }

        File midletJar = new File(args[0]);
        mark("M1_9_MIDLET_PATH=" + midletJar.getPath());
        if (!midletJar.isFile()) { mark("M1_9_MIDLET_JAR_MISSING=" + midletJar.getPath()); System.exit(3); }
        mark("M1_9_MIDLET_FILE=PASS");

        System.setProperty("rg35xx.headless.font", "true");
        mark("M1_9_HEADLESS_FONT=ENABLED");
        System.setProperty("rg35xx.headless.image.probe", "true");
        mark("M1_9_HEADLESS_IMAGE_PROBE=ENABLED");
        System.setProperty("rg35xx.headless.graphics.probe", "true");
        mark("M1_9_HEADLESS_GRAPHICS_PROBE=ENABLED");

        mark("M1_9_FONT_SIZE_BEGIN=YES");
        PlatformFont.setScreenSize(640, 480);
        mark("M1_9_FONT_SIZE_END=YES");

        mark("M1_9C_IMAGE_BEGIN=YES");
        PlatformImage image = new PlatformImage(640, 480);
        mark("M1_9C_IMAGE_END=YES");
        mark("M1_9C_BUFFER_LENGTH=" + image.getDataBuffer().length);

        mark("M1_9C_GRAPHICS_BEGIN=YES");
        javax.microedition.lcdui.Graphics graphics = image.getMIDPGraphics();
        mark("M1_9C_GRAPHICS_END=YES");
        mark("M1_9C_GRAPHICS_BUFFER_LENGTH=" + graphics.getFrameBuffer().length);
        mark("M1_9C_GRAPHICS_ACCEPTANCE_MARKER=PASS");
        mark("M1_9C_STOP_BEFORE_RENDER_METHODS=YES");
    }
}
