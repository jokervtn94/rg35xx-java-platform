package org.recompile.mobile;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;

/** M1.9F: real Canvas callback -> proven fillRect -> proven M1.9E presenter. */
public final class M19CanvasE2EMIDlet extends MIDlet {
    private E2ECanvas canvas;
    private M19InputPump inputPump;

    protected void startApp() {
        canvas = new E2ECanvas();
        Display.getDisplay(this).setCurrent(canvas);
        inputPump = new M19InputPump();
        new Thread(inputPump, "m19f-input").start();
        canvas.startPresenter();
        System.out.println("M1_9F_CANVAS_VISIBLE_READY=YES");
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {
        if (inputPump != null) inputPump.stop();
        if (canvas != null) canvas.stopPresenter();
    }

    private final class E2ECanvas extends Canvas implements Runnable {
        private volatile boolean running = true;
        private volatile int x = 280, y = 200;
        private volatile int presses, releases, repeats, directions, fires;
        private volatile boolean fire;
        private Thread presenterThread;

        E2ECanvas() { setFullScreenMode(true); }
        void startPresenter() { presenterThread = new Thread(this, "m19f-presenter"); presenterThread.start(); }
        void stopPresenter() { running = false; }

        protected void paint(Graphics g) {
            int w = getWidth(), h = getHeight();
            g.setColor(0x000000FF); g.fillRect(0, 0, w, h);
            g.setColor(fire ? 0x00FF0000 : 0x0000FF00);
            g.fillRect(x, y, 80, 80);
        }

        public void keyPressed(int keyCode) {
            presses++;
            int ga = getGameAction(keyCode);
            if (ga == UP) { y -= 20; directions++; }
            else if (ga == DOWN) { y += 20; directions++; }
            else if (ga == LEFT) { x -= 20; directions++; }
            else if (ga == RIGHT) { x += 20; directions++; }
            else if (ga == FIRE) { fire = true; fires++; }
            clamp();
            System.out.println("M1_9F_KEY_PRESSED="+keyCode+" GAME_ACTION="+ga);
            repaint(); serviceRepaints();
        }
        public void keyReleased(int keyCode) {
            releases++;
            if (getGameAction(keyCode) == FIRE) fire = false;
            System.out.println("M1_9F_KEY_RELEASED="+keyCode);
            repaint(); serviceRepaints();
        }
        public void keyRepeated(int keyCode) {
            repeats++;
            int ga = getGameAction(keyCode);
            if (ga == UP) y -= 20; else if (ga == DOWN) y += 20; else if (ga == LEFT) x -= 20; else if (ga == RIGHT) x += 20;
            clamp();
            System.out.println("M1_9F_KEY_REPEATED="+keyCode);
            repaint(); serviceRepaints();
        }
        private void clamp() {
            if (x < 0) x=0; if (y < 0) y=0;
            if (x > 560) x=560; if (y > 400) y=400;
        }

        public void run() {
            int init = M19SdlPresenter.initDisplay();
            System.out.println("M1_9F_NATIVE_INIT_RC="+init);
            if (init != 0) { running=false; System.out.println("M1_9F_NORMAL_EXIT=FAIL"); System.exit(1); return; }
            long end = System.currentTimeMillis()+30000L;
            int presents=0;
            while (running && System.currentTimeMillis()<end) {
                repaint(); serviceRepaints();
                PlatformImage image = MobilePlatform.getLcdBackbuffer();
                if (image != null) {
                    int[] fb = image.getMIDPGraphics().getFrameBuffer();
                    int rc = M19SdlPresenter.presentARGB(fb, 640, 480);
                    if (rc != 0) { System.out.println("M1_9F_PRESENT_FAIL_RC="+rc); break; }
                    presents++;
                }
                try { Thread.sleep(50L); } catch (InterruptedException ignored) { break; }
            }
            running=false;

            // r7: keep the proven M1.8 pump alive briefly so physical releases that
            // occur at the 30 s boundary can traverse the normal js0 -> MIDP path.
            // No synthetic release and no M1.8 dispatcher/mapping change is made.
            long releaseDeadline = System.currentTimeMillis()+2000L;
            while (releases < presses && System.currentTimeMillis() < releaseDeadline) {
                try { Thread.sleep(20L); } catch (InterruptedException ignored) { break; }
            }
            System.out.println("M1_9F_RELEASE_DRAIN_MS=2000");
            if (inputPump != null) inputPump.stop();
            M19SdlPresenter.shutdownDisplay();
            System.out.println("M1_9F_PRESENT_COUNT="+presents);
            System.out.println("M1_9F_PRESS_COUNT="+presses);
            System.out.println("M1_9F_RELEASE_COUNT="+releases);
            System.out.println("M1_9F_REPEAT_COUNT="+repeats);
            System.out.println("M1_9F_DIRECTION_COUNT="+directions);
            System.out.println("M1_9F_FIRE_COUNT="+fires);
            boolean pass = presents>0 && presses>0 && releases>0 && presses==releases && directions>0 && fires>0;
            System.out.println("M1_9F_RELEASE_NO_STUCK="+(presses==releases?"PASS":"FAIL"));
            System.out.println("M1_9F_DEVICE_ACCEPTANCE_MARKER="+(pass?"PASS":"FAIL"));

            // r7 acceptance harness exits directly after SDL shutdown. Calling
            // MIDlet.notifyDestroyed() makes pinned FreeJ2ME draw its desktop
            // "app terminated" text, which re-enters AWT drawString and is outside
            // this no-font Canvas acceptance scope. This is not the production
            // lifecycle policy; it only prevents that unrelated screen from
            // masking the input/render result.
            System.out.println("M1_9F_AWT_TERMINATION_SCREEN_SKIPPED=YES");
            System.out.println("M1_9F_NORMAL_EXIT=PASS");
            System.exit(pass ? 0 : 2);
        }
    }
}
