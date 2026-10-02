package org.recompile.rg35xx.p1a;

import java.awt.BasicStroke;
import java.awt.Graphics2D;
import java.awt.Shape;
import java.awt.geom.GeneralPath;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

import sun.java2d.SunGraphics2D;
import sun.java2d.pipe.LoopPipe;
import sun.java2d.pipe.RenderingEngine;
import sun.java2d.pipe.ShapeSpanIterator;

/**
 * D5.2 diagnostic only. Proves the minimum source-equivalent boundary for
 * alpha DirectGraphics drawPolygon/drawTriangle stroke coverage:
 * integer translation -> ON_NO_AA quarter-pixel normalization -> default
 * 1px BasicStroke/Pisces widening -> ShapeSpanIterator(false) NON_ZERO scan.
 * No RG35XX runtime source is exercised or modified.
 */
public final class RG35XXDGDrawVectorD52MinimalStrokeBoundaryDiagnostic {
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
        final int[] mask;
        final String sequence;
        final int rects;
        final int pixels;

        SpanResult(int[] mask, String sequence, int rects, int pixels) {
            this.mask = mask;
            this.sequence = sequence;
            this.rects = rects;
            this.pixels = pixels;
        }
    }

    public static void main(String[] args) {
        int fixed = 0;
        int fuzz = 0;
        int comparisons = 0;
        int failures = 0;
        long totalRects = 0;
        long totalPixels = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixed++;
            SpanResult a = canonical(c);
            SpanResult b = isolated(c);
            comparisons++;
            totalRects += a.rects;
            totalPixels += a.pixels;
            if (!same(a, b)) {
                failures++;
                System.out.println("D52_MISMATCH=" + c.name + " firstMask=" + firstDiff(a.mask,b.mask) +
                                   " canonicalRects=" + a.rects + " isolatedRects=" + b.rects);
            }
            if ("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) {
                System.out.println("D52_SENTINEL=" + c.name +
                                   " RECTS=" + a.rects +
                                   " PIXELS=" + a.pixels +
                                   " MASK_CHECKSUM=" + Long.toHexString(checksum(a.mask)) +
                                   " SEQUENCE_CHECKSUM=" + Long.toHexString(checksum(a.sequence)));
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
            fuzz++;
            SpanResult a = canonical(c);
            SpanResult b = isolated(c);
            comparisons++;
            totalRects += a.rects;
            totalPixels += a.pixels;
            if (!same(a, b)) {
                failures++;
                if (failures <= 8) {
                    System.out.println("D52_MISMATCH=" + c.name + " firstMask=" + firstDiff(a.mask,b.mask) +
                                       " canonicalRects=" + a.rects + " isolatedRects=" + b.rects);
                }
            }
        }

        BasicStroke bs = new BasicStroke();
        System.out.println("P1A_DG_D52_FIXED_CASE_COUNT=" + fixed);
        System.out.println("P1A_DG_D52_FUZZ_CASE_COUNT=" + fuzz);
        System.out.println("P1A_DG_D52_COMPARISON_COUNT=" + comparisons);
        System.out.println("P1A_DG_D52_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D52_BOUNDARY_FAILURE_COUNT=" + failures);
        System.out.println("P1A_DG_D52_TOTAL_SPAN_RECT_COUNT=" + totalRects);
        System.out.println("P1A_DG_D52_TOTAL_SPAN_PIXEL_COUNT=" + totalPixels);
        System.out.println("P1A_DG_D52_RENDERING_ENGINE=" + RenderingEngine.getInstance().getClass().getName());
        System.out.println("P1A_DG_D52_NORMALIZATION=ON_NO_AA_QUARTER_PIXEL");
        System.out.println("P1A_DG_D52_STROKE_WIDTH=" + bs.getLineWidth());
        System.out.println("P1A_DG_D52_STROKE_CAP=" + bs.getEndCap());
        System.out.println("P1A_DG_D52_STROKE_JOIN=" + bs.getLineJoin());
        System.out.println("P1A_DG_D52_STROKE_MITER=" + bs.getMiterLimit());
        System.out.println("P1A_DG_D52_STROKE_DASH=" + (bs.getDashArray() == null ? "NONE" : "PRESENT"));
        System.out.println("P1A_DG_D52_SSI_ADJUST=false");
        System.out.println("P1A_DG_D52_SSI_RULE=NON_ZERO");
        System.out.println("P1A_DG_D52_MINIMUM_BOUNDARY=NORMALIZE_QUARTER_PIXEL+LINE_ONLY_STROKER+FLOAT_SSI_NONZERO_SCAN");
        System.out.println("P1A_DG_D52_RUNTIME_CHANGE=NO");
        if (failures != 0) throw new RuntimeException("P1A_DG_D52_BOUNDARY_FAIL=" + failures);
        System.out.println("P1A_DG_D52_DIAGNOSTIC_GATE=PASS");
    }

    private static boolean same(SpanResult a, SpanResult b) {
        return a.rects == b.rects && a.pixels == b.pixels &&
               a.sequence.equals(b.sequence) && Arrays.equals(a.mask, b.mask);
    }

    private static SpanResult canonical(C c) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        SunGraphics2D sg = (SunGraphics2D)g;
        ShapeSpanIterator ssi = LoopPipe.getStrokeSpans(sg, makePath(c.x, c.y));
        try {
            return collect(ssi);
        } finally {
            ssi.dispose();
            g.dispose();
        }
    }

    private static SpanResult isolated(C c) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        SunGraphics2D sg = (SunGraphics2D)g;

        GeneralPath normalized = makeNormalizedDevicePath(c);
        BasicStroke bs = new BasicStroke();
        Shape widened = RenderingEngine.getInstance().createStrokedShape(
            normalized, 1.0f, BasicStroke.CAP_SQUARE, BasicStroke.JOIN_MITER,
            10.0f, null, 0.0f);

        ShapeSpanIterator ssi = new ShapeSpanIterator(false);
        ssi.setOutputArea(sg.getCompClip());
        ssi.appendPath(widened.getPathIterator(null));
        try {
            return collect(ssi);
        } finally {
            ssi.dispose();
            g.dispose();
        }
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
        GeneralPath gp = new GeneralPath(GeneralPath.WIND_NON_ZERO);
        if (c.x.length > 0) {
            gp.moveTo(norm(c.x[0] + c.tx), norm(c.y[0] + c.ty));
            for (int i = 1; i < c.x.length; i++) {
                gp.lineTo(norm(c.x[i] + c.tx), norm(c.y[i] + c.ty));
            }
            gp.closePath();
        }
        return gp;
    }

    private static float norm(int v) {
        return (float)Math.floor(((float)v) + 0.25f) + 0.25f;
    }

    private static SpanResult collect(ShapeSpanIterator ssi) {
        int[] mask = new int[W * H];
        StringBuilder seq = new StringBuilder();
        int[] span = new int[4];
        int rects = 0;
        int pixels = 0;
        while (ssi.nextSpan(span)) {
            rects++;
            seq.append(span[0]).append(',').append(span[1]).append(',')
               .append(span[2]).append(',').append(span[3]).append(';');
            for (int yy = span[1]; yy < span[3]; yy++) {
                if (yy < 0 || yy >= H) continue;
                for (int xx = span[0]; xx < span[2]; xx++) {
                    if (xx < 0 || xx >= W) continue;
                    mask[yy * W + xx] = 1;
                    pixels++;
                }
            }
        }
        return new SpanResult(mask, seq.toString(), rects, pixels);
    }

    private static String firstDiff(int[] a, int[] b) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return (i % W) + "," + (i / W) + ":" + a[i] + "/" + b[i];
        }
        return "NONE";
    }

    private static long checksum(int[] a) {
        long h = 1469598103934665603L;
        for (int i = 0; i < a.length; i++) {
            h ^= (long)a[i];
            h *= 1099511628211L;
        }
        return h;
    }

    private static long checksum(String s) {
        long h = 1469598103934665603L;
        for (int i = 0; i < s.length(); i++) {
            h ^= (long)s.charAt(i);
            h *= 1099511628211L;
        }
        return h;
    }
}
