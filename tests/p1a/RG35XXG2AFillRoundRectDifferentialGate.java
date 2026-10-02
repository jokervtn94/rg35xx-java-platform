package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Differential gate for G2A only: MIDP Graphics.fillRoundRect. */
public final class RG35XXG2AFillRoundRectDifferentialGate {
    private static final int W = 36;
    private static final int H = 28;
    private static final int COLOR = 0x3366CC;

    private interface Op {
        int[] run(PlatformImage image, PlatformGraphics g);
    }

    private static final class Result {
        final int[] pixels;
        final Throwable error;
        Result(int[] pixels, Throwable error) { this.pixels = pixels; this.error = error; }
    }

    public static void main(String[] args) {
        int failures = 0;

        failures += expectMatch("NORMAL", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(4, 4, 20, 14, 7, 5);
                return pixels(image);
            }
        });

        failures += expectMatch("OVERSIZE_ARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(4, 4, 20, 14, 40, 30);
                return pixels(image);
            }
        });

        failures += expectMatch("ZERO_ARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(4, 4, 20, 14, 0, 0);
                return pixels(image);
            }
        });

        failures += expectMatch("CLIP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setClip(8, 7, 10, 8);
                g.fillRoundRect(3, 3, 24, 18, 9, 7);
                return pixels(image);
            }
        });

        failures += expectMatch("TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.translate(5, 3);
                g.fillRoundRect(2, 4, 18, 11, 6, 4);
                return pixels(image);
            }
        });

        failures += expectMatch("CLIP_TRANSLATE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setClip(9, 8, 12, 9);
                g.translate(5, 3);
                g.fillRoundRect(0, 1, 25, 17, 8, 8);
                return pixels(image);
            }
        });

        failures += expectMatch("ZERO_WIDTH", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(5, 5, 0, 10, 6, 6);
                return pixels(image);
            }
        });

        failures += expectMatch("ZERO_HEIGHT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(5, 5, 10, 0, 6, 6);
                return pixels(image);
            }
        });

        failures += expectMatch("NEGATIVE_WIDTH", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(5, 5, -7, 10, 6, 6);
                return pixels(image);
            }
        });

        failures += expectMatch("NEGATIVE_HEIGHT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(5, 5, 10, -7, 6, 6);
                return pixels(image);
            }
        });

        // Prove the pinned final-result quirk directly on both backends.
        failures += expectRoundEqualsRect(false, "AWT_QUIRK");
        failures += expectRoundEqualsRect(true, "RAW_QUIRK");

        // Scope sentinels: G2A must not implement neighboring G2 methods.
        failures += expectClass("SENTINEL_DRAWROUNDRECT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.drawRoundRect(4, 4, 20, 14, 7, 5);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        failures += expectClass("SENTINEL_DRAWARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.drawArc(5, 4, 17, 13, 25, 230);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        failures += expectClass("SENTINEL_FILLARC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillArc(5, 4, 17, 13, 25, 230);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        failures += expectClass("SENTINEL_FILLTRIANGLE", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillTriangle(4, 4, 24, 7, 10, 22);
                return pixels(image);
            }
        }, "RAW_EXCEPTION");

        System.out.println("P1A_G2A_FAILURE_COUNT=" + failures);
        if (failures != 0) throw new RuntimeException("P1A_G2A_DIFFERENTIAL_FAIL=" + failures);
        System.out.println("P1A_G2A_FILLROUNDRECT_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_G2A_SCOPE=fillRoundRect_ONLY");
    }

    private static int expectRoundEqualsRect(boolean raw, String name) {
        int[] round = execute(raw, new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRoundRect(4, 4, 20, 14, 7, 5);
                return pixels(image);
            }
        }).pixels;
        int[] rect = execute(raw, new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.fillRect(4, 4, 20, 14);
                return pixels(image);
            }
        }).pixels;
        boolean match = round != null && rect != null && Arrays.equals(round, rect);
        System.out.println("P1A_G2A_QUIRK=" + name + " FILLROUNDRECT_EQUALS_FILLRECT=" + match);
        return match ? 0 : 1;
    }

    private static int expectMatch(String name, Op op) {
        return expectClass(name, op, "MATCH");
    }

    private static int expectClass(String name, Op op, String expected) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G2A_CASE=" + name + " EXPECTED=" + expected + " ACTUAL=" + actual
                + " AWT=" + errorName(awt.error) + " RAW=" + errorName(raw.error));
        return expected.equals(actual) ? 0 : 1;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true");
            else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W, H);
            PlatformGraphics g = image.getGraphics();
            g.setColor(COLOR);
            return new Result(op.run(image, g), null);
        } catch (Throwable t) {
            return new Result(null, t);
        }
    }

    private static String classify(Result awt, Result raw) {
        if (awt.error != null) return "AWT_EXCEPTION";
        if (raw.error != null) return "RAW_EXCEPTION";
        return Arrays.equals(awt.pixels, raw.pixels) ? "MATCH" : "MISMATCH";
    }

    private static String errorName(Throwable t) { return t == null ? "NONE" : t.getClass().getName(); }

    private static int[] pixels(PlatformImage image) {
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }
}
