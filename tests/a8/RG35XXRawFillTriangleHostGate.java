package org.recompile.rg35xx.a8;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawFillTriangleHostGate {
    private static final int W = 12;
    private static final int H = 12;
    private static final int BLACK = 0xFF000000;

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");

        basicAndWinding();
        translateAndClip();
        degenerate();

        System.out.println("A8_COMP02_FILLTRIANGLE_HOST_GATE=PASS");
    }

    private static void basicAndWinding() {
        PlatformImage image = blank();
        PlatformGraphics g = image.getGraphics();
        int[] p = image.getRG35XXPixels();

        g.setColor(0xCC2200);
        g.fillTriangle(1, 1, 7, 1, 1, 7);

        req(p[1 * W + 1] == 0xFFCC2200, "basic-left");
        req(p[1 * W + 6] == 0xFFCC2200, "basic-top-span");
        req(p[1 * W + 7] == BLACK, "basic-right-exclusive");
        req(p[6 * W + 1] == 0xFFCC2200, "basic-tip-row");
        req(p[6 * W + 2] == BLACK, "basic-tip-exclusive");
        req(p[7 * W + 1] == BLACK, "basic-bottom-exclusive");

        g.setColor(0x1166AA);
        g.fillTriangle(10, 2, 7, 8, 4, 2);
        req(p[2 * W + 5] == 0xFF1166AA, "reverse-winding-top");
        req(p[4 * W + 7] == 0xFF1166AA, "reverse-winding-center");
        req(p[8 * W + 7] == BLACK, "reverse-winding-bottom-exclusive");
    }

    private static void translateAndClip() {
        PlatformImage image = blank();
        PlatformGraphics g = image.getGraphics();
        int[] p = image.getRG35XXPixels();

        g.translate(2, 1);
        g.setClip(0, 0, 3, 3);
        g.setColor(0x123456);
        g.fillTriangle(0, 0, 6, 0, 0, 6);

        req(p[1 * W + 2] == 0xFF123456, "translate-origin");
        req(p[1 * W + 4] == 0xFF123456, "clip-inside-right");
        req(p[1 * W + 5] == BLACK, "clip-right");
        req(p[3 * W + 2] == 0xFF123456, "clip-inside-bottom");
        req(p[4 * W + 2] == BLACK, "clip-bottom");
    }

    private static void degenerate() {
        PlatformImage image = blank();
        PlatformGraphics g = image.getGraphics();
        int[] p = image.getRG35XXPixels();

        g.setColor(0x00FF00);
        g.fillTriangle(2, 9, 5, 9, 8, 9);
        req(p[9 * W + 2] == BLACK, "degenerate-horizontal");
        req(p[9 * W + 5] == BLACK, "degenerate-horizontal-mid");
    }

    private static PlatformImage blank() {
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        g.setClip(0, 0, W, H);
        g.setColor(0x000000);
        g.fillRect(0, 0, W, H);
        return image;
    }

    private static void req(boolean ok, String msg) {
        if (!ok) throw new RuntimeException("A8_COMP02_FILLTRIANGLE_HOST_GATE_FAIL=" + msg);
    }
}
