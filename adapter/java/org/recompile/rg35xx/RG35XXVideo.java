package org.recompile.rg35xx;

import java.io.File;

/** Thin JNI boundary for the original-RG35XX SDL1/fbcon presenter. */
public final class RG35XXVideo {
    static {
        String dir = System.getProperty("rg35xx.native.dir");
        if (dir != null && dir.length() > 0) {
            System.load(new File(dir, "librg35xx_video.so").getAbsolutePath());
        } else {
            System.loadLibrary("rg35xx_video");
        }
    }

    private RG35XXVideo() { }

    public static native int initDisplay();
    public static native int presentARGB(int[] pixels, int width, int height);
    public static native void shutdownDisplay();
}
