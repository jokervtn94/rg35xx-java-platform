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
import sun.java2d.pipe.ShapeSpanIterator;

/**
 * D5.3A diagnostic only.
 *
 * Independently reconstructs the line-only closed-path subset of the
 * OpenJDK8 Pisces Stroker used by D5.2:
 *   - input already normalized to device-space quarter pixels
 *   - width = 1.0 (half width 0.5)
 *   - CAP_SQUARE
 *   - JOIN_MITER
 *   - miter limit = 10.0
 *   - no dashes
 *   - MOVE/LINE/CLOSE only
 *
 * Candidate side does NOT call BasicStroke/Pisces to widen geometry.
 * Both canonical and candidate widened paths are scan-converted by the same
 * host ShapeSpanIterator only so this gate isolates widening geometry.
 * No RG35XX runtime source is exercised or modified.
 */
public final class RG35XXDGDrawVectorD53ALineStrokerDiagnostic {
    private static final int W = 64;
    private static final int H = 48;
    private static final long SEED = 0x35d5001L;
    private static final float HALF_WIDTH = 0.5f;
    private static final float MITER_LIMIT_SQ = 25.0f;

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

    /** Small point stack matching the reverse-side LIFO behavior of Pisces. */
    private static final class ReverseStack {
        private float[] xy = new float[32];
        private int size;

        void push(float x, float y) {
            if ((size + 1) * 2 > xy.length) {
                float[] n = new float[xy.length * 2];
                System.arraycopy(xy, 0, n, 0, xy.length);
                xy = n;
            }
            xy[size * 2] = x;
            xy[size * 2 + 1] = y;
            size++;
        }

        boolean isEmpty() { return size == 0; }

        void popTo(GeneralPath out) {
            size--;
            out.lineTo(xy[size * 2], xy[size * 2 + 1]);
        }
    }

    /** Independent line-only subset; no BasicStroke or Pisces classes used here. */
    private static final class LineStroker {
        private static final int MOVE_TO = 0;
        private static final int DRAWING = 1;
        private static final int CLOSE = 2;

        private final GeneralPath out = new GeneralPath(GeneralPath.WIND_NON_ZERO);
        private final ReverseStack reverse = new ReverseStack();
        private final float[] off = new float[2];
        private final float[] miter = new float[2];

        private int prev = CLOSE;
        private float sx0, sy0, sdx, sdy;
        private float cx0, cy0, cdx, cdy;
        private float smx, smy, cmx, cmy;

        GeneralPath stroke(GeneralPath src) {
            PathIterator pi = src.getPathIterator(null);
            float[] c = new float[6];
            while (!pi.isDone()) {
                int type = pi.currentSegment(c);
                if (type == PathIterator.SEG_MOVETO) {
                    moveTo(c[0], c[1]);
                } else if (type == PathIterator.SEG_LINETO) {
                    lineTo(c[0], c[1]);
                } else if (type == PathIterator.SEG_CLOSE) {
                    closePath();
                } else {
                    throw new RuntimeException("P1A_DG_D53A_NON_LINE_SEGMENT=" + type);
                }
                pi.next();
            }
            pathDone();
            return out;
        }

        private void moveTo(float x, float y) {
            if (prev == DRAWING) finish();
            sx0 = cx0 = x;
            sy0 = cy0 = y;
            cdx = sdx = 1.0f;
            cdy = sdy = 0.0f;
            prev = MOVE_TO;
        }

        private void lineTo(float x1, float y1) {
            float dx = x1 - cx0;
            float dy = y1 - cy0;
            if (dx == 0.0f && dy == 0.0f) dx = 1.0f;

            computeOffset(dx, dy, off);
            float mx = off[0];
            float my = off[1];

            drawJoin(cdx, cdy, cx0, cy0, dx, dy, cmx, cmy, mx, my);

            emitLine(cx0 + mx, cy0 + my);
            emitLine(x1 + mx, y1 + my);
            emitLine(cx0 - mx, cy0 - my, true);
            emitLine(x1 - mx, y1 - my, true);

            cmx = mx;
            cmy = my;
            cdx = dx;
            cdy = dy;
            cx0 = x1;
            cy0 = y1;
            prev = DRAWING;
        }

        private void closePath() {
            if (prev != DRAWING) {
                if (prev == CLOSE) return;
                emitMove(cx0, cy0 - HALF_WIDTH);
                cmx = smx = 0.0f;
                cmy = smy = -HALF_WIDTH;
                cdx = sdx = 1.0f;
                cdy = sdy = 0.0f;
                finish();
                return;
            }

            if (cx0 != sx0 || cy0 != sy0) lineTo(sx0, sy0);

            drawJoin(cdx, cdy, cx0, cy0, sdx, sdy, cmx, cmy, smx, smy);
            emitLine(sx0 + smx, sy0 + smy);
            emitMove(sx0 - smx, sy0 - smy);
            emitReverse();
            prev = CLOSE;
            out.closePath();
        }

