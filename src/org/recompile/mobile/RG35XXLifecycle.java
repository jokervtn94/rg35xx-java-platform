package org.recompile.mobile;

/**
 * Central lifecycle contract for the RG35XX target.
 * Subsystems keep their own implementation/state; this class only defines
 * deterministic ordering across game load, unload and platform shutdown.
 * Java 6 compatible. Tasklog: RGJ-B6-001..010, RGJ-RC1-011B.
 */
public final class RG35XXLifecycle
{
    private static boolean platformStarted;
    private static boolean gameActive;
    private static boolean gameLoadPrepared;

    private RG35XXLifecycle() { }

    public static synchronized void platformStart()
    {
        if(platformStarted) return;
        RG35XXRmsCoordinator.getInstance().start();

        /* Fail-safe: absence of the inherited audio FD leaves rollback media
         * available; stdout is never used as an audio transport. */
        RG35XXAudioBootstrap.initialize();
        platformStarted = true;
    }

    /**
     * Complete old-game persistence/reset before MobilePlatform.load() is
     * allowed to replace loader/suite context. This prepares a load but does
     * not claim that the next game exists yet.
     */
    public static synchronized void beforeGameLoad() throws Exception
    {
        platformStart();
        if(gameActive) unloadGame();

        /* Defensive native reset also covers stale state after a failed load. */
        if(RG35XXAudioTransport.isAvailable()) RG35XXAudioTransport.resetNative();
        RG35XXMediaRegistry.reset();

        /* Per-game acceleration/input state must not leak between MIDlets. */
        RG35XXImageCache.clear();
        RG35XXTransformCache.reset();
        RG35XXInputEngine.reset();
        RG35XXFrameScheduler.reset();
        gameActive = false;
        gameLoadPrepared = true;
    }

    /** Commit the prepared load only after MobilePlatform.load() succeeds. */
    public static synchronized void afterGameLoad()
    {
        if(!platformStarted || !gameLoadPrepared) return;
        gameActive = true;
        gameLoadPrepared = false;
    }

    /** Clear a prepared-but-failed load without fabricating an active game. */
    public static synchronized void gameLoadFailed()
    {
        gameActive = false;
        gameLoadPrepared = false;
        RG35XXInputEngine.reset();
        RG35XXFrameScheduler.reset();
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

        /* Persistent data must reach stable storage before volatile state dies. */
        RG35XXRmsCoordinator.getInstance().forceFlush();

        /* Native RESET owns final release of all target media blobs/voices. */
        if(RG35XXAudioTransport.isAvailable()) RG35XXAudioTransport.resetNative();
        RG35XXMediaRegistry.reset();

        RG35XXInputEngine.reset();
        RG35XXImageCache.clear();
        RG35XXTransformCache.reset();
        RG35XXFrameScheduler.reset();
        gameActive = false;
        gameLoadPrepared = false;
    }

    public static synchronized void platformShutdown() throws Exception
    {
        if(!platformStarted) return;
        Exception failure = null;

        try { unloadGame(); }
        catch(Exception e) { failure = e; }

        try { RG35XXAudioBootstrap.shutdown(); }
        catch(Exception e) { if(failure == null) failure = e; }

        try { RG35XXRmsCoordinator.getInstance().shutdown(); }
        catch(Exception e) { if(failure == null) failure = e; }

        platformStarted = false;
        gameActive = false;
        gameLoadPrepared = false;
        if(failure != null) throw failure;
    }

    public static synchronized boolean isGameActive() { return gameActive; }
}
