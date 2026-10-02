package org.recompile.rg35xx.p1a;

import java.awt.BasicStroke;
import java.awt.Graphics2D;
import java.awt.Shape;
import java.awt.geom.GeneralPath;
import java.awt.geom.PathIterator;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

import sun.java2d.SunGraphics2D;
import sun.java2d.pipe.LoopPipe;
import sun.java2d.pipe.RenderingEngine;
import sun.java2d.pipe.ShapeSpanIterator;

/**
 * D5.2 diagnostic only.
 *
 * Proves the minimal Pisces subset for the D5/D5.1 corpus:
 * integer-translate closed line polygons, default 1px BasicStroke,
 * non-AA stroke normalization, no dashes.
 *
 * Canonical owner:
 *   LoopPipe.getStrokeSpans -> PiscesRenderingEngine.strokeTo
 *
 * Reduced equivalent under this corpus:
 *   integer translate
 *   -> ON_NO_AA endpoint normalization (nearest .25 pixel)
 *   -> BasicStroke(1, CAP_SQUARE, JOIN_MITER, 10) widen
 *   -> ShapeSpanIterator NON_ZERO fill
 *
 * No RG35XX runtime source is exercised or modified.
 */
public final class RG35XXDGDrawVectorD52PiscesSubsetDiagnostic {
    private static final int W = 64;
    private static final int H = 48;
    private static final long SEED = 0x35d5001L;

    private static final class C {
        final String name;
        final int[] x;
        final int[] y;
        final int tx;
        final int ty;
        final int cx;
        final int cy;
        final int cw;
        final int ch;

        C(String name, int[] x, int[] y) {
            this(name, x, y, 0, 0, 0, 0, W, H);
        }

        C(String name, int[] x, int[] y,
          int tx, int ty, int cx, int cy, int cw, int ch) {
            this.name = name;
            this.x = x;
            this.y = y;
            this.tx = tx;
            this.ty = ty;
            this.cx = cx;
            this.cy = cy;
            this.cw = cw;
            this.ch = ch;
        }
    }

    private static final C[] FIXED = {
        new C("TRIANGLE_STANDARD", new int[]{7,33,18}, new int[]{6,8,27}),
        new C("TRIANGLE_REVERSED", new int[]{18,33,7}, new int[]{27,8,6}),
        new C("TRIANGLE_FLAT", new int[]{6,22,38}, new int[]{15,15,15}),
        new C("TRIANGLE_DUPLICATE", new int[]{10,10,31}, new int[]{9,9,28}),
        new C("TRIANGLE_CLIP", new int[]{-5,38,17}, new int[]{2,8,39}, 0,0,4,5,31,26),
        new C("TRIANGLE_TRANSLATE", new int[]{7,33,18}, new int[]{6,8,27}, 5,3,0,0,W,H),
        new C("POLYGON_SQUARE", new int[]{6,34,34,6}, new int[]{6,6,30,30}),
        new C("POLYGON_CONCAVE", new int[]{5,36,20,38,7}, new int[]{5,8,18,31,34}),
        new C("POLYGON_STAR", new int[]{24,29,40,31,34,24,14,17,8,19}, new int[]{3,14,14,21,35,27,35,21,14,14}),
        new C("POLYGON_SELF_CROSS", new int[]{7,39,8,38}, new int[]{6,32,31,7}),
        new C("POLYGON_DUPLICATE", new int[]{5,33,33,20,7}, new int[]{7,7,7,29,30}),
        new C("POLYGON_ALREADY_CLOSED", new int[]{7,36,29,9,7}, new int[]{6,8,31,28,6}),
        new C("POLYGON_ONE_POINT", new int[]{17}, new int[]{13}),
        new C("POLYGON_TWO_POINTS", new int[]{8,37}, new int[]{7,29}),
        new C("POLYGON_CLIP", new int[]{-9,46,39,8}, new int[]{4,3,37,42}, 0,0,3,6,35,27),
        new C("POLYGON_TRANSLATE", new int[]{5,34,26,38,8}, new int[]{6,7,18,29,31}, 4,-2,0,0,W,H),
        new C("POLYGON_CLIP_TRANSLATE", new int[]{2,36,31,5}, new int[]{3,7,35,31}, 6,4,4,5,34,27),
        new C("POLYGON_PARTIAL_NEGATIVE", new int[]{-18,22,47,5}, new int[]{-9,4,33,43}),
        new C("POLYGON_RIGHT_BOTTOM", new int[]{42,75,70,48}, new int[]{30,27,61,55}),
        new C("POLYGON_OFFSCREEN", new int[]{80,96,91,78}, new int[]{60,62,79,76})
    };

