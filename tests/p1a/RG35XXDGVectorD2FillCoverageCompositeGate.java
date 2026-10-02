package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

/**
 * P1A-DG-VECTOR-D2 diagnostic-only gate for Nokia DirectGraphics fill family.
 *
 * This does not execute or modify RG35XX runtime code. It tests a property of
 * the pinned Java2D reference used by Miyoo/FreeJ2ME:
 *   fillTriangle/fillPolygon alpha output == opaque polygon coverage
 *                                      + exact SrcOver on an opaque background.
 *
 * Generic java.awt.Polygon uses WIND_EVEN_ODD. Do not substitute the
 * Arc2D.PIE/non-zero winding rule used by the G2D fillArc work.
 */
public final class RG35XXDGVectorD2FillCoverageCompositeGate {
    private static final int W = 64;
    private static final int H = 52;
    private static final int BG = 0xFF102030;
    private static final int RGB = 0x003366CC;
    private static final int OPAQUE = 0xFF3366CC;
    private static final int[] ALPHAS = {0x40, 0x80, 0xCC};
    private static final long SEED = 0x35D2F11L;

    private static int fixedTriangleCount;
    private static int fixedPolygonCount;
    private static int fuzzTriangleCount;
    private static int fuzzPolygonCount;
    private static int failures;
    private static int reportedFailures;

    private static final class FillCase {
        final String name;
        final int[] xs;
        final int[] ys;
        final int n;
        final boolean clip;
        final int cx, cy, cw, ch;
        final int tx, ty;

        FillCase(String name, int[] xs, int[] ys, int n) {
            this(name, xs, ys, n, false, 0, 0, 0, 0, 0, 0);
        }

        FillCase(String name, int[] xs, int[] ys, int n,
                 boolean clip, int cx, int cy, int cw, int ch,
                 int tx, int ty) {
            this.name = name;
            this.xs = xs;
            this.ys = ys;
            this.n = n;
            this.clip = clip;
            this.cx = cx;
            this.cy = cy;
            this.cw = cw;
            this.ch = ch;
            this.tx = tx;
            this.ty = ty;
        }
    }

