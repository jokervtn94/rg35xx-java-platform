package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.GeneralPath;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

import sun.java2d.SunGraphics2D;
import sun.java2d.pipe.LoopPipe;
import sun.java2d.pipe.RenderingEngine;
import sun.java2d.pipe.ShapeSpanIterator;

/**
 * D5.1 diagnostic only. Proves the semi-transparent DirectGraphics draw
 * polygon/triangle coverage model directly against LoopPipe.getStrokeSpans.
 * No RG35XX runtime source is exercised or modified.
 */
public final class RG35XXDGDrawVectorD51StrokeSpanDiagnostic {
    private static final int W = 64;
    private static final int H = 48;
    private static final int BG = 0xFF102030;
    private static final int RGB = 0x003366CC;
    private static final int[] ALPHAS = {0x40, 0x80, 0xCC};
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

    public static void main(String[] args) {
        int fixedCases = 0;
        int fuzzCases = 0;
        int comparisons = 0;
        int failures = 0;
        long spanRectCount = 0;
        long spanPixelCount = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixedCases++;
            for (int a = 0; a < ALPHAS.length; a++) {
                int argb = (ALPHAS[a] << 24) | RGB;
                Result r = compare(c, argb);
                comparisons++;
                spanRectCount += r.spanRects;
                spanPixelCount += r.spanPixels;
                if (!r.match) {
                    failures++;
                    System.out.println("D51_MISMATCH=" + c.name + " alpha=" + ALPHAS[a] + " first=" + r.firstDiff);
                }
                if (("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) && ALPHAS[a] == 0x80) {
                    System.out.println("D51_SENTINEL=" + c.name +
                        " ACTUAL_CHANGED=" + changedCount(r.actual) +
                        " SPAN_CHANGED=" + changedCount(r.expected) +
                        " ACTUAL_CHECKSUM=" + Long.toHexString(checksum(r.actual)) +
                        " SPAN_CHECKSUM=" + Long.toHexString(checksum(r.expected)) +
                        " SPAN_RECTS=" + r.spanRects +
                        " SPAN_PIXELS=" + r.spanPixels);
                }
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
            int tx = rnd.nextInt(9) - 4;
            int ty = rnd.nextInt(9) - 4;
            int cx = rnd.nextInt(9);
            int cy = rnd.nextInt(7);
            int cw = 34 + rnd.nextInt(31);
            int ch = 28 + rnd.nextInt(25);
            C c = new C("FUZZ_" + i, x, y, tx, ty, cx, cy, cw, ch);
            fuzzCases++;
            for (int a = 0; a < ALPHAS.length; a++) {
                int argb = (ALPHAS[a] << 24) | RGB;
                Result r = compare(c, argb);
                comparisons++;
                spanRectCount += r.spanRects;
                spanPixelCount += r.spanPixels;
                if (!r.match) {
                    failures++;
                    if (failures <= 8) {
                        System.out.println("D51_MISMATCH=" + c.name + " alpha=" + ALPHAS[a] + " first=" + r.firstDiff);
                    }
                }
            }
        }

        System.out.println("P1A_DG_D51_FIXED_CASE_COUNT=" + fixedCases);
        System.out.println("P1A_DG_D51_FUZZ_CASE_COUNT=" + fuzzCases);
        System.out.println("P1A_DG_D51_ALPHA_LEVEL_COUNT=" + ALPHAS.length);
        System.out.println("P1A_DG_D51_COMPARISON_COUNT=" + comparisons);
        System.out.println("P1A_DG_D51_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D51_STROKE_SPAN_FAILURE_COUNT=" + failures);
        System.out.println("P1A_DG_D51_TOTAL_SPAN_RECT_COUNT=" + spanRectCount);
        System.out.println("P1A_DG_D51_TOTAL_SPAN_PIXEL_COUNT=" + spanPixelCount);
        System.out.println("P1A_DG_D51_RENDERING_ENGINE=" + RenderingEngine.getInstance().getClass().getName());
        System.out.println("P1A_DG_D51_ALPHA_OWNER=OPENJDK8_LOOPPIPE_GETSTROKESPANS_RENDERINGENGINE_STROKETO_SHAPESPANITERATOR");
        System.out.println("P1A_DG_D51_ALPHA_COMPOSITE=G1_EXACT_8BIT_SRCOVER");
        System.out.println("P1A_DG_D51_RUNTIME_CHANGE=NO");
        if (failures != 0) {
            throw new RuntimeException("P1A_DG_D51_STROKE_SPAN_FAIL=" + failures);
        }
        System.out.println("P1A_DG_D51_DIAGNOSTIC_GATE=PASS");
    }

    private static final class Result {
        final int[] actual;
        final int[] expected;
        final boolean match;
        final String firstDiff;
        final int spanRects;
        final int spanPixels;

        Result(int[] actual, int[] expected, int spanRects, int spanPixels) {
            this.actual = actual;
            this.expected = expected;
            this.match = Arrays.equals(actual, expected);
            this.firstDiff = firstDiff(actual, expected);
            this.spanRects = spanRects;
            this.spanPixels = spanPixels;
        }
    }

    private static Result compare(C c, int argb) {
        int[] actual = renderApi(c, argb);
        SpanResult spans = renderStrokeSpans(c, argb);
        return new Result(actual, spans.pixels, spans.spanRects, spans.spanPixels);
    }

    private static int[] renderApi(C c, int argb) {
        BufferedImage image = blank();
        Graphics2D g = image.createGraphics();
        configure(g, c, argb);
        g.drawPolygon(c.x, c.y, c.x.length);
        g.dispose();
        return image.getRGB(0, 0, W, H, null, 0, W);
    }

    private static final class SpanResult {
        final int[] pixels;
        final int spanRects;
        final int spanPixels;

        SpanResult(int[] pixels, int spanRects, int spanPixels) {
            this.pixels = pixels;
            this.spanRects = spanRects;
            this.spanPixels = spanPixels;
        }
    }

    private static SpanResult renderStrokeSpans(C c, int argb) {
        BufferedImage image = blank();
        Graphics2D g = image.createGraphics();
        configure(g, c, argb);
        if (!(g instanceof SunGraphics2D)) {
            g.dispose();
            throw new RuntimeException("P1A_DG_D51_NOT_SUNGRAPHICS2D=" + g.getClass().getName());
        }
        SunGraphics2D sg = (SunGraphics2D) g;
        GeneralPath gp = makePath(c.x, c.y);
        ShapeSpanIterator ssi = LoopPipe.getStrokeSpans(sg, gp);
        int[] out = new int[W * H];
        Arrays.fill(out, BG);
        int[] span = new int[4];
        int rects = 0;
        int pixels = 0;
        try {
            while (ssi.nextSpan(span)) {
                rects++;
                for (int yy = span[1]; yy < span[3]; yy++) {
                    if (yy < 0 || yy >= H) continue;
                    for (int xx = span[0]; xx < span[2]; xx++) {
                        if (xx < 0 || xx >= W) continue;
                        int idx = yy * W + xx;
                        out[idx] = srcOver(argb, out[idx]);
                        pixels++;
                    }
                }
            }
        } finally {
            ssi.dispose();
            g.dispose();
        }
        return new SpanResult(out, rects, pixels);
    }

    private static void configure(Graphics2D g, C c, int argb) {
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        g.setColor(new Color(argb, true));
    }

    private static BufferedImage blank() {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] bg = new int[W * H];
        Arrays.fill(bg, BG);
        image.setRGB(0, 0, W, H, bg, 0, W);
        return image;
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

    private static int mul8(int a, int b) {
        return (a * b + 127) / 255;
    }

    private static int div8(int a, int b) {
        if (b <= 0) return 0;
        if (a >= b) return 255;
        long inc = (((255L << 24) + (b / 2)) / b);
        return (int)(((1L << 23) + ((long)a * inc)) >> 24);
    }

    private static int srcOver(int s, int d) {
        int sa = (s >>> 24) & 0xFF;
        if (sa == 0) return d;
        if (sa == 255) return s;
        int da = (d >>> 24) & 0xFF;
        int sr = (s >>> 16) & 0xFF;
        int sg = (s >>> 8) & 0xFF;
        int sb = s & 0xFF;
        int dr = (d >>> 16) & 0xFF;
        int dg = (d >>> 8) & 0xFF;
        int db = d & 0xFF;
        int rr = mul8(sa, sr);
        int gg = mul8(sa, sg);
        int bb = mul8(sa, sb);
        int dstA = mul8(255 - sa, da);
        int outA = sa + dstA;
        rr += mul8(dstA, dr);
        gg += mul8(dstA, dg);
        bb += mul8(dstA, db);
        if (outA > 0 && outA < 255) {
            rr = div8(rr, outA);
            gg = div8(gg, outA);
            bb = div8(bb, outA);
        }
        return (outA << 24) | (rr << 16) | (gg << 8) | bb;
    }

    private static String firstDiff(int[] a, int[] b) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return (i % W) + "," + (i / W) + ":" + Integer.toHexString(a[i]) + "/" + Integer.toHexString(b[i]);
            }
        }
        return "NONE";
    }

    private static int changedCount(int[] p) {
        int n = 0;
        for (int i = 0; i < p.length; i++) if (p[i] != BG) n++;
        return n;
    }

    private static long checksum(int[] pixels) {
        long hash = 1469598103934665603L;
        for (int i = 0; i < pixels.length; i++) {
            hash ^= (pixels[i] & 0xFFFFFFFFL);
            hash *= 1099511628211L;
        }
        return hash;
    }
}
