package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Protect G1 clear/copy and G2A fillRoundRect while G2B opens fillTriangle. */
public final class RG35XXG2BParentRegressionGate {
    private static final int W = 36;
    private static final int H = 28;

    private interface Op { int[] run(PlatformImage image, PlatformGraphics g); }

    private static final class Result {
        final int[] pixels;
        final Throwable error;
        Result(int[] pixels, Throwable error) { this.pixels = pixels; this.error = error; }
    }

    public static void main(String[] args) {
        int failures = 0;
        failures += expectMatch("G1_CLEAR_CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x315579); g.fillRect(0, 0, W, H);
                g.setClip(7, 5, 14, 11); g.translate(4, 3); g.clearRect(0, 0, 30, 20);
                return pixels(image);
            }
        });
        failures += expectMatch("G1_COPY_OVERLAP_RIGHT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g); g.copyArea(2, 4, 18, 10, 7, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });
        failures += expectMatch("G1_COPY_OVERLAP_DOWN", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g); g.copyArea(4, 3, 14, 12, 4, 8, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });
        failures += expectMatch("G2A_FILLROUNDRECT_NORMAL", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x3366CC); g.fillRoundRect(4, 4, 20, 14, 7, 5); return pixels(image);
            }
        });
        failures += expectMatch("G2A_FILLROUNDRECT_CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x3366CC); g.setClip(9, 8, 12, 9); g.translate(5, 3);
                g.fillRoundRect(0, 1, 25, 17, 8, 8); return pixels(image);
            }
        });
        System.out.println("P1A_G2B_PARENT_REGRESSION_FAILURE_COUNT=" + failures);
        if (failures != 0) throw new RuntimeException("P1A_G2B_PARENT_REGRESSION_FAIL=" + failures);
        System.out.println("P1A_G2B_G1_G2A_PARENT_REGRESSION=PASS");
    }

    private static int expectMatch(String name, Op op) {
        Result awt = execute(false, op); Result raw = execute(true, op);
        boolean match = awt.error == null && raw.error == null && Arrays.equals(awt.pixels, raw.pixels);
        System.out.println("P1A_G2B_PARENT_CASE=" + name + " MATCH=" + match
                + " AWT=" + err(awt.error) + " RAW=" + err(raw.error));
        return match ? 0 : 1;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true"); else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W, H); PlatformGraphics g = image.getGraphics();
            return new Result(op.run(image, g), null);
        } catch (Throwable t) { return new Result(null, t); }
    }

    private static void paintGrid(PlatformGraphics g) {
        for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
            int r = (x * 29 + y * 11) & 0xFF, gr = (x * 17 + y * 43) & 0xFF, b = (x * 7 + y * 71) & 0xFF;
            g.setColor((r << 16) | (gr << 8) | b); g.fillRect(x, y, 1, 1);
        }
    }

    private static int[] pixels(PlatformImage image) {
        int[] out = new int[W * H]; image.getRGB(out, 0, W, 0, 0, W, H); return out;
    }

    private static String err(Throwable t) { return t == null ? "NONE" : t.getClass().getName(); }
}
