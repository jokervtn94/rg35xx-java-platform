#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit("usage: b4_apply_timebase_trace_r1.py <MIDletEnhancements.java>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

if "RG35XX-B4-TIMEBASE" in s:
    raise SystemExit("B4 TIMEBASE TRACE R1 FAIL already applied")

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("B4 TIMEBASE TRACE R1 FAIL %s count=%d" % (label, n))
    s = s.replace(old, new, 1)

anchor = """    private static final long startNanoTime = lastNanoTime;

"""
helpers = """    private static final long startNanoTime = lastNanoTime;

    private static final AtomicLong rg35xxB4TraceSeq = new AtomicLong(0);

    private static long rg35xxB4NextTraceSeq()
    {
        return rg35xxB4TraceSeq.incrementAndGet();
    }

    private static boolean rg35xxB4TraceLog(long seq)
    {
        return seq <= 128L || (seq > 0L && (seq & (seq - 1L)) == 0L);
    }

    private static String rg35xxB4ThreadName()
    {
        Thread t = Thread.currentThread();
        return t == null ? "null" : t.getName();
    }

"""
once(anchor, helpers, "helper insertion")

old_draw = """    public static void drawSleep(long millis) throws InterruptedException
    {
        if (Mobile.unlockFramerateHack == 0 && !MobilePlatform.pressedKeys[20]) { Thread.sleep(millis); } 
        else { Thread.sleep(1); }
    }
"""
new_draw = """    public static void drawSleep(long millis) throws InterruptedException
    {
        final long rg35xxSeq = rg35xxB4NextTraceSeq();
        final boolean rg35xxLog = rg35xxB4TraceLog(rg35xxSeq);
        final long rg35xxWallBegin = System.currentTimeMillis();
        if(rg35xxLog)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=DRAWSLEEP_BEGIN seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName() + " requestedMs=" + millis
                + " unlock=" + Mobile.unlockFramerateHack
                + " fast=" + MobilePlatform.pressedKeys[20]);
        }
        if (Mobile.unlockFramerateHack == 0 && !MobilePlatform.pressedKeys[20]) { Thread.sleep(millis); } 
        else { Thread.sleep(1); }
        if(rg35xxLog)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=DRAWSLEEP_END seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName()
                + " wallElapsedMs=" + (System.currentTimeMillis() - rg35xxWallBegin));
        }
    }
"""
once(old_draw, new_draw, "drawSleep")

old_sleep = """    public static void sleep(long millis) throws InterruptedException
    {
        if (Mobile.unlockFramerateHack == 0 && !MobilePlatform.pressedKeys[20]) { Thread.sleep(millis); } 
        else { Thread.sleep(1); }
    }
"""
new_sleep = """    public static void sleep(long millis) throws InterruptedException
    {
        final long rg35xxSeq = rg35xxB4NextTraceSeq();
        final boolean rg35xxLog = rg35xxB4TraceLog(rg35xxSeq);
        final long rg35xxWallBegin = System.currentTimeMillis();
        if(rg35xxLog)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=SLEEP_BEGIN seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName() + " requestedMs=" + millis
                + " unlock=" + Mobile.unlockFramerateHack
                + " fast=" + MobilePlatform.pressedKeys[20]);
        }
        if (Mobile.unlockFramerateHack == 0 && !MobilePlatform.pressedKeys[20]) { Thread.sleep(millis); } 
        else { Thread.sleep(1); }
        if(rg35xxLog)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=SLEEP_END seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName()
                + " wallElapsedMs=" + (System.currentTimeMillis() - rg35xxWallBegin));
        }
    }
"""
once(old_sleep, new_sleep, "sleep")

old_millis = """    public static long currentTimeMillis() 
    {
        long now = System.currentTimeMillis();
        long elapsedMillis = now - lastMillisTime;

        if (MobilePlatform.pressedKeys[20])
        {
            float multiplier = Mobile.fastForwardMultiplier;
            if (multiplier <= 0.0f) { multiplier = 20.0f; }
            curTimeMillis.addAndGet((long) (elapsedMillis * multiplier));
        }
        else if (Mobile.unlockFramerateHack > 2) { curTimeMillis.addAndGet((long) (elapsedMillis * (Mobile.limitFPS == 0 ? 20 : (float) Mobile.limitFPS / 10f))); } 
        else { curTimeMillis.addAndGet(elapsedMillis); }

        lastMillisTime = now;
        return startMillisTime + curTimeMillis.get();
    }
"""
new_millis = """    public static long currentTimeMillis() 
    {
        final long rg35xxSeq = rg35xxB4NextTraceSeq();
        final boolean rg35xxLog = rg35xxB4TraceLog(rg35xxSeq);
        final long rg35xxLastBefore = lastMillisTime;
        final long rg35xxCurBefore = curTimeMillis.get();
        long now = System.currentTimeMillis();
        long elapsedMillis = now - lastMillisTime;

        if (MobilePlatform.pressedKeys[20])
        {
            float multiplier = Mobile.fastForwardMultiplier;
            if (multiplier <= 0.0f) { multiplier = 20.0f; }
            curTimeMillis.addAndGet((long) (elapsedMillis * multiplier));
        }
        else if (Mobile.unlockFramerateHack > 2) { curTimeMillis.addAndGet((long) (elapsedMillis * (Mobile.limitFPS == 0 ? 20 : (float) Mobile.limitFPS / 10f))); } 
        else { curTimeMillis.addAndGet(elapsedMillis); }

        lastMillisTime = now;
        final long rg35xxCurAfter = curTimeMillis.get();
        final long rg35xxResult = startMillisTime + rg35xxCurAfter;
        if(rg35xxLog || elapsedMillis < 0L)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=MILLIS seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName()
                + " wallNow=" + now + " lastBefore=" + rg35xxLastBefore
                + " elapsed=" + elapsedMillis + " curBefore=" + rg35xxCurBefore
                + " curAfter=" + rg35xxCurAfter + " returned=" + rg35xxResult
                + " unlock=" + Mobile.unlockFramerateHack
                + " limitFPS=" + Mobile.limitFPS
                + " fast=" + MobilePlatform.pressedKeys[20]
                + " negativeElapsed=" + (elapsedMillis < 0L));
        }
        return rg35xxResult;
    }
"""
once(old_millis, new_millis, "currentTimeMillis")

