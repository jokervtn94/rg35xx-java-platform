package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

/**
 * D5.4 diagnostic only.
 *
 * Reconstructs the OpenJDK8 opaque DrawPolygons -> GeneralRenderer.doDrawPoly
 * -> doDrawLine -> adjustLine path with Java-6-compatible integer code and
 * compares it pixel-for-pixel with the host Java2D drawPolygon result.
 *
 * This file does not exercise or modify the RG35XX runtime candidate.
 */
public final class RG35XXDGDrawVectorD54OpaqueDrawPolyDiagnostic {
    private static final int W = 64;
    private static final int H = 48;
    private static final int BG = 0xFF102030;
    private static final int OPAQUE = 0xFF3366CC;
    private static final long SEED = 0x35d5001L;

    private static final int OUTCODE_TOP = 1;
    private static final int OUTCODE_BOTTOM = 2;
    private static final int OUTCODE_LEFT = 4;
    private static final int OUTCODE_RIGHT = 8;

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
        int fixed = 0;
        int fuzz = 0;
        int failures = 0;
        int mismatchPixels = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixed++;
            int mm = compare(c);
            if (mm != 0) {
                failures++;
                mismatchPixels += mm;
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
            int mm = compare(c);
            if (mm != 0) {
                failures++;
                mismatchPixels += mm;
            }
        }

        System.out.println("P1A_DG_D54_FIXED_CASE_COUNT=" + fixed);
        System.out.println("P1A_DG_D54_FUZZ_CASE_COUNT=" + fuzz);
        System.out.println("P1A_DG_D54_COMPARISON_COUNT=" + (fixed + fuzz));
        System.out.println("P1A_DG_D54_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D54_MISMATCH_CASE_COUNT=" + failures);
        System.out.println("P1A_DG_D54_MISMATCH_PIXEL_COUNT=" + mismatchPixels);
        System.out.println("P1A_DG_D54_MODEL=OPENJDK8_GENERALRENDERER_DODRAWPOLY_DODRAWLINE_ADJUSTLINE");
        System.out.println("P1A_DG_D54_CLIP_MODEL=DEVICE_HALF_OPEN_TO_INCLUSIVE_HI_MINUS_1");
        System.out.println("P1A_DG_D54_RUNTIME_CHANGE=NO");

