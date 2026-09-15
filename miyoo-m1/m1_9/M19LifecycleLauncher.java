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

        // M1.9A primary variable only: prevent PlatformFont from constructing
        // host java.awt.Font/FontMetrics. The workflow patches only
        // PlatformFont for this property; locked M1.6-M1.8 remain unchanged.
        System.setProperty("rg35xx.headless.font", "true");
        mark("M1_9_HEADLESS_FONT=ENABLED");

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

        mark("M1_9_PLATFORM_CREATE_BEGIN=YES");
        MobilePlatform platform = new MobilePlatform(640, 480);
        mark("M1_9_PLATFORM_CREATE_END=YES");
        Mobile.setPlatform(platform, new Runnable() { public void run() { } });
        mark("M1_9_PLATFORM_SET=YES");

        mark("M1_9_LIFECYCLE_PLATFORM_READY=YES");
        mark("M1_9_LOAD_BEGIN=YES");
        if (!platform.load(midletJar.toURI().toString())) { mark("M1_9_LIFECYCLE_LOAD=FAIL"); System.exit(4); }
        mark("M1_9_LIFECYCLE_LOAD=PASS");

        mark("M1_9_STARTAPP_BEGIN=YES");
        platform.loader.start();
        mark("M1_9_LIFECYCLE_STARTAPP_INVOKED=YES");
    }
}
