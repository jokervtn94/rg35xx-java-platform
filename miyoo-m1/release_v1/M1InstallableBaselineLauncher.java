package org.recompile.mobile;

import java.io.File;

/**
 * RG35XX Installable Baseline v1.
 * Packaging/integration launcher only. It composes device-proven M1 input,
 * headless LCD/frontbuffer, GameCanvas flush and SDL1/fbcon presentation.
 */
public final class M1InstallableBaselineLauncher {
    private static M19InputPump inputPump;
    private static volatile boolean displayReady;
    private static volatile int presentCount;

    private M1InstallableBaselineLauncher() {}

    private static void mark(String s) {
        System.out.println(s); System.out.flush();
        System.err.println(s); System.err.flush();
    }

    private static void shutdown() {
        try { if (inputPump != null) inputPump.stop(); } catch (Throwable ignored) {}
        try { if (displayReady) M19SdlPresenter.shutdownDisplay(); } catch (Throwable ignored) {}
        displayReady = false;
    }

    public static void main(String[] args) throws Exception {
        mark("RG35XX_BASELINE_V1_MAIN_ENTER=YES");
        if (args.length != 1) {
            mark("RG35XX_BASELINE_V1_USAGE=FAIL_EXPECT_ONE_JAR");
            System.exit(2);
        }

        File jar = new File(args[0]);
        if (!jar.isFile()) {
            mark("RG35XX_BASELINE_V1_JAR=FAIL_NOT_FOUND");
            System.exit(3);
        }
        mark("RG35XX_BASELINE_V1_JAR=" + jar.getAbsolutePath());

        System.setProperty("rg35xx.headless.font", "true");
        System.setProperty("rg35xx.headless.image.probe", "true");
        System.setProperty("rg35xx.headless.graphics.probe", "true");
        mark("RG35XX_BASELINE_V1_HEADLESS_PROPERTIES=PASS");

        String encoding = System.getProperty("file.encoding");
        mark("RG35XX_BASELINE_V1_ENCODING_BEFORE=" + encoding);
        if ("8859_1".equals(encoding)) {
            System.setProperty("file.encoding", Mobile.supportedEncodings[Mobile.ISO_8859_1]);
            mark("RG35XX_BASELINE_V1_ENCODING_NORMALIZED=PASS");
        } else {
            mark("RG35XX_BASELINE_V1_ENCODING_NORMALIZED=NOT_REQUIRED");
        }

        PlatformFont.setScreenSize(640, 480);
        final MobilePlatform platform = new MobilePlatform(640, 480);
        MobilePlatform.isLibretro = true;
        Mobile.setPlatform(platform, new Runnable() { public void run() {} });
        mark("RG35XX_BASELINE_V1_PLATFORM_CONSTRUCT=PASS");

        int displayRc = M19SdlPresenter.initDisplay();
        mark("RG35XX_BASELINE_V1_DISPLAY_INIT_RC=" + displayRc);
        if (displayRc != 0) System.exit(4);
        displayReady = true;

        platform.setPainter(new Runnable() {
            public void run() {
                if (!displayReady) return;
                try {
                    PlatformImage front = platform.getLcdFrontbuffer();
                    if (front == null) return;
                    int w = front.getRG35XXWidth();
                    int h = front.getRG35XXHeight();
                    int rc = M19SdlPresenter.presentARGB(front.getDataBuffer(), w, h);
                    if (rc != 0) {
                        mark("RG35XX_BASELINE_V1_PRESENT_FAIL_RC=" + rc + " SIZE=" + w + "x" + h);
                        return;
                    }
                    presentCount++;
                    if ((presentCount % 300) == 0) {
                        mark("RG35XX_BASELINE_V1_PRESENT_HEARTBEAT=" + presentCount);
                    }
                } catch (Throwable t) {
                    mark("RG35XX_BASELINE_V1_PRESENT_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
                }
            }
        });

        inputPump = new M19InputPump();
        new Thread(inputPump, "rg35xx-baseline-input").start();
        mark("RG35XX_BASELINE_V1_INPUT_PUMP=STARTED");

        if (!platform.load(jar.toURI().toString())) {
            mark("RG35XX_BASELINE_V1_PLATFORM_LOAD=FAIL");
            shutdown();
            System.exit(5);
        }
        mark("RG35XX_BASELINE_V1_PLATFORM_LOAD=PASS");

        try {
            // Keep the proven direct loader path. Do not call runJar(): pinned
            // upstream runJar() performs eager media preparation, which is not
            // part of this locked baseline.
            platform.loader.start();
            mark("RG35XX_BASELINE_V1_LOADER_START_RETURNED=YES");
            while (!MobilePlatform.appTerminated) {
                try { Thread.sleep(250L); } catch (InterruptedException e) { break; }
            }
            mark("RG35XX_BASELINE_V1_APP_TERMINATED=" + MobilePlatform.appTerminated);
        } catch (Throwable t) {
            mark("RG35XX_BASELINE_V1_FATAL=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            shutdown();
            System.exit(6);
        }

        shutdown();
        mark("RG35XX_BASELINE_V1_PRESENT_COUNT=" + presentCount);
        mark("RG35XX_BASELINE_V1_NORMAL_EXIT=PASS");
    }
}
