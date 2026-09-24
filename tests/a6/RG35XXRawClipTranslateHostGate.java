package org.recompile.rg35xx.a6;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXRawClipTranslateHostGate {
    private static final int W = 24;
    private static final int H = 16;

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");

        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        int[] pixels = image.getRG35XXPixels();

        g.setClip(0, 0, W, H);
        g.setColor(0x000000);
        g.fillRect(0, 0, W, H);

        // This models the evidence-owned failure: God of War establishes a
        // physical full-screen clip, moves the user origin, then draws sprite
        // regions whose translated device coordinates are still on screen.
        // The physical clip must remain fixed at 0..W / 0..H.
        g.translate(0, -10);
        g.setColor(0x55AA22);
        g.fillRect(4, 19, 3, 2); // device y = 9..10

        int c = 0xFF55AA22;
        require(pixels[9 * W + 4] == c, "translated draw top-left clipped");
        require(pixels[10 * W + 6] == c, "translated draw bottom-right clipped");
        require(pixels[8 * W + 4] == 0xFF000000, "unexpected pixel above draw");

        // A clip set after translation is converted from user coordinates to
        // device coordinates exactly once.
        g.setClip(2, 18, 4, 3); // device rect x=2..5, y=8..10
        g.setColor(0xAA3355);
        g.fillRect(0, 17, 10, 5); // device y=7..11; only clip intersection writes
        int c2 = 0xFFAA3355;
        require(pixels[8 * W + 2] == c2, "translated setClip top-left");
        require(pixels[10 * W + 5] == c2, "translated setClip bottom-right");
        require(pixels[8 * W + 1] != c2, "translated setClip leaked left");
        require(pixels[11 * W + 2] != c2, "translated setClip leaked bottom");

        System.out.println("A6_CORPUS3_CLIPTRANSLATE_HOST_GATE=PASS");
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new RuntimeException("A6_CORPUS3_CLIPTRANSLATE_HOST_GATE_FAIL=" + message);
        }
    }
}
