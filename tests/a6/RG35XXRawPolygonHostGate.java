package org.recompile.rg35xx.a6;

import javax.microedition.lcdui.Graphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawPolygonHostGate {
    private static final int W = 10;
    private static final int H = 10;

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        int[] p = image.getRG35XXPixels();

        g.setClip(0, 0, W, H);
        g.setColor(0x000000);
        g.fillRect(0, 0, W, H);

        int[] x = {1, 5, 5, 1};
        int[] y = {1, 1, 5, 5};
        g.fillPolygon(x, 0, y, 0, 4, 0xFFFF0000);
        require(p[1 * W + 1] == 0xFFFF0000, "opaque rect start");
        require(p[4 * W + 4] == 0xFFFF0000, "opaque rect end");
        require(p[5 * W + 5] == 0xFF000000, "opaque rect exclusive bound");

        int[] x2 = {2, 6, 6, 2};
        int[] y2 = {2, 2, 6, 6};
        g.fillPolygon(x2, 0, y2, 0, 4, 0x8000FF00);
        require(p[2 * W + 2] == 0xFF7F8000 || p[2 * W + 2] == 0xFF7F8000,
                "alpha source-over over red");
        require(p[5 * W + 5] == 0xFF008000, "alpha source-over over black");

        g.setClip(3, 3, 2, 2);
        int[] x3 = {0, 8, 8, 0};
        int[] y3 = {0, 0, 8, 8};
        g.fillPolygon(x3, 0, y3, 0, 4, 0xFF112233);
        require(p[3 * W + 3] == 0xFF112233, "clip inside");
        require(p[4 * W + 4] == 0xFF112233, "clip inside2");
        require(p[2 * W + 3] != 0xFF112233, "clip top");
        require(p[3 * W + 5] != 0xFF112233, "clip right");

        PlatformImage image2 = new PlatformImage(W, H);
        PlatformGraphics g2 = image2.getGraphics();
        int[] p2 = image2.getRG35XXPixels();
        g2.setClip(0, 0, W, H);
        g2.setColor(0x000000);
        g2.fillRect(0, 0, W, H);
        g2.translate(2, 1);
        int[] xt = {0, 3, 3, 0};
        int[] yt = {0, 0, 3, 3};
        g2.fillPolygon(xt, 0, yt, 0, 4, 0xFFABCDEF);
        require(p2[1 * W + 2] == 0xFFABCDEF, "translate start");
        require(p2[3 * W + 4] == 0xFFABCDEF, "translate end");
        require(p2[0 * W + 0] == 0xFF000000, "translate origin untouched");

        int[] tx = {1, 5, 3};
        int[] ty = {7, 7, 9};
        g2.translate(-2, -1);
        g2.setClip(0, 0, W, H);
        g2.fillPolygon(tx, 0, ty, 0, 3, 0xFF445566);
        require(p2[7 * W + 2] == 0xFF445566 || p2[8 * W + 3] == 0xFF445566,
                "generic triangle scanline");

        g.setAlphaRGB(0x80123456);
        require(g.getAlphaComponent() == 0x80, "setAlphaRGB raw state");

        System.out.println("A6_R5P_RAW_POLYGON_HOST_GATE=PASS");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new RuntimeException("A6_R5P_RAW_POLYGON_HOST_GATE_FAIL=" + message);
    }
}
