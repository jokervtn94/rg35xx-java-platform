package org.recompile.mobile;

/** M1.9E: one-frame bridge from the proven Java ARGB framebuffer to Golden M1.6 SDL1/fbcon. */
public final class M19SdlPresenter {
    static { System.loadLibrary("m1_9e_presenter"); }
    private M19SdlPresenter() {}
    public static native int initDisplay();
    public static native int presentARGB(int[] pixels, int width, int height);
    public static native void shutdownDisplay();
}
