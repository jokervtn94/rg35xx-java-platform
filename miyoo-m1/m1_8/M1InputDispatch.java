package org.recompile.mobile;

/**
 * M1.8 semantic-control -> canonical FreeJ2ME-Plus MIDP adapter.
 *
 * Contract:
 *  - M1.8/JNI is the sole raw js0 owner in the production M1.8 runtime.
 *  - MobilePlatform remains the sole MIDP event owner.
 *  - Raw RG35XX semantic controls are converted to canonical Libretro logical
 *    slots, then Mobile.getMobileKey(slot) performs the phone-specific MIDP
 *    mapping already owned by FreeJ2ME-Plus.
 *  - This class never calls a Displayable directly.
 *  - Repeat is generated only for held directional/FIRE controls and is
 *    bounded by time; press/release are edge-triggered.
 */
public final class M1InputDispatch {
    public static final int UP=1, DOWN=2, LEFT=3, RIGHT=4;
    public static final int A=5, B=6, X=7, Y=8, L1=9, R1=10, START=11, SELECT=12;

    private static final int REPEAT_DELAY_MS = 400;
    private static final int REPEAT_PERIOD_MS = 100;

    private int previous;
    private final long[] nextRepeat = new long[13];

    /** Poll exactly once. Call from the existing canonical frontend input tick only. */
    public void poll(long nowMs) {
        final int state = M1Input.rawGetState();
        dispatchState(state, nowMs);
    }

    /** Package-visible deterministic seam for CI/device exercisers. */
    void dispatchState(int state, long nowMs) {
        for (int id = UP; id <= SELECT; id++) {
            final int bit = 1 << (id - 1);
            final boolean wasDown = (previous & bit) != 0;
            final boolean isDown = (state & bit) != 0;
            final int slot = toLibretroSlot(id);
            if (slot < 0) continue;
            final int key = Mobile.getMobileKey(slot);

            if (!wasDown && isDown) {
                MobilePlatform.keyPressed(key);
                nextRepeat[id] = repeatable(id) ? nowMs + REPEAT_DELAY_MS : 0;
            } else if (wasDown && !isDown) {
                MobilePlatform.keyReleased(key);
                nextRepeat[id] = 0;
            } else if (isDown && repeatable(id) && nextRepeat[id] != 0 && nowMs >= nextRepeat[id]) {
                MobilePlatform.keyRepeated(key);
                // At most one repeat per control per poll: no catch-up burst after a stalled tick.
                nextRepeat[id] = nowMs + REPEAT_PERIOD_MS;
            }
        }
        previous = state;
    }

    private static boolean repeatable(int id) {
        return id == UP || id == DOWN || id == LEFT || id == RIGHT || id == A;
    }

    /**
     * Canonical FreeJ2ME-Plus Libretro logical slots (Mobile.java):
     * 0 Up, 1 Down, 2 Left, 3 Right, 4=9, 5=7, 6=0, 7 Fire,
     * 8 RightSoft, 9 LeftSoft, 10=1, 11=3, 12=*, 13=#, ...
     *
     * Physical RG35XX labels are mapped only to these frontend-neutral slots;
     * Mobile.getMobileKey() remains responsible for device/profile keycodes.
     */
    private static int toLibretroSlot(int id) {
        switch (id) {
            case UP:     return 0;
            case DOWN:   return 1;
            case LEFT:   return 2;
            case RIGHT:  return 3;
            case A:      return 7;  // Fire
            case B:      return 8;  // RightSoft
            case X:      return 5;  // 7 / GAME_A-compatible slot
            case Y:      return 4;  // 9 / GAME_B-compatible slot
            case L1:     return 12; // * / GAME_C-compatible slot
            case R1:     return 13; // # / GAME_D-compatible slot
            case START:  return 9;  // LeftSoft
            case SELECT: return 6;  // 0; canonical slot, device behavior still needs RG35XX test
            default:     return -1;
        }
    }
}
