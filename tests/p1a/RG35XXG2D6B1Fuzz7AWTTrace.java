package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;

/**
 * G2D-6B1 diagnostic-only reproduction of FUZZ_7 AWT fillArc side.
 * No RG35XX runtime code is exercised or modified here.
 */
public final class RG35XXG2D6B1Fuzz7AWTTrace {
    private static final int W = 48;
    private static final int H = 40;
    private static final int COLOR = 0x3366CC;

    public static void main(String[] args) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] white = new int[W * H];
        Arrays.fill(white, 0xFFFFFFFF);
        image.setRGB(0, 0, W, H, white, 0, W);

        Graphics2D g = image.createGraphics();
        g.setColor(new Color(COLOR));
        g.fillArc(8, -4, 26, 9, 1191, 230);
        g.dispose();

        int[] pixels = image.getRGB(0, 0, W, H, null, 0, W);
        int count = 0;
        for (int i = 0; i < pixels.length; i++) {
            if ((pixels[i] & 0x00FFFFFF) == COLOR) count++;
        }

        long hash = 1469598103934665603L;
        for (int i = 0; i < pixels.length; i++) {
            hash ^= (pixels[i] & 0xFFFFFFFFL);
            hash *= 1099511628211L;
        }

        int p = pixels[5 * W + 21];
        System.out.println("G2D6B1_CASE=FUZZ_7");
        System.out.println("G2D6B1_SURFACE=BufferedImage.TYPE_INT_ARGB");
        System.out.println("G2D6B1_FILLARC=8,-4,26,9,1191,230");
        System.out.println("G2D6B1_CLIP=NONE");
        System.out.println("G2D6B1_TRANSLATE=0,0");
        System.out.println("G2D6B1_COLOR_COUNT=" + count);
        System.out.println("G2D6B1_CHECKSUM=" + Long.toHexString(hash));
        System.out.println("G2D6B1_PIXEL_21_5=" + hex(p));
        System.out.println("G2D6B1_AWT_TRACE_PROBE=PASS");
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
