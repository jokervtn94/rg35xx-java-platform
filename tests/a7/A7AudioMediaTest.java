import java.io.InputStream;

import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.media.PlayerListener;
import javax.microedition.media.control.VolumeControl;
import javax.microedition.midlet.MIDlet;

/**
 * One integration-level A7 device test.
 *
 * Uses only standard MMAPI from the canonical Aweigit Java surface:
 * WAV -> volume -> pause/resume -> MIDI -> END_OF_MEDIA -> normal MIDlet exit.
 * Generated media resources contain no commercial/copyrighted game content.
 */
public final class A7AudioMediaTest extends MIDlet implements Runnable, PlayerListener {
    private volatile boolean midiEnded;
    private volatile boolean failed;

    protected void startApp() {
        System.out.println("A7_TEST_BOOT=PASS");
        Thread t = new Thread(this, "A7AudioMediaTest");
        t.start();
    }

    protected void pauseApp() {
    }

    protected void destroyApp(boolean unconditional) {
    }

    public void playerUpdate(Player player, String event, Object eventData) {
        System.out.println("A7_TEST_PLAYER_EVENT=" + event);
        if (PlayerListener.END_OF_MEDIA.equals(event)) {
            midiEnded = true;
            System.out.println("A7_TEST_MIDI_END_OF_MEDIA=PASS");
        }
        if (PlayerListener.ERROR.equals(event)) {
            failed = true;
            System.out.println("A7_TEST_PLAYER_ERROR=FAIL");
        }
    }

    private void sleepMs(long ms) throws Exception {
        Thread.sleep(ms);
    }

    private InputStream resource(String path) throws Exception {
        InputStream in = getClass().getResourceAsStream(path);
        if (in == null) throw new Exception("resource missing: " + path);
        return in;
    }

    private void testWav() throws Exception {
        Player wav = null;
        try {
            wav = Manager.createPlayer(resource("/a7-test.wav"), "audio/x-wav");
            System.out.println("A7_TEST_WAV_CREATE=PASS");
            wav.addPlayerListener(this);
            wav.realize();
            wav.prefetch();

            VolumeControl vc = (VolumeControl) wav.getControl("VolumeControl");
            if (vc != null) {
                int level = vc.setLevel(45);
                System.out.println("A7_TEST_VOLUME=PASS LEVEL=" + level);
            } else {
                System.out.println("A7_TEST_VOLUME=UNAVAILABLE_CANONICAL");
            }

            wav.setLoopCount(1);
            wav.start();
            System.out.println("A7_TEST_WAV_START=PASS");
            sleepMs(700);

            wav.stop();
            System.out.println("A7_TEST_WAV_PAUSE=PASS");
            sleepMs(350);

            wav.start();
            System.out.println("A7_TEST_WAV_RESUME=PASS");
            sleepMs(900);

            wav.stop();
            System.out.println("A7_TEST_WAV_PAUSE_RESUME=PASS");
        } finally {
            if (wav != null) {
                try { wav.deallocate(); } catch (Throwable ignored) { }
                try { wav.close(); } catch (Throwable ignored) { }
            }
        }
    }

    private void testMidi() throws Exception {
        Player midi = null;
        midiEnded = false;
        try {
            midi = Manager.createPlayer(resource("/a7-test.mid"), "audio/midi");
            System.out.println("A7_TEST_MIDI_CREATE=PASS");
            midi.addPlayerListener(this);
            midi.realize();
            midi.prefetch();
            midi.start();
            System.out.println("A7_TEST_MIDI_START=PASS");

            long deadline = System.currentTimeMillis() + 6000L;
            while (!midiEnded && System.currentTimeMillis() < deadline) {
                sleepMs(100);
            }
            if (!midiEnded) {
                failed = true;
                System.out.println("A7_TEST_MIDI_END_OF_MEDIA=FAIL_TIMEOUT");
            }
        } finally {
            if (midi != null) {
                try { midi.deallocate(); } catch (Throwable ignored) { }
                try { midi.close(); } catch (Throwable ignored) { }
            }
        }
    }

    public void run() {
        try {
            System.out.println("A7_TEST_SCOPE=WAV,MIDI,PAUSE_RESUME,VOLUME,END_OF_MEDIA,NORMAL_EXIT");
            System.out.println("A7_TEST_PLAYTONE=EXCLUDED_CANONICAL_NOOP");
            testWav();
            testMidi();
            if (!failed) {
                System.out.println("A7_TEST_RESULT=PASS");
            } else {
                System.out.println("A7_TEST_RESULT=FAIL");
            }
        } catch (Throwable t) {
            failed = true;
            System.out.println("A7_TEST_RESULT=FAIL_EXCEPTION");
            t.printStackTrace();
        } finally {
            System.out.println("A7_TEST_NORMAL_EXIT=BEGIN");
            notifyDestroyed();
        }
    }
}
