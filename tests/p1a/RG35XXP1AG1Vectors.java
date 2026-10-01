package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;

/** Shared Java-6/MIDP copyArea vector set. CI runs AWT; device runs Raw2D. */
public final class RG35XXP1AG1Vectors {
    private static final int W = 32;
    private static final int H = 24;

    public static final String[] NAMES = {
        "COPY_BASIC",
        "COPY_CLIP_TRANSLATE",
        "COPY_OVERLAP_RIGHT",
        "COPY_OVERLAP_LEFT",
        "COPY_OVERLAP_DOWN",
        "COPY_OVERLAP_UP",
        "COPY_OVERLAP_FORWARD",
        "COPY_OVERLAP_BACKWARD",
        "COPY_ALPHA_SOURCE_OVER"
    };

    private RG35XXP1AG1Vectors() { }

    public static int count() { return NAMES.length; }

    public static int run(int index) {
        Image image = Image.createImage(W, H);
        Graphics g = image.getGraphics();
        switch (index) {
            case 0:
                seed(g);
                g.copyArea(2, 2, 8, 6, 17, 11, Graphics.LEFT | Graphics.TOP);
                break;
            case 1:
                seed(g);
                g.setClip(14, 9, 7, 6);
                g.translate(2, 1);
                g.copyArea(2, 2, 8, 6, 12, 8, Graphics.LEFT | Graphics.TOP);
                break;
            case 2:
                seed(g);
                g.copyArea(2, 4, 14, 8, 6, 4, Graphics.LEFT | Graphics.TOP);
                break;
            case 3:
                seed(g);
                g.copyArea(7, 4, 14, 8, 2, 4, Graphics.LEFT | Graphics.TOP);
                break;
            case 4:
                seed(g);
                g.copyArea(4, 2, 12, 10, 4, 6, Graphics.LEFT | Graphics.TOP);
                break;
            case 5:
                seed(g);
                g.copyArea(4, 7, 12, 10, 4, 2, Graphics.LEFT | Graphics.TOP);
                break;
            case 6:
                seed(g);
                g.copyArea(2, 2, 12, 8, 6, 5, Graphics.LEFT | Graphics.TOP);
                break;
            case 7:
                seed(g);
                g.copyArea(7, 6, 12, 8, 2, 2, Graphics.LEFT | Graphics.TOP);
                break;
            case 8:
                g.setColor(0x204060); g.fillRect(15, 10, 6, 5);
                int[] src = new int[6 * 5];
                Arrays.fill(src, 0x8040C020);
                g.drawRGB(src, 0, 6, 2, 2, 6, 5, true);
                g.copyArea(2, 2, 6, 5, 15, 10, Graphics.LEFT | Graphics.TOP);
                break;
            default:
                throw new IllegalArgumentException("case " + index);
        }
        int[] pixels = new int[W * H];
        image.getRGB(pixels, 0, W, 0, 0, W, H);
        return checksum(pixels);
    }

    private static void seed(Graphics g) {
        g.setColor(0x102030); g.fillRect(0, 0, W, H);
        g.setColor(0xC04020); g.fillRect(2, 2, 8, 6);
        g.setColor(0x2080C0); g.fillRect(10, 5, 9, 8);
        g.setColor(0x40A060); g.fillRect(4, 14, 12, 5);
    }

    private static int checksum(int[] pixels) {
        int h = 0x811C9DC5;
        for (int i = 0; i < pixels.length; i++) {
            int p = pixels[i];
            h = fnv(h, (p >>> 24) & 0xFF);
            h = fnv(h, (p >>> 16) & 0xFF);
            h = fnv(h, (p >>> 8) & 0xFF);
            h = fnv(h, p & 0xFF);
        }
        return h;
    }

    private static int fnv(int h, int b) {
        h ^= b;
        h *= 16777619;
        return h;
    }
}
