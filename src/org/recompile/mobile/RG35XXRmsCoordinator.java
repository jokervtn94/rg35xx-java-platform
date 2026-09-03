package org.recompile.mobile;

import java.util.Vector;

/**
 * Single low-priority coalescing writer for RG35XX RecordStore persistence.
 * RecordStore owns serialization/semantics; this class only schedules flushes.
 * Java 6 compatible. Tasklog: RGJ-B5-002 / RGJ-B5-004 / RGJ-B6-009.
 */
public final class RG35XXRmsCoordinator implements Runnable
{
    public static interface FlushableStore
    {
        void flushRG35XX() throws Exception;
    }

    private static final RG35XXRmsCoordinator INSTANCE = new RG35XXRmsCoordinator();
    private final Vector<FlushableStore> dirty = new Vector<FlushableStore>();
    private final Vector<FlushableStore> failed = new Vector<FlushableStore>();
    private final Object lock = new Object();
    private Thread worker;
    private boolean running;
    private boolean flushing;
    private Exception lastFailure;

    private RG35XXRmsCoordinator() { }

    public static RG35XXRmsCoordinator getInstance() { return INSTANCE; }

    public void start()
    {
        synchronized(lock)
        {
            if(running) return;
            running = true;
            worker = new Thread(this, "RG35XX-RMS");
            worker.setPriority(Thread.MIN_PRIORITY);
            worker.start();
        }
    }

    public void markDirty(FlushableStore store)
    {
        if(store == null) return;
        start();
        synchronized(lock)
        {
            failed.removeElement(store);
            if(!dirty.contains(store)) dirty.addElement(store);
            lock.notifyAll();
        }
    }

    public void run()
    {
        for(;;)
        {
            FlushableStore store = null;
            synchronized(lock)
            {
                while(running && dirty.isEmpty())
                    try { lock.wait(); } catch(InterruptedException ignored) { }
                if(!running && dirty.isEmpty()) break;
                if(!dirty.isEmpty())
                {
                    store = dirty.elementAt(0);
                    dirty.removeElementAt(0);
                    flushing = true;
                }
            }

            if(store != null)
            {
                try
                {
                    store.flushRG35XX();
                    synchronized(lock)
                    {
                        failed.removeElement(store);
                        if(failed.isEmpty()) lastFailure = null;
                    }
                }
                catch(Exception e)
                {
                    synchronized(lock)
                    {
                        lastFailure = e;
                        if(!failed.contains(store)) failed.addElement(store);
                    }
                }
                finally
                {
                    synchronized(lock)
                    {
                        flushing = false;
                        lock.notifyAll();
                    }
                }
            }
        }
    }

    /**
     * Force all queued stores to stable storage before returning.
     * A store that failed in the background gets exactly one barrier retry.
     * If that retry also fails, the exception is surfaced instead of spinning.
     */
    public void forceFlush() throws Exception
    {
        start();
        synchronized(lock)
        {
            if(!failed.isEmpty())
            {
                for(int i = 0; i < failed.size(); i++)
                {
                    FlushableStore store = failed.elementAt(i);
                    if(!dirty.contains(store)) dirty.addElement(store);
                }
                failed.removeAllElements();
                lastFailure = null;
            }

            lock.notifyAll();
            while(!dirty.isEmpty() || flushing)
                try { lock.wait(); } catch(InterruptedException ignored) { }

            if(!failed.isEmpty())
            {
                Exception failure = lastFailure;
                if(failure == null) failure = new Exception("RG35XX RMS flush failed");
                throw failure;
            }
        }
    }

    public void shutdown() throws Exception
    {
        Exception failure = null;
        try { forceFlush(); }
        catch(Exception e) { failure = e; }

        Thread t;
        synchronized(lock)
        {
            running = false;
            lock.notifyAll();
            t = worker;
            worker = null;
        }
        if(t != null) try { t.join(2000L); } catch(InterruptedException ignored) { }

        if(failure != null) throw failure;
    }
}
