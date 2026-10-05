import java.io.InputStream;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.media.PlayerListener;
import javax.microedition.midlet.MIDlet;

public final class RG35XXAudioBoundaryDiagnostic extends MIDlet implements Runnable, PlayerListener {
    private DiagnosticCanvas canvas;
    private volatile boolean failed;

    protected void startApp() {
        canvas = new DiagnosticCanvas();
        Display.getDisplay(this).setCurrent(canvas);
        new Thread(this, "RG35XXAudioBoundaryDiagnostic").start();
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    public void playerUpdate(Player player, String event, Object eventData) {
        System.out.println("AUDIO_DIAG_PLAYER_EVENT=" + event + " STATE=" + player.getState());
    }

    private void phase(String text) {
        System.out.println("AUDIO_DIAG_PHASE=" + text);
        if (canvas != null) canvas.setPhase(text);
    }

    private void sleepMs(long ms) throws Exception { Thread.sleep(ms); }

    private InputStream resource(String name) throws Exception {
        InputStream in = getClass().getResourceAsStream(name);
        if (in == null) throw new Exception("resource missing: " + name);
        return in;
    }

    private Player openMidi(String name, int loops) throws Exception {
        Player p = Manager.createPlayer(resource(name), "audio/midi");
        p.addPlayerListener(this);
        p.realize();
        p.prefetch();
        p.setLoopCount(loops);
        System.out.println("AUDIO_DIAG_OPEN=PASS RESOURCE=" + name + " LOOPS=" + loops);
        return p;
    }

    private void closePlayer(Player p) {
        if (p == null) return;
        try { p.stop(); } catch (Throwable ignored) { }
        try { p.deallocate(); } catch (Throwable ignored) { }
        try { p.close(); } catch (Throwable ignored) { }
    }

    private void testComplexMidi() throws Exception {
        Player complex = null;
        try {
            phase("A COMPLEX MIDI - LISTEN 6 SEC");
            complex = openMidi("/diag-complex-format1.mid", 1);
            complex.start();
            System.out.println("AUDIO_DIAG_A_COMPLEX_START=PASS");
            sleepMs(6000L);
            complex.stop();
            System.out.println("AUDIO_DIAG_A_COMPLEX_STOP=PASS");
        } finally {
            closePlayer(complex);
        }
        phase("A DONE - 2 SEC SILENCE");
        sleepMs(2000L);
    }

    private void testMultiPlayerLifecycle() throws Exception {
        Player bgm = null;
        Player fx = null;
        try {
            bgm = openMidi("/diag-bgm-loop.mid", -1);
            fx = openMidi("/diag-fx-silent-tail.mid", 1);

            phase("B1 LOW BGM - LISTEN 4 SEC");
            bgm.start();
            System.out.println("AUDIO_DIAG_B1_BGM_START=PASS");
            sleepMs(4000L);

            bgm.stop();
            System.out.println("AUDIO_DIAG_B1_BGM_STOP=PASS STATE=" + bgm.getState());
            sleepMs(500L);

            phase("B2 HIGH FX THEN SILENCE");
            fx.start();
            System.out.println("AUDIO_DIAG_B2_FX_START=PASS");
            sleepMs(1400L);
            fx.stop();
            System.out.println("AUDIO_DIAG_B2_FX_STOP=PASS STATE=" + fx.getState());
            sleepMs(500L);

            long rewind = bgm.setMediaTime(0L);
            System.out.println("AUDIO_DIAG_B3_SET_MEDIA_TIME_RETURN=" + rewind);
            phase("B3 LOW BGM MUST RETURN - LISTEN 5 SEC");
            bgm.start();
            System.out.println("AUDIO_DIAG_B3_BGM_RESTART=PASS STATE=" + bgm.getState());
            sleepMs(5000L);
            bgm.stop();
            System.out.println("AUDIO_DIAG_B3_BGM_STOP=PASS");
        } finally {
            closePlayer(fx);
            closePlayer(bgm);
        }
    }

    public void run() {
        try {
            System.out.println("AUDIO_DIAG_SCOPE=GENERIC_COMPLEX_MIDI_PLUS_MULTI_PLAYER_LIFECYCLE");
            System.out.println("AUDIO_DIAG_GAME_SPECIFIC_CODE=NO");
            testComplexMidi();
            testMultiPlayerLifecycle();
            if (!failed) System.out.println("AUDIO_DIAG_PROGRAMMATIC_RESULT=PASS");
        } catch (Throwable t) {
            failed = true;
            System.out.println("AUDIO_DIAG_PROGRAMMATIC_RESULT=FAIL_EXCEPTION");
            t.printStackTrace();
        } finally {
            phase("DONE - REPORT A, B1, B2, B3 AUDIO");
            System.out.println("AUDIO_DIAG_PHYSICAL_REVIEW_REQUIRED=A_COMPLEX+B1_BGM+B2_FX+B3_BGM_RETURN");
            try { sleepMs(2500L); } catch (Throwable ignored) { }
            notifyDestroyed();
        }
    }

    private static final class DiagnosticCanvas extends Canvas {
        private String phase = "Audio diagnostic starting";
        void setPhase(String p) { phase = p; repaint(); serviceRepaints(); }
        protected void paint(Graphics g) {
            int w = getWidth();
            int h = getHeight();
            g.setColor(0x000000);
            g.fillRect(0, 0, w, h);
            g.setColor(0xFFFFFF);
            g.drawString("RG35XX AUDIO BOUNDARY", w / 2, 24, Graphics.TOP | Graphics.HCENTER);
            g.drawString(phase, w / 2, h / 2, Graphics.BASELINE | Graphics.HCENTER);
            g.drawString("Listen and report phase result", w / 2, h - 24, Graphics.BOTTOM | Graphics.HCENTER);
        }
    }
}
