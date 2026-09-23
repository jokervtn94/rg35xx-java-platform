package org.recompile.rg35xx;

import org.recompile.mobile.Mobile;
import org.recompile.mobile.MobilePlatform;

/**
 * Converts the device-proven RG35XX semantic bitmap to the pinned Aweigit
 * MobilePlatform event boundary. This class does not call Displayable directly.
 */
public final class RG35XXKeyDispatcher {
    public static final int UP=1, DOWN=2, LEFT=3, RIGHT=4;
    public static final int A=5, B=6, X=7, Y=8, L1=9, R1=10, START=11, SELECT=12;

    private static final int REPEAT_DELAY_MS = 400;
    private static final int REPEAT_PERIOD_MS = 100;

    private final MobilePlatform platform;
    private int previous;
    private final long[] nextRepeat = new long[13];

    public RG35XXKeyDispatcher(MobilePlatform platform) {
        if (platform == null) throw new IllegalArgumentException("platform");
        this.platform = platform;
    }

    public void poll(long nowMs) {
        dispatchState(RG35XXInput.rawGetState(), nowMs);
    }

    void dispatchState(int state, long nowMs) {
        if (Mobile.getDisplay() == null || Mobile.getDisplay().getCurrent() == null) {
            return;
        }
        for (int id = UP; id <= SELECT; id++) {
            int bit = 1 << (id - 1);
            boolean wasDown = (previous & bit) != 0;
            boolean isDown = (state & bit) != 0;
            int key = toAweigitDefaultKey(id);
            if (key == 0) continue;

            if (!wasDown && isDown) {
                platform.keyPressed(key);
                nextRepeat[id] = repeatable(id) ? nowMs + REPEAT_DELAY_MS : 0;
            } else if (wasDown && !isDown) {
                platform.keyReleased(key);
                nextRepeat[id] = 0;
            } else if (isDown && repeatable(id) && nextRepeat[id] != 0 && nowMs >= nextRepeat[id]) {
                platform.keyRepeated(key);
                nextRepeat[id] = nowMs + REPEAT_PERIOD_MS;
            }
        }
        previous = state;
    }

    private static boolean repeatable(int id) {
        return id == UP || id == DOWN || id == LEFT || id == RIGHT || id == A;
    }

    /** Mirrors the pinned Aweigit default P-phone mapping, without its SDL2 frontend. */
    private static int toAweigitDefaultKey(int id) {
        switch (id) {
            case UP:     return Mobile.KEY_NUM2;
            case DOWN:   return Mobile.KEY_NUM8;
            case LEFT:   return Mobile.KEY_NUM4;
            case RIGHT:  return Mobile.KEY_NUM6;
            case A:      return Mobile.KEY_NUM5;
            case B:      return Mobile.NOKIA_SOFT2;
            case X:      return Mobile.KEY_NUM7;
            case Y:      return Mobile.KEY_NUM9;
            case L1:     return Mobile.KEY_STAR;
            case R1:     return Mobile.KEY_POUND;
            case START:  return Mobile.NOKIA_SOFT1;
            case SELECT: return Mobile.KEY_NUM0;
            default:     return 0;
        }
    }
}
