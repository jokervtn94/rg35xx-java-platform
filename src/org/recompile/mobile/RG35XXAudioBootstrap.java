package org.recompile.mobile;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Opens the dedicated native audio pipe inherited across exec(JamVM).
 *
 * The native launcher passes -Dfreej2me.rg35xx.audio.fd=N. Linux exposes
 * inherited descriptors through /proc/self/fd/N; opening that path duplicates
 * the descriptor for Java ownership without touching stdout/stderr.
 *
 * If procfs/descriptor opening is unavailable, initialization fails closed and
 * the caller may retain the documented legacy media bridge as rollback until
 * device validation is complete.
 *
 * Tasklog: RGJ-B3-004
 */
public final class RG35XXAudioBootstrap
{
    public static final String FD_PROPERTY = "freej2me.rg35xx.audio.fd";
    private static OutputStream stream;

    private RG35XXAudioBootstrap() { }

    public static synchronized boolean initialize()
    {
        if(RG35XXAudioTransport.isAvailable()) return true;
        String value = System.getProperty(FD_PROPERTY);
        if(value == null || value.length() == 0) return false;

        try
        {
            int fd = Integer.parseInt(value);
            if(fd < 3) return false; // never accept stdin/stdout/stderr
            stream = new FileOutputStream("/proc/self/fd/" + fd);
            RG35XXAudioTransport.attach(stream);
            return true;
        }
        catch(Exception e)
        {
            closeQuietly();
            RG35XXAudioTransport.detach();
            return false;
        }
    }

    public static synchronized void shutdown()
    {
        if(RG35XXAudioTransport.isAvailable())
            RG35XXAudioTransport.resetNative();
        RG35XXAudioTransport.detach();
        closeQuietly();
    }

    private static void closeQuietly()
    {
        if(stream != null)
        {
            try { stream.close(); } catch(IOException ignored) { }
            stream = null;
        }
    }
}
