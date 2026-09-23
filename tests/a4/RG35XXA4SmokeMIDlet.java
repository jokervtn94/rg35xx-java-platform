package org.recompile.rg35xx.smoke;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.game.GameCanvas;
import javax.microedition.midlet.MIDlet;

/**
 * A4 level-1 smoke probe for the original RG35XX.
 *
 * Scope is intentionally limited to boot, Canvas callbacks/rendering,
 * GameCanvas getKeyStates()/flushGraphics(), physical input and normal exit.
 * It does not exercise RMS, fonts, Image/Sprite/TiledLayer, audio or media.
 */
public final class RG35XXA4SmokeMIDlet extends MIDlet {
    private static final long PHASE_TIMEOUT_MS = 30000L;
    private static final boolean INPUT_TRACE = Boolean.getBoolean("rg35xx.a4.inputtrace");

    private Display display;
    private CanvasProbe canvasProbe;
    private GameProbe gameProbe;
    private volatile boolean finishing;

    protected void startApp() {
        System.out.println("A4_SMOKE_BOOT=PASS");
        if (INPUT_TRACE) System.out.println("A4_INPUT_TRACE=ENABLED");
        display = Display.getDisplay(this);
        canvasProbe = new CanvasProbe();
        display.setCurrent(canvasProbe);
        canvasProbe.startProbe();
        System.out.println("A4_CANVAS_READY=YES");
    }

    protected void pauseApp() { }

    protected void destroyApp(boolean unconditional) {
        if (canvasProbe != null) canvasProbe.stopProbe();
        if (gameProbe != null) gameProbe.stopProbe();
    }

    private synchronized void startGameCanvas() {
        if (finishing || gameProbe != null) return;
        if (canvasProbe != null) canvasProbe.stopProbe();
        gameProbe = new GameProbe();
        display.setCurrent(gameProbe);
        gameProbe.startProbe();
        System.out.println("A4_GAMECANVAS_READY=YES");
    }

    private synchronized void finishSmoke(boolean pass, String reason) {
        if (finishing) return;
        finishing = true;
        destroyApp(true);
        System.out.println("A4_SMOKE_REASON=" + reason);
        System.out.println("A4_SMOKE_DEVICE_ACCEPTANCE_MARKER=" + (pass ? "PASS" : "FAIL"));
        System.out.println("A4_NORMAL_EXIT=PASS");
        System.out.flush();
        System.exit(pass ? 0 : 2);
    }

    private final class CanvasProbe extends Canvas implements Runnable {
        private volatile boolean running;
        private Thread thread;
        private int x = 280;
        private int y = 200;
        private int paintCount;
        private int trackedPresses;
        private int trackedReleases;
        private boolean sawDirection;
        private boolean sawFire;
        private boolean fire;

        CanvasProbe() {
            setFullScreenMode(true);
        }

        void startProbe() {
            running = true;
            thread = new Thread(this, "a4-canvas");
            thread.start();
        }

        void stopProbe() {
            running = false;
            if (thread != null) thread.interrupt();
        }

        protected void paint(Graphics g) {
            paintCount++;
            g.setColor(0x00000080);
            g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(fire ? 0x00FF0000 : 0x0000FF00);
            g.fillRect(x, y, 80, 80);
        }

        public void keyPressed(int keyCode) {
            int action = getGameAction(keyCode);
            if (INPUT_TRACE) {
                System.out.println("A4_CANVAS_CALLBACK=PRESS key=" + keyCode + " action=" + action);
            }
            boolean tracked = true;
            if (action == UP) {
                y -= 20;
                sawDirection = true;
            } else if (action == DOWN) {
                y += 20;
                sawDirection = true;
            } else if (action == LEFT) {
                x -= 20;
                sawDirection = true;
            } else if (action == RIGHT) {
                x += 20;
                sawDirection = true;
            } else if (action == FIRE) {
                fire = true;
                sawFire = true;
            } else {
                tracked = false;
            }
            if (tracked) trackedPresses++;
            if (INPUT_TRACE) {
                System.out.println("A4_CANVAS_COUNTS_AFTER_PRESS=presses=" + trackedPresses
                    + " releases=" + trackedReleases + " tracked=" + (tracked ? "YES" : "NO"));
            }
            clamp();
            repaint();
            serviceRepaints();
        }

        public void keyReleased(int keyCode) {
            int action = getGameAction(keyCode);
            boolean tracked = action == UP || action == DOWN || action == LEFT || action == RIGHT || action == FIRE;
            if (INPUT_TRACE) {
                System.out.println("A4_CANVAS_CALLBACK=RELEASE key=" + keyCode + " action=" + action
                    + " tracked=" + (tracked ? "YES" : "NO"));
            }
            if (tracked) {
                trackedReleases++;
                if (action == FIRE) fire = false;
            }
            if (INPUT_TRACE) {
                System.out.println("A4_CANVAS_COUNTS_AFTER_RELEASE=presses=" + trackedPresses
                    + " releases=" + trackedReleases);
            }
            repaint();
            serviceRepaints();
        }

        public void keyRepeated(int keyCode) {
            int action = getGameAction(keyCode);
            if (INPUT_TRACE) {
                System.out.println("A4_CANVAS_CALLBACK=REPEAT key=" + keyCode + " action=" + action);
            }
            if (action == UP) y -= 20;
            else if (action == DOWN) y += 20;
            else if (action == LEFT) x -= 20;
            else if (action == RIGHT) x += 20;
            clamp();
            repaint();
            serviceRepaints();
        }

        private void clamp() {
            int maxX = getWidth() - 80;
            int maxY = getHeight() - 80;
            if (x < 0) x = 0;
            if (y < 0) y = 0;
            if (x > maxX) x = maxX;
            if (y > maxY) y = maxY;
        }

