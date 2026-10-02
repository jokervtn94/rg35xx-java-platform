package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;

/**
 * Diagnostic-only reproduction of G2D FUZZ_68 AWT side.
 * No RG35XX runtime code is exercised or modified here.
 */
public final class RG35XXG2D6A4BFuzz68AWTTrace {
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
        g.translate(6, -3);
        g.drawArc(20, 39, 30, 29, -971, -720);
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

        int p = pixels[39 * W + 31];
        System.out.println("G2D6A4B_CASE=FUZZ_68");
        System.out.println("G2D6A4B_SURFACE=BufferedImage.TYPE_INT_ARGB");
        System.out.println("G2D6A4B_DRAWARC=20,39,30,29,-971,-720");
        System.out.println("G2D6A4B_TRANSLATE=6,-3");
        System.out.println("G2D6A4B_COLOR_COUNT=" + count);
        System.out.println("G2D6A4B_CHECKSUM=" + Long.toHexString(hash));
        System.out.println("G2D6A4B_PIXEL_31_39=" + hex(p));
        System.out.println("G2D6A4B_AWT_TRACE_PROBE=PASS");
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
