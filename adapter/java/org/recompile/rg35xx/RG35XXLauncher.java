package org.recompile.rg35xx;

import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Method;

import org.recompile.mobile.Mobile;
import org.recompile.mobile.MobilePlatform;

/** Original-RG35XX standalone launcher for the pinned Aweigit core. */
public final class RG35XXLauncher {
    private static final int INPUT_POLL_MS = 10;

    private RG35XXLauncher() { }

    public static void main(String[] args) {
        if (args.length < 3) {
            usage();
            System.exit(2);
        }

        File jar = new File(args[0]).getAbsoluteFile();
        int width = positiveInt(args[1], "width");
        int height = positiveInt(args[2], "height");
        if (!jar.isFile()) {
            System.err.println("RG35XX_A3_JAR_NOT_FOUND=" + jar.getAbsolutePath());
            System.exit(3);
        }

        File dataDir = args.length >= 4 ? new File(args[3]).getAbsoluteFile() : jar.getParentFile();
        File rootDir = args.length >= 5 ? new File(args[4]).getAbsoluteFile() : dataDir;
        if (dataDir == null) dataDir = new File(".").getAbsoluteFile();
        if (rootDir == null) rootDir = dataDir;

        final boolean raw2d = Boolean.getBoolean("rg35xx.raw2d");
        if (raw2d) {
            System.out.println("RG35XX_A4_RAW2D=ENABLED");
        }

        final MobilePlatform platform = new MobilePlatform(width, height);
        Mobile.setPlatform(platform);
        platform.dataPath = withSlash(dataDir.getAbsolutePath());
        platform.rootPath = withSlash(rootDir.getAbsolutePath());

        try {
            int videoRc = RG35XXVideo.initDisplay();
            if (videoRc != 0) {
                System.err.println("RG35XX_A3_VIDEO_INIT_FAIL=" + videoRc);
                System.exit(4);
            }
            RG35XXInput.rawGetState();
        } catch (UnsatisfiedLinkError e) {
            System.err.println("RG35XX_A3_NATIVE_LOAD_FAIL=" + e.toString());
            System.exit(5);
        }

        final FramePresenter presenter = new FramePresenter(platform, raw2d);
        platform.setPainter(presenter);

        if (!platform.loadJar(jar.getAbsolutePath())) {
            RG35XXVideo.shutdownDisplay();
            System.err.println("RG35XX_A3_LOAD_JAR_FAIL=" + jar.getAbsolutePath());
            System.exit(6);
        }

        final InputPump input = new InputPump(platform);
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            public void run() {
                input.stop();
                RG35XXVideo.shutdownDisplay();
            }
        }, "rg35xx-shutdown"));

        System.out.println("RG35XX_A3_LAUNCH=" + jar.getAbsolutePath());
        System.out.println("RG35XX_A3_LOGICAL_LCD=" + width + "x" + height);
        System.out.println("RG35XX_A3_DATA_PATH=" + platform.dataPath);
        System.out.println("RG35XX_A3_ROOT_PATH=" + platform.rootPath);

        platform.runJar();
        input.start();
    }

    private static int positiveInt(String text, String name) {
        try {
            int value = Integer.parseInt(text);
            if (value > 0) return value;
        } catch (NumberFormatException e) {
            // handled below
        }
        System.err.println("RG35XX_A3_BAD_" + name.toUpperCase() + "=" + text);
        System.exit(2);
        return 0;
    }

    private static String withSlash(String path) {
        return path.endsWith("/") ? path : path + "/";
    }

    private static void usage() {
        System.err.println("Usage: RG35XXLauncher <midlet.jar> <logical-width> <logical-height> [data-dir] [file-root]");
    }

    private static final class FramePresenter implements Runnable {
        private final MobilePlatform platform;
        private final boolean rawMode;
        private final Method rawPixelsMethod;
        private int[] pixels;
        private int lastError = Integer.MIN_VALUE;
        private boolean rawInvokeErrorLogged;

        FramePresenter(MobilePlatform platform, boolean rawMode) {
            this.platform = platform;
            this.rawMode = rawMode;
            Method method = null;
            if (rawMode) {
                try {
                    method = platform.getClass().getMethod("getRG35XXLCDPixels", new Class[0]);
                } catch (Exception e) {
                    throw new IllegalStateException("RG35XX_A4_RAW2D_METHOD_MISSING", e);
                }
            }
            rawPixelsMethod = method;
        }

        public void run() {
            if (rawMode) {
                try {
                    int[] raw = (int[]) rawPixelsMethod.invoke(platform, new Object[0]);
                    int width = platform.lcdWidth;
                    int height = platform.lcdHeight;
                    if (raw == null || raw.length < width * height) {
                        if (!rawInvokeErrorLogged) {
                            System.err.println("RG35XX_A4_RAW2D_BUFFER_INVALID");
                            rawInvokeErrorLogged = true;
                        }
                        return;
                    }
                    int rc = RG35XXVideo.presentARGB(raw, width, height);
                    if (rc != 0 && rc != lastError) {
                        System.err.println("RG35XX_A3_PRESENT_FAIL=" + rc + " SOURCE=" + width + "x" + height + " RAW2D=YES");
                    }
                    lastError = rc;
                    return;
                } catch (Exception e) {
                    if (!rawInvokeErrorLogged) {
                        System.err.println("RG35XX_A4_RAW2D_PRESENT_EXCEPTION=" + e.toString());
                        rawInvokeErrorLogged = true;
                    }
                    return;
                }
            }

            BufferedImage image = platform.getLCD();
            if (image == null) return;
            int width = image.getWidth();
            int height = image.getHeight();
            int needed = width * height;
            if (pixels == null || pixels.length != needed) pixels = new int[needed];
            pixels = image.getRGB(0, 0, width, height, pixels, 0, width);
            int rc = RG35XXVideo.presentARGB(pixels, width, height);
            if (rc != 0 && rc != lastError) {
                System.err.println("RG35XX_A3_PRESENT_FAIL=" + rc + " SOURCE=" + width + "x" + height);
            }
            lastError = rc;
        }
    }

    private static final class InputPump implements Runnable {
        private final RG35XXKeyDispatcher dispatcher;
        private volatile boolean running;
        private Thread thread;

        InputPump(MobilePlatform platform) {
            dispatcher = new RG35XXKeyDispatcher(platform);
        }

        void start() {
            if (running) return;
            running = true;
            thread = new Thread(this, "rg35xx-input");
            thread.setDaemon(true);
            thread.start();
        }

        void stop() {
            running = false;
            if (thread != null) thread.interrupt();
        }

        public void run() {
            while (running) {
                dispatcher.poll(System.currentTimeMillis());
                try {
                    Thread.sleep(INPUT_POLL_MS);
                } catch (InterruptedException e) {
                    // re-check running
                }
            }
        }
    }
}
