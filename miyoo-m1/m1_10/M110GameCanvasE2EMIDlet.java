package org.recompile.mobile;

import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.game.GameCanvas;
import javax.microedition.midlet.MIDlet;

/** M1.10-r3: isolate GameCanvas source-buffer vs flush/frontbuffer boundary. */
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
        private boolean sourceHasExpectedColor, frontHasExpectedColor;

        ProbeCanvas() { super(false); setFullScreenMode(true); }
        void startProbe() { new Thread(this, "m110-gamecanvas").start(); }
        void stopProbe() { running = false; }

        private void clamp() {
            if (x < 0) x = 0; if (y < 0) y = 0;
            if (x > 560) x = 560; if (y > 400) y = 400;
        }
        private boolean expected(int p) {
            int rgb = p & 0x00FFFFFF;
            return rgb == 0x000000FF || rgb == 0x0000FF00 || rgb == 0x00FF0000;
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

                // Capture the actual GameCanvas private render target through the Graphics
                // object returned by GameCanvas.getGraphics(). This does not alter M1.8,
                // M1.9E, JamVM or glibj; it isolates the failing flush/frontbuffer boundary.
                int[] source = g.getFrameBuffer();
                int sourceBg = source[10 * 640 + 10];
                int sourceSquare = source[(y + 40) * 640 + (x + 40)];
                if (expected(sourceBg) && expected(sourceSquare)) sourceHasExpectedColor = true;

                flushGraphics();
                PlatformImage front = Mobile.getPlatform().getLcdFrontbuffer();
                int[] frontFb = front.getDataBuffer();
                int frontBg = frontFb[10 * 640 + 10];
                int frontSquare = frontFb[(y + 40) * 640 + (x + 40)];
                if (expected(frontBg) && expected(frontSquare)) frontHasExpectedColor = true;

                if (samples == 1 || samples == 100) {
                    System.out.println("M1_10_R3_SOURCE_BG=0x"+Integer.toHexString(sourceBg));
                    System.out.println("M1_10_R3_SOURCE_SQUARE=0x"+Integer.toHexString(sourceSquare));
                    System.out.println("M1_10_R3_FRONT_BG=0x"+Integer.toHexString(frontBg));
                    System.out.println("M1_10_R3_FRONT_SQUARE=0x"+Integer.toHexString(frontSquare));
                }

                // Diagnostic A/B: present the exact GameCanvas render target. If this is
                // visible while r2 frontbuffer stayed white, GameCanvas primitive rendering
                // and M1.9E are proven and the remaining defect is strictly flush/frontbuffer.
                int rc = M19SdlPresenter.presentARGB(source, 640, 480);
                if (rc != 0) { System.out.println("M1_10_PRESENT_FAIL_RC="+rc); break; }
                presents++;
                try { Thread.sleep(50L); } catch (InterruptedException ignored) { break; }
            }
            running=false;

            long drainEnd = System.currentTimeMillis()+2000L;
            while (previousFire && System.currentTimeMillis()<drainEnd) {
                int state=getKeyStates();
                boolean fire=(state & FIRE_PRESSED)!=0;
                if (!fire) { sawFireRelease=true; previousFire=false; }
                try { Thread.sleep(20L); } catch (InterruptedException ignored) { break; }
            }
            if (inputPump != null) inputPump.stop();
            M19SdlPresenter.shutdownDisplay();

            System.out.println("M1_10_PRESENT_BUFFER=GAMECANVAS_SOURCE_R3_DIAGNOSTIC");
            System.out.println("M1_10_R3_SOURCE_EXPECTED_COLOR="+(sourceHasExpectedColor?"PASS":"FAIL"));
            System.out.println("M1_10_R3_FRONT_EXPECTED_COLOR="+(frontHasExpectedColor?"PASS":"FAIL"));
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
            boolean pass=presents>0 && sourceHasExpectedColor && directionalSamples>0 && sawFire && sawFireRelease;
            System.out.println("M1_10_R3_DIAGNOSTIC_ACCEPTANCE="+(pass?"PASS":"FAIL"));
            System.out.println("M1_10_DEVICE_ACCEPTANCE_MARKER=FAIL_PENDING_FLUSH_BOUNDARY_FIX");
            System.out.println("M1_10_AWT_TERMINATION_SCREEN_SKIPPED=YES");
            System.out.println("M1_10_NORMAL_EXIT=PASS");
            System.exit(pass ? 0 : 2);
        }
    }
}
