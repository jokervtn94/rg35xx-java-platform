package org.recompile.mobile;

import java.io.File;

/**
 * M1.9 standalone acceptance entry point.
 * Uses FreeJ2ME's real MobilePlatform -> MIDletLoader.start() lifecycle instead
 * of attempting to execute the MIDlet class as a Java main class.
 */
public final class M19LifecycleLauncher {
    private M19LifecycleLauncher() {}

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("M1_9_LIFECYCLE_USAGE=launcher <acceptance-midlet.jar>");
            System.exit(2);
        }

        File midletJar = new File(args[0]);
        if (!midletJar.isFile()) {
            System.err.println("M1_9_MIDLET_JAR_MISSING=" + midletJar.getPath());
            System.exit(3);
        }

        MobilePlatform platform = new MobilePlatform(640, 480);
        Mobile.setPlatform(platform, new Runnable() {
            public void run() { }
        });

        System.out.println("M1_9_LIFECYCLE_PLATFORM_READY=YES");
        if (!platform.load(midletJar.toURI().toString())) {
            System.err.println("M1_9_LIFECYCLE_LOAD=FAIL");
            System.exit(4);
        }
        System.out.println("M1_9_LIFECYCLE_LOAD=PASS");

        // Call the canonical FreeJ2ME MIDlet loader lifecycle directly.
        // Do not call MobilePlatform.runJar(): that also preloads the media
        // engine, which is outside the M1.9 input/Canvas acceptance scope.
        platform.loader.start();
        System.out.println("M1_9_LIFECYCLE_STARTAPP_INVOKED=YES");
    }
}
