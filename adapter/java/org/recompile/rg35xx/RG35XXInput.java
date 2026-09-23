package org.recompile.rg35xx;

import java.io.File;

/** Thin JNI owner for the proven original-RG35XX /dev/input/js0 path. */
public final class RG35XXInput {
    static {
        String dir = System.getProperty("rg35xx.native.dir");
        if (dir != null && dir.length() > 0) {
            System.load(new File(dir, "librg35xx_input.so").getAbsolutePath());
        } else {
            System.loadLibrary("rg35xx_input");
        }
    }

    private RG35XXInput() { }

    public static native int rawGetState();
}
