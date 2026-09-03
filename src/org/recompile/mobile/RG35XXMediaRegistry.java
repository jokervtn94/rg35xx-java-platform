package org.recompile.mobile;

import java.util.Hashtable;

/**
 * Small Java-side registry for RG35XX native-backed MMAPI players.
 *
 * The registry owns Java semantic state only.  Native playback/decode timing
 * remains authoritative for native-backed media, including END_OF_MEDIA.
 *
 * Java 6 compatible; no java.util.concurrent dependency is required here.
 *
 * Tasklog: RGJ-B3-003
 */
public final class RG35XXMediaRegistry
{
    public static final int TYPE_UNKNOWN = 0;
    public static final int TYPE_MIDI = 1;
    public static final int TYPE_PCM16 = 2;
    public static final int TYPE_TONE = 3;

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
        if(e != null) { e.released = true; }
    }

    public static synchronized void reset()
    {
        entries.clear();
        nextPlayerId = 1;
    }

    public static synchronized int size()
    {
        return entries.size();
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
    }
}
