package org.recompile.mobile;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Java-6-compatible atomic-ish sibling replacement helper for RG35XX RMS.
 * Avoids java.nio.file, which is unavailable on the JamVM/GNU Classpath target.
 *
 * Tasklog: RGJ-B5-003
 */
public final class RG35XXRmsAtomicFile
{
    private RG35XXRmsAtomicFile() { }

    public static void write(File target, byte[] data) throws IOException
    {
        if(target == null || data == null) throw new NullPointerException();
        File parent = target.getParentFile();
        if(parent != null && !parent.exists() && !parent.mkdirs() && !parent.exists())
            throw new IOException("cannot create RMS directory");

        File temp = new File(target.getPath() + ".tmp");
        File backup = new File(target.getPath() + ".bak");
        FileOutputStream out = null;
        try
        {
            out = new FileOutputStream(temp, false);
            out.write(data);
            out.flush();
        }
        finally
        {
            if(out != null) try { out.close(); } catch(IOException ignored) { }
        }

        if(backup.exists() && !backup.delete())
            throw new IOException("cannot remove stale RMS backup");

        boolean hadTarget = target.exists();
        if(hadTarget && !target.renameTo(backup))
            throw new IOException("cannot preserve previous RMS file");

        if(!temp.renameTo(target))
        {
            if(hadTarget && backup.exists()) backup.renameTo(target);
            throw new IOException("cannot promote RMS temp file");
        }

        if(backup.exists()) backup.delete();
    }

    /** Startup cleanup only; parser-level recovery remains RecordStore-owned. */
    public static void discardStaleTempWhenTargetExists(File target)
    {
        if(target == null || !target.exists()) return;
        File temp = new File(target.getPath() + ".tmp");
        if(temp.exists()) temp.delete();
    }
}
