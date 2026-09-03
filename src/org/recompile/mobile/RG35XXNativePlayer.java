package org.recompile.mobile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * RG35XX target adapter between PlatformPlayer/MMAPI semantics and the
 * dedicated native media transport.
 *
 * This class does not implement javax.microedition.media.Player itself. It is
 * deliberately a small backend so upstream PlatformPlayer keeps listener and
 * vendor compatibility responsibilities while RG35XX owns target transport.
 *
 * Tasklog: RGJ-B3-003 / RGJ-B3-004 / RGJ-B3-006
 */
public final class RG35XXNativePlayer
{
    public static final int UNREALIZED = 100;
    public static final int REALIZED = 200;
    public static final int PREFETCHED = 300;
    public static final int STARTED = 400;
    public static final int CLOSED = 0;

    private final RG35XXMediaRegistry.Entry entry;
    private byte[] media;
    private int sampleRate;
    private int channels;
    private int state = UNREALIZED;

    public RG35XXNativePlayer(InputStream stream, String contentType) throws IOException
    {
        entry = RG35XXMediaRegistry.create(contentType);
        media = readAll(stream);
    }

    public int getPlayerId() { return entry.playerId; }
    public int getState() { return state; }
    public String getContentType() { return entry.contentType; }

    /** WAV must already be normalized by RG35XXWavDecoder before this call. */
    public synchronized void setPcm16(byte[] pcm, int rate, int channelCount)
    {
        if(state == CLOSED) throw new IllegalStateException("player closed");
        media = pcm;
        sampleRate = rate;
        channels = channelCount;
    }

    public synchronized void realize()
    {
        ensureOpen();
        if(state >= REALIZED) return;
        state = REALIZED;
        entry.setState(state);
    }

    public synchronized boolean prefetch()
    {
        ensureOpen();
        if(state < REALIZED) realize();
        if(state >= PREFETCHED) return entry.registeredNative;
        if(!RG35XXAudioTransport.isAvailable()) return false;

        boolean ok;
        if(entry.mediaType == RG35XXMediaRegistry.TYPE_MIDI)
            ok = RG35XXAudioTransport.registerMidi(entry.playerId, media);
        else if(entry.mediaType == RG35XXMediaRegistry.TYPE_PCM16)
            ok = RG35XXAudioTransport.registerPcm16(entry.playerId, sampleRate, channels, media);
        else
            ok = false;

        if(ok)
        {
            entry.markRegisteredNative();
            RG35XXAudioTransport.setVolume(entry.playerId, entry.volume);
            RG35XXAudioTransport.setLoopCount(entry.playerId, entry.loopCount);
            state = PREFETCHED;
            entry.setState(state);
        }
        return ok;
    }

    public synchronized boolean start()
    {
        ensureOpen();
        if(state == STARTED) return true;
        if(state < PREFETCHED && !prefetch()) return false;
        if(!RG35XXAudioTransport.play(entry.playerId)) return false;
        state = STARTED;
        entry.setState(state);
        entry.markStarted(true);
        return true;
    }

    public synchronized boolean stop()
    {
        ensureOpen();
        if(state != STARTED) return true;
        if(!RG35XXAudioTransport.stop(entry.playerId)) return false;
        state = PREFETCHED;
        entry.setState(state);
        entry.markStarted(false);
        entry.setMediaTimeUs(0L);
        return true;
    }

    public synchronized boolean pause()
    {
        ensureOpen();
        if(state != STARTED) return true;
        if(!RG35XXAudioTransport.pause(entry.playerId)) return false;
        state = PREFETCHED;
        entry.setState(state);
        entry.markStarted(false);
        return true;
    }

    public synchronized long setMediaTime(long microseconds)
    {
        ensureOpen();
        if(microseconds < 0L) microseconds = 0L;
        if(entry.registeredNative && !RG35XXAudioTransport.seekUs(entry.playerId, microseconds))
            return entry.mediaTimeUs;
        entry.setMediaTimeUs(microseconds);
        return entry.mediaTimeUs;
    }

    public synchronized void setLoopCount(int count)
    {
        ensureOpen();
        if(count == 0) throw new IllegalArgumentException("loop count cannot be zero");
        entry.setLoopCount(count);
        if(entry.registeredNative) RG35XXAudioTransport.setLoopCount(entry.playerId, count);
    }

    public synchronized int setVolume(int level)
    {
        ensureOpen();
        entry.setVolume(level);
        if(entry.registeredNative) RG35XXAudioTransport.setVolume(entry.playerId, entry.volume);
        return entry.volume;
    }

    public synchronized void close()
    {
        if(state == CLOSED) return;
        if(entry.registeredNative) RG35XXAudioTransport.release(entry.playerId);
        RG35XXMediaRegistry.release(entry.playerId);
        media = null;
        state = CLOSED;
    }

    private void ensureOpen()
    {
        if(state == CLOSED || entry.released) throw new IllegalStateException("player closed");
    }

    private static byte[] readAll(InputStream in) throws IOException
    {
        if(in == null) return new byte[0];
        ByteArrayOutputStream out = new ByteArrayOutputStream(4096);
        byte[] buf = new byte[4096];
        int n;
        while((n = in.read(buf)) != -1) out.write(buf, 0, n);
        return out.toByteArray();
    }
}
