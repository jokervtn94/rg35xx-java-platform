package org.recompile.mobile;

import java.io.IOException;
import java.io.OutputStream;

/**
 * Dedicated Java -> native audio transport.
 *
 * The native launcher supplies an OutputStream backed by the inherited audio
 * pipe/JNI descriptor bridge.  stdout must never be supplied here because it
 * is reserved for FreeJ2ME/libretro frame IPC.
 *
 * Tasklog: RGJ-B3-004
 */
public final class RG35XXAudioTransport
{
    private static OutputStream out;
    private static boolean available;

    private RG35XXAudioTransport() { }

    public static synchronized void attach(OutputStream stream)
    {
        out = stream;
        available = stream != null;
    }

    public static synchronized boolean isAvailable()
    {
        return available && out != null;
    }

    public static synchronized void detach()
    {
        out = null;
        available = false;
    }

    public static synchronized boolean registerMidi(int playerId, byte[] midi)
    {
        return send(RG35XXAudioProtocol.OP_REGISTER_MIDI, playerId, midi);
    }

    /** PCM registration payload: sampleRate(32), channels(32), PCM16 LE bytes. */
    public static synchronized boolean registerPcm16(int playerId, int sampleRate, int channels, byte[] pcm)
    {
        if(pcm == null) return false;
        byte[] payload = new byte[8 + pcm.length];
        copy32(payload, 0, sampleRate);
        copy32(payload, 4, channels);
        System.arraycopy(pcm, 0, payload, 8, pcm.length);
        return send(RG35XXAudioProtocol.OP_REGISTER_PCM16, playerId, payload);
    }

    public static synchronized boolean play(int playerId)
    {
        return send(RG35XXAudioProtocol.OP_PLAY, playerId, null);
    }

    public static synchronized boolean pause(int playerId)
    {
        return send(RG35XXAudioProtocol.OP_PAUSE, playerId, null);
    }

    public static synchronized boolean stop(int playerId)
    {
        return send(RG35XXAudioProtocol.OP_STOP, playerId, null);
    }

    public static synchronized boolean seekUs(int playerId, long mediaTimeUs)
    {
        return send(RG35XXAudioProtocol.OP_SEEK_US, playerId, RG35XXAudioProtocol.int64(mediaTimeUs));
    }

    public static synchronized boolean setVolume(int playerId, int level)
    {
        if(level < 0) level = 0;
        if(level > 100) level = 100;
        return send(RG35XXAudioProtocol.OP_SET_VOLUME, playerId, RG35XXAudioProtocol.int32(level));
    }

    public static synchronized boolean setLoopCount(int playerId, int count)
    {
        return send(RG35XXAudioProtocol.OP_SET_LOOP_COUNT, playerId, RG35XXAudioProtocol.int32(count));
    }

    public static synchronized boolean release(int playerId)
    {
        return send(RG35XXAudioProtocol.OP_RELEASE, playerId, null);
    }

    public static synchronized boolean resetNative()
    {
        return send(RG35XXAudioProtocol.OP_RESET, 0, null);
    }

    private static boolean send(int opcode, int playerId, byte[] payload)
    {
        if(!isAvailable()) return false;
        int length = payload == null ? 0 : payload.length;
        if(length > RG35XXAudioProtocol.MAX_PAYLOAD) return false;
        try
        {
            out.write(RG35XXAudioProtocol.header(opcode, playerId, length));
            if(length != 0) out.write(payload);
            out.flush();
            return true;
        }
        catch(IOException e)
        {
            available = false;
            return false;
        }
    }

    private static void copy32(byte[] b, int off, int value)
    {
        b[off] = (byte)value;
        b[off + 1] = (byte)(value >>> 8);
        b[off + 2] = (byte)(value >>> 16);
        b[off + 3] = (byte)(value >>> 24);
    }
}
