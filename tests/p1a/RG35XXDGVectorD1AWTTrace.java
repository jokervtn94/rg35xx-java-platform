package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;

/**
 * P1A-DG-VECTOR-D1 diagnostic-only Java2D trace for Nokia DirectGraphics
 * vector methods. No RG35XX runtime code is exercised or modified here.
 */
public final class RG35XXDGVectorD1AWTTrace {
    private static final int W = 48;
    private static final int H = 40;
    private static final int BG = 0xFF102030;
    private static final int OPAQUE = 0xFF3366CC;
    private static final int ALPHA = 0x803366CC;

    private static final int[] TX = {7, 33, 18};
    private static final int[] TY = {6, 8, 27};
    private static final int[] PX = {5, 34, 26, 38, 8};
    private static final int[] PY = {6, 7, 18, 29, 31};

    public static void main(String[] args) {
        if (args.length != 1) {
            throw new IllegalArgumentException("operation required");
        }
        String op = args[0];

        int[] opaque = render(op, OPAQUE);
        int[] alpha = render(op, ALPHA);

        int opaqueCount = 0;
        int alphaCount = 0;
        int maskMismatch = 0;
        int alphaFirst = BG;
        int alphaDistinctSecond = BG;
        boolean haveFirst = false;
        boolean haveSecond = false;

        for (int i = 0; i < opaque.length; i++) {
            boolean oc = opaque[i] != BG;
            boolean ac = alpha[i] != BG;
            if (oc) opaqueCount++;
            if (ac) {
                alphaCount++;
                if (!haveFirst) {
                    alphaFirst = alpha[i];
                    haveFirst = true;
                } else if (!haveSecond && alpha[i] != alphaFirst) {
                    alphaDistinctSecond = alpha[i];
                    haveSecond = true;
                }
            }
            if (oc != ac) maskMismatch++;
        }

        long opaqueHash = checksum(opaque);
        long alphaHash = checksum(alpha);

        System.out.println("DGVD1_CASE=" + op);
        System.out.println("DGVD1_SURFACE=BufferedImage.TYPE_INT_ARGB");
        System.out.println("DGVD1_BACKGROUND=" + hex(BG));
        System.out.println("DGVD1_OPAQUE_COLOR=" + hex(OPAQUE));
        System.out.println("DGVD1_ALPHA_COLOR=" + hex(ALPHA));
        System.out.println("DGVD1_OPAQUE_COUNT=" + opaqueCount);
        System.out.println("DGVD1_ALPHA_COUNT=" + alphaCount);
        System.out.println("DGVD1_SUPPORT_MASK_MISMATCH=" + maskMismatch);
        System.out.println("DGVD1_SUPPORT_MASK_MATCH=" + (maskMismatch == 0 ? "YES" : "NO"));
        System.out.println("DGVD1_OPAQUE_CHECKSUM=" + Long.toHexString(opaqueHash));
        System.out.println("DGVD1_ALPHA_CHECKSUM=" + Long.toHexString(alphaHash));
        System.out.println("DGVD1_ALPHA_FIRST_CHANGED=" + hex(alphaFirst));
        System.out.println("DGVD1_ALPHA_SECOND_DISTINCT=" + (haveSecond ? hex(alphaDistinctSecond) : "NONE"));
        System.out.println("DGVD1_TRACE_PROBE=PASS");
    }

    private static int[] render(String op, int argb) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] bg = new int[W * H];
        Arrays.fill(bg, BG);
        image.setRGB(0, 0, W, H, bg, 0, W);

        Graphics2D g = image.createGraphics();
        g.setColor(new Color(argb, true));

        if ("drawTriangle".equals(op)) {
            g.drawPolygon(TX, TY, 3);
        } else if ("fillTriangle".equals(op)) {
            g.fillPolygon(TX, TY, 3);
        } else if ("drawPolygon".equals(op)) {
            g.drawPolygon(PX, PY, PX.length);
        } else if ("fillPolygon".equals(op)) {
            g.fillPolygon(PX, PY, PX.length);
        } else {
            g.dispose();
            throw new IllegalArgumentException("unknown operation: " + op);
        }

        g.dispose();
        return image.getRGB(0, 0, W, H, null, 0, W);
    }

    private static long checksum(int[] pixels) {
        long hash = 1469598103934665603L;
        for (int i = 0; i < pixels.length; i++) {
            hash ^= (pixels[i] & 0xFFFFFFFFL);
            hash *= 1099511628211L;
        }
        return hash;
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
