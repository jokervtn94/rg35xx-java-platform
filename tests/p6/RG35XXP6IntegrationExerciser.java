import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;

public final class RG35XXP6IntegrationExerciser extends MIDlet {
    private static final int LOGICAL_W = 176;
    private static final int LOGICAL_H = 208;
    private final P6Canvas canvas = new P6Canvas();
    private volatile boolean finished;

    protected void startApp() {
        System.out.println("P6_LIFECYCLE_START=PASS");
        System.out.println("P6_INTEGRATION_BOOT=PASS");
        if (!resourceGate()) {
            finish(false, "RESOURCE");
            return;
        }
        Display.getDisplay(this).setCurrent(canvas);
        Thread verifier = new Thread(new Runnable() {
            public void run() {
                try {
                    Thread.sleep(350L);
                    int w = canvas.getWidth();
                    int h = canvas.getHeight();
                    if (w != LOGICAL_W || h != LOGICAL_H) {
                        System.out.println("P6_CANVAS_SIZE=" + w + "x" + h + " RESULT=FAIL");
                        finish(false, "RESOLUTION");
                        return;
                    }
                    System.out.println("P6_CANVAS_SIZE=176x208 RESULT=PASS");
                    finish(true, null);
                } catch (Throwable t) {
                    System.out.println("P6_INTEGRATION_EXCEPTION=" + t.getClass().getName());
                    finish(false, "EXCEPTION");
                }
            }
        });
        verifier.start();
    }

    protected void pauseApp() {
        System.out.println("P6_LIFECYCLE_PAUSE=OBSERVED");
    }

    protected void destroyApp(boolean unconditional) {
        System.out.println("P6_LIFECYCLE_DESTROY=PASS");
    }

    private boolean resourceGate() {
        InputStream in = null;
        try {
            in = getClass().getResourceAsStream("/p6-resource.txt");
            if (in == null) {
                System.out.println("P6_RESOURCE_LOADER=FAIL:MISSING");
                return false;
            }
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[64];
            int n;
            while ((n = in.read(buffer)) >= 0) {
                if (n > 0) out.write(buffer, 0, n);
            }
            String value = new String(out.toByteArray(), "UTF-8").trim();
            if (!"RG35XX_P6_RESOURCE_OK".equals(value)) {
                System.out.println("P6_RESOURCE_LOADER=FAIL:CONTENT");
                return false;
            }
            System.out.println("P6_RESOURCE_LOADER=PASS");
            return true;
        } catch (Throwable t) {
            System.out.println("P6_RESOURCE_LOADER=FAIL:" + t.getClass().getName());
            return false;
        } finally {
            if (in != null) {
                try { in.close(); } catch (Throwable ignored) { }
            }
        }
    }

    private synchronized void finish(boolean pass, String owner) {
        if (finished) return;
        finished = true;
        if (pass) {
            System.out.println("P6_INTEGRATION_RESULT=PASS");
        } else {
            System.out.println("P6_INTEGRATION_RESULT=FAIL:" + owner);
        }
        try {
            destroyApp(true);
        } catch (Throwable ignored) { }
        notifyDestroyed();
    }

    private static final class P6Canvas extends Canvas {
        protected void paint(Graphics g) {
            g.setColor(0x000000);
            g.fillRect(0, 0, getWidth(), getHeight());
            g.setColor(0xFFFFFF);
            g.drawString("RG35XX P6", 2, 2, Graphics.TOP | Graphics.LEFT);
        }
    }
}
