package org.recompile.mobile;

/** Deterministic M1.8 acceptance seam. Java 5 compatible. */
public final class M18DispatchAcceptance {
    private static int failures;

    private static void check(String name, boolean ok) {
        System.out.println("M1_8_ACCEPT " + name + "=" + (ok ? "PASS" : "FAIL"));
        if (!ok) failures++;
    }

    public static void main(String[] args) {
        M1InputDispatch d = new M1InputDispatch();
        MobilePlatform.m1AcceptanceReset();

        d.dispatchState(0, 0);
        d.dispatchState(1 << 0, 10);       // UP press
        d.dispatchState(1 << 0, 409);      // before repeat
        d.dispatchState(1 << 0, 410);      // first repeat
        d.dispatchState(0, 420);           // UP release
        check("UP_PRESS", MobilePlatform.m1AcceptancePressCount() == 1);
        check("UP_REPEAT_BOUNDED", MobilePlatform.m1AcceptanceRepeatCount() == 1);
        check("UP_RELEASE", MobilePlatform.m1AcceptanceReleaseCount() == 1);

        MobilePlatform.m1AcceptanceReset();
        d.dispatchState(1 << 4, 500);       // A / FIRE press
        d.dispatchState(0, 510);            // A / FIRE release
        check("FIRE_PRESS", MobilePlatform.m1AcceptancePressCount() == 1);
        check("FIRE_RELEASE", MobilePlatform.m1AcceptanceReleaseCount() == 1);

        MobilePlatform.m1AcceptanceReset();
        d.dispatchState(1 << 5, 600);       // B non-repeatable
        d.dispatchState(1 << 5, 2000);
        d.dispatchState(0, 2010);
        check("NO_REPEAT_NON_GAMEPLAY", MobilePlatform.m1AcceptanceRepeatCount() == 0);
        check("NO_STUCK_KEY", MobilePlatform.m1AcceptancePressCount() == MobilePlatform.m1AcceptanceReleaseCount());

        if (failures == 0) {
            System.out.println("M1_8_MIDP_ACCEPTANCE_MARKER=PASS");
            return;
        }
        System.out.println("M1_8_MIDP_ACCEPTANCE_MARKER=FAIL failures=" + failures);
        System.exit(2);
    }
}
