public final class M17InputProbe {
    static { System.loadLibrary("m1_7_input"); }
    private static native int openInput();
    private static native int waitControl(int control, int timeoutMs);
    private static native void closeInput();

    private static final String[] NAMES = {
        "UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","L","R"
    };

    public static void main(String[] args) {
        System.out.println("M1_7_JAVA_MARKER=PASS");
        int rc = openInput();
        System.out.println("M1_7_INPUT_OPEN_RC=" + rc);
        if (rc != 0) System.exit(10);
        for (int i=0; i<NAMES.length; i++) {
            System.out.println("M1_7_WAIT=" + NAMES[i]);
            rc = waitControl(i, 15000);
            System.out.println("M1_7_CONTROL_" + NAMES[i] + "_RC=" + rc);
            if (rc != 0) { closeInput(); System.exit(20+i); }
        }
        closeInput();
        System.out.println("M1_7_INPUT_SEQUENCE_MARKER=PASS");
    }
}
