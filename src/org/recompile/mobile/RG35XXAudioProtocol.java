package org.recompile.mobile;

/**
 * Binary protocol shared by the RG35XX Java media facade and native core.
 *
 * This protocol is deliberately independent of the existing stdout video IPC.
 * Multi-byte integers are encoded little-endian to match the RG35XX native
 * target without relying on DataOutputStream's big-endian representation.
 *
 * Tasklog: RGJ-B3-004
 */
public final class RG35XXAudioProtocol
{
    public static final int MAGIC = 0x41354A52; // bytes: R J 5 A
    public static final int VERSION = 1;
    public static final int HEADER_SIZE = 14;
    public static final int MAX_PAYLOAD = 4 * 1024 * 1024;

    public static final int OP_REGISTER_MIDI  = 1;
    public static final int OP_REGISTER_PCM16 = 2;
    public static final int OP_PLAY           = 3;
    public static final int OP_PAUSE          = 4;
    public static final int OP_STOP           = 5;
    public static final int OP_SEEK_US        = 6;
    public static final int OP_SET_VOLUME     = 7;
    public static final int OP_SET_LOOP_COUNT = 8;
    public static final int OP_RELEASE        = 9;
    public static final int OP_RESET          = 10;

    private RG35XXAudioProtocol() { }

    public static byte[] header(int opcode, int playerId, int payloadSize)
    {
        if(payloadSize < 0 || payloadSize > MAX_PAYLOAD)
            throw new IllegalArgumentException("invalid RG35XX audio payload size");

        byte[] h = new byte[HEADER_SIZE];
        put32(h, 0, MAGIC);
        h[4] = (byte)VERSION;
        h[5] = (byte)opcode;
        put32(h, 6, playerId);
        put32(h, 10, payloadSize);
        return h;
    }

    public static byte[] int32(int value)
    {
        byte[] b = new byte[4];
        put32(b, 0, value);
        return b;
    }

    public static byte[] int64(long value)
    {
        byte[] b = new byte[8];
        for(int i = 0; i < 8; i++) b[i] = (byte)(value >>> (i * 8));
        return b;
    }

    private static void put32(byte[] b, int off, int value)
    {
        b[off]     = (byte)value;
        b[off + 1] = (byte)(value >>> 8);
        b[off + 2] = (byte)(value >>> 16);
        b[off + 3] = (byte)(value >>> 24);
    }
}
