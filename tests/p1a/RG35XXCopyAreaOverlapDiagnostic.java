package org.recompile.rg35xx.p1a;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * Diagnostic only. Characterizes pinned Java2D self-copy behavior versus the
 * current Raw2D G1 candidate. It does not assert or patch any semantics.
 */
public final class RG35XXCopyAreaOverlapDiagnostic {
    private static final int W = 16;
    private static final int H = 12;

    private interface Op {
        void run(PlatformGraphics g);
    }

    public static void main(String[] args) {
        runCase("H_RIGHT", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(2, 3, 8, 4, 5, 3, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        runCase("H_LEFT", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(5, 3, 8, 4, 2, 3, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        runCase("V_DOWN", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(3, 2, 7, 6, 3, 5, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        runCase("V_UP", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(3, 5, 7, 6, 3, 2, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        runCase("DIAG_DOWN_RIGHT", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(2, 2, 8, 6, 5, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        runCase("DIAG_UP_LEFT", new Op() {
            public void run(PlatformGraphics g) {
                g.copyArea(5, 4, 8, 6, 2, 2, PlatformGraphics.TOP | PlatformGraphics.LEFT);
            }
        });
        System.out.println("P1A_COPYAREA_OVERLAP_DIAGNOSTIC=COMPLETE");
        System.out.println("P1A_COPYAREA_OVERLAP_RUNTIME_CHANGE=NO");
    }

    private static void runCase(String name, Op op) {
        int[] awt = execute(false, op);
        int[] raw = execute(true, op);
        System.out.println("P1A_COPYAREA_CASE=" + name + " MATCH=" + same(awt, raw));
        for (int y = 0; y < H; y++) {
            String a = row(awt, y);
            String r = row(raw, y);
            if (!a.equals(r)) {
                System.out.println("P1A_COPYAREA_DIFF=" + name + " Y=" + y + " AWT=" + a + " RAW=" + r);
            }
        }
        System.out.println("P1A_COPYAREA_AWT_CHECKSUM=" + name + ":" + checksum(awt));
        System.out.println("P1A_COPYAREA_RAW_CHECKSUM=" + name + ":" + checksum(raw));
    }

    private static int[] execute(boolean raw, Op op) {
        if (raw) System.setProperty("rg35xx.raw2d", "true");
        else System.clearProperty("rg35xx.raw2d");
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        seed(g);
        op.run(g);
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }

    private static void seed(PlatformGraphics g) {
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                // Opaque unique 16-bit coordinate code in RGB: 0x00YYXX.
                int rgb = ((y & 0xFF) << 8) | (x & 0xFF);
                g.setColor(rgb);
                g.fillRect(x, y, 1, 1);
            }
        }
    }

    private static String row(int[] p, int y) {
        StringBuffer s = new StringBuffer();
        for (int x = 0; x < W; x++) {
            if (x > 0) s.append(',');
            int v = p[y * W + x] & 0xFFFF;
            int sy = (v >>> 8) & 0xFF;
            int sx = v & 0xFF;
            if (sy < 10) s.append('0');
            s.append(sy).append('/');
            if (sx < 10) s.append('0');
            s.append(sx);
        }
        return s.toString();
    }

    private static boolean same(int[] a, int[] b) {
        if (a.length != b.length) return false;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    private static String checksum(int[] p) {
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) {
            h ^= (p[i] & 0xFFFFFFFFL);
            h *= 1099511628211L;
        }
        return Long.toHexString(h);
    }
}