    public static void main(String[] args) {
        // Locks the integer SrcOver rounding model against the D1 observation.
        int d1 = srcOverOpaqueDst(0x803366CC, BG);
        System.out.println("DGVD2_D1_BLEND_803366CC_OVER_FF102030=" + hex(d1));
        if (d1 != 0xFF22437E) {
            throw new RuntimeException("DGVD2_SRCOVER_MODEL_SELF_CHECK_FAIL");
        }

        runFixedTriangles();
        runFixedPolygons();
        runFuzzTriangles();
        runFuzzPolygons();

        System.out.println("DGVD2_FIXED_TRIANGLE_COUNT=" + fixedTriangleCount);
        System.out.println("DGVD2_FIXED_POLYGON_COUNT=" + fixedPolygonCount);
        System.out.println("DGVD2_FUZZ_TRIANGLE_COUNT=" + fuzzTriangleCount);
        System.out.println("DGVD2_FUZZ_POLYGON_COUNT=" + fuzzPolygonCount);
        System.out.println("DGVD2_ALPHA_LEVEL_COUNT=" + ALPHAS.length);
        System.out.println("DGVD2_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("DGVD2_STRICT_FAILURE_COUNT=" + failures);
        System.out.println("DGVD2_RUNTIME_CHANGE=NO");
        System.out.println("DGVD2_GENERIC_POLYGON_WINDING=EVEN_ODD");

        if (failures != 0) {
            throw new RuntimeException("DGVD2_STRICT_FAIL=" + failures);
        }

        System.out.println("DGVD2_FILL_COVERAGE_ALPHA_INDEPENDENT=YES_FOR_MATRIX");
        System.out.println("DGVD2_FILL_ALPHA_MODEL=OPAQUE_COVERAGE_PLUS_EXACT_SRCOVER");
        System.out.println("DGVD2_FILL_DIAGNOSTIC_GATE=PASS");
    }

    private static void runFixedTriangles() {
        checkTriangle(tc("TRI_REFERENCE", 4,4,24,7,10,22));
        checkTriangle(tc("TRI_REVERSED", 10,22,24,7,4,4));
        checkTriangle(tc("TRI_PERM_BAC", 24,7,4,4,10,22));
        checkTriangle(tc("TRI_PERM_BCA", 24,7,10,22,4,4));
        checkTriangle(tc("TRI_PERM_CAB", 10,22,4,4,24,7));
        checkTriangle(tc("TRI_PERM_CBA", 10,22,24,7,4,4));
        checkTriangle(tc("TRI_FLAT_HORIZONTAL", 5,12,16,12,25,12));
        checkTriangle(tc("TRI_FLAT_VERTICAL", 12,4,12,16,12,25));
        checkTriangle(tc("TRI_DUPLICATE_AB", 5,5,5,5,23,20));
        checkTriangle(tc("TRI_DUPLICATE_BC", 5,5,23,20,23,20));
        checkTriangle(tc("TRI_ALL_DUPLICATE", 12,11,12,11,12,11));
        checkTriangle(tc("TRI_SKINNY_VERTICAL", 10,3,11,27,12,3));
        checkTriangle(tc("TRI_SKINNY_HORIZONTAL", 3,14,35,15,3,16));
        checkTriangle(tc("TRI_TINY_RIGHT", 10,10,11,10,10,11));
        checkTriangle(tc("TRI_TINY_TWO", 10,10,12,10,10,12));
        checkTriangle(tcx("TRI_CLIP", new int[]{3,31,12}, new int[]{3,8,27},
                          true,9,8,13,11,0,0));
        checkTriangle(tcx("TRI_TRANSLATE", new int[]{2,22,7}, new int[]{2,5,20},
                          false,0,0,0,0,5,4));
        checkTriangle(tcx("TRI_CLIP_TRANSLATE", new int[]{-2,26,8}, new int[]{-1,4,24},
                          true,10,8,14,12,5,4));
        checkTriangle(tc("TRI_PARTIAL_NEGATIVE", -12,-7,23,4,6,25));
        checkTriangle(tc("TRI_PARTIAL_RIGHT_BOTTOM", 17,9,71,14,38,62));
        checkTriangle(tc("TRI_SPANNING", -20,-12,81,3,18,69));
    }

    private static void runFixedPolygons() {
        checkPolygon(pc("POLY_CONVEX_5", new int[]{5,34,46,25,7}, new int[]{6,5,21,42,31}));
        checkPolygon(pc("POLY_CONVEX_5_REVERSED", new int[]{7,25,46,34,5}, new int[]{31,42,21,5,6}));
        checkPolygon(pc("POLY_CONCAVE_ARROW", new int[]{6,42,28,42,6,18}, new int[]{7,7,21,35,35,21}));
        checkPolygon(pc("POLY_CONCAVE_ARROW_REVERSED", new int[]{18,6,42,28,42,6}, new int[]{21,35,35,21,7,7}));
        checkPolygon(pc("POLY_BOWTIE", new int[]{8,45,8,45}, new int[]{7,35,35,7}));
        checkPolygon(pc("POLY_STAR_SELF_CROSS", new int[]{27,34,51,39,43,27,11,15,3,20},
                         new int[]{3,18,18,28,45,35,45,28,18,18}));
        checkPolygon(pc("POLY_DUPLICATE_POINTS", new int[]{7,35,35,35,12,7,7}, new int[]{8,8,8,31,39,31,8}));
        checkPolygon(pc("POLY_COLLINEAR_H", new int[]{4,18,33,52}, new int[]{17,17,17,17}));
        checkPolygon(pc("POLY_COLLINEAR_V", new int[]{22,22,22,22}, new int[]{4,13,29,45}));
        checkPolygon(new FillCase("POLY_TWO_POINTS", new int[]{9,41}, new int[]{8,33}, 2));
        checkPolygon(new FillCase("POLY_ONE_POINT", new int[]{19}, new int[]{14}, 1));
        checkPolygon(new FillCase("POLY_ZERO_POINTS", new int[0], new int[0], 0));
        checkPolygon(new FillCase("POLY_CLIP_CONCAVE", new int[]{1,50,29,50,1,16}, new int[]{2,2,22,45,45,22}, 6,
                                  true,11,9,27,24,0,0));
        checkPolygon(new FillCase("POLY_TRANSLATE_CONCAVE", new int[]{2,35,20,35,2,13}, new int[]{3,3,18,34,34,18}, 6,
                                  false,0,0,0,0,7,5));
        checkPolygon(new FillCase("POLY_CLIP_TRANSLATE_BOWTIE", new int[]{-4,41,-4,41}, new int[]{0,36,36,0}, 4,
                                  true,10,8,31,27,6,4));
        checkPolygon(pc("POLY_OFFSCREEN", new int[]{-20,18,79,51,-9}, new int[]{-14,-8,17,68,49}));
        // Same loop traversed twice: a useful even-odd cancellation stress case.
        checkPolygon(pc("POLY_DOUBLE_LOOP_EVEN_ODD", new int[]{10,38,38,10,10,38,38,10},
                         new int[]{10,10,36,36,10,10,36,36}));
    }

    private static void runFuzzTriangles() {
        Random r = new Random(SEED);
        for (int i = 0; i < 128; i++) {
            int[] xs = new int[3];
            int[] ys = new int[3];
            for (int j = 0; j < 3; j++) {
                xs[j] = r.nextInt(97) - 16;
                ys[j] = r.nextInt(81) - 14;
            }
            boolean clip = (i % 3) == 0;
            int cx = r.nextInt(24);
            int cy = r.nextInt(18);
            int cw = 8 + r.nextInt(38);
            int ch = 7 + r.nextInt(30);
            int tx = (i % 4) == 0 ? r.nextInt(13) - 6 : 0;
            int ty = (i % 4) == 0 ? r.nextInt(11) - 5 : 0;
            checkTriangle(new FillCase("FTRI_" + i, xs, ys, 3, clip, cx, cy, cw, ch, tx, ty));
        }
    }

    private static void runFuzzPolygons() {
        Random r = new Random(SEED ^ 0x504F4C59L);
        for (int i = 0; i < 128; i++) {
            int n = r.nextInt(9); // includes 0/1/2-point degenerate polygons
            int[] xs = new int[n];
            int[] ys = new int[n];
            for (int j = 0; j < n; j++) {
                xs[j] = r.nextInt(97) - 16;
                ys[j] = r.nextInt(81) - 14;
            }
            if ((i % 5) == 0 && n >= 4) {
                // Inject duplicate vertices without inventing a different API path.
                xs[n - 1] = xs[0];
                ys[n - 1] = ys[0];
            }
            boolean clip = (i % 3) == 0;
            int cx = r.nextInt(24);
            int cy = r.nextInt(18);
            int cw = 8 + r.nextInt(38);
            int ch = 7 + r.nextInt(30);
            int tx = (i % 4) == 0 ? r.nextInt(13) - 6 : 0;
            int ty = (i % 4) == 0 ? r.nextInt(11) - 5 : 0;
            checkPolygon(new FillCase("FPOLY_" + i, xs, ys, n, clip, cx, cy, cw, ch, tx, ty));
        }
    }

    private static FillCase tc(String name, int x1,int y1,int x2,int y2,int x3,int y3) {
        return new FillCase(name, new int[]{x1,x2,x3}, new int[]{y1,y2,y3}, 3);
    }

    private static FillCase tcx(String name, int[] xs, int[] ys,
                                boolean clip,int cx,int cy,int cw,int ch,int tx,int ty) {
        return new FillCase(name, xs, ys, 3, clip, cx, cy, cw, ch, tx, ty);
    }

    private static FillCase pc(String name, int[] xs, int[] ys) {
        return new FillCase(name, xs, ys, xs.length);
    }

    private static void checkTriangle(FillCase c) {
        fixedOrFuzzTriangle(c);
        check(c);
    }

    private static void checkPolygon(FillCase c) {
        fixedOrFuzzPolygon(c);
        check(c);
    }

    private static void fixedOrFuzzTriangle(FillCase c) {
        if (c.name.startsWith("FTRI_")) fuzzTriangleCount++; else fixedTriangleCount++;
    }

    private static void fixedOrFuzzPolygon(FillCase c) {
        if (c.name.startsWith("FPOLY_")) fuzzPolygonCount++; else fixedPolygonCount++;
    }

    private static void check(FillCase c) {
        int[] opaque = render(c, OPAQUE);
        verifyOpaque(c, opaque);

        int[] transparent = render(c, RGB); // alpha == 0
        if (!allBackground(transparent)) {
            fail(c.name, "ALPHA0_CHANGED_FRAME", transparent, null);
        }

        for (int ai = 0; ai < ALPHAS.length; ai++) {
            int src = (ALPHAS[ai] << 24) | RGB;
            int[] actual = render(c, src);
            int blended = srcOverOpaqueDst(src, BG);
            int[] expected = deriveFromOpaqueCoverage(opaque, blended);
            if (!Arrays.equals(actual, expected)) {
                fail(c.name, "ALPHA_" + ALPHAS[ai] + "_FRAME_MISMATCH", actual, expected);
            }
        }
    }

    private static void verifyOpaque(FillCase c, int[] opaque) {
        for (int i = 0; i < opaque.length; i++) {
            int v = opaque[i];
            if (v != BG && v != OPAQUE) {
                fail(c.name, "OPAQUE_UNEXPECTED_PIXEL_" + hex(v), opaque, null);
                return;
            }
        }
    }

    private static int[] deriveFromOpaqueCoverage(int[] opaque, int blended) {
        int[] out = new int[opaque.length];
        for (int i = 0; i < opaque.length; i++) {
            out[i] = opaque[i] == BG ? BG : blended;
        }
        return out;
    }

    private static boolean allBackground(int[] p) {
        for (int i = 0; i < p.length; i++) if (p[i] != BG) return false;
        return true;
    }

    private static int[] render(FillCase c, int argb) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] bg = new int[W * H];
        Arrays.fill(bg, BG);
        image.setRGB(0, 0, W, H, bg, 0, W);

