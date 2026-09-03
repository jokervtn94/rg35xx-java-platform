package org.recompile.mobile;

import java.util.Hashtable;

/**
 * Small Java-side registry for RG35XX native-backed MMAPI players.
 *
 * The registry owns Java semantic state only. Native playback/decode timing
 * remains authoritative for native-backed media, including END_OF_MEDIA.
 *
 * Java 6 compatible; no java.util.concurrent dependency is required here.
 *
 * Tasklog: RGJ-B3-003 / RGJ-RC1-010E
 */
public final class RG35XXMediaRegistry
{
    public static final int TYPE_UNKNOWN = 0;
    public static final int TYPE_MIDI = 1;
    public static final int TYPE_PCM16 = 2;
    public static final int TYPE_TONE = 3;

    public static final int EVENT_END_OF_MEDIA = 1;
    public static final int EVENT_LOOPED = 2;

    private static final int EVENT_QUEUE_SIZE = 32;
    private static final int[] eventPlayerIds = new int[EVENT_QUEUE_SIZE];
    private static final int[] eventTypes = new int[EVENT_QUEUE_SIZE];
    private static final long[] eventTimes = new long[EVENT_QUEUE_SIZE];
    private static int eventHead = 0;
    private static int eventTail = 0;
    private static int eventCount = 0;

    public static interface EventListener
    {
        void onNativeMediaEvent(int playerId, int eventType, long mediaTimeUs);
    }

    private static final Hashtable entries = new Hashtable();
    private static int nextPlayerId = 1;

    private RG35XXMediaRegistry() { }

    public static synchronized Entry create(String contentType)
    {
        int id = allocateId();
        Entry e = new Entry(id, RG35XXMediaProfile.canonicalType(contentType));
        entries.put(new Integer(id), e);
        return e;
    }

    public static synchronized Entry get(int playerId)
    {
        return (Entry) entries.get(new Integer(playerId));
    }

    public static synchronized void release(int playerId)
    {
        Entry e = (Entry) entries.remove(new Integer(playerId));
        if(e != null)
        {
            e.released = true;
            e.eventListener = null;
        }
    }

    public static synchronized void reset()
    {
        entries.clear();
        nextPlayerId = 1;
        eventHead = 0;
        eventTail = 0;
        eventCount = 0;
    }

    public static synchronized int size()
    {
        return entries.size();
    }

    /**
     * Called from Libretro's stdin parser. This method must stay bounded and
     * must not invoke MIDlet/vendor listener code on the IO parser thread.
     */
    public static synchronized void enqueueNativeEvent(int playerId, int eventType, long mediaTimeUs)
    {
        Entry e = (Entry) entries.get(new Integer(playerId));
        if(e == null || e.released) return;
        if(eventType != EVENT_END_OF_MEDIA && eventType != EVENT_LOOPED) return;

        if(eventCount == EVENT_QUEUE_SIZE)
        {
            /* Drop the oldest stale event rather than blocking the IO thread. */
            eventHead = (eventHead + 1) % EVENT_QUEUE_SIZE;
            eventCount--;
        }

        eventPlayerIds[eventTail] = playerId;
        eventTypes[eventTail] = eventType;
        eventTimes[eventTail] = mediaTimeUs < 0L ? 0L : mediaTimeUs;
        eventTail = (eventTail + 1) % EVENT_QUEUE_SIZE;
        eventCount++;
    }

    /**
     * Drain from an existing bounded libretro frame/update cadence. No worker
     * thread is created and no event object is allocated.
     */
    public static void drainNativeEvents()
    {
        while(true)
        {
            int playerId;
            int eventType;
            long mediaTimeUs;

            synchronized(RG35XXMediaRegistry.class)
            {
                if(eventCount == 0) return;
                playerId = eventPlayerIds[eventHead];
                eventType = eventTypes[eventHead];
                mediaTimeUs = eventTimes[eventHead];
                eventHead = (eventHead + 1) % EVENT_QUEUE_SIZE;
                eventCount--;
            }

            dispatchNativeEvent(playerId, eventType, mediaTimeUs);
        }
    }

    private static void dispatchNativeEvent(int playerId, int eventType, long mediaTimeUs)
    {
        EventListener listener = null;

        synchronized(RG35XXMediaRegistry.class)
        {
            Entry e = (Entry) entries.get(new Integer(playerId));
            if(e == null || e.released) return;

            e.started = false;
            e.mediaTimeUs = mediaTimeUs;
            listener = e.eventListener;
        }

        if(listener != null)
            listener.onNativeMediaEvent(playerId, eventType, mediaTimeUs);
    }

    private static int allocateId()
    {
        int start = nextPlayerId;
        do
        {
            int id = nextPlayerId++;
            if(nextPlayerId <= 0) { nextPlayerId = 1; }
            if(!entries.containsKey(new Integer(id))) { return id; }
        }
        while(nextPlayerId != start);

        throw new IllegalStateException("RG35XX media player id space exhausted");
    }

    public static int detectType(String contentType)
    {
        if(RG35XXMediaProfile.isMidi(contentType)) return TYPE_MIDI;
        if(RG35XXMediaProfile.isTone(contentType)) return TYPE_TONE;
        if(RG35XXMediaProfile.isWav(contentType)) return TYPE_PCM16;
        return TYPE_UNKNOWN;
    }

    public static final class Entry
    {
        public final int playerId;
        public final String contentType;
        public final int mediaType;

        public int state;
        public int loopCount = 1;
        public int volume = 100;
        public long mediaTimeUs = 0L;
        public boolean registeredNative = false;
        public boolean released = false;
        public boolean started = false;
        private EventListener eventListener;

        private Entry(int playerId, String contentType)
        {
            this.playerId = playerId;
            this.contentType = contentType == null ? "" : contentType;
            this.mediaType = detectType(this.contentType);
        }

        public synchronized void setState(int state)
        {
            this.state = state;
        }

        public synchronized void setLoopCount(int count)
        {
            this.loopCount = count;
        }

        public synchronized void setVolume(int level)
        {
            if(level < 0) level = 0;
            if(level > 100) level = 100;
            this.volume = level;
        }

        public synchronized void setMediaTimeUs(long value)
        {
            this.mediaTimeUs = value < 0L ? 0L : value;
        }

        public synchronized void markRegisteredNative()
        {
            this.registeredNative = true;
        }

        public synchronized void markStarted(boolean value)
        {
            this.started = value;
        }

        public synchronized void setEventListener(EventListener listener)
        {
            this.eventListener = listener;
        }
    }
}
