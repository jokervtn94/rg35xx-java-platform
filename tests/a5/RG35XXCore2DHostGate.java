package org.recompile.rg35xx.a5;

import org.recompile.rg35xx.RG35XXCore2D;

/** Build-only arithmetic gate. This never promotes DEVICE-PASS. */
public final class RG35XXCore2DHostGate {
    private static void require(boolean ok, String message) {
        if (!ok) throw new RuntimeException(message);
    }

    private static int blend(int source, int destination) {
        int[] dst = new int[] { destination };
        int[] src = new int[] { source };
        RG35XXCore2D.blit(dst, 1, 1, src, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1);
        return dst[0];
    }

    public static void main(String[] args) {
        int transparent = blend(0x8000FF00, 0x00000000);
        require(transparent == 0x8000FF00,
                "transparent-dst expected=0x8000ff00 got=0x" + Integer.toHexString(transparent));

        int opaque = blend(0x8000FF00, 0xFF000000);
        require(opaque == 0xFF008000,
                "opaque-dst expected=0xff008000 got=0x" + Integer.toHexString(opaque));

        int preserved = blend(0x00010203, 0x80445566);
        require(preserved == 0x80445566,
                "zero-alpha source changed destination: 0x" + Integer.toHexString(preserved));

        System.out.println("A5_CORE2D_ALPHA_HOST_GATE=PASS");
    }
}
