package org.recompile.rg35xx;

import java.io.File;

import org.recompile.mobile.Mobile;
import org.recompile.mobile.MobilePlatform;

/**
 * Converts the original-RG35XX semantic bitmap to the pinned Aweigit
 * frontend/MobilePlatform boundary. This class never calls Displayable.
 */
public final class RG35XXKeyDispatcher {
    public static final int UP=1, DOWN=2, LEFT=3, RIGHT=4;
    public static final int A=5, B=6, X=7, Y=8, L1=9, R1=10, START=11, SELECT=12, L2=13, R2=14;

    private static final int REPEAT_DELAY_MS = 400;
    private static final int REPEAT_PERIOD_MS = 100;

    private final MobilePlatform platform;
    private final RG35XXFrontendPolicy policy;
    private int previous;
    private int suppressedBits;
    /* Keep a recognized SELECT chord latched until both physical keys are up. */
    private int chordLatchMask;
    private boolean suppressSelectRelease;
    private final long[] nextRepeat = new long[15];
    private final int[] activeKey = new int[15];

    public RG35XXKeyDispatcher(MobilePlatform platform) {
        this(platform, new RG35XXFrontendPolicy(platform, new File("."), new File("."), "default", platform.lcdWidth, platform.lcdHeight));
    }

    public RG35XXKeyDispatcher(MobilePlatform platform, RG35XXFrontendPolicy policy) {
        if (platform == null) throw new IllegalArgumentException("platform");
        if (policy == null) throw new IllegalArgumentException("policy");
        this.platform = platform;
        this.policy = policy;
    }

    public void poll(long nowMs) {
        dispatchState(RG35XXInput.rawGetState(), nowMs);
    }

    void dispatchState(int state, long nowMs) {
        boolean displayReady = Mobile.getDisplay() != null && Mobile.getDisplay().getCurrent() != null;
        if (!displayReady) return;

        int rising = state & ~previous;
        boolean selectDown = isDown(state, SELECT);

        if (selectDown && chordLatchMask == 0 && (rising & bit(START)) != 0 && !policy.isPointerMode()) {
            armChord(START);
            policy.cyclePhoneMode();
        }
        if (selectDown && chordLatchMask == 0 && (rising & bit(B)) != 0) {
            armChord(B);
            policy.cycleRotation();
        }
        if (selectDown && chordLatchMask == 0 && (rising & bit(Y)) != 0) {
            armChord(Y);
            boolean entering = !policy.isPointerMode();
            if (entering) releaseAllActiveKeysExcept(SELECT);
            policy.togglePointerMode();
        }

        for (int id = UP; id <= R2; id++) {
            int mask = bit(id);
            boolean wasDown = (previous & mask) != 0;
            boolean isDown = (state & mask) != 0;

            if ((chordLatchMask & mask) != 0) {
                if (!isDown) chordLatchMask &= ~mask;
                nextRepeat[id] = 0;
                activeKey[id] = 0;
                continue;
            }

            if ((suppressedBits & mask) != 0) {
                if (!isDown) suppressedBits &= ~mask;
                nextRepeat[id] = 0;
                activeKey[id] = 0;
                continue;
            }
            if (id == SELECT && suppressSelectRelease) {
                if (!isDown) suppressSelectRelease = false;
                nextRepeat[id] = 0;
                activeKey[id] = 0;
                continue;
            }

            if (policy.isPointerMode()) {
                if (id == X) {
                    if (wasDown != isDown) policy.setPointerConfirm(isDown);
                    nextRepeat[id] = 0;
                    activeKey[id] = 0;
                    continue;
                }
                if (id >= UP && id <= RIGHT) {
                    if (!wasDown && isDown) {
                        policy.movePointer(id);
                        nextRepeat[id] = nowMs + REPEAT_DELAY_MS;
                    } else if (isDown && nextRepeat[id] != 0 && nowMs >= nextRepeat[id]) {
                        policy.movePointer(id);
                        nextRepeat[id] = nowMs + REPEAT_PERIOD_MS;
                    } else if (!isDown) {
                        nextRepeat[id] = 0;
                    }
                    activeKey[id] = 0;
                    continue;
                }
                nextRepeat[id] = 0;
                activeKey[id] = 0;
                continue;
            }

            if (!wasDown && isDown) {
                int key = policy.mapPhysicalToMobileKey(id);
                activeKey[id] = key;
                if (key != 0) platform.keyPressed(key);
                nextRepeat[id] = repeatable(id) ? nowMs + REPEAT_DELAY_MS : 0;
            } else if (wasDown && !isDown) {
                int key = activeKey[id];
                if (key != 0) platform.keyReleased(key);
                activeKey[id] = 0;
                nextRepeat[id] = 0;
            } else if (isDown && repeatable(id) && nextRepeat[id] != 0 && nowMs >= nextRepeat[id]) {
                int key = activeKey[id];
                if (key != 0) platform.keyRepeated(key);
                nextRepeat[id] = nowMs + REPEAT_PERIOD_MS;
            }
        }
        previous = state;
    }

    private void releaseSelectForChord() {
        if (activeKey[SELECT] != 0) {
            platform.keyReleased(activeKey[SELECT]);
            activeKey[SELECT] = 0;
        }
        nextRepeat[SELECT] = 0;
        suppressSelectRelease = true;
    }

    private void armChord(int partner) {
        releaseSelectForChord();
        chordLatchMask |= bit(SELECT) | bit(partner);
    }

    private void releaseAllActiveKeysExcept(int except) {
        for (int id = UP; id <= R2; id++) {
            if (id == except) continue;
            if (activeKey[id] != 0) {
                platform.keyReleased(activeKey[id]);
                activeKey[id] = 0;
            }
            nextRepeat[id] = 0;
        }
    }

    private boolean repeatable(int id) {
        return id == UP || id == DOWN || id == LEFT || id == RIGHT || policy.isOkPhysical(id);
    }

    private static int bit(int id) { return 1 << (id - 1); }
    private static boolean isDown(int state, int id) { return (state & bit(id)) != 0; }
}
