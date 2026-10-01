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

        Image translated = Image.createImage(16, 16);
        Graphics tg = translated.getGraphics();
        tg.translate(3, 2);
        tg.setClip(0, 0, 8, 8);
        tg.setColor(0x3366AA);
        tg.fillTriangle(1, 1, 7, 1, 1, 7);

        require(pixel(translated, 5, 4) == 0xFF3366AA,
                "raw fillTriangle did not apply translation");
        require(pixel(translated, 2, 2) == 0xFFFFFFFF,
                "raw fillTriangle wrote before translated origin");
        require(pixel(translated, 11, 9) == 0xFFFFFFFF,
                "raw fillTriangle wrote outside translated clip");

        Image degenerate = Image.createImage(12, 12);
        Graphics dg = degenerate.getGraphics();
        dg.setColor(0x884422);
        dg.fillTriangle(2, 5, 8, 5, 4, 5);
        require(pixel(degenerate, 2, 5) == 0xFF884422,
                "raw degenerate fillTriangle missed left endpoint");
        require(pixel(degenerate, 8, 5) == 0xFF884422,
                "raw degenerate fillTriangle missed right endpoint");

        System.out.println("A9_FILLTRIANGLE_HOST_GATE=PASS");
        System.out.println("A9_FILLTRIANGLE_TRANSLATE_CLIP_GATE=PASS");
        System.out.println("A9_FILLTRIANGLE_DEGENERATE_GATE=PASS");
    }
}
