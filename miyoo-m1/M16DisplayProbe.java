public final class M16DisplayProbe {
    static {
        System.loadLibrary("m1_6_display");
    }

    private static native int initDisplay();
    private static native int showColor(int rgb, int milliseconds);
    private static native void shutdownDisplay();

    public static void main(String[] args) {
        System.out.println("M1_6_JAVA_MARKER=PASS");
        int rc = initDisplay();
        System.out.println("M1_6_NATIVE_INIT_RC=" + rc);
        if (rc != 0) System.exit(10);
        int[] colors = {0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF};
        String[] names = {"RED", "GREEN", "BLUE", "WHITE"};
        for (int i = 0; i < colors.length; i++) {
            rc = showColor(colors[i], 900);
            System.out.println("M1_6_FRAME_" + names[i] + "_RC=" + rc);
            if (rc != 0) {
                shutdownDisplay();
                System.exit(20 + i);
            }
        }
        shutdownDisplay();
        System.out.println("M1_6_DISPLAY_SEQUENCE_MARKER=PASS");
    }
}
