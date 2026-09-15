package org.recompile.mobile;

/** M1.7 raw /dev/input/js0 bridge. JNI owns acquisition only. */
public final class M1Input {
    private M1Input() {}
    public static native int rawGetState();
}
