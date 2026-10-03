package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * P1A diagnostic inventory: compare the staged canonical/AWT backing with the
 * RG35XX Raw2D backing for identical PlatformGraphics calls.
 *
 * This test intentionally does not implement or patch any missing method.
 */
public final class RG35XXGraphicsDifferentialInventory {
    private static final int W = 32;
    private static final int H = 24;

    private interface Op {
        int[] run(PlatformImage image, PlatformGraphics g) throws Exception;
    }

    private static final class Result {
        final int[] output;
        final Throwable error;
        Result(int[] output, Throwable error) {
            this.output = output;
            this.error = error;
        }
    }

    public static void main(String[] args) throws Exception {
        int unexpected = 0;

        unexpected += expect("CONTROL_FILLRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x113355);
                g.fillRect(3, 4, 7, 5);
                return pixels(image);
            }
        }, "MATCH");

        unexpected += expect("CONTROL_DRAWLINE_AXIS", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x224466);
                g.drawLine(2, 6, 15, 6);
                return pixels(image);
            }
        }, "MATCH");

        unexpected += expect("CONTROL_DRAWRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x335577);
                g.drawRect(2, 3, 10, 8);
                return pixels(image);
            }
        }, "MATCH");

        unexpected += expect("CONTROL_CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setClip(4, 3, 10, 8);
                g.translate(2, 1);
                g.setColor(0x446688);
                g.fillRect(0, 0, 20, 20);
                return pixels(image);
            }
        }, "MATCH");

        unexpected += expect("GAP_CLEARRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.clearRect(2, 2, 8, 6);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_COPYAREA", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x556699);
                g.fillRect(2, 2, 6, 5);
                g.copyArea(2, 2, 6, 5, 14, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DRAWARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x6677AA);
                g.drawArc(4, 3, 15, 12, 20, 220);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_FILLARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x7788BB);
                g.fillArc(4, 3, 15, 12, 20, 220);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DRAWROUNDRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x8899CC);
                g.drawRoundRect(3, 3, 18, 12, 6, 6);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_FILLROUNDRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x99AADD);
                g.fillRoundRect(3, 3, 18, 12, 6, 6);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_MIDP_FILLTRIANGLE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0xAA55CC);
                g.fillTriangle(4, 4, 20, 5, 9, 18);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DG_DRAWTRIANGLE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.drawTriangle(4, 4, 20, 5, 9, 18, 0xA0CC3311);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DG_FILLTRIANGLE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillTriangle(4, 4, 20, 5, 9, 18, 0xA0CC3311);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DG_DRAWPOLYGON", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                int[] xs = {4, 20, 18, 7};
                int[] ys = {4, 6, 17, 19};
                g.drawPolygon(xs, 0, ys, 0, 4, 0xB04488CC);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        // Current accepted A6 raw fillPolygon has an intentionally narrow
        // rectangle-only branch. A generic four-point polygon therefore
        // returns without throwing but does not match canonical AWT output.
        unexpected += expect("GAP_DG_FILLPOLYGON_GENERIC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                int[] xs = {4, 20, 18, 7};
                int[] ys = {4, 6, 17, 19};
                g.fillPolygon(xs, 0, ys, 0, 4, 0xB04488CC);
                return pixels(image);
            }
        }, "MISMATCH");

        unexpected += expect("GAP_DG_DRAWPIXELS_INT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                int[] src = new int[6 * 5];
                Arrays.fill(src, 0x80CC4422);
                g.drawPixels(src, true, 0, 6, 7, 8, 6, 5, 0, 8888);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        unexpected += expect("GAP_DG_GETPIXELS_INT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x13579B);
                g.fillRect(2, 2, 8, 6);
                int[] out = new int[8 * 6];
                g.getPixels(out, 0, 8, 2, 2, 8, 6, 8888);
                return out;
            }
        }, "RAW_EXCEPTION");

        System.out.println("P1A_DIFFERENTIAL_UNEXPECTED_COUNT=" + unexpected);
        if (unexpected != 0) {
            throw new RuntimeException("P1A_DIFFERENTIAL_INVENTORY_DRIFT=" + unexpected);
        }
        System.out.println("P1A_DIFFERENTIAL_INVENTORY=PASS");
        System.out.println("P1A_RUNTIME_CHANGE=NO");
    }

    private static int expect(String name, Op op, String expected) throws Exception {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_CASE=" + name
                + " EXPECTED=" + expected
                + " ACTUAL=" + actual
                + " AWT=" + errorName(awt.error)
                + " RAW=" + errorName(raw.error));
        return expected.equals(actual) ? 0 : 1;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true");
            else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W, H);
            PlatformGraphics g = image.getGraphics();
            return new Result(op.run(image, g), null);
        } catch (Throwable t) {
            return new Result(null, t);
        }
    }

    private static String classify(Result awt, Result raw) {
        if (awt.error != null) return "AWT_EXCEPTION";
        if (raw.error != null) return "RAW_EXCEPTION";
        return Arrays.equals(awt.output, raw.output) ? "MATCH" : "MISMATCH";
    }

    private static String errorName(Throwable t) {
        return t == null ? "NONE" : t.getClass().getName();
    }

    private static int[] pixels(PlatformImage image) {
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }
}
