package org.recompile.freej2me;

import java.io.PrintStream;
import org.recompile.mobile.Mobile;

/**
 * Golden RG35XX Java-side video transport.
 *
 * The libretro command parser only signals that a frame is wanted. A dedicated
 * low-priority worker snapshots the current MIDlet frontbuffer, converts ARGB to
 * the exact big-endian RGB565 byte stream used by the device-proven binary, then
 * writes one complete 16-byte header + payload transaction to binary stdout.
 *
 * Java-6 compatible. No per-frame allocation.
 */
public final class RG35XXGoldenFrameTransport
{
    public static final int MAX_WIDTH = 800;
    public static final int MAX_HEIGHT = 800;
    public static final int MAX_PIXELS = MAX_WIDTH * MAX_HEIGHT;
    public static final int FRAME_HEADER_BYTES = 16;

    private final PrintStream ipcOut;
    private final Object signal = new Object();
    /* Worker frames and rare control/restart frames share these scratch buffers. */
    private final Object encodeLock = new Object();
    private final int[] argbSnapshot = new int[MAX_PIXELS];
    private final byte[] rgb565 = new byte[MAX_PIXELS * 2];
    private final byte[] high = new byte[65536];
    private final byte[] low = new byte[65536];
    private final byte[] header = new byte[FRAME_HEADER_BYTES];

    private volatile boolean running = true;
    private volatile boolean pending;
    private Thread worker;

    private int width;
    private int height;
    private int[] lcdData;
    private Object frontbufferLock;

    public RG35XXGoldenFrameTransport(PrintStream out)
    {
        if(out == null) throw new NullPointerException("ipcOut");
        ipcOut = out;
        init565Tables();
        startWorker();
    }

    private void init565Tables()
    {
        /* Recovered from the device-proven freej2me-lr.jar bytecode. */
        for(int i = 0; i < 65536; i++)
        {
            high[i] = (byte)(((i >> 8) & 0xF8) | ((i >> 5) & 0x07));
            low[i]  = (byte)(((i >> 5) & 0xE0) | ((i >> 3) & 0x1F));
        }
    }

    private void startWorker()
    {
        worker = new Thread(new Runnable()
        {
            public void run() { workerLoop(); }
        }, "RG35XX-FrameWorker");
        worker.setDaemon(true);
        try { worker.setPriority(Thread.MIN_PRIORITY); }
        catch(Throwable ignored) {}
        worker.start();
    }

    /** Coalescing request: stale pending frames are never queued. */
    public void requestFrame(int sourceWidth, int sourceHeight,
                             int[] sourceData, Object sourceLock)
    {
        if(!validSource(sourceWidth, sourceHeight, sourceData, sourceLock)) return;
        synchronized(signal)
        {
            width = sourceWidth;
            height = sourceHeight;
            lcdData = sourceData;
            frontbufferLock = sourceLock;
            pending = true;
            signal.notifyAll();
        }
    }

    /**
     * Rare synchronous control transaction used by the character-encoding
     * restart handshake. The old runtime sent a valid frame immediately before
     * sleeping for the native core to restart it; preserving that ordering is
     * required because no normal frame request may arrive before the restart.
     */
    public void sendControlFrame(int sourceWidth, int sourceHeight,
                                 int[] sourceData, Object sourceLock)
    {
        if(!validSource(sourceWidth, sourceHeight, sourceData, sourceLock)) return;
        try
        {
            synchronized(encodeLock)
            {
                sendFrameLocked(sourceWidth, sourceHeight, sourceData, sourceLock);
            }
        }
        catch(Throwable t)
        {
            System.err.println("RG35XX-VIDEO JAVA control-frame error: " + t);
        }
    }

    private boolean validSource(int sourceWidth, int sourceHeight,
                                int[] sourceData, Object sourceLock)
    {
        if(!running || sourceData == null || sourceLock == null) return false;
        if(sourceWidth <= 0 || sourceHeight <= 0 ||
           sourceWidth > MAX_WIDTH || sourceHeight > MAX_HEIGHT) return false;
        final int pixels = sourceWidth * sourceHeight;
        return pixels > 0 && pixels <= MAX_PIXELS && sourceData.length >= pixels;
    }