        private void pathDone() {
            if (prev == DRAWING) finish();
            prev = CLOSE;
        }

        private void finish() {
            // CAP_SQUARE only.
            emitLine(cx0 - cmy + cmx, cy0 + cmx + cmy);
            emitLine(cx0 - cmy - cmx, cy0 + cmx - cmy);
            emitReverse();
            emitLine(sx0 + smy - smx, sy0 - smx - smy);
            emitLine(sx0 + smy + smx, sy0 - smx + smy);
            out.closePath();
        }

        private void drawJoin(float pdx, float pdy,
                              float x0, float y0,
                              float dx, float dy,
                              float omx, float omy,
                              float mx, float my) {
            if (prev != DRAWING) {
                emitMove(x0 + mx, y0 + my);
                sdx = dx;
                sdy = dy;
                smx = mx;
                smy = my;
            } else {
                boolean cw = isCW(pdx, pdy, dx, dy);
                drawMiter(pdx, pdy, x0, y0, dx, dy, omx, omy, mx, my, cw);
                emitLine(x0, y0, !cw);
            }
            prev = DRAWING;
        }

        private void drawMiter(float pdx, float pdy,
                               float x0, float y0,
                               float dx, float dy,
                               float omx, float omy,
                               float mx, float my,
                               boolean rev) {
            if ((mx == omx && my == omy) ||
                (pdx == 0.0f && pdy == 0.0f) ||
                (dx == 0.0f && dy == 0.0f)) return;

            if (rev) {
                omx = -omx;
                omy = -omy;
                mx = -mx;
                my = -my;
            }

            intersection((x0 - pdx) + omx, (y0 - pdy) + omy,
                         x0 + omx, y0 + omy,
                         (dx + x0) + mx, (dy + y0) + my,
                         x0 + mx, y0 + my,
                         miter);

            float ddx = miter[0] - x0;
            float ddy = miter[1] - y0;
            float lenSq = ddx * ddx + ddy * ddy;
            if (lenSq < MITER_LIMIT_SQ) emitLine(miter[0], miter[1], rev);
        }

        private void computeOffset(float dx, float dy, float[] m) {
            float len = (float)Math.sqrt(dx * dx + dy * dy);
            if (len == 0.0f) {
                m[0] = m[1] = 0.0f;
            } else {
                m[0] = (dy * HALF_WIDTH) / len;
                m[1] = -(dx * HALF_WIDTH) / len;
            }
        }

        private static boolean isCW(float dx1, float dy1, float dx2, float dy2) {
            return dx1 * dy2 <= dy1 * dx2;
        }

        private static void intersection(float x0, float y0,
                                         float x1, float y1,
                                         float x0p, float y0p,
                                         float x1p, float y1p,
                                         float[] m) {
            float x10 = x1 - x0;
            float y10 = y1 - y0;
            float x10p = x1p - x0p;
            float y10p = y1p - y0p;
            float den = x10 * y10p - x10p * y10;
            float t = x10p * (y0 - y0p) - y10p * (x0 - x0p);
            t /= den;
            m[0] = x0 + t * x10;
            m[1] = y0 + t * y10;
        }

        private void emitMove(float x, float y) { out.moveTo(x, y); }
        private void emitLine(float x, float y) { out.lineTo(x, y); }
        private void emitLine(float x, float y, boolean rev) {
            if (rev) reverse.push(x, y); else out.lineTo(x, y);
        }
        private void emitReverse() {
            while (!reverse.isEmpty()) reverse.popTo(out);
        }
    }

    public static void main(String[] args) {
        int fixed = 0;
        int fuzz = 0;
        int comparisons = 0;
        int maskFailures = 0;
        int rectFailures = 0;
        long canonicalRects = 0;
        long candidateRects = 0;
        long canonicalPixels = 0;
        long candidatePixels = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixed++;
            SpanResult a = raster(c, canonicalWiden(c));
            SpanResult b = raster(c, candidateWiden(c));
            comparisons++;
            canonicalRects += a.rects;
            candidateRects += b.rects;
            canonicalPixels += a.pixels;
            candidatePixels += b.pixels;
            if (!Arrays.equals(a.mask, b.mask)) {
                maskFailures++;
                System.out.println("D53A_MISMATCH=" + c.name + " first=" + firstDiff(a.mask, b.mask));
            }
            if (a.rects != b.rects) rectFailures++;
            if ("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) {
                System.out.println("D53A_SENTINEL=" + c.name +
                    " CANON_RECTS=" + a.rects + " CAND_RECTS=" + b.rects +
                    " CANON_PIXELS=" + a.pixels + " CAND_PIXELS=" + b.pixels +
                    " CANON_CHECKSUM=" + Long.toHexString(checksum(a.mask)) +
                    " CAND_CHECKSUM=" + Long.toHexString(checksum(b.mask)));
            }
        }

