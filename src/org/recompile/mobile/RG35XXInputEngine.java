package org.recompile.mobile;

/**
 * Deterministic J2ME key press/release/repeat timing for RG35XX.
 * Introduced in Beta 1; restored into the consolidated project tree in Beta 6.
 * Java 6 compatible.
 */
public final class RG35XXInputEngine
{
    public static interface Sink
    {
        void keyPressed(int logicalKey);
        void keyReleased(int logicalKey);
        void keyRepeated(int logicalKey);
    }

    private static final long REPEAT_DELAY_MS = 340L;
    private static final long REPEAT_INTERVAL_MS = 75L;
    private static final int KEY_COUNT = 20;
    private static final boolean[] held = new boolean[KEY_COUNT];
    private static final long[] nextRepeat = new long[KEY_COUNT];

    private RG35XXInputEngine() { }

    public static synchronized void press(int logicalKey, long nowMs, Sink sink)
    {
        if(!valid(logicalKey) || sink == null || held[logicalKey]) return;
        held[logicalKey] = true;
        nextRepeat[logicalKey] = nowMs + REPEAT_DELAY_MS;
        sink.keyPressed(logicalKey);
    }

    public static synchronized void release(int logicalKey, Sink sink)
    {
        if(!valid(logicalKey) || sink == null || !held[logicalKey]) return;
        held[logicalKey] = false;
        nextRepeat[logicalKey] = 0L;
        sink.keyReleased(logicalKey);
    }

    public static synchronized void update(long nowMs, Sink sink)
    {
        if(sink == null) return;
        for(int key = 0; key < KEY_COUNT; key++)
        {
            if(!held[key] || !repeatable(key)) continue;
            long due = nextRepeat[key];
            if(due == 0L || nowMs < due) continue;
            sink.keyRepeated(key);
            long next = due + REPEAT_INTERVAL_MS;
            if(next <= nowMs) next = nowMs + REPEAT_INTERVAL_MS;
            nextRepeat[key] = next;
        }
    }

    public static synchronized boolean isHeld(int logicalKey)
    {
        return valid(logicalKey) && held[logicalKey];
    }

    public static synchronized void reset()
    {
        for(int i = 0; i < KEY_COUNT; i++)
        {
            held[i] = false;
            nextRepeat[i] = 0L;
        }
    }

    private static boolean valid(int key) { return key >= 0 && key < KEY_COUNT; }

    private static boolean repeatable(int key)
    {
        /* directions 0..3, numeric logical slots 4..6 and 10..18. */
        return (key >= 0 && key <= 6) || (key >= 10 && key <= 18);
    }
}
