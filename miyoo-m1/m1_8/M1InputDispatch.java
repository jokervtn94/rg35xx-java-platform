package org.recompile.mobile;

/**
 * M1.8 semantic-control -> FreeJ2ME MIDP adapter.
 *
 * Contract:
 *  - M1.7/JNI remains the sole raw js0 owner.
 *  - MobilePlatform remains the sole MIDP event owner.
 *  - This class converts each semantic bit exactly once and never calls a
 *    Displayable directly.
 *  - Repeat is generated only for held directional/FIRE controls and is
 *    bounded by time; press/release are edge-triggered.
 */
public final class M1InputDispatch {
    public static final int UP=1, DOWN=2, LEFT=3, RIGHT=4;
    public static final int A=5, B=6, X=7, Y=8, L1=9, R1=10, START=11, SELECT=12;

    private static final int REPEAT_DELAY_MS = 400;
    private static final int REPEAT_PERIOD_MS = 100;

    private final MobilePlatform platform;
    private int previous;
    private final long[] nextRepeat = new long[13];

    public M1InputDispatch(MobilePlatform platform) {
        if (platform == null) throw new NullPointerException("platform");
        this.platform = platform;
    }

    /** Poll exactly once. Call from the existing platform/input tick only. */
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
            final int key = toMidpKey(id);
            if (key == 0) continue;

            if (!wasDown && isDown) {
                platform.keyPressed(key);
                nextRepeat[id] = repeatable(id) ? nowMs + REPEAT_DELAY_MS : 0;
            } else if (wasDown && !isDown) {
                platform.keyReleased(key);
                nextRepeat[id] = 0;
            } else if (isDown && repeatable(id) && nextRepeat[id] != 0 && nowMs >= nextRepeat[id]) {
                platform.keyRepeated(key);
                // At most one repeat per poll: no burst after a stalled frame/tick.
                nextRepeat[id] = nowMs + REPEAT_PERIOD_MS;
            }
        }
        previous = state;
    }

    private static boolean repeatable(int id) {
        return id == UP || id == DOWN || id == LEFT || id == RIGHT || id == A;
    }

    private static int toMidpKey(int id) {
        switch (id) {
            case UP:     return Mobile.NOKIA_UP;
            case DOWN:   return Mobile.NOKIA_DOWN;
            case LEFT:   return Mobile.NOKIA_LEFT;
            case RIGHT:  return Mobile.NOKIA_RIGHT;
            case A:      return Mobile.NOKIA_SOFT3; // FIRE; updateKeyState maps SOFT3 to FIRE_PRESSED.
            case B:      return Mobile.NOKIA_SOFT2;
            case X:      return Mobile.KEY_NUM7;    // GAME_A
            case Y:      return Mobile.KEY_NUM9;    // GAME_B
            case L1:     return Mobile.KEY_STAR;    // GAME_C
            case R1:     return Mobile.KEY_POUND;   // GAME_D
            case START:  return Mobile.NOKIA_SOFT1;
            case SELECT: return Mobile.NOKIA_END;
            default:     return 0;
        }
    }
}
