package org.recompile.mobile;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;

/** Minimal real MIDP Canvas used only for M1.9 RG35XX device acceptance. */
public final class M19CanvasAcceptanceMIDlet extends MIDlet {
    private AcceptanceCanvas canvas;
    private M19InputPump inputPump;

    protected void startApp() {
        canvas = new AcceptanceCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        inputPump = new M19InputPump();
        new Thread(inputPump).start();
        System.out.println("M1_9_CANVAS_VISIBLE_READY=YES");
        System.out.println("M1_9_PRODUCTION_INPUT_PUMP=STARTED");
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {
        if (inputPump != null) inputPump.stop();
    }

    private final class AcceptanceCanvas extends Canvas implements Runnable {
        private volatile boolean running = true;
        private int presses, releases, repeats, directions, fires;
        private String last = "PRESS D-PAD + A";

        AcceptanceCanvas() {
            setFullScreenMode(true);
            new Thread(this).start();
        }

        protected void paint(Graphics g) {
            int w=getWidth(), h=getHeight();
            g.setColor(0x101820); g.fillRect(0,0,w,h);
            g.setColor(0xFFFFFF);
            g.drawString("RG35XX M1.9 CANVAS", w/2, 12, Graphics.TOP|Graphics.HCENTER);
            g.drawString(last, w/2, h/2-18, Graphics.TOP|Graphics.HCENTER);
            g.drawString("P:"+presses+" R:"+releases+" REP:"+repeats, w/2, h/2+8, Graphics.TOP|Graphics.HCENTER);
            g.drawString("DIR:"+directions+" FIRE:"+fires, w/2, h/2+30, Graphics.TOP|Graphics.HCENTER);
        }

        protected void keyPressed(int keyCode) {
            presses++;
            int ga=getGameAction(keyCode);
            if (ga==UP || ga==DOWN || ga==LEFT || ga==RIGHT) directions++;
            if (ga==FIRE) fires++;
            last="PRESS key="+keyCode+" ga="+ga;
            System.out.println("M1_9_CANVAS_KEY_PRESSED="+keyCode+" GAME_ACTION="+ga);
            repaint(); serviceRepaints();
        }

        protected void keyReleased(int keyCode) {
            releases++;
            last="RELEASE key="+keyCode;
            System.out.println("M1_9_CANVAS_KEY_RELEASED="+keyCode);
            repaint(); serviceRepaints();
        }

        protected void keyRepeated(int keyCode) {
            repeats++;
            last="REPEAT key="+keyCode;
            System.out.println("M1_9_CANVAS_KEY_REPEATED="+keyCode);
            repaint(); serviceRepaints();
        }

        public void run() {
            long end=System.currentTimeMillis()+30000L;
            while (running && System.currentTimeMillis()<end) {
                try { Thread.sleep(100L); } catch (InterruptedException ignored) {}
            }
            running=false;
            if (inputPump != null) inputPump.stop();
            System.out.println("M1_9_PRESS_COUNT="+presses);
            System.out.println("M1_9_RELEASE_COUNT="+releases);
            System.out.println("M1_9_REPEAT_COUNT="+repeats);
            System.out.println("M1_9_DIRECTION_COUNT="+directions);
            System.out.println("M1_9_FIRE_COUNT="+fires);
            if (presses>0 && releases>0 && presses==releases && directions>0 && fires>0) {
                System.out.println("M1_9_DIRECTION_CALLBACK=PASS");
                System.out.println("M1_9_FIRE_CALLBACK=PASS");
                System.out.println("M1_9_RELEASE_NO_STUCK=PASS");
                System.out.println("M1_9_DEVICE_ACCEPTANCE_MARKER=PASS");
            } else {
                System.out.println("M1_9_DEVICE_ACCEPTANCE_MARKER=FAIL");
            }
            notifyDestroyed();
        }
    }
}
