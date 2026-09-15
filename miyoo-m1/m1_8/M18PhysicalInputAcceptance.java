package org.recompile.mobile;

/**
 * Real-device M1.8 physical-input acceptance harness.
 * Uses the production poll() path, therefore JNI /dev/input/js0 acquisition is
 * exercised rather than dispatchState(). MobilePlatform acceptance counters
 * are the bounded observation seam; no alternate MIDP dispatcher is added.
 */
public final class M18PhysicalInputAcceptance {
    private static final long TEST_MS = 30000L;
    private static final long POLL_MS = 20L;

    private M18PhysicalInputAcceptance() {}

    public static void main(String[] args) throws Exception {
        MobilePlatform.m1AcceptanceReset();
        M1InputDispatch dispatch = new M1InputDispatch();
        long start = System.currentTimeMillis();
        long end = start + TEST_MS;

        System.out.println("M1_8_PHYSICAL_BEGIN=YES");
        System.out.println("M1_8_PHYSICAL_WINDOW_MS=" + TEST_MS);
        System.out.println("M1_8_PHYSICAL_INSTRUCTION=PRESS_DPAD_AND_A_THEN_RELEASE");

        while (System.currentTimeMillis() < end) {
            dispatch.poll(System.currentTimeMillis());
            Thread.sleep(POLL_MS);
        }

        int presses = MobilePlatform.m1AcceptancePressCount();
        int releases = MobilePlatform.m1AcceptanceReleaseCount();
        int repeats = MobilePlatform.m1AcceptanceRepeatCount();
        System.out.println("M1_8_PHYSICAL_PRESS_COUNT=" + presses);
        System.out.println("M1_8_PHYSICAL_RELEASE_COUNT=" + releases);
        System.out.println("M1_8_PHYSICAL_REPEAT_COUNT=" + repeats);

        if (presses <= 0) throw new RuntimeException("NO_PHYSICAL_PRESS");
        if (releases <= 0) throw new RuntimeException("NO_PHYSICAL_RELEASE");
        if (presses != releases) throw new RuntimeException("PRESS_RELEASE_MISMATCH");
        System.out.println("M1_8_PHYSICAL_ACCEPTANCE_MARKER=PASS");
    }
}
