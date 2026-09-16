package org.recompile.mobile;

import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.game.GameCanvas;
import javax.microedition.midlet.MIDlet;

/** M1.10: GameCanvas getKeyStates -> primitive render -> locked M1.9E presenter. */
public final class M110GameCanvasE2EMIDlet extends MIDlet {
    private ProbeCanvas canvas;
    private M19InputPump inputPump;

    protected void startApp() {
        canvas = new ProbeCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        inputPump = new M19InputPump();
        new Thread(inputPump, "m110-input").start();
        canvas.startProbe();
        System.out.println("M1_10_GAMECANVAS_VISIBLE_READY=YES");
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {
        if (inputPump != null) inputPump.stop();
        if (canvas != null) canvas.stopProbe();
    }

    private final class ProbeCanvas extends GameCanvas implements Runnable {
        private volatile boolean running = true;
        private int x = 280, y = 200;
        private int presents, samples, directionalSamples, fireSamples;
        private boolean sawUp, sawDown, sawLeft, sawRight, sawFire, sawFireRelease;
        private boolean previousFire;

        ProbeCanvas() { super(false); setFullScreenMode(true); }
        void startProbe() { new Thread(this, "m110-gamecanvas").start(); }
        void stopProbe() { running = false; }

        private void clamp() {
            if (x < 0) x = 0; if (y < 0) y = 0;
            if (x > 560) x = 560; if (y > 400) y = 400;
        }

        public void run() {
            int init = M19SdlPresenter.initDisplay();
            System.out.println("M1_10_NATIVE_INIT_RC=" + init);
            if (init != 0) { System.out.println("M1_10_NORMAL_EXIT=FAIL"); System.exit(1); return; }

            long end = System.currentTimeMillis() + 30000L;
            while (running && System.currentTimeMillis() < end) {
                int state = getKeyStates();
                samples++;
                if ((state & UP_PRESSED) != 0) { y -= 10; sawUp=true; directionalSamples++; }
                if ((state & DOWN_PRESSED) != 0) { y += 10; sawDown=true; directionalSamples++; }
                if ((state & LEFT_PRESSED) != 0) { x -= 10; sawLeft=true; directionalSamples++; }
                if ((state & RIGHT_PRESSED) != 0) { x += 10; sawRight=true; directionalSamples++; }
                boolean fire = (state & FIRE_PRESSED) != 0;
                if (fire) { sawFire=true; fireSamples++; }
                if (previousFire && !fire) sawFireRelease=true;
                previousFire = fire;
                clamp();

                Graphics g = getGraphics();
                g.setColor(0x000000FF); g.fillRect(0, 0, getWidth(), getHeight());
                g.setColor(fire ? 0x00FF0000 : 0x0000FF00); g.fillRect(x, y, 80, 80);
                flushGraphics();

                // GameCanvas.flushGraphics() copies its private off-screen buffer into
                // MobilePlatform's LCD FRONTBUFFER. M1.10-r1 incorrectly presented the
                // LCD backbuffer, which remained white even though GameCanvas input and
                // flush execution were healthy. Present exactly the flushed frontbuffer.
                PlatformImage image = Mobile.getPlatform().getLcdFrontbuffer();
                if (image != null) {
                    int[] fb = image.getMIDPGraphics().getFrameBuffer();
                    int rc = M19SdlPresenter.presentARGB(fb, 640, 480);
                    if (rc != 0) { System.out.println("M1_10_PRESENT_FAIL_RC="+rc); break; }
                    presents++;
                }
                try { Thread.sleep(50L); } catch (InterruptedException ignored) { break; }
            }
            running=false;

            // Keep locked M1.8 pump alive briefly to observe a real FIRE release.
            long drainEnd = System.currentTimeMillis()+2000L;
            while (previousFire && System.currentTimeMillis()<drainEnd) {
                int state=getKeyStates();
                boolean fire=(state & FIRE_PRESSED)!=0;
                if (!fire) { sawFireRelease=true; previousFire=false; }
                try { Thread.sleep(20L); } catch (InterruptedException ignored) { break; }
            }
            if (inputPump != null) inputPump.stop();
            M19SdlPresenter.shutdownDisplay();

            System.out.println("M1_10_PRESENT_BUFFER=FRONTBUFFER");
            System.out.println("M1_10_PRESENT_COUNT="+presents);
            System.out.println("M1_10_KEYSTATE_SAMPLE_COUNT="+samples);
            System.out.println("M1_10_DIRECTION_SAMPLE_COUNT="+directionalSamples);
            System.out.println("M1_10_FIRE_SAMPLE_COUNT="+fireSamples);
            System.out.println("M1_10_SAW_UP="+sawUp);
            System.out.println("M1_10_SAW_DOWN="+sawDown);
            System.out.println("M1_10_SAW_LEFT="+sawLeft);
            System.out.println("M1_10_SAW_RIGHT="+sawRight);
            System.out.println("M1_10_SAW_FIRE="+sawFire);
            System.out.println("M1_10_SAW_FIRE_RELEASE="+sawFireRelease);
            boolean pass=presents>0 && directionalSamples>0 && sawFire && sawFireRelease;
            System.out.println("M1_10_DEVICE_ACCEPTANCE_MARKER="+(pass?"PASS":"FAIL"));
            System.out.println("M1_10_AWT_TERMINATION_SCREEN_SKIPPED=YES");
            System.out.println("M1_10_NORMAL_EXIT=PASS");
            System.exit(pass ? 0 : 2);
        }
    }
}
