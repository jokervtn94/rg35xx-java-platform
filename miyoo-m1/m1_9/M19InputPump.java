package org.recompile.mobile;

/**
 * M1.9 device acceptance input pump.
 * It does not dispatch MIDP events itself: it only calls the already
 * DEVICE-PASS M1InputDispatch.poll() production path at a bounded cadence.
 */
public final class M19InputPump implements Runnable {
    private final M1InputDispatch dispatch = new M1InputDispatch();
    private volatile boolean running = true;

    public void stop() { running = false; }

    public void run() {
        while (running) {
            dispatch.poll(System.currentTimeMillis());
            try { Thread.sleep(20L); }
            catch (InterruptedException ignored) { running = false; }
        }
    }
}
