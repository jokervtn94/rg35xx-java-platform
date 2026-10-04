package org.recompile.rg35xx;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;

import org.recompile.mobile.Mobile;
import org.recompile.mobile.MobilePlatform;

public final class RG35XXP2CFrontendHostGate {
    private static final List<String> events = new ArrayList<String>();

    private static final class CaptureCanvas extends Canvas {
        protected void paint(Graphics g) { }
        public void keyPressed(int keyCode) { events.add("KP:" + keyCode); }
        public void keyReleased(int keyCode) { events.add("KR:" + keyCode); }
        public void keyRepeated(int keyCode) { events.add("KT:" + keyCode); }
        public void pointerPressed(int x, int y) { events.add("PP:" + x + "," + y); }
        public void pointerReleased(int x, int y) { events.add("PR:" + x + "," + y); }
    }

    public static void main(String[] args) {
        try {
            File root = new File("build/p2c-host-gate").getAbsoluteFile();
            deleteTree(root);
            root.mkdirs();

            MobilePlatform platform = new MobilePlatform(240, 320);
            Mobile.setPlatform(platform);
            Display display = new Display();
            CaptureCanvas canvas = new CaptureCanvas();
            display.setCurrent(canvas);

            testDefaultAndModes(platform, root);
            testCustomKeymap(platform, root);
            testDispatcherHotkeys(platform, root);
            testPointerAndRotation(platform, root);

            System.out.println("P2C_HOST_DEFAULT_MAPPING_GATE=PASS");
            System.out.println("P2C_HOST_PHONE_MODE_GATE=PASS");
            System.out.println("P2C_HOST_KEYMAP_CFG_GATE=PASS");
            System.out.println("P2C_HOST_HOTKEY_GATE=PASS");
            System.out.println("P2C_HOST_POINTER_GATE=PASS");
            System.out.println("P2C_HOST_ROTATION_GATE=PASS");
            System.out.println("P2C_FRONTEND_HOST_GATE=PASS");
            System.exit(0);
        } catch (Throwable t) {
            t.printStackTrace();
            System.out.println("P2C_FRONTEND_HOST_GATE=FAIL");
            System.exit(1);
        }
    }

