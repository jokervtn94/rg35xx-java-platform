package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.GeneralPath;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

/**
 * D5 diagnostic only.  It characterizes the two OpenJDK8 Java2D paths used
 * by DirectGraphics drawTriangle/drawPolygon semantics.  No RG35XX runtime
 * implementation is exercised or modified here.
 */
public final class RG35XXDGDrawVectorD5Diagnostic {
    private static final int W = 64;
    private static final int H = 48;
    private static final int BG = 0xFF102030;
    private static final int RGB = 0x003366CC;
    private static final int OPAQUE = 0xFF3366CC;
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
        if (args.length > 0 && "trace".equals(args[0])) {
            trace(args);
            return;
        }

        int alphaPathFailures = 0;
        int onceModelMismatchCases = 0;
        long onceModelMismatchPixels = 0;
        int opaqueApiVsPathMismatchCases = 0;
        int fixedCases = 0;
        int fuzzCases = 0;

        for (int i = 0; i < FIXED.length; i++) {
            C c = FIXED[i];
            fixedCases++;
            int[] opaqueApi = render(c, OPAQUE, false);
            int[] opaquePath = render(c, OPAQUE, true);
            if (!Arrays.equals(opaqueApi, opaquePath)) {
                opaqueApiVsPathMismatchCases++;
            }
            for (int a = 0; a < ALPHAS.length; a++) {
                int argb = (ALPHAS[a] << 24) | RGB;
                int[] api = render(c, argb, false);
                int[] path = render(c, argb, true);
                if (!Arrays.equals(api, path)) {
                    alphaPathFailures++;
                    System.out.println("D5_ALPHA_PATH_MISMATCH=" + c.name + " alpha=" + ALPHAS[a] + " first=" + firstDiff(api, path));
                }
                int[] once = onceCompositeFromOpaqueMask(opaqueApi, argb);
                int mm = diffCount(api, once);
                if (mm != 0) {
                    onceModelMismatchCases++;
                    onceModelMismatchPixels += mm;
                }
                if (("TRIANGLE_STANDARD".equals(c.name) || "POLYGON_CONCAVE".equals(c.name)) && ALPHAS[a] == 0x80) {
                    System.out.println("D5_SENTINEL=" + c.name + " ALPHA80_ONCE_MODEL_MISMATCH_PIXELS=" + mm);
                }
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
            int tx = r.nextInt(9) - 4;
            int ty = r.nextInt(9) - 4;
            int cx = r.nextInt(9);
            int cy = r.nextInt(7);
            int cw = 34 + r.nextInt(31);
            int ch = 28 + r.nextInt(25);
            C c = new C("FUZZ_" + i, x, y, tx, ty, cx, cy, cw, ch);
            fuzzCases++;

            int[] opaqueApi = render(c, OPAQUE, false);
            int[] opaquePath = render(c, OPAQUE, true);
            if (!Arrays.equals(opaqueApi, opaquePath)) {
                opaqueApiVsPathMismatchCases++;
            }
            for (int a = 0; a < ALPHAS.length; a++) {
                int argb = (ALPHAS[a] << 24) | RGB;
                int[] api = render(c, argb, false);
                int[] path = render(c, argb, true);
                if (!Arrays.equals(api, path)) {
                    alphaPathFailures++;
                    if (alphaPathFailures <= 8) {
                        System.out.println("D5_ALPHA_PATH_MISMATCH=" + c.name + " alpha=" + ALPHAS[a] + " first=" + firstDiff(api, path));
                    }
                }
                int[] once = onceCompositeFromOpaqueMask(opaqueApi, argb);
                int mm = diffCount(api, once);
                if (mm != 0) {
                    onceModelMismatchCases++;
                    onceModelMismatchPixels += mm;
                }
            }
        }

        System.out.println("P1A_DG_D5_FIXED_CASE_COUNT=" + fixedCases);
        System.out.println("P1A_DG_D5_FUZZ_CASE_COUNT=" + fuzzCases);
        System.out.println("P1A_DG_D5_ALPHA_LEVEL_COUNT=" + ALPHAS.length);
        System.out.println("P1A_DG_D5_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("P1A_DG_D5_ALPHA_SOURCE_EQUIVALENT_PATH_FAILURE_COUNT=" + alphaPathFailures);
        System.out.println("P1A_DG_D5_OPAQUE_API_VS_PATH_MISMATCH_CASE_COUNT=" + opaqueApiVsPathMismatchCases);
        System.out.println("P1A_DG_D5_ONCE_COMPOSITE_MODEL_MISMATCH_CASE_COUNT=" + onceModelMismatchCases);
        System.out.println("P1A_DG_D5_ONCE_COMPOSITE_MODEL_MISMATCH_PIXEL_COUNT=" + onceModelMismatchPixels);
        System.out.println("P1A_DG_D5_OPAQUE_OWNER=OPENJDK8_DRAWPOLYGONS_GENERALRENDERER_DODRAWPOLY");
        System.out.println("P1A_DG_D5_ALPHA_OWNER=PIXELTOSHAPECONVERTER_SPANSHAPERENDERER_GETSTROKESPANS");
        System.out.println("P1A_DG_D5_ALPHA_COMPOSITE=SRCOVER_MASKBLIT");
        System.out.println("P1A_DG_D5_RUNTIME_CHANGE=NO");

        if (alphaPathFailures != 0) {
            throw new RuntimeException("P1A_DG_D5_ALPHA_SOURCE_PATH_FAIL=" + alphaPathFailures);
        }
        if (onceModelMismatchCases == 0) {
            throw new RuntimeException("P1A_DG_D5_ONCE_MODEL_UNEXPECTEDLY_MATCHED_ALL");
        }
        System.out.println("P1A_DG_D5_DIAGNOSTIC_GATE=PASS");
    }

    private static void trace(String[] args) {
        if (args.length != 3) throw new IllegalArgumentException("trace <triangle|polygon> <opaque|alpha>");
        C c;
        if ("triangle".equals(args[1])) {
            c = FIXED[0];
        } else if ("polygon".equals(args[1])) {
            c = FIXED[7];
        } else {
            throw new IllegalArgumentException("bad shape");
        }
        int argb;
        if ("opaque".equals(args[2])) {
            argb = OPAQUE;
        } else if ("alpha".equals(args[2])) {
            argb = 0x803366CC;
        } else {
            throw new IllegalArgumentException("bad alpha mode");
        }
        int[] p = render(c, argb, false);
        System.out.println("P1A_DG_D5_TRACE_CASE=" + args[1] + "_" + args[2]);
        System.out.println("P1A_DG_D5_TRACE_CHANGED=" + changedCount(p));
        System.out.println("P1A_DG_D5_TRACE_CHECKSUM=" + Long.toHexString(checksum(p)));
        System.out.println("P1A_DG_D5_TRACE_PROBE=PASS");
    }

    private static int[] render(C c, int argb, boolean explicitPath) {
        BufferedImage image = new BufferedImage(W, H, BufferedImage.TYPE_INT_ARGB);
        int[] bg = new int[W * H];
        Arrays.fill(bg, BG);
        image.setRGB(0, 0, W, H, bg, 0, W);
        Graphics2D g = image.createGraphics();
        g.translate(c.tx, c.ty);
        g.setClip(c.cx, c.cy, c.cw, c.ch);
        g.setColor(new Color(argb, true));
        if (explicitPath) {
            GeneralPath gp = makePath(c.x, c.y);
            g.draw(gp);
        } else {
            g.drawPolygon(c.x, c.y, c.x.length);
        }
        g.dispose();
        return image.getRGB(0, 0, W, H, null, 0, W);
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

    private static int[] onceCompositeFromOpaqueMask(int[] opaque, int argb) {
        int[] out = new int[opaque.length];
        Arrays.fill(out, BG);
        for (int i = 0; i < opaque.length; i++) {
            if (opaque[i] != BG) out[i] = srcOver(argb, BG);
        }
        return out;
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

    private static int diffCount(int[] a, int[] b) {
        int n = 0;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) n++;
        return n;
    }

    private static String firstDiff(int[] a, int[] b) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return (i % W) + "," + (i / W) + ":" + Integer.toHexString(a[i]) + "/" + Integer.toHexString(b[i]);
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
