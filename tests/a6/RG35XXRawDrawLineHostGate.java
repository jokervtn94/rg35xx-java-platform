package org.recompile.rg35xx.a6;

import javax.microedition.lcdui.Graphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawDrawLineHostGate {
    private static final int W = 16;
    private static final int H = 12;

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        int[] pixels = image.getRG35XXPixels();

        g.setClip(0, 0, W, H);
        g.setColor(0x000000);
        g.fillRect(0, 0, W, H);

        // Critical real-game font workload: drawLine(x,y,x,y) is a putPixel.
        g.setColor(0x3366CC);
        g.setStrokeStyle(Graphics.SOLID);
        g.drawLine(7, 6, 7, 6);
        require(pixels[6 * W + 7] == 0xFF3366CC, "single pixel fast path");

        g.setColor(0x12AB34);
        g.drawLine(1, 1, 5, 1);
        int expected = 0xFF12AB34;
        for (int x = 1; x <= 5; x++) require(pixels[1 * W + x] == expected, "solid horizontal x=" + x);
        require(pixels[1 * W] == 0xFF000000, "solid left bound");
        require(pixels[1 * W + 6] == 0xFF000000, "solid right bound");

        g.setColor(0x8844AA);
        g.drawLine(12, 2, 12, 6);
        for (int y = 2; y <= 6; y++) require(pixels[y * W + 12] == 0xFF8844AA, "solid vertical y=" + y);

        g.setClip(2, 2, 3, 3);
        g.setColor(0xCC5500);
        g.drawLine(0, 3, 7, 3);
        int clipped = 0xFFCC5500;
        require(pixels[3 * W + 1] != clipped, "clip before");
        require(pixels[3 * W + 2] == clipped, "clip x2");
        require(pixels[3 * W + 3] == clipped, "clip x3");
        require(pixels[3 * W + 4] == clipped, "clip x4");
        require(pixels[3 * W + 5] != clipped, "clip after");

        g.setClip(0, 0, W, H);
        g.setColor(0x00FF00);
        g.drawLine(8, 2, 11, 5);
        int diagonal = 0xFF00FF00;
        require(pixels[2 * W + 8] == diagonal, "diag start");
        require(pixels[3 * W + 9] == diagonal, "diag 1");
        require(pixels[4 * W + 10] == diagonal, "diag 2");
        require(pixels[5 * W + 11] == diagonal, "diag end");

        System.out.println("A6_R5_RAW_DRAWLINE_FASTPATH_GATE=PASS");
        System.out.println("A6_R5_RAW_DRAWLINE_HOST_GATE=PASS");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new RuntimeException("A6_R5_RAW_DRAWLINE_HOST_GATE_FAIL=" + message);
    }
}
