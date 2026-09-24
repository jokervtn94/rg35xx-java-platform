package org.recompile.rg35xx.a6;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawDrawRectHostGate {
    private static final int W = 18;
    private static final int H = 14;

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        int[] pixels = image.getRG35XXPixels();

        g.setClip(0, 0, W, H);
        g.setColor(0x000000);
        g.fillRect(0, 0, W, H);

        g.setColor(0x336699);
        g.drawRect(2, 3, 5, 4);
        int c = 0xFF336699;
        for (int x = 2; x <= 7; x++) {
            require(pixels[3 * W + x] == c, "top x=" + x);
            require(pixels[7 * W + x] == c, "bottom x=" + x);
        }
        for (int y = 3; y <= 7; y++) {
            require(pixels[y * W + 2] == c, "left y=" + y);
            require(pixels[y * W + 7] == c, "right y=" + y);
        }
        require(pixels[5 * W + 4] == 0xFF000000, "interior untouched");

        g.setClip(4, 4, 3, 3);
        g.setColor(0xCC5500);
        g.drawRect(3, 3, 4, 4);
        int cc = 0xFFCC5500;
        require(pixels[4 * W + 4] != cc, "clip interior remains untouched");
        require(pixels[4 * W + 7] != cc, "clip excludes x7");
        require(pixels[7 * W + 4] != cc, "clip excludes y7");

        g.setClip(0, 0, W, H);
        g.translate(2, 1);
        g.setColor(0x00AA44);
        g.drawRect(1, 1, 2, 2);
        int t = 0xFF00AA44;
        require(pixels[2 * W + 3] == t, "translate top-left");
        require(pixels[4 * W + 5] == t, "translate bottom-right");

        System.out.println("A6_R5P3I2_RAW_DRAWRECT_HOST_GATE=PASS");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new RuntimeException("A6_R5P3I2_RAW_DRAWRECT_HOST_GATE_FAIL=" + message);
    }
}
