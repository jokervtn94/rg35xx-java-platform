package org.recompile.mobile;

/**
 * Dirty-frame generation scheduler used by the RG35XX libretro frame worker.
 * Java 6 compatible. Introduced in Alpha 1; restored into the consolidated
 * project tree during Beta 6 integration audit.
 */
public final class RG35XXFrameScheduler
{
    private static final Object lock = new Object();
    private static long generation = 1L;

    private RG35XXFrameScheduler() { }

    public static long getGeneration()
    {
        synchronized(lock) { return generation; }
    }

    public static long markDirty()
    {
        synchronized(lock)
        {
            generation++;
            if(generation <= 0L) generation = 1L;
            lock.notifyAll();
            return generation;
        }
    }

    /** Wait until generation differs from the caller's last seen value. */
    public static long waitForChange(long lastSeen) throws InterruptedException
    {
        synchronized(lock)
        {
            while(generation == lastSeen) lock.wait();
            return generation;
        }
    }

    public static void wake()
    {
        synchronized(lock) { lock.notifyAll(); }
    }

    /** First frame after reset is intentionally dirty. */
    public static void reset()
    {
        synchronized(lock)
        {
            generation = 1L;
            lock.notifyAll();
        }
    }
}
