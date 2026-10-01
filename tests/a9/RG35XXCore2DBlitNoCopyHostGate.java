package org.recompile.rg35xx.a9;

import java.util.Arrays;
import javax.microedition.lcdui.game.Sprite;
import org.recompile.rg35xx.RG35XXCore2D;

/** Host gate for the A9 transform==0 no-copy blit optimization. */
public final class RG35XXCore2DBlitNoCopyHostGate {
    private static void require(boolean ok, String message) {
        if (!ok) throw new RuntimeException(message);
    }

    private static int at(int[] pixels, int width, int x, int y) {
        return pixels[y * width + x];
    }

    public static void main(String[] args) {
        // Exact transform==0 source-window indexing and source-over semantics.
        int blue = 0xFF0000FF;
        int[] dst = new int[16];
        Arrays.fill(dst, blue);
        int[] src = new int[] {
            0xFFFF0000, 0x00000000,
            0x8000FF00, 0xFFFFFFFF
        };
        int[] srcBefore = (int[]) src.clone();

        RG35XXCore2D.blit(dst, 4, 4,
                src, 2, 2,
                0, 0, 2, 2, Sprite.TRANS_NONE,
                1, 1,
                0, 0, 4, 4);

        require(at(dst, 4, 1, 1) == 0xFFFF0000, "opaque source pixel changed");
        require(at(dst, 4, 2, 1) == blue, "transparent source pixel changed destination");
        require(at(dst, 4, 1, 2) == 0xFF00807F, "half-alpha source-over mismatch");
        require(at(dst, 4, 2, 2) == 0xFFFFFFFF, "opaque white source pixel mismatch");
        require(Arrays.equals(src, srcBefore), "blit modified source pixels");

        // Non-zero source origin must index the original source directly.
        int[] src4 = new int[16];
        for (int i = 0; i < src4.length; i++) src4[i] = 0xFF000000 | i;
        int[] dst2 = new int[9];
        Arrays.fill(dst2, 0xFF101010);
        RG35XXCore2D.blit(dst2, 3, 3,
                src4, 4, 4,
                1, 1, 2, 2, Sprite.TRANS_NONE,
                0, 0,
                0, 0, 3, 3);
        require(at(dst2, 3, 0, 0) == src4[5], "srcX/srcY top-left mismatch");
        require(at(dst2, 3, 1, 0) == src4[6], "srcX/srcY top-right mismatch");
        require(at(dst2, 3, 0, 1) == src4[9], "srcX/srcY bottom-left mismatch");
        require(at(dst2, 3, 1, 1) == src4[10], "srcX/srcY bottom-right mismatch");
        require(at(dst2, 3, 2, 2) == 0xFF101010, "blit escaped requested source window");

        // Clip semantics must remain identical.
        int[] clipped = new int[16];
        Arrays.fill(clipped, 0xFF222222);
        int[] opaque4 = new int[] {
            0xFF111111, 0xFF222233,
            0xFF334455, 0xFF556677
        };
        RG35XXCore2D.blit(clipped, 4, 4,
                opaque4, 2, 2,
                0, 0, 2, 2, Sprite.TRANS_NONE,
                1, 1,
                2, 2, 1, 1);
        require(at(clipped, 4, 2, 2) == 0xFF556677, "clip did not preserve in-clip pixel");
        require(at(clipped, 4, 1, 1) == 0xFF222222, "clip wrote outside left/top");
        require(at(clipped, 4, 2, 1) == 0xFF222222, "clip wrote outside top");
        require(at(clipped, 4, 1, 2) == 0xFF222222, "clip wrote outside left");

        // Preserve the accepted exception contract from subRaw for bad windows.
        boolean boundsThrown = false;
        try {
            RG35XXCore2D.blit(new int[4], 2, 2,
                    src, 2, 2,
                    1, 1, 2, 2, Sprite.TRANS_NONE,
                    0, 0,
                    0, 0, 2, 2);
        } catch (IllegalArgumentException expected) {
            boundsThrown = "subimage bounds".equals(expected.getMessage());
        }
        require(boundsThrown, "transform==0 bounds contract changed");

        // Non-zero transforms remain on the accepted transform path.
        int[] rotatedDst = new int[4];
        Arrays.fill(rotatedDst, 0xFF000000);
        int[] row = new int[] { 0xFFFF0000, 0xFF00FF00 };
        RG35XXCore2D.blit(rotatedDst, 2, 2,
                row, 2, 1,
                0, 0, 2, 1, Sprite.TRANS_ROT90,
                0, 0,
                0, 0, 2, 2);
        require(at(rotatedDst, 2, 0, 0) == 0xFFFF0000, "ROT90 top pixel changed");
        require(at(rotatedDst, 2, 0, 1) == 0xFF00FF00, "ROT90 bottom pixel changed");

        System.out.println("A9_CORE2D_BLIT_NOCOPY_HOST_GATE=PASS");
        System.out.println("A9_CORE2D_BLIT_ALPHA_GATE=PASS");
        System.out.println("A9_CORE2D_BLIT_CLIP_GATE=PASS");
        System.out.println("A9_CORE2D_BLIT_TRANSFORM_REGRESSION_GATE=PASS");
    }
}
