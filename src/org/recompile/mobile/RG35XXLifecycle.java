package org.recompile.mobile;

/**
 * Central lifecycle contract for the RG35XX target.
 * Subsystems keep their own implementation/state; this class only defines
 * deterministic ordering across game load, unload and platform shutdown.
 * Java 6 compatible. Tasklog: RGJ-B6-001..004.
 */
public final class RG35XXLifecycle
{
    private static boolean platformStarted;
    private static boolean gameActive;

    private RG35XXLifecycle() { }

    public static synchronized void platformStart()
    {
        if(platformStarted) return;
        RG35XXRmsCoordinator.getInstance().start();
        platformStarted = true;
    }

    public static synchronized void beforeGameLoad() throws Exception
    {
        platformStart();
        if(gameActive) unloadGame();

        /* Per-game caches/input must never leak state from the previous MIDlet. */
        RG35XXImageCache.clear();
        RG35XXTransformCache.clear();
        RG35XXInputEngine.reset();
        RG35XXMediaRegistry.reset();
        RG35XXFrameScheduler.reset();
        gameActive = true;
    }

    public static synchronized void pauseBarrier() throws Exception
    {
        if(!platformStarted) return;
        RG35XXRmsCoordinator.getInstance().forceFlush();
    }

    public static synchronized void destroyBarrier() throws Exception
    {
        if(!platformStarted) return;
        RG35XXRmsCoordinator.getInstance().forceFlush();
    }

    public static synchronized void unloadGame() throws Exception
    {
        if(!platformStarted) return;

        /* Persist before volatile state is discarded. */
        RG35XXRmsCoordinator.getInstance().forceFlush();

        /* Release target media before transport reset/detach. */
        RG35XXMediaRegistry.reset();
        if(RG35XXAudioTransport.isAvailable()) RG35XXAudioTransport.reset();

        RG35XXInputEngine.reset();
        RG35XXImageCache.clear();
        RG35XXTransformCache.clear();
        RG35XXFrameScheduler.reset();
        gameActive = false;
    }

    public static synchronized void platformShutdown() throws Exception
    {
        if(!platformStarted) return;
        Exception failure = null;
        try { unloadGame(); } catch(Exception e) { failure = e; }
        try { RG35XXAudioBootstrap.shutdown(); } catch(Exception e) { if(failure == null) failure = e; }
        try { RG35XXRmsCoordinator.getInstance().shutdown(); } catch(Exception e) { if(failure == null) failure = e; }
        platformStarted = false;
        gameActive = false;
        if(failure != null) throw failure;
    }

    public static synchronized boolean isGameActive() { return gameActive; }
}
