import java.io.InputStream;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.midlet.MIDlet;

public final class RG35XXMidiOwnershipDiagnostic extends MIDlet implements Runnable {
    private DiagnosticCanvas canvas;

    protected void startApp() {
        canvas = new DiagnosticCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        new Thread(this, "RG35XXMidiOwnershipDiagnostic").start();
    }
    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    private void phase(String s) {
        System.out.println("MIDI_OWNER_PHASE=" + s);
        if (canvas != null) canvas.setPhase(s);
    }
    private void sleepMs(long ms) throws Exception { Thread.sleep(ms); }
    private InputStream resource(String p) throws Exception {
        InputStream in = getClass().getResourceAsStream(p);
        if (in == null) throw new Exception("resource missing: " + p);
        return in;
    }
    private Player open(String path) throws Exception {
        Player p = Manager.createPlayer(resource(path), "audio/midi");
        p.realize(); p.prefetch(); p.setLoopCount(-1);
        System.out.println("MIDI_OWNER_OPEN=PASS RESOURCE=" + path);
        return p;
    }
    private void dispose(Player p) {
        if (p == null) return;
        try { p.stop(); } catch (Throwable ignored) { }
        try { p.deallocate(); } catch (Throwable ignored) { }
        try { p.close(); } catch (Throwable ignored) { }
    }

    public void run() {
        Player a=null, b=null;
        try {
            System.out.println("MIDI_OWNER_SCOPE=GENERIC_TWO_PLAYER_A_TO_B_TO_A");
            System.out.println("MIDI_OWNER_GAME_SPECIFIC_CODE=NO");
            a=open("/owner-a-low.mid");
            b=open("/owner-b-high.mid");
            System.out.println("MIDI_OWNER_TWO_PRELOADED=PASS");

            phase("A1 LOW TONE - LISTEN 3 SEC");
            a.start(); System.out.println("MIDI_OWNER_A1_START=PASS"); sleepMs(3000L);
            a.stop(); System.out.println("MIDI_OWNER_A1_STOP=PASS"); sleepMs(600L);

            phase("B HIGH TONE - LISTEN 3 SEC");
            b.start(); System.out.println("MIDI_OWNER_B_START=PASS"); sleepMs(3000L);
            b.stop(); System.out.println("MIDI_OWNER_B_STOP=PASS"); sleepMs(600L);

            a.setMediaTime(0L);
            phase("A2 LOW TONE MUST RETURN - LISTEN 4 SEC");
            a.start(); System.out.println("MIDI_OWNER_A2_RETURN_START=PASS"); sleepMs(4000L);
            a.stop(); System.out.println("MIDI_OWNER_A2_STOP=PASS");
            System.out.println("MIDI_OWNER_PROGRAMMATIC_RESULT=PASS");
        } catch (Throwable t) {
            System.out.println("MIDI_OWNER_PROGRAMMATIC_RESULT=FAIL_EXCEPTION");
            t.printStackTrace();
        } finally {
            dispose(b); dispose(a);
            phase("DONE - REPORT A1 LOW, B HIGH, A2 LOW");
            System.out.println("MIDI_OWNER_PHYSICAL_REVIEW_REQUIRED=A1_LOW+B_HIGH+A2_LOW_RETURN");
            try { sleepMs(1800L); } catch (Throwable ignored) { }
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
            g.drawString("MIDI OWNER R5",w/2,24,Graphics.TOP|Graphics.HCENTER);
            g.drawString(phase,w/2,h/2,Graphics.BASELINE|Graphics.HCENTER);
            g.drawString("A=LOW / B=HIGH",w/2,h-24,Graphics.BOTTOM|Graphics.HCENTER);
        }
    }
}
