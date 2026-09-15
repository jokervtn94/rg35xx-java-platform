package org.recompile.mobile;
import java.io.File;
/** M1.9F-r5 canonical lifecycle launcher; normalize standalone JamVM encoding only. */
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

        // Real RG35XX/JamVM reports the ISO-8859-1 alias "8859_1". FreeJ2ME's
        // constructor compares file.encoding literally against supportedEncodings,
        // so that alias enters its desktop restart path before resizeLCD().
        // Normalize only this proven standalone alias; leave every other encoding
        // untouched/fail-closed so game-specific encoding behavior is not changed.
        String encoding = System.getProperty("file.encoding");
        mark("M1_9F_ENCODING_BEFORE=" + encoding);
        if ("8859_1".equals(encoding)) {
            System.setProperty("file.encoding", Mobile.supportedEncodings[Mobile.ISO_8859_1]);
            mark("M1_9F_ENCODING_NORMALIZED=PASS");
        } else {
            mark("M1_9F_ENCODING_NORMALIZED=NOT_REQUIRED");
        }
        mark("M1_9F_ENCODING_AFTER=" + System.getProperty("file.encoding"));

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

        Thread.sleep(32000L);
        mark("M1_9F_NORMAL_EXIT=PASS");
    }
}
