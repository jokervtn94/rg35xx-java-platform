package org.recompile.rg35xx.p3;

import java.io.InputStream;
import java.io.OutputStream;

import javax.microedition.io.Connector;
import javax.microedition.io.file.FileConnection;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.media.PlayerListener;
import javax.microedition.media.control.VolumeControl;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.RecordEnumeration;
import javax.microedition.rms.RecordStore;
import javax.microedition.rms.RecordStoreNotFoundException;

/** One public-MIDP module test for the P3 runtime-service boundary. */
public final class RG35XXP3RuntimeServiceExerciser extends MIDlet
        implements Runnable, PlayerListener {
    private static final String STORE = "P3_RUNTIME_SERVICE";
    private static final String FILE_URL = "file:///mnt/RG35XX-P3-RUNTIME-SERVICE.TEST";
    private static final byte[] RMS_MARKER = new byte[] { 7, 3, 5, 2 };
    private static final byte[] FILE_MARKER = new byte[] { 3, 5, 7, 2, 0x35 };

    private P3Canvas canvas;
    private volatile boolean failed;
    private volatile boolean midiEnded;

    protected void startApp() {
        System.out.println("P3_TEST_BOOT=PASS");
        canvas = new P3Canvas();
        Display.getDisplay(this).setCurrent(canvas);
        Thread worker = new Thread(this, "RG35XXP3RuntimeServiceExerciser");
        worker.start();
    }

    protected void pauseApp() {
        System.out.println("P3_TEST_PAUSE_CALLBACK=PASS");
    }

    protected void destroyApp(boolean unconditional) {
        System.out.println("P3_TEST_DESTROY_CALLBACK=PASS");
    }

    public void playerUpdate(Player player, String event, Object eventData) {
        if (PlayerListener.END_OF_MEDIA.equals(event)) {
            midiEnded = true;
            System.out.println("P3_MMAPI_MIDI_END_OF_MEDIA=PASS");
        } else if (PlayerListener.ERROR.equals(event)) {
            failed = true;
            System.out.println("P3_MMAPI_PLAYER_EVENT=FAIL_ERROR");
        }
    }

    private void mark(String text) {
        System.out.println(text);
        if (canvas != null) {
            canvas.setStatus(text);
        }
    }

    private void require(boolean condition, String name) throws Exception {
        if (!condition) {
            failed = true;
            throw new Exception(name);
        }
    }

    private boolean same(byte[] a, byte[] b) {
        if (a == null || b == null || a.length != b.length) return false;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    private void sleepMs(long millis) throws Exception {
        Thread.sleep(millis);
    }

    private InputStream resource(String name) throws Exception {
        InputStream in = getClass().getResourceAsStream(name);
        if (in == null) throw new Exception("resource-missing:" + name);
        return in;
    }

    private void testRms() throws Exception {
        try {
            RecordStore.deleteRecordStore(STORE);
        } catch (RecordStoreNotFoundException ignored) {
        }
        RecordStore store = RecordStore.openRecordStore(STORE, true);
        try {
            int id = store.addRecord(RMS_MARKER, 0, RMS_MARKER.length);
            require(same(RMS_MARKER, store.getRecord(id)), "rms-read");
            byte[] updated = new byte[] { 9, 8, 7, 6, 5 };
            store.setRecord(id, updated, 0, updated.length);
            require(same(updated, store.getRecord(id)), "rms-update");
            RecordEnumeration enumeration = store.enumerateRecords(null, null, false);
            require(enumeration.numRecords() == 1, "rms-enumeration");
            enumeration.destroy();
            mark("P3_RMS_CRUD_ENUMERATE=PASS");
        } finally {
            store.closeRecordStore();
        }

        RecordStore reopened = RecordStore.openRecordStore(STORE, false);
        require(reopened.getNumRecords() == 1, "rms-reopen");
        reopened.closeRecordStore();
        RecordStore.deleteRecordStore(STORE);
        try {
            RecordStore.openRecordStore(STORE, false);
            throw new Exception("rms-delete");
        } catch (RecordStoreNotFoundException expected) {
            mark("P3_RMS_REOPEN_DELETE=PASS");
        }
    }

    private void testFileConnection() throws Exception {
        FileConnection connection = null;
        try {
            connection = (FileConnection) Connector.open(FILE_URL, Connector.READ_WRITE);
            if (connection.exists()) connection.delete();
            connection.create();
            OutputStream out = connection.openOutputStream();
            out.write(FILE_MARKER);
            out.close();
            connection.close();
            connection = null;

            connection = (FileConnection) Connector.open(FILE_URL, Connector.READ_WRITE);
            require(connection.exists(), "file-exists");
            require(connection.fileSize() == FILE_MARKER.length, "file-size");
            InputStream in = connection.openInputStream();
            byte[] read = new byte[FILE_MARKER.length];
            int offset = 0;
            while (offset < read.length) {
                int count = in.read(read, offset, read.length - offset);
                if (count < 0) break;
                offset += count;
            }
            in.close();
            require(same(FILE_MARKER, read), "file-read");
            connection.delete();
            require(!connection.exists(), "file-delete");
            mark("P3_FILE_CREATE_WRITE_READ_DELETE=PASS");
        } finally {
            if (connection != null) {
                try { if (connection.exists()) connection.delete(); } catch (Throwable ignored) { }
                try { connection.close(); } catch (Throwable ignored) { }
            }
        }
    }

    private void testWav() throws Exception {
        Player player = null;
        try {
            player = Manager.createPlayer(resource("/p3-test.wav"), "audio/x-wav");
            player.addPlayerListener(this);
            player.realize();
            player.prefetch();
            VolumeControl volume = (VolumeControl) player.getControl("VolumeControl");
            if (volume != null) volume.setLevel(45);
            player.start();
            mark("P3_MMAPI_WAV_START=PASS");
            sleepMs(650);
            player.stop();
            sleepMs(250);
            player.start();
            sleepMs(650);
            player.stop();
            mark("P3_MMAPI_WAV_PAUSE_RESUME=PASS");
        } finally {
            if (player != null) {
                try { player.deallocate(); } catch (Throwable ignored) { }
                try { player.close(); } catch (Throwable ignored) { }
            }
        }
    }

    private void testMidi() throws Exception {
        Player player = null;
        midiEnded = false;
        try {
            player = Manager.createPlayer(resource("/p3-test.mid"), "audio/midi");
            player.addPlayerListener(this);
            player.realize();
            player.prefetch();
            player.start();
            mark("P3_MMAPI_MIDI_START=PASS");
            long deadline = System.currentTimeMillis() + 6000L;
            while (!midiEnded && System.currentTimeMillis() < deadline) sleepMs(100);
            require(midiEnded, "midi-end-of-media-timeout");
        } finally {
            if (player != null) {
                try { player.deallocate(); } catch (Throwable ignored) { }
                try { player.close(); } catch (Throwable ignored) { }
            }
        }
    }

    public void run() {
        try {
            mark("P3_TEST_SCOPE=LIFECYCLE,RMS,FILECONNECTION,WAV,MIDI");
            testRms();
            testFileConnection();
            testWav();
            testMidi();
            if (!failed) mark("P3_RUNTIME_SERVICE_RESULT=PASS");
        } catch (Throwable error) {
            failed = true;
            System.out.println("P3_RUNTIME_SERVICE_RESULT=FAIL_EXCEPTION");
            error.printStackTrace();
            if (canvas != null) canvas.setStatus("P3_RUNTIME_SERVICE_RESULT=FAIL");
        } finally {
            System.out.println("P3_AUDIO_AUDIBLE_REVIEW=REQUIRED_MANUAL");
            System.out.println("P3_TEST_NORMAL_EXIT=BEGIN");
            notifyDestroyed();
        }
    }

    private final class P3Canvas extends Canvas {
        private String status = "P3_TEST_BOOT=PASS";

        void setStatus(String value) {
            status = value;
            repaint();
        }

        protected void paint(Graphics graphics) {
            graphics.setColor(0x000000);
            graphics.fillRect(0, 0, getWidth(), getHeight());
            graphics.setColor(failed ? 0xFF4040 : 0x80FF80);
            graphics.drawString(status, 4, 4, Graphics.TOP | Graphics.LEFT);
        }
    }
}
