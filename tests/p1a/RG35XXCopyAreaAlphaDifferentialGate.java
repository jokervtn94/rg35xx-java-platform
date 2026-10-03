package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * G1 alpha gate: copyArea must preserve pinned SrcOver + live-raster overlap.
 *
 * The pinned PlatformImage(int[]) constructor itself draws the ARGB array onto
 * a transparent Java2D surface. Semi-alpha values can therefore be normalized
 * by Java2D before copyArea is reached. To isolate copyArea, first converge the
 * seed through the canonical constructor/getRGB path, then require identical
 * AWT/Raw pre-copy baselines before comparing the operation output.
 */
public final class RG35XXCopyAreaAlphaDifferentialGate {
    private static final int W = 20;
    private static final int H = 12;

    public static void main(String[] args) {
        int[] seed = canonicalFixedPoint(makeSeed());
        int[] awtBaseline = createAndRead(false, seed);
        int[] rawBaseline = createAndRead(true, seed);
        boolean baselineMatch = Arrays.equals(awtBaseline, rawBaseline);
        System.out.println("P1A_G1_ALPHA_BASELINE_MATCH=" + baselineMatch
                + " AWT=" + checksum(awtBaseline)
                + " RAW=" + checksum(rawBaseline));
        if (!baselineMatch) {
            throw new RuntimeException("P1A_G1_ALPHA_BASELINE_NOT_EQUIVALENT");
        }

        int failures = 0;
        failures += run("ALPHA_NONOVERLAP", seed, 2, 3, 8, 4, 11, 3);
        failures += run("ALPHA_OVERLAP_RIGHT", seed, 2, 3, 10, 4, 5, 3);
        failures += run("ALPHA_OVERLAP_DOWN", seed, 3, 2, 8, 7, 3, 5);
        System.out.println("P1A_G1_ALPHA_FAILURE_COUNT=" + failures);
        if (failures != 0) {
            throw new RuntimeException("P1A_G1_ALPHA_DIFFERENTIAL_FAIL=" + failures);
        }
        System.out.println("P1A_G1_COPYAREA_ALPHA_DIFFERENTIAL_GATE=PASS");
    }

    private static int[] canonicalFixedPoint(int[] seed) {
        int[] current = copy(seed);
        for (int i = 0; i < 16; i++) {
            int[] next = createAndRead(false, current);
            if (Arrays.equals(current, next)) {
                System.out.println("P1A_G1_ALPHA_CANONICAL_FIXED_POINT_ITERATIONS=" + i);
                return current;
            }
            current = next;
        }
        throw new RuntimeException("P1A_G1_ALPHA_CANONICAL_FIXED_POINT_NOT_REACHED");
    }

    private static int run(String name, int[] seed,
                           int sx, int sy, int sw, int sh, int dx, int dy) {
        int[] awt = execute(false, seed, sx, sy, sw, sh, dx, dy);
        int[] raw = execute(true, seed, sx, sy, sw, sh, dx, dy);
        boolean match = Arrays.equals(awt, raw);
        System.out.println("P1A_G1_ALPHA_CASE=" + name + " MATCH=" + match
                + " AWT=" + checksum(awt) + " RAW=" + checksum(raw));
        if (!match) printFirstDiff(name, awt, raw);
        return match ? 0 : 1;
    }

    private static int[] execute(boolean raw, int[] seed,
                                 int sx, int sy, int sw, int sh, int dx, int dy) {
        if (raw) System.setProperty("rg35xx.raw2d", "true");
        else System.clearProperty("rg35xx.raw2d");
        PlatformImage image = new PlatformImage(copy(seed), W, H, true);
        PlatformGraphics g = image.getGraphics();
        g.copyArea(sx, sy, sw, sh, dx, dy, PlatformGraphics.TOP | PlatformGraphics.LEFT);
        return read(image);
    }

    private static int[] createAndRead(boolean raw, int[] seed) {
        if (raw) System.setProperty("rg35xx.raw2d", "true");
        else System.clearProperty("rg35xx.raw2d");
        PlatformImage image = new PlatformImage(copy(seed), W, H, true);
        return read(image);
    }

    private static int[] read(PlatformImage image) {
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }

    private static int[] makeSeed() {
        int[] p = new int[W * H];
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                int a = ((x + y) % 4 == 0) ? 0x20 : (((x + y) % 4 == 1) ? 0x60 : (((x + y) % 4 == 2) ? 0xA0 : 0xE0));
                int r = (x * 31 + y * 13) & 0xFF;
                int g = (x * 19 + y * 47) & 0xFF;
                int b = (x * 7 + y * 73) & 0xFF;
                p[y * W + x] = (a << 24) | (r << 16) | (g << 8) | b;
            }
        }
        return p;
    }

    private static int[] copy(int[] src) {
        int[] out = new int[src.length];
        System.arraycopy(src, 0, out, 0, src.length);
        return out;
    }

    private static void printFirstDiff(String name, int[] awt, int[] raw) {
        for (int i = 0; i < awt.length; i++) {
            if (awt[i] != raw[i]) {
                int x = i % W;
                int y = i / W;
                System.out.println("P1A_G1_ALPHA_FIRST_DIFF=" + name
                        + " X=" + x + " Y=" + y
                        + " AWT=" + hex(awt[i]) + " RAW=" + hex(raw[i]));
                return;
            }
        }
    }

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