    private static final class SpanResult {
        final boolean[] mask;
        final int rects;
        final int pixels;

        SpanResult(boolean[] mask, int rects, int pixels) {
            this.mask = mask;
            this.rects = rects;
            this.pixels = pixels;
        }
    }

    public static void main(String[] args) {
        int fixedCases = 0;
        int fuzzCases = 0;
        int comparisons = 0;
        int maskFailures = 0;
        int rectCountMismatchCases = 0;
        long canonicalRects = 0;
        long reducedRects = 0;
        long canonicalPixels = 0;
        long reducedPixels = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixedCases++;
            SpanResult canonical = canonical(c);
            SpanResult reduced = reduced(c);
            comparisons++;
            canonicalRects += canonical.rects;
            reducedRects += reduced.rects;
            canonicalPixels += canonical.pixels;
            reducedPixels += reduced.pixels;
            if (!Arrays.equals(canonical.mask, reduced.mask)) {
                maskFailures++;
                System.out.println("D52_MISMATCH=" + c.name + " first=" + firstDiff(canonical.mask, reduced.mask));
            }
            if (canonical.rects != reduced.rects) rectCountMismatchCases++;
            if ("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) {
                System.out.println("D52_SENTINEL=" + c.name +
                    " CANON_RECTS=" + canonical.rects +
                    " REDUCED_RECTS=" + reduced.rects +
                    " CANON_PIXELS=" + canonical.pixels +
                    " REDUCED_PIXELS=" + reduced.pixels +
                    " CANON_MASK_CHECKSUM=" + Long.toHexString(checksum(canonical.mask)) +
                    " REDUCED_MASK_CHECKSUM=" + Long.toHexString(checksum(reduced.mask)));
            }
        }

        Random rnd = new Random(SEED);
        for (int i = 0; i < 160; i++) {
            int n = 3 + rnd.nextInt(6);
            int[] x = new int[n];
            int[] y = new int[n];
            for (int p = 0; p < n; p++) {
                x[p] = rnd.nextInt(86) - 11;
                y[p] = rnd.nextInt(66) - 9;
            }
            C c = new C("FUZZ_" + i, x, y,
                        rnd.nextInt(9) - 4, rnd.nextInt(9) - 4,
                        rnd.nextInt(9), rnd.nextInt(7),
                        34 + rnd.nextInt(31), 28 + rnd.nextInt(25));
            fuzzCases++;
            SpanResult canonical = canonical(c);
            SpanResult reduced = reduced(c);
            comparisons++;
            canonicalRects += canonical.rects;
            reducedRects += reduced.rects;
            canonicalPixels += canonical.pixels;
            reducedPixels += reduced.pixels;
            if (!Arrays.equals(canonical.mask, reduced.mask)) {
                maskFailures++;
                if (maskFailures <= 8) {
                    System.out.println("D52_MISMATCH=" + c.name + " first=" + firstDiff(canonical.mask, reduced.mask));
                }
            }
            if (canonical.rects != reduced.rects) rectCountMismatchCases++;
        }

