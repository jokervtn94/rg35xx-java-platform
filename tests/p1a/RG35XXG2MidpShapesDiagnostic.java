package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * P1A G2 diagnostic only. Captures the pinned JDK8 AWT raster for MIDP shapes
 * while proving the pre-G2 Raw2D candidate still fails at the same methods.
 */
public final class RG35XXG2MidpShapesDiagnostic {
    private static final int W = 34;
    private static final int H = 28;
    private static final int COLOR = 0x3366CC;

    private interface Op {
        void run(PlatformGraphics g);
    }

    private static final class Result {
        final int[] pixels;
        final Throwable error;
        Result(int[] pixels, Throwable error) {
            this.pixels = pixels;
            this.error = error;
        }
    }

    public static void main(String[] args) {
        int failures = 0;

        failures += capture("DRAWARC_PARTIAL", new Op() {
            public void run(PlatformGraphics g) { g.drawArc(5, 4, 17, 13, 25, 230); }
        });
        failures += capture("DRAWARC_FULL", new Op() {
            public void run(PlatformGraphics g) { g.drawArc(4, 3, 18, 18, 0, 360); }
        });
        failures += capture("DRAWARC_NEGATIVE", new Op() {
            public void run(PlatformGraphics g) { g.drawArc(4, 3, 20, 14, 310, -190); }
        });

        failures += capture("FILLARC_PARTIAL", new Op() {
            public void run(PlatformGraphics g) { g.fillArc(5, 4, 17, 13, 25, 230); }
        });
        failures += capture("FILLARC_FULL", new Op() {
            public void run(PlatformGraphics g) { g.fillArc(4, 3, 18, 18, 0, 360); }
        });
        failures += capture("FILLARC_NEGATIVE", new Op() {
            public void run(PlatformGraphics g) { g.fillArc(4, 3, 20, 14, 310, -190); }
        });

        failures += capture("DRAWROUNDRECT_NORMAL", new Op() {
            public void run(PlatformGraphics g) { g.drawRoundRect(4, 4, 20, 14, 7, 5); }
        });
        failures += capture("DRAWROUNDRECT_OVERSIZE", new Op() {
            public void run(PlatformGraphics g) { g.drawRoundRect(4, 4, 20, 14, 40, 30); }
        });
        failures += capture("DRAWROUNDRECT_ZERO_ARC", new Op() {
            public void run(PlatformGraphics g) { g.drawRoundRect(4, 4, 20, 14, 0, 0); }
        });

        failures += capture("FILLROUNDRECT_NORMAL", new Op() {
            public void run(PlatformGraphics g) { g.fillRoundRect(4, 4, 20, 14, 7, 5); }
        });
        failures += capture("FILLROUNDRECT_OVERSIZE", new Op() {
            public void run(PlatformGraphics g) { g.fillRoundRect(4, 4, 20, 14, 40, 30); }
        });

        failures += capture("FILLTRIANGLE_NORMAL", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(4, 4, 24, 7, 10, 22); }
        });
        failures += capture("FILLTRIANGLE_REVERSED", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 22, 24, 7, 4, 4); }
        });
        failures += capture("FILLTRIANGLE_FLAT", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(5, 12, 16, 12, 25, 12); }
        });

        // Lock the pinned fillRoundRect quirk: round fill followed by full fillRect.
        int[] round = execute(false, new Op() {
            public void run(PlatformGraphics g) { g.fillRoundRect(4, 4, 20, 14, 7, 5); }
        }).pixels;
        int[] rect = execute(false, new Op() {
            public void run(PlatformGraphics g) { g.fillRect(4, 4, 20, 14); }
        }).pixels;
        boolean fullRectQuirk = Arrays.equals(round, rect);
        System.out.println("P1A_G2_FILLROUNDRECT_EQUALS_FILLRECT=" + fullRectQuirk);
        if (!fullRectQuirk) failures++;

        System.out.println("P1A_G2_DIAGNOSTIC_FAILURE_COUNT=" + failures);
        if (failures != 0) {
            throw new RuntimeException("P1A_G2_DIAGNOSTIC_FAIL=" + failures);
        }
        System.out.println("P1A_G2_MIDP_SHAPES_DIAGNOSTIC=PASS");
        System.out.println("P1A_G2_RUNTIME_CHANGE=NO");
    }

    private static int capture(String name, Op op) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G2_CASE=" + name
                + " EXPECTED=RAW_EXCEPTION ACTUAL=" + actual
                + " AWT=" + errorName(awt.error)
                + " RAW=" + errorName(raw.error));
        if (awt.error == null) {
            System.out.println("P1A_G2_AWT_SIGNATURE=" + name
                    + " CHECKSUM=" + checksum(awt.pixels)
                    + " COUNT=" + countPainted(awt.pixels)
                    + " BOUNDS=" + bounds(awt.pixels));
            dumpMask(name, awt.pixels);
        }
        return "RAW_EXCEPTION".equals(actual) ? 0 : 1;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true");
            else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W, H);
            PlatformGraphics g = image.getGraphics();
            g.setColor(COLOR);
            op.run(g);
            int[] out = new int[W * H];
            image.getRGB(out, 0, W, 0, 0, W, H);
            return new Result(out, null);
        } catch (Throwable t) {
            return new Result(null, t);
        }
    }

    private static String classify(Result awt, Result raw) {
        if (awt.error != null) return "AWT_EXCEPTION";
        if (raw.error != null) return "RAW_EXCEPTION";
        return Arrays.equals(awt.pixels, raw.pixels) ? "MATCH" : "MISMATCH";
    }

    private static int countPainted(int[] p) {
        int n = 0;
        for (int i = 0; i < p.length; i++) if ((p[i] & 0x00FFFFFF) == COLOR) n++;
        return n;
    }

    private static String bounds(int[] p) {
        int minX = W, minY = H, maxX = -1, maxY = -1;
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                if ((p[y * W + x] & 0x00FFFFFF) == COLOR) {
                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }
            }
        }
        return maxX < 0 ? "EMPTY" : (minX + "," + minY + ".." + maxX + "," + maxY);
    }

    private static void dumpMask(String name, int[] p) {
        System.out.println("P1A_G2_MASK_BEGIN=" + name);
        for (int y = 0; y < H; y++) {
            StringBuffer row = new StringBuffer(W);
            for (int x = 0; x < W; x++) {
                row.append(((p[y * W + x] & 0x00FFFFFF) == COLOR) ? '#' : '.');
            }
            System.out.println(row.toString());
        }
        System.out.println("P1A_G2_MASK_END=" + name);
    }

    private static String errorName(Throwable t) {
        return t == null ? "NONE" : t.getClass().getName();
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
