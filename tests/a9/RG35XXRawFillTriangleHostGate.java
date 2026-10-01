package org.recompile.rg35xx.a9;

import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;

public final class RG35XXRawFillTriangleHostGate {
    private static void require(boolean value, String message) {
        if (!value) throw new RuntimeException(message);
    }

    private static int pixel(Image image, int x, int y) {
        int[] one = new int[1];
        image.getRGB(one, 0, 1, x, y, 1, 1);
        return one[0];
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");

        Image image = Image.createImage(12, 12);
        Graphics g = image.getGraphics();
        g.setColor(0x123456);
        g.fillTriangle(1, 1, 9, 1, 1, 9);

        require(pixel(image, 2, 2) == 0xFF123456,
                "raw fillTriangle did not fill an interior pixel");
        require(pixel(image, 10, 10) == 0xFFFFFFFF,
                "raw fillTriangle modified an exterior pixel");

        Image clipped = Image.createImage(12, 12);
        Graphics cg = clipped.getGraphics();
        cg.setClip(4, 4, 4, 4);
        cg.setColor(0xCC3300);
        cg.fillTriangle(0, 0, 10, 0, 0, 10);

        require(pixel(clipped, 4, 4) == 0xFFCC3300,
                "raw fillTriangle did not respect visible clipped interior");
        require(pixel(clipped, 3, 4) == 0xFFFFFFFF,
                "raw fillTriangle wrote outside clip bounds");

        System.out.println("A9_FILLTRIANGLE_HOST_GATE=PASS");
    }
}
