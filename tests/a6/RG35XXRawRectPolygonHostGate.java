package org.recompile.rg35xx.a6;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawRectPolygonHostGate {
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

        int[] x = {1,5,5,1};
        int[] y = {1,1,5,5};
        g.fillPolygon(x,0,y,0,4,0xFFFF0000);
        req(p[1*W+1] == 0xFFFF0000, "opaque-start");
        req(p[4*W+4] == 0xFFFF0000, "opaque-end");
        req(p[5*W+5] == 0xFF000000, "exclusive-bound");

        int[] x2 = {2,6,6,2};
        int[] y2 = {2,2,6,6};
        g.fillPolygon(x2,0,y2,0,4,0x8000FF00);
        req(p[2*W+2] == 0xFF7F8000, "alpha-over-red");
        req(p[5*W+5] == 0xFF008000, "alpha-over-black");

        PlatformImage image2 = new PlatformImage(W, H);
        PlatformGraphics g2 = image2.getGraphics();
        int[] p2 = image2.getRG35XXPixels();
        g2.setClip(0, 0, W, H);
        g2.setColor(0x000000);
        g2.fillRect(0, 0, W, H);
        g2.translate(2,1);
        g2.setClip(0,0,4,4);
        int[] xt = {0,3,3,0};
        int[] yt = {0,0,3,3};
        g2.fillPolygon(xt,0,yt,0,4,0xFFABCDEF);
        req(p2[1*W+2] == 0xFFABCDEF, "translate-start");
        req(p2[3*W+4] == 0xFFABCDEF, "translate-end");
        req(p2[1*W+5] == 0xFF000000, "clip-right");

        int before = p2[7*W+2];
        int[] tx = {1,5,3};
        int[] ty = {7,7,9};
        g2.translate(-2,-1);
        g2.setClip(0,0,W,H);
        g2.fillPolygon(tx,0,ty,0,3,0xFF445566);
        req(p2[7*W+2] == before, "nonrect-noop");

        System.out.println("A6_R5P3_RAW_RECT_POLYGON_HOST_GATE=PASS");
    }

    private static void req(boolean ok, String msg) {
        if (!ok) throw new RuntimeException("A6_R5P3_RAW_RECT_POLYGON_HOST_GATE_FAIL=" + msg);
    }
}
