package org.recompile.mobile;

import javax.microedition.lcdui.*;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.midlet.MIDlet;

public final class M116R11ImageSpriteIsolationMIDlet extends MIDlet implements Runnable {
    protected void startApp() {
        System.out.println("M1_16_R11_PRIMARY_VARIABLE=IMAGE_TO_SPRITE_CONSTRUCTOR_PATH_ONLY");
        System.out.println("M1_16_R11_GAME_LAYER_IMPLEMENTATION_CHANGE=NONE");
        System.out.println("M1_16_R11_PLATFORMIMAGE_IMPLEMENTATION_CHANGE=NONE");
        System.out.println("M1_16_R11_RENDERER_CHANGE=NONE");
        new Thread(this, "m116-r11").start();
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}

    private static void logImage(String tag, Image img) {
        try {
            System.out.println("M1_16_R11_" + tag + "_NULL=" + (img == null ? "YES" : "NO"));
            if (img != null) {
                System.out.println("M1_16_R11_" + tag + "_CLASS=" + img.getClass().getName());
                System.out.println("M1_16_R11_" + tag + "_WIDTH=" + img.getWidth());
                System.out.println("M1_16_R11_" + tag + "_HEIGHT=" + img.getHeight());
                System.out.println("M1_16_R11_" + tag + "_MUTABLE=" + img.isMutable());
            }
        } catch (Throwable t) {
            System.out.println("M1_16_R11_" + tag + "_IMAGE_ACCESS=FAIL:" + t.getClass().getName());
        }
    }

    private static boolean spriteCtor(String tag, Image img) {
        try {
            Sprite s = new Sprite(img, 8, 8);
            System.out.println("M1_16_R11_" + tag + "_SPRITE_CTOR=PASS");
            System.out.println("M1_16_R11_" + tag + "_SPRITE_SIZE=" + s.getWidth() + "x" + s.getHeight());
            return true;
        } catch (Throwable t) {
            System.out.println("M1_16_R11_" + tag + "_SPRITE_CTOR=FAIL");
            System.out.println("M1_16_R11_" + tag + "_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            return false;
        }
    }

    private static Image makeMutable() throws Exception {
        Image img = Image.createImage(16, 8);
        Graphics g = img.getGraphics();
        g.setColor(0xFF0000); g.fillRect(0, 0, 8, 8);
        g.setColor(0x00FF00); g.fillRect(8, 0, 8, 8);
        return img;
    }

    public void run() {
        try {
            Image a = makeMutable();
            logImage("A_MUTABLE", a);
            boolean ap = spriteCtor("A_MUTABLE", a);

            Image b = Image.createImage(a);
            logImage("B_COPY", b);
            boolean bp = spriteCtor("B_COPY", b);

            int[] rgb = new int[16 * 8];
            int i;
            for (i = 0; i < rgb.length; i++) rgb[i] = (i % 16 < 8) ? 0xFFFF0000 : 0xFF00FF00;
            Image c = Image.createRGBImage(rgb, 16, 8, true);
            logImage("C_RGB", c);
            boolean cp = spriteCtor("C_RGB", c);

            System.out.println("M1_16_R11_A_RESULT=" + (ap ? "PASS" : "FAIL"));
            System.out.println("M1_16_R11_B_RESULT=" + (bp ? "PASS" : "FAIL"));
            System.out.println("M1_16_R11_C_RESULT=" + (cp ? "PASS" : "FAIL"));
            System.out.println("M1_16_R11_DIAGNOSTIC_GATE=PASS");
            System.out.println("M1_16_R11_RUNTIME_GATE=PASS");
            notifyDestroyed();
            System.exit(0);
        } catch (Throwable t) {
            System.out.println("M1_16_R11_DIAGNOSTIC_GATE=FAIL");
            System.out.println("M1_16_R11_RUNTIME_GATE=FAIL");
            System.out.println("M1_16_R11_FATAL_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(2);
        }
    }
}
