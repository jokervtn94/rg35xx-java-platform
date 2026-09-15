package org.recompile.mobile;
import java.io.File;
/** M1.9F-r2 canonical FreeJ2ME MIDlet lifecycle launcher with bounded diagnostics. */
public final class M19CanvasLifecycleLauncher {
    private M19CanvasLifecycleLauncher() {}
    private static void mark(String s) {
        System.out.println(s); System.out.flush();
        System.err.println(s); System.err.flush();
    }
    public static void main(String[] args) throws Exception {
        mark("M1_9F_MAIN_ENTER=YES");
        if (args.length != 1) System.exit(2);
        File jar = new File(args[0]); if (!jar.isFile()) System.exit(3);
        mark("M1_9F_JAR_VALID=PASS");

        System.setProperty("rg35xx.headless.font","true");
        System.setProperty("rg35xx.headless.image.probe","true");
        System.setProperty("rg35xx.headless.graphics.probe","true");
        mark("M1_9F_HEADLESS_PROPERTIES=PASS");

        mark("M1_9F_FONT_SIZE_BEGIN=YES");
        PlatformFont.setScreenSize(640,480);
        mark("M1_9F_FONT_SIZE_END=PASS");

        mark("M1_9F_PLATFORM_CONSTRUCT_BEGIN=YES");
        MobilePlatform platform = new MobilePlatform(640,480);
        mark("M1_9F_PLATFORM_CONSTRUCT_END=PASS");

        mark("M1_9F_SET_PLATFORM_BEGIN=YES");
        Mobile.setPlatform(platform, new Runnable(){ public void run(){} });
        mark("M1_9F_SET_PLATFORM_END=PASS");

        mark("M1_9F_PLATFORM_LOAD_BEGIN=YES");
        if (!platform.load(jar.toURI().toString())) {
            mark("M1_9F_PLATFORM_LOAD=FAIL");
            System.exit(4);
        }
        mark("M1_9F_PLATFORM_LOAD=PASS");

        mark("M1_9F_LOADER_START_BEGIN=YES");
        platform.loader.start();
        mark("M1_9F_LOADER_START_RETURNED=YES");

        // Acceptance MIDlet owns its bounded 30-second lifetime and calls notifyDestroyed().
        Thread.sleep(32000L);
        mark("M1_9F_NORMAL_EXIT=PASS");
    }
}
