package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Differential gate for P1A G1 only: clearRect + copyArea. */
public final class RG35XXGraphicsG1DifferentialGate {
    private static final int W = 36;
    private static final int H = 28;

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
        int failures = 0;

        unexpectedControl();

        failures += expectMatch("CONTROL_FILLRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x214365);
                g.fillRect(3, 4, 11, 7);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_CLEAR_BASIC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintBackground(g);
                g.clearRect(5, 4, 12, 9);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_CLEAR_CLIP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintBackground(g);
                g.setClip(8, 6, 10, 9);
                g.clearRect(3, 2, 22, 18);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_CLEAR_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintBackground(g);
                g.translate(4, 3);
                g.clearRect(2, 2, 9, 7);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_CLEAR_CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintBackground(g);
                g.setClip(7, 5, 14, 11);
                g.translate(4, 3);
                g.clearRect(0, 0, 30, 20);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_CLEAR_DEGENERATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintBackground(g);
                g.clearRect(5, 5, 0, 7);
                g.clearRect(5, 5, 7, 0);
                g.clearRect(5, 5, -3, 7);
                g.clearRect(5, 5, 7, -3);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_BASIC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintPattern(g);
                g.copyArea(2, 3, 10, 7, 20, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_ANCHOR", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintPattern(g);
                g.copyArea(2, 3, 10, 7, 28, 20, PlatformGraphics.RIGHT | PlatformGraphics.BOTTOM);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintPattern(g);
                g.setClip(11, 8, 12, 10);
                g.translate(4, 3);
                g.copyArea(1, 2, 12, 8, 8, 6, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_OVERLAP_FORWARD", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintColumns(g);
                g.copyArea(2, 4, 18, 10, 7, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_OVERLAP_BACKWARD", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintColumns(g);
                g.copyArea(7, 4, 18, 10, 2, 4, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        // JDK8 diagnostic 36944718157 proves self-copy is a live raster traversed
        // top-to-bottom and left-to-right. Lock both propagation and safe directions.
        failures += expectMatch("G1_COPY_OVERLAP_DOWN", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g);
                g.copyArea(4, 3, 14, 12, 4, 8, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_OVERLAP_UP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g);
                g.copyArea(4, 8, 14, 12, 4, 3, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_OVERLAP_DOWN_RIGHT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g);
                g.copyArea(3, 3, 15, 12, 8, 7, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_OVERLAP_UP_LEFT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                paintGrid(g);
                g.copyArea(8, 7, 15, 12, 3, 3, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        failures += expectMatch("G1_COPY_TRANSPARENT_SOURCE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x204080);
                g.fillRect(0, 0, W, H);
                g.clearRect(2, 2, 10, 8);
                g.setColor(0xF06020);
                g.fillRect(4, 4, 4, 3);
                g.copyArea(2, 2, 10, 8, 19, 5, PlatformGraphics.TOP | PlatformGraphics.LEFT);
                return pixels(image);
            }
        });

        // Scope sentinels: G1 must not silently expand later method groups.
        failures += expectClass("SENTINEL_DRAWARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.drawArc(4, 4, 15, 11, 20, 220);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        failures += expectClass("SENTINEL_FILLTRIANGLE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillTriangle(4, 4, 20, 5, 9, 18);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        failures += expectClass("SENTINEL_GENERIC_FILLPOLYGON", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                int[] xs = {4, 20, 18, 7};
                int[] ys = {4, 6, 17, 19};
                g.fillPolygon(xs, 0, ys, 0, 4, 0xB04488CC);
                return pixels(image);
            }
        }, "MISMATCH");

        System.out.println("P1A_G1_FAILURE_COUNT=" + failures);
        if (failures != 0) {
            throw new RuntimeException("P1A_G1_DIFFERENTIAL_FAIL=" + failures);
        }
        System.out.println("P1A_G1_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_G1_COPYAREA_OVERLAP=JDK8_LIVE_RASTER_TOP_TO_BOTTOM_LEFT_TO_RIGHT");
        System.out.println("P1A_G1_SCOPE=clearRect+copyArea_ONLY");
    }

    private static void unexpectedControl() {
        // Keeps this gate Java 6-compatible while making accidental static init
        // failures visible before any operation-specific classification.
        if (W <= 0 || H <= 0) throw new RuntimeException("invalid test dimensions");
    }

    private static void paintBackground(PlatformGraphics g) {
        g.setColor(0x315579);
        g.fillRect(0, 0, W, H);
    }

    private static void paintPattern(PlatformGraphics g) {
        g.setColor(0x102030);
        g.fillRect(0, 0, W, H);
        g.setColor(0xCC4422);
        g.fillRect(2, 3, 10, 7);
        g.setColor(0x33AA66);
        g.fillRect(5, 5, 3, 3);
    }

    private static void paintColumns(PlatformGraphics g) {
        g.setColor(0x101010);
        g.fillRect(0, 0, W, H);
        for (int x = 0; x < W; x++) {
            int r = (x * 37) & 0xFF;
            int gr = (x * 67) & 0xFF;
            int b = (x * 97) & 0xFF;
            g.setColor((r << 16) | (gr << 8) | b);
            g.fillRect(x, 4, 1, 10);
        }
    }

    private static void paintGrid(PlatformGraphics g) {
        for (int y = 0; y < H; y++) {
            for (int x = 0; x < W; x++) {
                int r = (x * 29 + y * 11) & 0xFF;
                int gr = (x * 17 + y * 43) & 0xFF;
                int b = (x * 7 + y * 71) & 0xFF;
                g.setColor((r << 16) | (gr << 8) | b);
                g.fillRect(x, y, 1, 1);
            }
        }
    }

    private static int expectMatch(String name, Op op) throws Exception {
        return expectClass(name, op, "MATCH");
    }

    private static int expectClass(String name, Op op, String expected) throws Exception {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G1_CASE=" + name
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