        BasicStroke bs = new BasicStroke();
        System.out.println("P1A_DG_D52_FIXED_CASE_COUNT=" + fixedCases);
        System.out.println("P1A_DG_D52_FUZZ_CASE_COUNT=" + fuzzCases);
        System.out.println("P1A_DG_D52_COMPARISON_COUNT=" + comparisons);
        System.out.println("P1A_DG_D52_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D52_MASK_FAILURE_COUNT=" + maskFailures);
        System.out.println("P1A_DG_D52_RECT_COUNT_MISMATCH_CASE_COUNT=" + rectCountMismatchCases);
        System.out.println("P1A_DG_D52_CANONICAL_RECT_TOTAL=" + canonicalRects);
        System.out.println("P1A_DG_D52_REDUCED_RECT_TOTAL=" + reducedRects);
        System.out.println("P1A_DG_D52_CANONICAL_PIXEL_TOTAL=" + canonicalPixels);
        System.out.println("P1A_DG_D52_REDUCED_PIXEL_TOTAL=" + reducedPixels);
        System.out.println("P1A_DG_D52_RENDERING_ENGINE=" + RenderingEngine.getInstance().getClass().getName());
        System.out.println("P1A_DG_D52_STROKE_WIDTH=" + bs.getLineWidth());
        System.out.println("P1A_DG_D52_STROKE_CAP=" + bs.getEndCap());
        System.out.println("P1A_DG_D52_STROKE_JOIN=" + bs.getLineJoin());
        System.out.println("P1A_DG_D52_STROKE_MITER=" + bs.getMiterLimit());
        System.out.println("P1A_DG_D52_DASH_NULL=" + (bs.getDashArray() == null));
        System.out.println("P1A_DG_D52_NORMALIZATION=ON_NO_AA_NEAREST_QUARTER_PIXEL");
        System.out.println("P1A_DG_D52_REDUCED_OWNER=NORMALIZE_QUARTER_PIXEL_BASICSTROKE_WIDEN_SHAPESPANITERATOR_NONZERO");
        System.out.println("P1A_DG_D52_RUNTIME_CHANGE=NO");
        if (maskFailures != 0) {
            throw new RuntimeException("P1A_DG_D52_REDUCED_SUBSET_FAIL=" + maskFailures);
        }
        System.out.println("P1A_DG_D52_DIAGNOSTIC_GATE=PASS");
    }

    private static SpanResult canonical(C c) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        if (!(g instanceof SunGraphics2D)) {
            String name = g.getClass().getName();
            g.dispose();
            throw new RuntimeException("P1A_DG_D52_NOT_SUNGRAPHICS2D=" + name);
        }
        SunGraphics2D sg = (SunGraphics2D) g;
        ShapeSpanIterator ssi = LoopPipe.getStrokeSpans(sg, makePath(c.x, c.y));
        SpanResult out = collect(ssi);
        ssi.dispose();
        g.dispose();
        return out;
    }

    private static SpanResult reduced(C c) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        if (!(g instanceof SunGraphics2D)) {
            String name = g.getClass().getName();
            g.dispose();
            throw new RuntimeException("P1A_DG_D52_NOT_SUNGRAPHICS2D=" + name);
        }
        SunGraphics2D sg = (SunGraphics2D) g;

        GeneralPath normalized = makeNormalizedDevicePath(c);
        Shape widened = new BasicStroke().createStrokedShape(normalized);
        ShapeSpanIterator ssi = new ShapeSpanIterator(false);
        ssi.setOutputArea(sg.getCompClip());
        ssi.setRule(PathIterator.WIND_NON_ZERO);
        ssi.appendPath(widened.getPathIterator(null));
        SpanResult out = collect(ssi);
        ssi.dispose();
        g.dispose();
        return out;
    }

    private static GeneralPath makePath(int[] x, int[] y) {
        GeneralPath gp = new GeneralPath(GeneralPath.WIND_EVEN_ODD);
        if (x.length > 0) {
            gp.moveTo(x[0], y[0]);
            for (int i = 1; i < x.length; i++) gp.lineTo(x[i], y[i]);
            gp.closePath();
        }
        return gp;
    }

    private static GeneralPath makeNormalizedDevicePath(C c) {
        GeneralPath gp = new GeneralPath(GeneralPath.WIND_EVEN_ODD);
        if (c.x.length > 0) {
            gp.moveTo(normNoAA(c.x[0] + c.tx), normNoAA(c.y[0] + c.ty));
            for (int i = 1; i < c.x.length; i++) {
                gp.lineTo(normNoAA(c.x[i] + c.tx), normNoAA(c.y[i] + c.ty));
            }
            gp.closePath();
        }
        return gp;
    }

    private static float normNoAA(int v) {
        return (float)Math.floor(((float)v) + 0.25f) + 0.25f;
    }

    private static SpanResult collect(ShapeSpanIterator ssi) {
        boolean[] mask = new boolean[W * H];
        int[] span = new int[4];
        int rects = 0;
        int pixels = 0;
        while (ssi.nextSpan(span)) {
            rects++;
            for (int yy = span[1]; yy < span[3]; yy++) {
                if (yy < 0 || yy >= H) continue;
                for (int xx = span[0]; xx < span[2]; xx++) {
                    if (xx < 0 || xx >= W) continue;
                    int idx = yy * W + xx;
                    if (!mask[idx]) {
                        mask[idx] = true;
                        pixels++;
                    }
                }
            }
        }
        return new SpanResult(mask, rects, pixels);
    }

    private static String firstDiff(boolean[] a, boolean[] b) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return (i % W) + "," + (i / W) + ":" + a[i] + "/" + b[i];
        }
        return "NONE";
    }

    private static long checksum(boolean[] mask) {
        long h = 1469598103934665603L;
        for (int i = 0; i < mask.length; i++) {
            h ^= mask[i] ? 1L : 0L;
            h *= 1099511628211L;
        }
        return h;
    }
}
