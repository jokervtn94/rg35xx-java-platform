import java.io.InputStream;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.midlet.MIDlet;

public final class RG35XXMidiLifecycleDiagnostic extends MIDlet implements Runnable {
    private DiagnosticCanvas canvas;

    protected void startApp() {
        canvas = new DiagnosticCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        new Thread(this, "RG35XXMidiLifecycleDiagnostic").start();
    }
    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    private void phase(String s) {
        System.out.println("MIDI_LIFE_PHASE=" + s);
        if (canvas != null) canvas.setPhase(s);
    }
    private void sleepMs(long ms) throws Exception { Thread.sleep(ms); }
    private InputStream resource(String p) throws Exception {
        InputStream in = getClass().getResourceAsStream(p);
        if (in == null) throw new Exception("resource missing: " + p);
        return in;
    }
    private String mode() throws Exception {
        InputStream in = resource("/mode.txt");
        StringBuffer sb = new StringBuffer();
        int c;
        while ((c = in.read()) != -1) sb.append((char)c);
        in.close();
        return sb.toString().trim();
    }
    private Player openTone() throws Exception {
        Player p = Manager.createPlayer(resource("/tone.mid"), "audio/midi");
        p.realize();
        p.prefetch();
        p.setLoopCount(-1);
        System.out.println("MIDI_LIFE_OPEN=PASS");
        return p;
    }
    private void dispose(Player p) {
        if (p == null) return;
        try { p.stop(); } catch (Throwable ignored) { }
        try { p.deallocate(); } catch (Throwable ignored) { }
        try { p.close(); } catch (Throwable ignored) { }
    }
    private void c0() throws Exception {
        Player p=null;
        try {
            p=openTone(); phase("C0 FIRST PLAY - LISTEN");
            p.start(); System.out.println("MIDI_LIFE_C0_START=PASS");
            sleepMs(4000L);
        } finally { dispose(p); }
    }
    private void c1() throws Exception {
        Player p=null;
        try {
            p=openTone(); phase("C1A SAME PLAYER FIRST");
            p.start(); System.out.println("MIDI_LIFE_C1A_START=PASS"); sleepMs(2500L);
            p.stop(); System.out.println("MIDI_LIFE_C1_STOP=PASS"); sleepMs(1000L);
            phase("C1B SAME PLAYER RESUME");
            p.start(); System.out.println("MIDI_LIFE_C1B_START=PASS"); sleepMs(3500L);
        } finally { dispose(p); }
    }
    private void c2() throws Exception {
        Player p1=null, p2=null;
        try {
            p1=openTone(); phase("C2A BEFORE FREE");
            p1.start(); System.out.println("MIDI_LIFE_C2A_START=PASS"); sleepMs(2500L);
            dispose(p1); p1=null; System.out.println("MIDI_LIFE_C2_FREE=PASS"); sleepMs(1000L);
            p2=openTone(); phase("C2B RELOAD AFTER FREE");
            p2.start(); System.out.println("MIDI_LIFE_C2B_START=PASS"); sleepMs(3500L);
        } finally { dispose(p2); dispose(p1); }
    }
    private void c3() throws Exception {
        Player p1=null, p2=null;
        try {
            p1=openTone(); p2=openTone(); System.out.println("MIDI_LIFE_C3_TWO_PRELOADED=PASS");
            phase("C3A PLAYER ONE");
            p1.start(); System.out.println("MIDI_LIFE_C3A_START=PASS"); sleepMs(2500L);
            dispose(p1); p1=null; System.out.println("MIDI_LIFE_C3_FIRST_FREE=PASS"); sleepMs(1000L);
            phase("C3B PRELOADED PLAYER TWO");
            p2.start(); System.out.println("MIDI_LIFE_C3B_START=PASS"); sleepMs(3500L);
        } finally { dispose(p2); dispose(p1); }
    }
    public void run() {
        try {
            String m=mode();
            System.out.println("MIDI_LIFE_MODE="+m);
            if ("C0".equals(m)) c0();
            else if ("C1".equals(m)) c1();
            else if ("C2".equals(m)) c2();
            else if ("C3".equals(m)) c3();
            else throw new Exception("unknown mode:"+m);
            System.out.println("MIDI_LIFE_PROGRAMMATIC_RESULT=PASS");
        } catch (Throwable t) {
            System.out.println("MIDI_LIFE_PROGRAMMATIC_RESULT=FAIL_EXCEPTION");
            t.printStackTrace();
        } finally {
            phase("DONE - REPORT AUDIBLE PHASES");
            try { sleepMs(1500L); } catch (Throwable ignored) { }
            notifyDestroyed();
        }
    }
    private static final class DiagnosticCanvas extends Canvas {
        private String phase="Starting";
        void setPhase(String s){ phase=s; repaint(); serviceRepaints(); }
        protected void paint(Graphics g){
            int w=getWidth(), h=getHeight();
            g.setColor(0x000000); g.fillRect(0,0,w,h);
            g.setColor(0xFFFFFF);
            g.drawString("MIDI LIFECYCLE",w/2,24,Graphics.TOP|Graphics.HCENTER);
            g.drawString(phase,w/2,h/2,Graphics.BASELINE|Graphics.HCENTER);
            g.drawString("Listen",w/2,h-24,Graphics.BOTTOM|Graphics.HCENTER);
        }
    }
}
