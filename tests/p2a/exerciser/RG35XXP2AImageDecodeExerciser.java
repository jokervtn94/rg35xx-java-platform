import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.midlet.MIDlet;
import javax.microedition.midlet.MIDletStateChangeException;

/**
 * Generated/non-commercial P2A image-decode module exerciser.
 *
 * Each build creates 150 PNG fixtures covering all legal PNG color-type / bit
 * depth combinations, both non-interlaced and Adam7, and filter types 0..4.
 * The fixture expected table is produced by pinned JDK8 ImageIO at build time.
 *
 * Every fixture is decoded through all three canonical MIDP Image frontends:
 * byte[], InputStream, and resource-name. The exerciser never calls the RG35XX
 * decoder helper directly. Any key exits only after the complete module run.
 */
public final class RG35XXP2AImageDecodeExerciser extends MIDlet {
    private P2ACanvas canvas;

    protected void startApp() throws MIDletStateChangeException {
        if (canvas == null) {
            canvas = new P2ACanvas(this);
            Display.getDisplay(this).setCurrent(canvas);
            canvas.startTests();
        } else {
            Display.getDisplay(this).setCurrent(canvas);
        }
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) throws MIDletStateChangeException { }

    private static final class P2ACanvas extends Canvas implements Runnable {
        private static final int FIXTURES = 150;
        private static final int FRONTENDS = 3;
        private static final int EXPECTED_DECODES = FIXTURES * FRONTENDS;
        private static final int BG = 0x00101820;
        private static final int PASS = 0x0000A840;
        private static final int FAIL = 0x00B02030;
        private static final int TEXT = 0x00FFFFFF;

        private final RG35XXP2AImageDecodeExerciser app;
        private final String[] names = new String[FIXTURES];
        private final int[] widths = new int[FIXTURES];
        private final int[] heights = new int[FIXTURES];
        private final int[] hashA = new int[FIXTURES];
        private final int[] hashB = new int[FIXTURES];

        private volatile int fixtureDone;
        private volatile int decodeDone;
        private volatile int failureCount;
        private volatile boolean finished;
        private volatile boolean overall;
        private String firstFailure = "NONE";
        private Thread worker;

        P2ACanvas(RG35XXP2AImageDecodeExerciser owner) {
            app = owner;
            setFullScreenMode(true);
            overall = true;
            System.out.println("P2A_EXERCISER_BOOT=PASS");
        }

        void startTests() {
            if (worker == null) {
                worker = new Thread(this, "P2A-image-decode");
                worker.start();
            }
        }

        public void run() {
            try {
                loadExpected();
                System.out.println("P2A_EXERCISER_EXPECTED_TABLE=PASS");
                for (int i = 0; i < FIXTURES; i++) {
                    runFixture(i);
                    fixtureDone = i + 1;
                    if ((fixtureDone % 5) == 0 || fixtureDone == FIXTURES) {
                        repaint();
                        serviceRepaints();
                        Thread.yield();
                    }
                }
            } catch (Throwable t) {
                failGlobal("HARNESS", t);
            }
            finished = true;
            overall = failureCount == 0 && fixtureDone == FIXTURES && decodeDone == EXPECTED_DECODES;
            System.out.println("P2A_EXERCISER_FIXTURE_COUNT=" + fixtureDone);
            System.out.println("P2A_EXERCISER_FRONTEND_COUNT=" + FRONTENDS);
            System.out.println("P2A_EXERCISER_DECODE_COUNT=" + decodeDone);
            System.out.println("P2A_EXERCISER_FAILURE_COUNT=" + failureCount);
            System.out.println("P2A_EXERCISER_RESULT=" + (overall ? "PASS" : "FAIL"));
            repaint();
            serviceRepaints();
        }

        private void loadExpected() throws Exception {
            InputStream in = resource("/p2a/expected.tsv");
            BufferedReader br = new BufferedReader(new InputStreamReader(in, "UTF-8"));
            int count = 0;
            String line;
            while ((line = br.readLine()) != null) {
                if (line.length() == 0 || line.charAt(0) == '#') continue;
                if (count >= FIXTURES) throw new IOException("too many expected rows");
                String[] p = split5(line);
                String expectedName = fixtureName(count);
                if (!expectedName.equals(p[0])) throw new IOException("expected order " + count + " got " + p[0]);
                names[count] = p[0];
                widths[count] = Integer.parseInt(p[1]);
                heights[count] = Integer.parseInt(p[2]);
                hashA[count] = (int)Long.parseLong(p[3], 16);
                hashB[count] = (int)Long.parseLong(p[4], 16);
                count++;
            }
            br.close();
            if (count != FIXTURES) throw new IOException("expected row count " + count);
        }

        private void runFixture(int i) {
            String path = "/p2a/" + names[i];
            try {
                byte[] bytes = readAll(resource(path));
                validate("BYTES", i, Image.createImage(bytes, 0, bytes.length));
            } catch (Throwable t) {
                failCase(i, "BYTES", t);
            }

            try {
                InputStream in = resource(path);
                Image img = Image.createImage(in);
                try { in.close(); } catch (Throwable ignored) { }
                validate("STREAM", i, img);
            } catch (Throwable t) {
                failCase(i, "STREAM", t);
            }

            try {
                validate("RESOURCE", i, Image.createImage(path));
            } catch (Throwable t) {
                failCase(i, "RESOURCE", t);
            }
        }

