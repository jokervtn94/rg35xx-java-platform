package org.recompile.rg35xx.p1a;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Hashtable;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;

/** Original-RG35XX P1A-G1 copyArea physical platform exerciser; no commercial game. */
public final class RG35XXP1AG1DeviceMIDlet extends MIDlet {
    private Display display;
    private ProbeCanvas canvas;
    private boolean programmaticPass;
    private String failure = "NONE";

    protected void startApp() {
        System.out.println("P1A_G1_DEVICE_BOOT=PASS");
        try {
            Hashtable expected = loadExpected();
            programmaticPass = runVectors(expected);
        } catch (Throwable t) {
            programmaticPass = false;
            failure = t.getClass().getName() + ":" + String.valueOf(t.getMessage());
            System.out.println("P1A_G1_DEVICE_EXCEPTION=" + failure);
        }
        System.out.println("P1A_G1_PROGRAMMATIC=" + (programmaticPass ? "PASS" : "FAIL"));
        display = Display.getDisplay(this);
        canvas = new ProbeCanvas();
        display.setCurrent(canvas);
        canvas.repaint();
        canvas.serviceRepaints();
        System.out.println("P1A_G1_VISUAL_REVIEW=PENDING_HUMAN");
        System.out.println("P1A_G1_DEVICE_PASS=NO_PENDING_PHYSICAL_REVIEW");
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) { }

    private Hashtable loadExpected() throws Exception {
        InputStream in = getClass().getResourceAsStream("/p1a-g1-expected.txt");
        if (in == null) throw new Exception("expected vector resource missing");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[256];
        int n;
        while ((n = in.read(buf)) != -1) out.write(buf, 0, n);
        in.close();
        String text = new String(out.toByteArray(), "UTF-8");
        Hashtable table = new Hashtable();
        int start = 0;
        while (start < text.length()) {
            int end = text.indexOf('\n', start);
            if (end < 0) end = text.length();
            String line = text.substring(start, end).trim();
            if (line.length() > 0 && !line.startsWith("#") && line.indexOf('=') > 0) {
                int eq = line.indexOf('=');
                table.put(line.substring(0, eq), line.substring(eq + 1));
            }
            start = end + 1;
        }
        return table;
    }

    private boolean runVectors(Hashtable expected) {
        boolean pass = true;
        for (int i = 0; i < RG35XXP1AG1Vectors.count(); i++) {
            String name = RG35XXP1AG1Vectors.NAMES[i];
            Object value = expected.get(name);
            if (value == null) {
                pass = false;
                failure = "MISSING_EXPECTED_" + name;
                System.out.println("P1A_G1_DEVICE_CASE=" + name + " RESULT=FAIL REASON=MISSING_EXPECTED");
                continue;
            }
            int wanted = Integer.parseInt((String)value);
            int actual = RG35XXP1AG1Vectors.run(i);
            boolean ok = wanted == actual;
            if (!ok) {
                pass = false;
                failure = "CHECKSUM_" + name;
            }
            System.out.println("P1A_G1_DEVICE_CASE=" + name
                    + " EXPECTED=" + wanted + " ACTUAL=" + actual
                    + " RESULT=" + (ok ? "PASS" : "FAIL"));
        }
        return pass;
    }

    private final class ProbeCanvas extends Canvas {
        ProbeCanvas() { setFullScreenMode(true); }

        protected void paint(Graphics g) {
            int w = getWidth();
            int h = getHeight();
            g.setColor(programmaticPass ? 0x103010 : 0x501010);
            g.fillRect(0, 0, w, h);
            g.setColor(0xFFFFFF);
            g.drawString("P1A G1 COPYAREA TEST", 8, 8, Graphics.LEFT | Graphics.TOP);
            g.drawString(programmaticPass ? "VECTOR CHECK: PASS" : "VECTOR CHECK: FAIL", 8, 28, Graphics.LEFT | Graphics.TOP);

            // Panel A: horizontal/diagonal overlap, directly exercising the aliased path.
            g.setColor(0xD04020); g.fillRect(18, 62, 64, 24);
            g.setColor(0x20A050); g.fillRect(18, 86, 64, 24);
            g.setColor(0x3060D0); g.fillRect(18, 110, 64, 24);
            g.copyArea(18, 62, 64, 72, 38, 86, Graphics.LEFT | Graphics.TOP);
            g.setColor(0xFFFFFF); g.drawRect(17, 61, 85, 97);

            // Panel B: second overlap direction.
            g.setColor(0xD09020); g.fillRect(132, 62, 64, 24);
            g.setColor(0x30A0C0); g.fillRect(132, 86, 64, 24);
            g.setColor(0x9040B0); g.fillRect(132, 110, 64, 24);
            g.copyArea(148, 78, 48, 56, 128, 58, Graphics.LEFT | Graphics.TOP);
            g.setColor(0xFFFFFF); g.drawRect(127, 57, 85, 97);

            // Panel C: destination clip + translate.
            g.setColor(0xC08020); g.fillRect(20, 180, 70, 40);
            g.setClip(110, 178, 70, 46);
            g.translate(8, 5);
            g.copyArea(20, 180, 70, 40, 105, 173, Graphics.LEFT | Graphics.TOP);
            g.translate(-8, -5);
            g.setClip(0, 0, w, h);
            g.setColor(0xFFFFFF); g.drawRect(109, 177, 71, 47);

            g.drawString("3 COPY PANELS MUST BE CLEAN", 8, 238, Graphics.LEFT | Graphics.TOP);
            g.drawString("A = EXIT AFTER VISUAL REVIEW", 8, 258, Graphics.LEFT | Graphics.TOP);
            if (!programmaticPass) g.drawString("FAIL: " + failure, 8, 278, Graphics.LEFT | Graphics.TOP);
            else g.drawString("NO SMEAR / STRAY PIXELS", 8, 278, Graphics.LEFT | Graphics.TOP);
        }

        public void keyPressed(int keyCode) {
            if (getGameAction(keyCode) == FIRE) {
                System.out.println("P1A_G1_HUMAN_EXIT_BUTTON=FIRE");
                System.out.println("P1A_G1_NORMAL_EXIT=PASS");
                System.out.flush();
                System.exit(programmaticPass ? 0 : 2);
            }
        }
    }
}
