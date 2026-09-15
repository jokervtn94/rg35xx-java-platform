package org.recompile.mobile;

import java.io.File;

/**
 * M1.9 standalone acceptance entry point.
 * Uses FreeJ2ME's real MobilePlatform -> MIDletLoader.start() lifecycle instead
 * of attempting to execute the MIDlet class as a Java main class.
 */
public final class M19LifecycleLauncher {
    private M19LifecycleLauncher() {}

    private static void mark(String value) {
        System.out.println(value);
        System.out.flush();
        System.err.println(value);
        System.err.flush();
    }

    public static void main(String[] args) throws Exception {
        mark("M1_9_MAIN_ENTER=YES");
        mark("M1_9_ARG_COUNT=" + args.length);
        if (args.length != 1) {
            mark("M1_9_LIFECYCLE_USAGE=launcher <acceptance-midlet.jar>");
            System.exit(2);
        }

        File midletJar = new File(args[0]);
        mark("M1_9_MIDLET_PATH=" + midletJar.getPath());
        if (!midletJar.isFile()) {
            mark("M1_9_MIDLET_JAR_MISSING=" + midletJar.getPath());
            System.exit(3);
        }
        mark("M1_9_MIDLET_FILE=PASS");

        mark("M1_9_PLATFORM_CREATE_BEGIN=YES");
        MobilePlatform platform = new MobilePlatform(640, 480);
        mark("M1_9_PLATFORM_CREATE_END=YES");
        Mobile.setPlatform(platform, new Runnable() {
            public void run() { }
        });
        mark("M1_9_PLATFORM_SET=YES");

        mark("M1_9_LIFECYCLE_PLATFORM_READY=YES");
        mark("M1_9_LOAD_BEGIN=YES");
        if (!platform.load(midletJar.toURI().toString())) {
            mark("M1_9_LIFECYCLE_LOAD=FAIL");
            System.exit(4);
        }
        mark("M1_9_LIFECYCLE_LOAD=PASS");

        // Call the canonical FreeJ2ME MIDlet loader lifecycle directly.
        // Do not call MobilePlatform.runJar(): that also preloads the media
        // engine, which is outside the M1.9 input/Canvas acceptance scope.
        mark("M1_9_STARTAPP_BEGIN=YES");
        platform.loader.start();
        mark("M1_9_LIFECYCLE_STARTAPP_INVOKED=YES");
    }
}