        private void validate(String frontend, int i, Image image) throws Exception {
            if (image == null) throw new IOException("null image");
            int w = image.getWidth();
            int h = image.getHeight();
            if (w != widths[i] || h != heights[i]) {
                throw new IOException("size " + w + "x" + h + " expected " + widths[i] + "x" + heights[i]);
            }
            int[] pixels = new int[w * h];
            image.getRGB(pixels, 0, w, 0, 0, w, h);
            int a = hash1(pixels);
            int b = hash2(pixels);
            if (a != hashA[i] || b != hashB[i]) {
                throw new IOException("pixel hash " + hex(a) + "/" + hex(b) +
                    " expected " + hex(hashA[i]) + "/" + hex(hashB[i]));
            }
            decodeDone++;
            System.out.println("P2A_EXERCISER_CASE=" + names[i] + " FRONTEND=" + frontend +
                " RESULT=PASS HASH=" + hex(a) + "/" + hex(b));
        }

        private void failCase(int i, String frontend, Throwable t) {
            decodeDone++;
            failureCount++;
            overall = false;
            String detail = names[i] + ":" + frontend + ":" + t.getClass().getName() + ":" + String.valueOf(t.getMessage());
            if ("NONE".equals(firstFailure)) firstFailure = detail;
            System.out.println("P2A_EXERCISER_CASE=" + names[i] + " FRONTEND=" + frontend + " RESULT=FAIL DETAIL=" + detail);
        }

        private void failGlobal(String where, Throwable t) {
            failureCount++;
            overall = false;
            if ("NONE".equals(firstFailure)) firstFailure = where + ":" + t.getClass().getName() + ":" + String.valueOf(t.getMessage());
            System.out.println("P2A_EXERCISER_GLOBAL_FAIL=" + firstFailure);
        }

        private InputStream resource(String path) throws IOException {
            InputStream in = getClass().getResourceAsStream(path);
            if (in == null) throw new IOException("missing resource " + path);
            return in;
        }

        private static byte[] readAll(InputStream in) throws IOException {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[1024];
            int n;
            try {
                while ((n = in.read(buf)) >= 0) {
                    if (n > 0) out.write(buf, 0, n);
                }
            } finally {
                try { in.close(); } catch (Throwable ignored) { }
            }
            return out.toByteArray();
        }

        private static String[] split5(String line) throws IOException {
            String[] out = new String[5];
            int start = 0;
            for (int i = 0; i < 4; i++) {
                int tab = line.indexOf('\t', start);
                if (tab < 0) throw new IOException("bad expected row " + line);
                out[i] = line.substring(start, tab);
                start = tab + 1;
            }
            out[4] = line.substring(start);
            return out;
        }

        private static String fixtureName(int index) {
            if (index < 10) return "f00" + index + ".png";
            if (index < 100) return "f0" + index + ".png";
            return "f" + index + ".png";
        }

        private static int hash1(int[] pixels) {
            int h = 0x13579BDF;
            for (int i = 0; i < pixels.length; i++) h = h * 33 + pixels[i];
            return h;
        }

        private static int hash2(int[] pixels) {
            int h = 0x2468ACE0;
            for (int i = 0; i < pixels.length; i++) {
                int p = pixels[i];
                h = h * 65599 + (p ^ (p >>> 16));
            }
            return h;
        }

        private static String hex(int v) {
            String s = Integer.toHexString(v);
            StringBuffer b = new StringBuffer(8);
            for (int i = s.length(); i < 8; i++) b.append('0');
            b.append(s);
            return b.toString();
        }

        protected void paint(Graphics g) {
            int w = getWidth();
            int h = getHeight();
            g.setColor(finished ? (overall ? PASS : FAIL) : BG);
            g.fillRect(0, 0, w, h);
            g.setColor(TEXT);
            g.drawString("P2A IMAGE DECODE", w / 2, 18, Graphics.HCENTER | Graphics.TOP);
            if (!finished) {
                g.drawString("RUNNING " + fixtureDone + "/" + FIXTURES, w / 2, 55, Graphics.HCENTER | Graphics.TOP);
                g.drawString("DECODE " + decodeDone + "/" + EXPECTED_DECODES, w / 2, 78, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Do not exit", w / 2, 108, Graphics.HCENTER | Graphics.TOP);
            } else if (overall) {
                g.drawString("PASS", w / 2, 58, Graphics.HCENTER | Graphics.TOP);
                g.drawString("150 PNG / 450 frontend decodes", w / 2, 88, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Press any key to return", w / 2, 118, Graphics.HCENTER | Graphics.TOP);
            } else {
                g.drawString("FAIL", w / 2, 58, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Failures: " + failureCount, w / 2, 88, Graphics.HCENTER | Graphics.TOP);
                g.drawString("See evidence log", w / 2, 118, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Press any key to return", w / 2, 148, Graphics.HCENTER | Graphics.TOP);
            }
        }

        public void keyPressed(int keyCode) {
            if (!finished) {
                System.out.println("P2A_EXERCISER_EXIT_IGNORED=TEST_IN_PROGRESS");
                return;
            }
            System.out.println("P2A_EXERCISER_EXIT_REQUEST=PASS");
            app.notifyDestroyed();
        }
    }
}