        Random r = new Random(SEED);
        for (int i = 0; i < 160; i++) {
            int n = 3 + r.nextInt(6);
            int[] x = new int[n];
            int[] y = new int[n];
            for (int p = 0; p < n; p++) {
                x[p] = r.nextInt(86) - 11;
                y[p] = r.nextInt(66) - 9;
            }
            C c = new C("FUZZ_" + i, x, y,
                        r.nextInt(9) - 4, r.nextInt(9) - 4,
                        r.nextInt(9), r.nextInt(7),
                        34 + r.nextInt(31), 28 + r.nextInt(25));
            fuzz++;
            SpanResult a = raster(c, canonicalWiden(c));
            SpanResult b = raster(c, candidateWiden(c));
            comparisons++;
            canonicalRects += a.rects;
            candidateRects += b.rects;
            canonicalPixels += a.pixels;
            candidatePixels += b.pixels;
            if (!Arrays.equals(a.mask, b.mask)) {
                maskFailures++;
                if (maskFailures <= 8) {
                    System.out.println("D53A_MISMATCH=" + c.name + " first=" + firstDiff(a.mask, b.mask));
                }
            }
            if (a.rects != b.rects) rectFailures++;
        }

        System.out.println("P1A_DG_D53A_FIXED_CASE_COUNT=" + fixed);
        System.out.println("P1A_DG_D53A_FUZZ_CASE_COUNT=" + fuzz);
        System.out.println("P1A_DG_D53A_COMPARISON_COUNT=" + comparisons);
        System.out.println("P1A_DG_D53A_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D53A_MASK_FAILURE_COUNT=" + maskFailures);
        System.out.println("P1A_DG_D53A_RECT_COUNT_MISMATCH_CASE_COUNT=" + rectFailures);
        System.out.println("P1A_DG_D53A_CANONICAL_RECT_TOTAL=" + canonicalRects);
        System.out.println("P1A_DG_D53A_CANDIDATE_RECT_TOTAL=" + candidateRects);
        System.out.println("P1A_DG_D53A_CANONICAL_PIXEL_TOTAL=" + canonicalPixels);
        System.out.println("P1A_DG_D53A_CANDIDATE_PIXEL_TOTAL=" + candidatePixels);
        System.out.println("P1A_DG_D53A_INDEPENDENT_WIDENER=LINE_ONLY_CLOSED_MITER_W1_QUARTER_NORMALIZED");
        System.out.println("P1A_DG_D53A_COMMON_RASTER=HOST_SHAPESPANITERATOR_NONZERO");
        System.out.println("P1A_DG_D53A_RUNTIME_CHANGE=NO");

        if (maskFailures != 0) {
            throw new RuntimeException("P1A_DG_D53A_WIDENER_FAIL=" + maskFailures);
        }
        System.out.println("P1A_DG_D53A_DIAGNOSTIC_GATE=PASS");
    }

    private static Shape canonicalWiden(C c) {
        return new BasicStroke().createStrokedShape(normalizedPath(c));
    }

    private static Shape candidateWiden(C c) {
        return new LineStroker().stroke(normalizedPath(c));
    }

    private static GeneralPath normalizedPath(C c) {
        GeneralPath gp = new GeneralPath(GeneralPath.WIND_EVEN_ODD);
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

    private static SpanResult raster(C c, Shape widened) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setTransform(new java.awt.geom.AffineTransform());
        g.setClip(c.cx + c.tx, c.cy + c.ty, c.cw, c.ch);
        if (!(g instanceof SunGraphics2D)) {
            String name = g.getClass().getName();
            g.dispose();
            throw new RuntimeException("P1A_DG_D53A_NOT_SUNGRAPHICS2D=" + name);
        }
        SunGraphics2D sg = (SunGraphics2D)g;
        PathIterator pi = widened.getPathIterator(null);
        if (pi.getWindingRule() != PathIterator.WIND_NON_ZERO) {
            g.dispose();
            throw new RuntimeException("P1A_DG_D53A_WINDING_NOT_NONZERO=" + pi.getWindingRule());
        }
        ShapeSpanIterator ssi = new ShapeSpanIterator(false);
        ssi.setOutputArea(sg.getCompClip());
        ssi.appendPath(pi);
        SpanResult result = collect(ssi);
        ssi.dispose();
        g.dispose();
        return result;
    }

    private static SpanResult collect(ShapeSpanIterator ssi) {
        boolean[] mask = new boolean[W * H];
        int[] span = new int[4];
        int rects = 0;
        int pixels = 0;
        while (ssi.nextSpan(span)) {
            rects++;
            for (int y = span[1]; y < span[3]; y++) {
                if (y < 0 || y >= H) continue;
                for (int x = span[0]; x < span[2]; x++) {
                    if (x < 0 || x >= W) continue;
                    int idx = y * W + x;
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