    private static void testDefaultAndModes(MobilePlatform platform, File root) throws Exception {
        File dir = new File(root, "default"); dir.mkdirs();
        RG35XXFrontendPolicy p = new RG35XXFrontendPolicy(platform, dir, dir, "Default.jar", 240, 320);
        eq('p', p.getPhoneMode(), "default phone mode");
        int[][] expected = new int[][] {
            {RG35XXKeyDispatcher.UP, Mobile.KEY_NUM2},
            {RG35XXKeyDispatcher.DOWN, Mobile.KEY_NUM8},
            {RG35XXKeyDispatcher.LEFT, Mobile.KEY_NUM4},
            {RG35XXKeyDispatcher.RIGHT, Mobile.KEY_NUM6},
            {RG35XXKeyDispatcher.Y, Mobile.NOKIA_SOFT1},
            {RG35XXKeyDispatcher.A, Mobile.NOKIA_SOFT2},
            {RG35XXKeyDispatcher.X, Mobile.KEY_NUM5},
            {RG35XXKeyDispatcher.B, Mobile.KEY_NUM0},
            {RG35XXKeyDispatcher.SELECT, Mobile.KEY_STAR},
            {RG35XXKeyDispatcher.START, Mobile.KEY_POUND},
            {RG35XXKeyDispatcher.L1, Mobile.KEY_NUM1},
            {RG35XXKeyDispatcher.R1, Mobile.KEY_NUM3},
            {RG35XXKeyDispatcher.L2, Mobile.KEY_NUM7},
            {RG35XXKeyDispatcher.R2, Mobile.KEY_NUM9}
        };
        for (int i = 0; i < expected.length; i++) eq(expected[i][1], p.mapPhysicalToMobileKey(expected[i][0]), "default map " + expected[i][0]);

        p.cyclePhoneMode();
        eq('n', p.getPhoneMode(), "n mode");
        eq(Mobile.NOKIA_UP, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.UP), "n up");
        eq(Mobile.NOKIA_SOFT3, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.X), "n ok");
        eq(Mobile.KEY_NUM7, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.L2), "n l2");

        p.cyclePhoneMode();
        eq('e', p.getPhoneMode(), "e mode");
        eq(109, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.B), "e zero");
        eq(114, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.L1), "e one");
        eq(121, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.R1), "e three");
        eq(118, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.L2), "e seven");
        eq(110, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.R2), "e nine");
        eq(117, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.SELECT), "e star");
        eq(106, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.START), "e pound");

        RG35XXFrontendPolicy reloaded = new RG35XXFrontendPolicy(platform, dir, dir, "Default.jar", 240, 320);
        eq('e', reloaded.getPhoneMode(), "phone persistence");

        p.cyclePhoneMode();
        eq('s', p.getPhoneMode(), "s mode");
        eq(Mobile.SIEMENS_UP, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.UP), "s up");
        eq(Mobile.SIEMENS_SOFT1, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.Y), "s left phone");
        eq(Mobile.SIEMENS_SOFT2, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.A), "s right phone");
        eq(Mobile.SIEMENS_FIRE, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.X), "s fire");

        p.cyclePhoneMode();
        eq('m', p.getPhoneMode(), "m mode");
        eq(Mobile.MOTOROLA_UP, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.UP), "m up");
        eq(Mobile.MOTOROLA_SOFT1, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.Y), "m left phone");
        eq(Mobile.MOTOROLA_SOFT2, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.A), "m right phone");
        eq(Mobile.MOTOROLA_FIRE, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.X), "m fire");
        p.cyclePhoneMode();
        eq('p', p.getPhoneMode(), "cycle back p");
    }

    private static void testCustomKeymap(MobilePlatform platform, File root) throws Exception {
        File dir = new File(root, "keymap"); dir.mkdirs();
        File cfg = new File(dir, "keymap.cfg");
        Writer w = new OutputStreamWriter(new FileOutputStream(cfg), "UTF-8");
        w.write("{\n");
        w.write("\"\u5de6\u952e\":\"A\",\n\"\u53f3\u952e\":\"Y\",\n\"OK\":\"B\",\n");
        w.write("\"*\":\"START\",\n\"#\":\"SELECT\",\n\"0\":\"X\",\n");
        w.write("\"1\":\"R\",\n\"3\":\"L\",\n\"7\":\"R2\",\n\"9\":\"L2\"\n}\n");
        w.close();
        RG35XXFrontendPolicy p = new RG35XXFrontendPolicy(platform, dir, dir, "Keymap.jar", 240, 320);
        eq(Mobile.NOKIA_SOFT1, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.A), "custom left phone");
        eq(Mobile.NOKIA_SOFT2, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.Y), "custom right phone");
        eq(Mobile.KEY_NUM5, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.B), "custom ok");
        eq(Mobile.KEY_STAR, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.START), "custom star");
        eq(Mobile.KEY_POUND, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.SELECT), "custom pound");
        eq(Mobile.KEY_NUM0, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.X), "custom zero");
        eq(Mobile.KEY_NUM1, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.R1), "custom one");
        eq(Mobile.KEY_NUM3, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.L1), "custom three");
        eq(Mobile.KEY_NUM7, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.R2), "custom seven");
        eq(Mobile.KEY_NUM9, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.L2), "custom nine");
    }

    private static void testDispatcherHotkeys(MobilePlatform platform, File root) throws Exception {
        File dir = new File(root, "hotkey"); dir.mkdirs();
        RG35XXFrontendPolicy p = new RG35XXFrontendPolicy(platform, dir, dir, "Hotkey.jar", 240, 320);
        RG35XXKeyDispatcher d = new RG35XXKeyDispatcher(platform, p);
        events.clear();
        long t = 1000;
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT) | bit(RG35XXKeyDispatcher.START), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(0, t++);
        eq('n', p.getPhoneMode(), "hotkey phone cycle");
        eq(2, events.size(), "balanced select chord events");
        eq("KP:" + Mobile.KEY_STAR, events.get(0), "select press");
        eq("KR:" + Mobile.KEY_STAR, events.get(1), "select release");

        events.clear();
        d.dispatchState(bit(RG35XXKeyDispatcher.START), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.START) | bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.START), t++);
        d.dispatchState(0, t++);
        eq('e', p.getPhoneMode(), "reverse-order hotkey phone cycle");
        eq(2, events.size(), "balanced reverse-order chord events");

        events.clear();
        d.dispatchState(bit(RG35XXKeyDispatcher.UP), t++);
        d.dispatchState(0, t++);
        eq("KP:" + Mobile.NOKIA_UP, events.get(0), "n-mode dispatcher up press");
        eq("KR:" + Mobile.NOKIA_UP, events.get(1), "n-mode dispatcher up release");
    }

    private static void testPointerAndRotation(MobilePlatform platform, File root) throws Exception {
        File dir = new File(root, "pointer"); dir.mkdirs();
        RG35XXFrontendPolicy p = new RG35XXFrontendPolicy(platform, dir, dir, "Pointer.jar", 240, 320);
        RG35XXKeyDispatcher d = new RG35XXKeyDispatcher(platform, p);
        long t = 2000;
        events.clear();
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT) | bit(RG35XXKeyDispatcher.Y), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(0, t++);
        check(p.isPointerMode(), "pointer enabled");
        d.dispatchState(bit(RG35XXKeyDispatcher.RIGHT), t++); d.dispatchState(0, t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.DOWN), t++); d.dispatchState(0, t++);
        eq(6, p.getPointerX(), "pointer x");
        eq(6, p.getPointerY(), "pointer y");
        events.clear();
        d.dispatchState(bit(RG35XXKeyDispatcher.X), t++); d.dispatchState(0, t++);
        eq("PP:6,6", events.get(0), "pointer press");
        eq("PR:6,6", events.get(1), "pointer release");
        int[] px = new int[240 * 320];
        p.drawPointerCursor(px, 240, 320);
        int changed = 0; for (int i = 0; i < px.length; i++) if (px[i] != 0) changed++;
        check(changed > 0, "pointer cursor visible");

        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT) | bit(RG35XXKeyDispatcher.Y), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(0, t++);
        check(!p.isPointerMode(), "pointer disabled");

        events.clear();
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT) | bit(RG35XXKeyDispatcher.B), t++);
        d.dispatchState(bit(RG35XXKeyDispatcher.SELECT), t++);
        d.dispatchState(0, t++);
        eq(1, p.getRotation(), "rotation 1");
        d.dispatchState(bit(RG35XXKeyDispatcher.UP), t++); d.dispatchState(0, t++);
        eq("KP:" + Mobile.KEY_NUM6, events.get(events.size()-2), "rot1 up -> right press");
        eq("KR:" + Mobile.KEY_NUM6, events.get(events.size()-1), "rot1 up -> right release");
        p.cycleRotation();
        eq(2, p.getRotation(), "rotation 2");
        eq(Mobile.KEY_NUM4, p.mapPhysicalToMobileKey(RG35XXKeyDispatcher.UP), "rot2 up -> left");
        p.cycleRotation();
        eq(0, p.getRotation(), "rotation 0");
    }

    private static int bit(int id) { return 1 << (id - 1); }
    private static void check(boolean ok, String name) { if (!ok) throw new AssertionError(name); }
    private static void eq(int e, int a, String name) { if (e != a) throw new AssertionError(name + " expected=" + e + " actual=" + a); }
    private static void eq(char e, char a, String name) { if (e != a) throw new AssertionError(name + " expected=" + e + " actual=" + a); }
    private static void eq(String e, String a, String name) { if (!e.equals(a)) throw new AssertionError(name + " expected=" + e + " actual=" + a); }

    private static void deleteTree(File f) {
        if (!f.exists()) return;
        if (f.isDirectory()) {
            File[] children = f.listFiles();
            if (children != null) for (int i = 0; i < children.length; i++) deleteTree(children[i]);
        }
        f.delete();
    }
}
