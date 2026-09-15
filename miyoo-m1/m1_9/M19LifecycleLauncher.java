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

        // M1.9B is allocation-only. It proves whether the two resizeLCD backing
        // buffers can exist without BufferedImage/GTK. Rendering is not enabled.
        System.setProperty("rg35xx.headless.image.probe", "true");
        mark("M1_9_HEADLESS_IMAGE_PROBE=ENABLED");

        mark("M1_9_RESIZE_PROBE_BEGIN=YES");
        mark("M1_9_FONT_SIZE_BEGIN=YES");
        PlatformFont.setScreenSize(640, 480);
        mark("M1_9_FONT_SIZE_END=YES");

        mark("M1_9_FRONT_IMAGE_BEGIN=YES");
        PlatformImage probeFront = new PlatformImage(640, 480);
        mark("M1_9_FRONT_IMAGE_END=YES");
        mark("M1_9_FRONT_BUFFER_LENGTH=" + probeFront.getDataBuffer().length);

        mark("M1_9_BACK_IMAGE_BEGIN=YES");
        PlatformImage probeBack = new PlatformImage(640, 480);
        mark("M1_9_BACK_IMAGE_END=YES");
        mark("M1_9_BACK_BUFFER_LENGTH=" + probeBack.getDataBuffer().length);
        probeFront = null;
        probeBack = null;
        mark("M1_9_RESIZE_PROBE_END=YES");

        // Stop deliberately here for M1.9B. MobilePlatform constructor would
        // immediately create PlatformGraphics, whose Graphics2D path is the next
        // independent AWT boundary and must not be mixed into this checkpoint.
        mark("M1_9B_ALLOCATION_ACCEPTANCE_MARKER=PASS");
        mark("M1_9B_STOP_BEFORE_PLATFORMGRAPHICS=YES");
    }
}
