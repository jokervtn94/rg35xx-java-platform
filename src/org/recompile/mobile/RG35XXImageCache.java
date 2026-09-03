package org.recompile.mobile;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.zip.CRC32;

/**
 * Bounded immutable decoded ARGB cache for RG35XX.
 * Introduced in Beta 1; restored into the consolidated project tree in Beta 6.
 * Returned pixel arrays are copies so MIDlets cannot mutate cached content.
 */
public final class RG35XXImageCache
{
    private static final int MAX_BYTES = 12 * 1024 * 1024;
    private static final int MAX_ENTRIES = 192;

    private static final LinkedHashMap cache = new LinkedHashMap(64, 0.75f, true);
    private static int bytes;

    private RG35XXImageCache() { }

    public static synchronized int[] get(String key)
    {
        Entry e = (Entry)cache.get(key);
        return e == null ? null : copy(e.pixels);
    }

    public static synchronized void put(String key, int[] pixels)
    {
        if(key == null || pixels == null) return;
        int cost = pixels.length * 4;
        if(cost <= 0 || cost > MAX_BYTES) return;

        Entry old = (Entry)cache.remove(key);
        if(old != null) bytes -= old.bytes;
        cache.put(key, new Entry(copy(pixels), cost));
        bytes += cost;
        trim();
    }

    public static String keyForBytes(byte[] data, int offset, int length)
    {
        if(data == null || offset < 0 || length < 0 || offset + length > data.length)
            throw new IllegalArgumentException("invalid image byte slice");
        CRC32 crc = new CRC32();
        crc.update(data, offset, length);
        return "B:" + length + ":" + Long.toHexString(crc.getValue());
    }

    public static synchronized void clear()
    {
        cache.clear();
        bytes = 0;
    }

    public static synchronized int size() { return cache.size(); }
    public static synchronized int bytes() { return bytes; }

    private static void trim()
    {
        while(cache.size() > MAX_ENTRIES || bytes > MAX_BYTES)
        {
            Object eldestKey = cache.keySet().iterator().next();
            Entry e = (Entry)cache.remove(eldestKey);
            if(e != null) bytes -= e.bytes;
        }
    }

    private static int[] copy(int[] src)
    {
        int[] out = new int[src.length];
        System.arraycopy(src, 0, out, 0, src.length);
        return out;
    }

    private static final class Entry
    {
        final int[] pixels;
        final int bytes;
        Entry(int[] pixels, int bytes) { this.pixels = pixels; this.bytes = bytes; }
    }
}