old_nano = """    public static long nanoTime() 
    {
        long now = System.nanoTime();
        long elapsedNanos = now - lastNanoTime;

        if (MobilePlatform.pressedKeys[20])
        {
            float multiplier = Mobile.fastForwardMultiplier;
            if (multiplier <= 0.0f) { multiplier = 20.0f; }
            curNanoTime.addAndGet((long) (elapsedNanos * multiplier));
        }
        else if (Mobile.unlockFramerateHack > 2) { curNanoTime.addAndGet((long) (elapsedNanos * (Mobile.limitFPS == 0 ? 20 : (float) Mobile.limitFPS / 10f))); } 
        else { curNanoTime.addAndGet(elapsedNanos); }

        lastNanoTime = now;
        return startNanoTime + curNanoTime.get();
    }
"""
new_nano = """    public static long nanoTime() 
    {
        final long rg35xxSeq = rg35xxB4NextTraceSeq();
        final boolean rg35xxLog = rg35xxB4TraceLog(rg35xxSeq);
        final long rg35xxLastBefore = lastNanoTime;
        final long rg35xxCurBefore = curNanoTime.get();
        long now = System.nanoTime();
        long elapsedNanos = now - lastNanoTime;

        if (MobilePlatform.pressedKeys[20])
        {
            float multiplier = Mobile.fastForwardMultiplier;
            if (multiplier <= 0.0f) { multiplier = 20.0f; }
            curNanoTime.addAndGet((long) (elapsedNanos * multiplier));
        }
        else if (Mobile.unlockFramerateHack > 2) { curNanoTime.addAndGet((long) (elapsedNanos * (Mobile.limitFPS == 0 ? 20 : (float) Mobile.limitFPS / 10f))); } 
        else { curNanoTime.addAndGet(elapsedNanos); }

        lastNanoTime = now;
        final long rg35xxCurAfter = curNanoTime.get();
        final long rg35xxResult = startNanoTime + rg35xxCurAfter;
        if(rg35xxLog || elapsedNanos < 0L)
        {
            System.err.println("RG35XX-B4-TIMEBASE stage=NANOS seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName()
                + " wallNow=" + now + " lastBefore=" + rg35xxLastBefore
                + " elapsed=" + elapsedNanos + " curBefore=" + rg35xxCurBefore
                + " curAfter=" + rg35xxCurAfter + " returned=" + rg35xxResult
                + " unlock=" + Mobile.unlockFramerateHack
                + " limitFPS=" + Mobile.limitFPS
                + " fast=" + MobilePlatform.pressedKeys[20]
                + " negativeElapsed=" + (elapsedNanos < 0L));
        }
        return rg35xxResult;
    }
"""
once(old_nano, new_nano, "nanoTime")

old_yield = """    public static void yieldOverride() throws InterruptedException { Thread.sleep(1); }
"""
new_yield = """    public static void yieldOverride() throws InterruptedException
    {
        final long rg35xxSeq = rg35xxB4NextTraceSeq();
        final boolean rg35xxLog = rg35xxB4TraceLog(rg35xxSeq);
        final long rg35xxWallBegin = System.currentTimeMillis();
        if(rg35xxLog)
            System.err.println("RG35XX-B4-TIMEBASE stage=YIELD_BEGIN seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName());
        Thread.sleep(1);
        if(rg35xxLog)
            System.err.println("RG35XX-B4-TIMEBASE stage=YIELD_END seq=" + rg35xxSeq
                + " thread=" + rg35xxB4ThreadName()
                + " wallElapsedMs=" + (System.currentTimeMillis() - rg35xxWallBegin));
    }
"""
once(old_yield, new_yield, "yieldOverride")

for token in (
    "RG35XX-B4-TIMEBASE stage=MILLIS",
    "RG35XX-B4-TIMEBASE stage=NANOS",
    "RG35XX-B4-TIMEBASE stage=SLEEP_BEGIN",
    "RG35XX-B4-TIMEBASE stage=SLEEP_END",
    "RG35XX-B4-TIMEBASE stage=DRAWSLEEP_BEGIN",
    "RG35XX-B4-TIMEBASE stage=DRAWSLEEP_END",
    "RG35XX-B4-TIMEBASE stage=YIELD_BEGIN",
    "negativeElapsed=",
):
    if token not in s:
        raise SystemExit("B4 TIMEBASE TRACE R1 FAIL missing token: " + token)

if s == orig:
    raise SystemExit("B4 TIMEBASE TRACE R1 FAIL no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("B4_DRAGON_TIMEBASE_TRACE_R1_PATCH=PASS")
print("PRIMARY_VARIABLE=BOUNDED_GAME_VIRTUAL_TIME_AND_SLEEP_OBSERVABILITY_ONLY")
print("BEHAVIOR_CHANGE=NONE")