    public void shutdown()
    {
        synchronized(signal)
        {
            running = false;
            pending = false;
            signal.notifyAll();
        }
        if(worker != null)
        {
            try { worker.join(500L); }
            catch(InterruptedException ignored) {}
        }
    }

    private void workerLoop()
    {
        while(running)
        {
            int w;
            int h;
            int[] data;
            Object lock;

            synchronized(signal)
            {
                while(!pending && running)
                {
                    try { signal.wait(); }
                    catch(InterruptedException ignored) {}
                }
                if(!running) return;
                pending = false;
                w = width;
                h = height;
                data = lcdData;
                lock = frontbufferLock;
            }

            try
            {
                synchronized(encodeLock)
                {
                    sendFrameLocked(w, h, data, lock);
                }
            }
            catch(Throwable t)
            {
                System.err.println("RG35XX-VIDEO JAVA worker error: " + t);
            }
        }
    }

    /* Caller owns encodeLock. */
    private void sendFrameLocked(int w, int h, int[] data, Object lock) throws Exception
    {
        final int pixels = w * h;
        if(pixels <= 0 || pixels > MAX_PIXELS || data == null || data.length < pixels)
        {
            System.err.println("RG35XX-VIDEO JAVA invalid snapshot pixels=" + pixels);
            return;
        }

        synchronized(lock)
        {
            System.arraycopy(data, 0, argbSnapshot, 0, pixels);
        }

        int src = 0;
        int dst = 0;
        final int bulk = pixels & ~7;
        while(src < bulk)
        {
            int p0 = argbSnapshot[src++];
            int p1 = argbSnapshot[src++];
            int p2 = argbSnapshot[src++];
            int p3 = argbSnapshot[src++];
            int p4 = argbSnapshot[src++];
            int p5 = argbSnapshot[src++];
            int p6 = argbSnapshot[src++];
            int p7 = argbSnapshot[src++];
            dst = put565(p0, dst); dst = put565(p1, dst);
            dst = put565(p2, dst); dst = put565(p3, dst);
            dst = put565(p4, dst); dst = put565(p5, dst);
            dst = put565(p6, dst); dst = put565(p7, dst);
        }
        while(src < pixels) dst = put565(argbSnapshot[src++], dst);

        header[0] = (byte)0xFE;
        header[1] = (byte)((w >> 8) & 0xFF);
        header[2] = (byte)(w & 0xFF);
        header[3] = (byte)((h >> 8) & 0xFF);
        header[4] = (byte)(h & 0xFF);
        header[5] = (byte)(Mobile.rotateDisplay / 90);

        final int vibrationDuration = Mobile.vibrationDuration;
        final int vibrationStrength = Mobile.vibrationStrength;
        putInt32(header, 6, vibrationDuration);
        putInt32(header, 10, vibrationStrength);
        header[14] = Mobile.libretroRestartRequested;
        header[15] = Mobile.libretroEncodingRequested;
        Mobile.vibrationDuration = 0;

        synchronized(ipcOut)
        {
            ipcOut.write(header, 0, FRAME_HEADER_BYTES);
            ipcOut.write(rgb565, 0, pixels * 2);
            ipcOut.flush();
        }
    }

    private int put565(int argb, int dst)
    {
        rgb565[dst++] = high[(argb >>> 8) & 0xFFFF];
        rgb565[dst++] = low[argb & 0xFFFF];
        return dst;
    }

    private static void putInt32(byte[] out, int off, int value)
    {
        out[off]     = (byte)((value >>> 24) & 0xFF);
        out[off + 1] = (byte)((value >>> 16) & 0xFF);
        out[off + 2] = (byte)((value >>> 8) & 0xFF);
        out[off + 3] = (byte)(value & 0xFF);
    }
}