        if (failures != 0) {
            throw new RuntimeException("P1A_DG_D54_FAIL cases=" + failures + " pixels=" + mismatchPixels);
        }
        System.out.println("P1A_DG_D54_OPAQUE_DRAWPOLY_DIAGNOSTIC_GATE=PASS");
    }

    private static int compare(C c) {
        int[] host = host(c);
        int[] model = model(c);
        int mm = diffCount(host, model);
        if (mm != 0) {
            System.out.println("D54_MISMATCH=" + c.name +
                               " PIXELS=" + mm +
                               " FIRST=" + firstDiff(host, model) +
                               " HOST_SUM=" + Long.toHexString(checksum(host)) +
                               " MODEL_SUM=" + Long.toHexString(checksum(model)));
        } else if ("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) {
            System.out.println("D54_SENTINEL=" + c.name +
                               " CHANGED=" + changedCount(host) +
                               " CHECKSUM=" + Long.toHexString(checksum(host)));
        }
        return mm;
    }

    private static int[] host(C c) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] bg = new int[W * H];
        Arrays.fill(bg, BG);
        image.setRGB(0, 0, W, H, bg, 0, W);

        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        g.setColor(new Color(OPAQUE, true));
        g.drawPolygon(c.x, c.y, c.x.length);
        g.dispose();
        return image.getRGB(0, 0, W, H, null, 0, W);
    }

    private static int[] model(C c) {
        int[] out = new int[W * H];
        Arrays.fill(out, BG);

        int lox = Math.max(0, c.cx + c.tx);
        int loy = Math.max(0, c.cy + c.ty);
        int hix = Math.min(W, c.cx + c.tx + c.cw);
        int hiy = Math.min(H, c.cy + c.ty + c.ch);

        drawPoly(out, c.x, c.y, 0, c.x.length,
                 lox, loy, hix, hiy, c.tx, c.ty, true);
        return out;
    }

    private static void drawPoly(int[] out,
                                 int[] xPoints, int[] yPoints,
                                 int off, int nPoints,
                                 int clipLoX, int clipLoY, int clipHiX, int clipHiY,
                                 int transx, int transy, boolean close) {
        int mx, my, x1, y1;
        int[] tmp = null;
        if (nPoints <= 0) return;

        mx = x1 = xPoints[off] + transx;
        my = y1 = yPoints[off] + transy;
        while (--nPoints > 0) {
            ++off;
            int x2 = xPoints[off] + transx;
            int y2 = yPoints[off] + transy;
            tmp = drawLine(out, tmp, clipLoX, clipLoY, clipHiX, clipHiY,
                           x1, y1, x2, y2);
            x1 = x2;
            y1 = y2;
        }
        if (close && (x1 != mx || y1 != my)) {
            drawLine(out, tmp, clipLoX, clipLoY, clipHiX, clipHiY,
                     x1, y1, mx, my);
        }
    }

    private static int[] drawLine(int[] out, int[] boundPts,
                                  int clipLoX, int clipLoY, int clipHiX, int clipHiY,
                                  int origx1, int origy1, int origx2, int origy2) {
        if (boundPts == null) boundPts = new int[8];
        boundPts[0] = origx1;
        boundPts[1] = origy1;
        boundPts[2] = origx2;
        boundPts[3] = origy2;
        if (!adjustLine(boundPts, clipLoX, clipLoY, clipHiX, clipHiY)) return boundPts;

        int x1 = boundPts[0];
        int y1 = boundPts[1];
        int x2 = boundPts[2];
        int y2 = boundPts[3];

        if (x1 == x2) {
            if (y1 > y2) {
                do {
                    write(out, x1, y1);
                    y1--;
                } while (y1 >= y2);
            } else {
                do {
                    write(out, x1, y1);
                    y1++;
                } while (y1 <= y2);
            }
        } else if (y1 == y2) {
            if (x1 > x2) {
                do {
                    write(out, x1, y1);
                    x1--;
                } while (x1 >= x2);
            } else {
                do {
                    write(out, x1, y1);
                    x1++;
                } while (x1 <= x2);
            }
        } else {
            int dx = boundPts[4];
            int dy = boundPts[5];
            int ax = boundPts[6];
            int ay = boundPts[7];
            int steps;
            int bumpmajor;
            int bumpminor;
            int errminor;
            int errmajor;
            int error;
            boolean xmajor;

            if (ax >= ay) {
                xmajor = true;
                errmajor = ay * 2;
                errminor = ax * 2;
                bumpmajor = (dx < 0) ? -1 : 1;
                bumpminor = (dy < 0) ? -1 : 1;
                ax = -ax;
                steps = x2 - x1;
            } else {
                xmajor = false;
                errmajor = ax * 2;
                errminor = ay * 2;
                bumpmajor = (dy < 0) ? -1 : 1;
                bumpminor = (dx < 0) ? -1 : 1;
                ay = -ay;
                steps = y2 - y1;
            }
            error = -(errminor / 2);
            if (y1 != origy1) {
                int ysteps = y1 - origy1;
                if (ysteps < 0) ysteps = -ysteps;
                error += ysteps * ax * 2;
            }
            if (x1 != origx1) {
                int xsteps = x1 - origx1;
                if (xsteps < 0) xsteps = -xsteps;
                error += xsteps * ay * 2;
            }
            if (steps < 0) steps = -steps;

            if (xmajor) {
                do {
                    write(out, x1, y1);
                    x1 += bumpmajor;
                    error += errmajor;
                    if (error >= 0) {
                        y1 += bumpminor;
                        error -= errminor;
                    }
                } while (--steps >= 0);
            } else {
                do {
                    write(out, x1, y1);
                    y1 += bumpmajor;
                    error += errmajor;
                    if (error >= 0) {
                        x1 += bumpminor;
                        error -= errminor;
                    }
                } while (--steps >= 0);
            }
        }
        return boundPts;
    }

    private static int outcode(int x, int y,
                               int xmin, int ymin, int xmax, int ymax) {
        int code;
        if (y < ymin) code = OUTCODE_TOP;
        else if (y > ymax) code = OUTCODE_BOTTOM;
        else code = 0;
        if (x < xmin) code |= OUTCODE_LEFT;
        else if (x > xmax) code |= OUTCODE_RIGHT;
        return code;
    }

    private static boolean adjustLine(int[] boundPts,
                                      int cxmin, int cymin, int cx2, int cy2) {
        int cxmax = cx2 - 1;
        int cymax = cy2 - 1;
        int x1 = boundPts[0];
        int y1 = boundPts[1];
        int x2 = boundPts[2];
        int y2 = boundPts[3];

        if ((cxmax < cxmin) || (cymax < cymin)) return false;

        if (x1 == x2) {
            if (x1 < cxmin || x1 > cxmax) return false;
            if (y1 > y2) {
                int t = y1; y1 = y2; y2 = t;
            }
            if (y1 < cymin) y1 = cymin;
            if (y2 > cymax) y2 = cymax;
            if (y1 > y2) return false;
            boundPts[1] = y1;
            boundPts[3] = y2;
        } else if (y1 == y2) {
            if (y1 < cymin || y1 > cymax) return false;
            if (x1 > x2) {
                int t = x1; x1 = x2; x2 = t;
            }
            if (x1 < cxmin) x1 = cxmin;
            if (x2 > cxmax) x2 = cxmax;
            if (x1 > x2) return false;
            boundPts[0] = x1;
            boundPts[2] = x2;
        } else {
            int outcode1, outcode2;
            int dx = x2 - x1;
            int dy = y2 - y1;
            int ax = (dx < 0) ? -dx : dx;
            int ay = (dy < 0) ? -dy : dy;
            boolean xmajor = (ax >= ay);

            outcode1 = outcode(x1, y1, cxmin, cymin, cxmax, cymax);
            outcode2 = outcode(x2, y2, cxmin, cymin, cxmax, cymax);
            while ((outcode1 | outcode2) != 0) {
                int xsteps, ysteps;
                if ((outcode1 & outcode2) != 0) return false;
                if (outcode1 != 0) {
                    if (0 != (outcode1 & (OUTCODE_TOP | OUTCODE_BOTTOM))) {
                        if (0 != (outcode1 & OUTCODE_TOP)) y1 = cymin;
                        else y1 = cymax;
                        ysteps = y1 - boundPts[1];
                        if (ysteps < 0) ysteps = -ysteps;
                        xsteps = 2 * ysteps * ax + ay;
                        if (xmajor) xsteps += ay - ax - 1;
                        xsteps = xsteps / (2 * ay);
                        if (dx < 0) xsteps = -xsteps;
                        x1 = boundPts[0] + xsteps;
                    } else if (0 != (outcode1 & (OUTCODE_LEFT | OUTCODE_RIGHT))) {
                        if (0 != (outcode1 & OUTCODE_LEFT)) x1 = cxmin;
                        else x1 = cxmax;
                        xsteps = x1 - boundPts[0];
                        if (xsteps < 0) xsteps = -xsteps;
                        ysteps = 2 * xsteps * ay + ax;
                        if (!xmajor) ysteps += ax - ay - 1;
                        ysteps = ysteps / (2 * ax);
                        if (dy < 0) ysteps = -ysteps;
                        y1 = boundPts[1] + ysteps;
                    }
                    outcode1 = outcode(x1, y1, cxmin, cymin, cxmax, cymax);
                } else {
                    if (0 != (outcode2 & (OUTCODE_TOP | OUTCODE_BOTTOM))) {
                        if (0 != (outcode2 & OUTCODE_TOP)) y2 = cymin;
                        else y2 = cymax;
                        ysteps = y2 - boundPts[3];
                        if (ysteps < 0) ysteps = -ysteps;
                        xsteps = 2 * ysteps * ax + ay;
                        if (xmajor) xsteps += ay - ax;
                        else xsteps -= 1;
                        xsteps = xsteps / (2 * ay);
                        if (dx > 0) xsteps = -xsteps;
                        x2 = boundPts[2] + xsteps;
                    } else if (0 != (outcode2 & (OUTCODE_LEFT | OUTCODE_RIGHT))) {
                        if (0 != (outcode2 & OUTCODE_LEFT)) x2 = cxmin;
                        else x2 = cxmax;
                        xsteps = x2 - boundPts[2];
                        if (xsteps < 0) xsteps = -xsteps;
                        ysteps = 2 * xsteps * ay + ax;
                        if (xmajor) ysteps -= 1;
                        else ysteps += ax - ay;
                        ysteps = ysteps / (2 * ax);
                        if (dy > 0) ysteps = -ysteps;
                        y2 = boundPts[3] + ysteps;
                    }
                    outcode2 = outcode(x2, y2, cxmin, cymin, cxmax, cymax);
                }
            }
            boundPts[0] = x1;
            boundPts[1] = y1;
            boundPts[2] = x2;
            boundPts[3] = y2;
            boundPts[4] = dx;
            boundPts[5] = dy;
            boundPts[6] = ax;
            boundPts[7] = ay;
        }
        return true;
    }

    private static void write(int[] out, int x, int y) {
        if (x >= 0 && x < W && y >= 0 && y < H) out[y * W + x] = OPAQUE;
    }

    private static int diffCount(int[] a, int[] b) {
        int n = 0;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) n++;
        return n;
    }

    private static String firstDiff(int[] a, int[] b) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return (i % W) + "," + (i / W) + ":" +
                       Integer.toHexString(a[i]) + "/" + Integer.toHexString(b[i]);
            }
        }
        return "NONE";
    }

    private static int changedCount(int[] p) {
        int n = 0;
        for (int i = 0; i < p.length; i++) if (p[i] != BG) n++;
        return n;
    }

    private static long checksum(int[] p) {
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) {
            h ^= (p[i] & 0xffffffffL);
            h *= 1099511628211L;
        }
        return h;
    }
}
