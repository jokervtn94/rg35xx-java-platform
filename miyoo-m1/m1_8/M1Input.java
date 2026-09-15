package org.recompile.mobile;

/** M1.8 raw /dev/input/js0 bridge. JNI owns acquisition only. */
public final class M1Input {
    static { System.loadLibrary("m1_8_input"); }
    private M1Input() {}
    public static native int rawGetState();
}
