import java.io.File;
import java.io.FileOutputStream;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;

public final class RG35XXBootProbe extends MIDlet {
    private static final String DIR = "/mnt/mmc/Java/test-evidence";
    private static final String LOG = DIR + "/rg35xx-boot-probe.log";
    private ProbeCanvas canvas;

    protected void startApp() {
        log("startApp ENTER");
        try {
            canvas = new ProbeCanvas(this);
            log("canvas constructed");
            Display.getDisplay(this).setCurrent(canvas);
            log("setCurrent done");
            canvas.start();
            log("loop started");
        } catch (Throwable t) {
            log("startApp FAIL " + t.getClass().getName() + ": " + t.getMessage());
        }
    }
    protected void pauseApp() { log("pauseApp"); }
    protected void destroyApp(boolean unconditional) { log("destroyApp"); }
    void exit() { log("exit"); notifyDestroyed(); }

    static void log(String s) {
        FileOutputStream out = null;
        try {
            File d = new File(DIR); if (!d.exists()) d.mkdirs();
            out = new FileOutputStream(LOG, true);
            out.write((System.currentTimeMillis()+" "+s+"\n").getBytes("UTF-8"));
            out.flush();
        } catch (Throwable ignored) {
        } finally {
            if (out != null) try { out.close(); } catch (Throwable ignored) {}
        }
    }

    static final class ProbeCanvas extends Canvas implements Runnable {
        private final RG35XXBootProbe midlet;
        private Thread thread;
        private int tick;
        ProbeCanvas(RG35XXBootProbe m) { midlet=m; setFullScreenMode(true); }
        void start() { if (thread==null) { thread=new Thread(this,"RG35XXBootProbe"); thread.start(); } }
        public void run() {
            log("render thread ENTER");
            while (thread==Thread.currentThread()) {
                tick++;
                repaint(); serviceRepaints();
                if (tick==1 || tick==10 || tick==50) log("render tick="+tick+" size="+getWidth()+"x"+getHeight());
                try { Thread.sleep(100); } catch (InterruptedException e) {}
            }
        }
        protected void paint(Graphics g) {
            int w=getWidth(), h=getHeight();
            g.setClip(0,0,w,h);
            if ((tick & 1)==0) g.setColor(0x0044CC); else g.setColor(0x00AA44);
            g.fillRect(0,0,w,h);
            g.setColor(0xFFFFFF);
            int bar = 20 + (tick % 20) * Math.max(1,(w-40)/20);
            g.fillRect(20,h/2-12,Math.min(w-40,bar),24);
            g.setColor(0xFF3300);
            g.fillRect(0,0,40,40);
        }
        public void keyPressed(int keyCode) { log("keyPressed="+keyCode); if (keyCode==KEY_NUM0) midlet.exit(); }
    }
}