        Graphics2D g = image.createGraphics();
        if (c.clip) g.setClip(c.cx, c.cy, c.cw, c.ch);
        if (c.tx != 0 || c.ty != 0) g.translate(c.tx, c.ty);
        g.setColor(new Color(argb, true));
        g.fillPolygon(c.xs, c.ys, c.n);
        g.dispose();
        return image.getRGB(0, 0, W, H, null, 0, W);
    }

    /** Exact 8-bit SrcOver for an opaque destination, round-to-nearest /255. */
    private static int srcOverOpaqueDst(int src, int dst) {
        int a = (src >>> 24) & 0xFF;
        int ia = 255 - a;
        int sr = (src >>> 16) & 0xFF;
        int sg = (src >>> 8) & 0xFF;
        int sb = src & 0xFF;
        int dr = (dst >>> 16) & 0xFF;
        int dg = (dst >>> 8) & 0xFF;
        int db = dst & 0xFF;
        int r = (sr * a + dr * ia + 127) / 255;
        int g = (sg * a + dg * ia + 127) / 255;
        int b = (sb * a + db * ia + 127) / 255;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    private static void fail(String name, String reason, int[] actual, int[] expected) {
        failures++;
        if (reportedFailures >= 20) return;
        reportedFailures++;
        System.out.println("DGVD2_FAILURE=" + name + " REASON=" + reason
                + " ACTUAL=" + checksum(actual)
                + " EXPECTED=" + checksum(expected));
        if (actual != null && expected != null) {
            for (int i = 0; i < actual.length; i++) {
                if (actual[i] != expected[i]) {
                    System.out.println("DGVD2_FIRST_DIFF=" + name
                            + " X=" + (i % W) + " Y=" + (i / W)
                            + " ACTUAL=" + hex(actual[i])
                            + " EXPECTED=" + hex(expected[i]));
                    break;
                }
            }
        }
    }

    private static String checksum(int[] p) {
        if (p == null) return "NONE";
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) {
            h ^= (p[i] & 0xFFFFFFFFL);
            h *= 1099511628211L;
        }
        return Long.toHexString(h);
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