        public void run() {
            long deadline = System.currentTimeMillis() + PHASE_TIMEOUT_MS;
            while (running && System.currentTimeMillis() < deadline) {
                repaint();
                serviceRepaints();
                if (paintCount > 0 && sawDirection && sawFire && trackedPresses > 0 && trackedPresses == trackedReleases) {
                    running = false;
                    System.out.println("A4_CANVAS_PAINT_COUNT=" + paintCount);
                    System.out.println("A4_CANVAS_TRACKED_PRESS_COUNT=" + trackedPresses);
                    System.out.println("A4_CANVAS_TRACKED_RELEASE_COUNT=" + trackedReleases);
                    System.out.println("A4_CANVAS_INPUT=PASS");
                    System.out.println("A4_CANVAS_EXECUTION=PASS");
                    startGameCanvas();
                    return;
                }
                try {
                    Thread.sleep(40L);
                } catch (InterruptedException e) {
                    return;
                }
            }
            if (running) {
                running = false;
                if (INPUT_TRACE) {
                    System.out.println("A4_CANVAS_TIMEOUT_STATE=sawDirection=" + (sawDirection ? "YES" : "NO")
                        + " sawFire=" + (sawFire ? "YES" : "NO")
                        + " fireHeld=" + (fire ? "YES" : "NO"));
                }
                System.out.println("A4_CANVAS_PAINT_COUNT=" + paintCount);
                System.out.println("A4_CANVAS_TRACKED_PRESS_COUNT=" + trackedPresses);
                System.out.println("A4_CANVAS_TRACKED_RELEASE_COUNT=" + trackedReleases);
                System.out.println("A4_CANVAS_EXECUTION=FAIL");
                finishSmoke(false, "CANVAS_TIMEOUT_OR_INPUT_INCOMPLETE");
            }
        }
    }

    private final class GameProbe extends GameCanvas implements Runnable {
        private volatile boolean running;
        private Thread thread;
        private int x = 280;
        private int y = 200;
        private int flushCount;
        private int sampleCount;
        private boolean sawDirection;
        private boolean sawFire;
        private boolean sawFireRelease;
        private boolean previousFire;

        GameProbe() {
            super(false);
            setFullScreenMode(true);
        }

        void startProbe() {
            running = true;
            thread = new Thread(this, "a4-gamecanvas");
            thread.start();
        }

        void stopProbe() {
            running = false;
            if (thread != null) thread.interrupt();
        }

        private void clamp() {
            int maxX = getWidth() - 80;
            int maxY = getHeight() - 80;
            if (x < 0) x = 0;
            if (y < 0) y = 0;
            if (x > maxX) x = maxX;
            if (y > maxY) y = maxY;
        }

        public void run() {
            long deadline = System.currentTimeMillis() + PHASE_TIMEOUT_MS;
            while (running && System.currentTimeMillis() < deadline) {
                int state = getKeyStates();
                sampleCount++;

                if ((state & UP_PRESSED) != 0) {
                    y -= 10;
                    sawDirection = true;
                }
                if ((state & DOWN_PRESSED) != 0) {
                    y += 10;
                    sawDirection = true;
                }
                if ((state & LEFT_PRESSED) != 0) {
                    x -= 10;
                    sawDirection = true;
                }
                if ((state & RIGHT_PRESSED) != 0) {
                    x += 10;
                    sawDirection = true;
                }

                boolean fireNow = (state & FIRE_PRESSED) != 0;
                if (fireNow) sawFire = true;
                if (previousFire && !fireNow) sawFireRelease = true;
                if (INPUT_TRACE && fireNow != previousFire) {
                    System.out.println("A4_GAMECANVAS_FIRE_STATE=" + (fireNow ? "PRESSED" : "RELEASED")
                        + " keyStates=0x" + Integer.toHexString(state));
                }
                previousFire = fireNow;
                clamp();

                Graphics g = getGraphics();
                g.setColor(0x00000000);
                g.fillRect(0, 0, getWidth(), getHeight());
                g.setColor(fireNow ? 0x00FFFF00 : 0x0000FFFF);
                g.fillRect(x, y, 80, 80);
                flushGraphics();
                flushCount++;

                if (flushCount > 0 && sawDirection && sawFire && sawFireRelease) {
                    running = false;
                    System.out.println("A4_GAMECANVAS_SAMPLE_COUNT=" + sampleCount);
                    System.out.println("A4_GAMECANVAS_FLUSH_COUNT=" + flushCount);
                    System.out.println("A4_GAMECANVAS_KEYSTATES=PASS");
                    System.out.println("A4_GAMECANVAS_EXECUTION=PASS");
                    finishSmoke(true, "SMOKE_PROGRAMMATIC_SCOPE_COMPLETE");
                    return;
                }

                try {
                    Thread.sleep(40L);
                } catch (InterruptedException e) {
                    return;
                }
            }

            if (running) {
                running = false;
                if (INPUT_TRACE) {
                    System.out.println("A4_GAMECANVAS_TIMEOUT_STATE=sawDirection=" + (sawDirection ? "YES" : "NO")
                        + " sawFire=" + (sawFire ? "YES" : "NO")
                        + " sawFireRelease=" + (sawFireRelease ? "YES" : "NO")
                        + " previousFire=" + (previousFire ? "YES" : "NO"));
                }
                System.out.println("A4_GAMECANVAS_SAMPLE_COUNT=" + sampleCount);
                System.out.println("A4_GAMECANVAS_FLUSH_COUNT=" + flushCount);
                System.out.println("A4_GAMECANVAS_EXECUTION=FAIL");
                finishSmoke(false, "GAMECANVAS_TIMEOUT_OR_INPUT_INCOMPLETE");
            }
        }
    }
}