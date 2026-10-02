package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * G2B diagnostic: compare the previously device-proven raw MIDP fillTriangle
 * helper against the pinned JDK8/AWT PlatformGraphics raster over a broad
 * geometry matrix. Pixel mismatch is evidence, not a diagnostic runner error.
 */
public final class RG35XXG2BFillTriangleDiagnostic {
    private static final int W = 40;
    private static final int H = 32;
    private static final int COLOR = 0x3366CC;

    private interface Op {
        void run(PlatformGraphics g);
    }

    private static final class Result {
        final int[] pixels;
        final Throwable error;
        Result(int[] pixels, Throwable error) { this.pixels = pixels; this.error = error; }
    }

    private static int mismatches;
    private static int errors;
    private static int scopeFailures;

    public static void main(String[] args) {
        compare("REFERENCE", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(4, 4, 24, 7, 10, 22); }
        });
        compare("REVERSED", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 22, 24, 7, 4, 4); }
        });
        compare("PERM_BAC", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(24, 7, 4, 4, 10, 22); }
        });
        compare("PERM_BCA", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(24, 7, 10, 22, 4, 4); }
        });
        compare("PERM_CAB", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 22, 4, 4, 24, 7); }
        });
        compare("PERM_CBA", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 22, 24, 7, 4, 4); }
        });

        compare("FLAT_HORIZONTAL", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(5, 12, 16, 12, 25, 12); }
        });
        compare("FLAT_VERTICAL", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(12, 4, 12, 16, 12, 25); }
        });
        compare("DUPLICATE_AB", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(5, 5, 5, 5, 23, 20); }
        });
        compare("DUPLICATE_BC", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(5, 5, 23, 20, 23, 20); }
        });
        compare("ALL_DUPLICATE", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(12, 11, 12, 11, 12, 11); }
        });

        compare("SKINNY_VERTICAL", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 3, 11, 27, 12, 3); }
        });
        compare("SKINNY_HORIZONTAL", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(3, 14, 35, 15, 3, 16); }
        });
        compare("TINY_RIGHT", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 10, 11, 10, 10, 11); }
        });
        compare("TINY_TWO", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(10, 10, 12, 10, 10, 12); }
        });

        compare("CLIP", new Op() {
            public void run(PlatformGraphics g) {
                g.setClip(9, 8, 13, 11);
                g.fillTriangle(3, 3, 31, 8, 12, 27);
            }
        });
        compare("TRANSLATE", new Op() {
            public void run(PlatformGraphics g) {
                g.translate(5, 4);
                g.fillTriangle(2, 2, 22, 5, 7, 20);
            }
        });
        compare("CLIP_TRANSLATE", new Op() {
            public void run(PlatformGraphics g) {
                g.setClip(10, 8, 14, 12);
                g.translate(5, 4);
                g.fillTriangle(-2, -1, 26, 4, 8, 24);
            }
        });
        compare("PARTIAL_NEGATIVE", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(-12, -7, 23, 4, 6, 25); }
        });
        compare("PARTIAL_RIGHT_BOTTOM", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(17, 9, 51, 14, 28, 42); }
        });
        compare("SPANNING", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(-20, -12, 61, 3, 18, 49); }
        });

        // Parent and scope sentinels.
        expectMatch("PARENT_FILLROUNDRECT", new Op() {
            public void run(PlatformGraphics g) { g.fillRoundRect(4, 4, 20, 14, 7, 5); }
        });
        expectRawException("SENTINEL_DRAWARC", new Op() {
            public void run(PlatformGraphics g) { g.drawArc(5, 4, 17, 13, 25, 230); }
        });
        expectRawException("SENTINEL_FILLARC", new Op() {
            public void run(PlatformGraphics g) { g.fillArc(5, 4, 17, 13, 25, 230); }
        });
        expectRawException("SENTINEL_DRAWROUNDRECT", new Op() {
            public void run(PlatformGraphics g) { g.drawRoundRect(4, 4, 20, 14, 7, 5); }
        });
        expectRawException("SENTINEL_DG_FILLTRIANGLE_7ARG", new Op() {
            public void run(PlatformGraphics g) { g.fillTriangle(4, 4, 24, 7, 10, 22, 0xCC3366CC); }
        });

        System.out.println("P1A_G2B_TRIANGLE_MISMATCH_COUNT=" + mismatches);
        System.out.println("P1A_G2B_TRIANGLE_ERROR_COUNT=" + errors);
        System.out.println("P1A_G2B_SCOPE_FAILURE_COUNT=" + scopeFailures);
        System.out.println("P1A_G2B_CANONICAL_EQUIVALENT=" + (mismatches == 0 && errors == 0 ? "YES" : "NO"));
        if (errors != 0 || scopeFailures != 0) {
            throw new RuntimeException("P1A_G2B_DIAGNOSTIC_INVALID errors=" + errors + " scope=" + scopeFailures);
        }
        System.out.println("P1A_G2B_FILLTRIANGLE_DIAGNOSTIC=COMPLETE");
        System.out.println("P1A_G2B_DIAGNOSTIC_MISMATCH_IS_EVIDENCE=YES");
    }

    private static void compare(String name, Op op) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        if (awt.error != null || raw.error != null) {
            errors++;
            System.out.println("P1A_G2B_CASE=" + name + " RESULT=ERROR AWT=" + errorName(awt.error) + " RAW=" + errorName(raw.error));
            return;
        }
        boolean match = Arrays.equals(awt.pixels, raw.pixels);
        if (!match) mismatches++;
        System.out.println("P1A_G2B_CASE=" + name + " RESULT=" + (match ? "MATCH" : "MISMATCH")
                + " AWT_CHECKSUM=" + checksum(awt.pixels)
                + " RAW_CHECKSUM=" + checksum(raw.pixels)
                + " AWT_COUNT=" + countPainted(awt.pixels)
                + " RAW_COUNT=" + countPainted(raw.pixels)
                + " AWT_BOUNDS=" + bounds(awt.pixels)
                + " RAW_BOUNDS=" + bounds(raw.pixels));
        if (!match) {
            firstDiff(name, awt.pixels, raw.pixels);
            dumpMask(name + "_AWT", awt.pixels);
            dumpMask(name + "_RAW", raw.pixels);
        }
    }

    private static void expectMatch(String name, Op op) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G2B_SCOPE_CASE=" + name + " EXPECTED=MATCH ACTUAL=" + actual
                + " AWT=" + errorName(awt.error) + " RAW=" + errorName(raw.error));
        if (!"MATCH".equals(actual)) scopeFailures++;
    }

    private static void expectRawException(String name, Op op) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G2B_SCOPE_CASE=" + name + " EXPECTED=RAW_EXCEPTION ACTUAL=" + actual
                + " AWT=" + errorName(awt.error) + " RAW=" + errorName(raw.error));
        if (!"RAW_EXCEPTION".equals(actual)) scopeFailures++;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true");
            else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W, H);
            PlatformGraphics g = image.getGraphics();
            g.setColor(COLOR);
            op.run(g);
            return new Result(pixels(image), null);
        } catch (Throwable t) {
            return new Result(null, t);
        }
    }

    private static String classify(Result awt, Result raw) {
        if (awt.error != null) return "AWT_EXCEPTION";
        if (raw.error != null) return "RAW_EXCEPTION";
        return Arrays.equals(awt.pixels, raw.pixels) ? "MATCH" : "MISMATCH";
    }

    private static int[] pixels(PlatformImage image) {
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
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
        return maxX < 0 ? "EMPTY" : minX + "," + minY + ".." + maxX + "," + maxY;
    }

    private static void firstDiff(String name, int[] awt, int[] raw) {
        for (int i = 0; i < awt.length; i++) {
            if (awt[i] != raw[i]) {
                int x = i % W;
                int y = i / W;
                System.out.println("P1A_G2B_FIRST_DIFF=" + name + " X=" + x + " Y=" + y
                        + " AWT=" + hex(awt[i]) + " RAW=" + hex(raw[i]));
                return;
            }
        }
    }

    private static void dumpMask(String name, int[] p) {
        System.out.println("P1A_G2B_MASK_BEGIN=" + name);
        for (int y = 0; y < H; y++) {
            StringBuffer row = new StringBuffer(W);
            for (int x = 0; x < W; x++) {
                row.append(((p[y * W + x] & 0x00FFFFFF) == COLOR) ? '#' : '.');
            }
            System.out.println(row.toString());
        }
        System.out.println("P1A_G2B_MASK_END=" + name);
    }

    private static String errorName(Throwable t) { return t == null ? "NONE" : t.getClass().getName(); }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
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
