package org.recompile.rg35xx.p1a;

import java.util.Arrays;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Differential gate for the P1A-G1 clearRect/copyArea Raw2D backing only. */
public final class RG35XXG1ClearCopyDifferentialGate {
    private static final int W = 32;
    private static final int H = 24;

    private interface Op { int[] run(PlatformImage image, PlatformGraphics g); }

    public static void main(String[] args) {
        check("CLEAR_BASIC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x224466); g.fillRect(0, 0, W, H);
                g.clearRect(3, 4, 9, 7);
                return pixels(image);
            }
        });
        check("CLEAR_CLIP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x335577); g.fillRect(0, 0, W, H);
                g.setClip(6, 5, 8, 7);
                g.clearRect(2, 2, 20, 15);
                return pixels(image);
            }
        });
        check("CLEAR_TRANSLATE_CLIP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x446688); g.fillRect(0, 0, W, H);
                g.setClip(7, 6, 10, 8);
                g.translate(3, 2);
                g.clearRect(1, 1, 18, 14);
                return pixels(image);
            }
        });
        check("CLEAR_OUTSIDE_BOUNDS", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x557799); g.fillRect(0, 0, W, H);
                g.clearRect(-5, -4, 10, 9);
                return pixels(image);
            }
        });
        check("CLEAR_EMPTY", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x6688AA); g.fillRect(0, 0, W, H);
                g.clearRect(3, 4, 0, 8);
                g.clearRect(3, 4, 8, 0);
                return pixels(image);
            }
        });
        check("CLEAR_PRESERVES_COLOR", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x6A8CAE); g.fillRect(0, 0, W, H);
                g.clearRect(2, 2, 5, 4);
                g.fillRect(20, 15, 4, 3);
                return pixels(image);
            }
        });
        check("COPY_BASIC", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(2, 2, 8, 6, 17, 11, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_TRANSLATE_DEST", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.translate(3, 2);
                g.copyArea(2, 2, 8, 6, 12, 8, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_CLIP_DEST", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.setClip(15, 10, 5, 4);
                g.copyArea(2, 2, 8, 6, 13, 8, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_ANCHOR_RIGHT_BOTTOM", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(2, 2, 8, 6, 25, 20, PlatformGraphics.RIGHT | PlatformGraphics.BOTTOM);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_RIGHT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(2, 4, 14, 8, 6, 4, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_LEFT", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(7, 4, 14, 8, 2, 4, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_DOWN", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(4, 2, 12, 10, 4, 6, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_UP", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(4, 7, 12, 10, 4, 2, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_FORWARD", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(2, 2, 12, 8, 6, 5, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_OVERLAP_BACKWARD", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                seed(g);
                g.copyArea(7, 6, 12, 8, 2, 2, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });
        check("COPY_ALPHA_SOURCE_OVER", new Op() {
            public int[] run(PlatformImage image, PlatformGraphics g) {
                g.setColor(0x204060); g.fillRect(15, 10, 6, 5);
                int[] src = new int[6 * 5]; Arrays.fill(src, 0x8040C020);
                g.drawRGB(src, 0, 6, 2, 2, 6, 5, true);
                g.copyArea(2, 2, 6, 5, 15, 10, PlatformGraphics.LEFT | PlatformGraphics.TOP);
                return pixels(image);
            }
        });

        System.out.println("P1A_G1_CLEAR_COPY_DIFFERENTIAL=PASS");
    }

    private static void seed(PlatformGraphics g) {
        g.setColor(0x102030); g.fillRect(0, 0, W, H);
        g.setColor(0xC04020); g.fillRect(2, 2, 8, 6);
        g.setColor(0x2080C0); g.fillRect(10, 5, 9, 8);
        g.setColor(0x40A060); g.fillRect(4, 14, 12, 5);
    }

    private static void check(String name, Op op) {
        int[] awt = execute(false, op);
        int[] raw = execute(true, op);
        if (!Arrays.equals(awt, raw)) {
            int first = -1;
            for (int i = 0; i < awt.length; i++) if (awt[i] != raw[i]) { first = i; break; }
            throw new RuntimeException("P1A_G1_MISMATCH=" + name + " FIRST=" + first
                    + " AWT=" + hex(first < 0 ? 0 : awt[first])
                    + " RAW=" + hex(first < 0 ? 0 : raw[first]));
        }
        System.out.println("P1A_G1_CASE=" + name + " MATCH");
    }

    private static int[] execute(boolean raw, Op op) {
        if (raw) System.setProperty("rg35xx.raw2d", "true");
        else System.clearProperty("rg35xx.raw2d");
        PlatformImage image = new PlatformImage(W, H);
        PlatformGraphics g = image.getGraphics();
        return op.run(image, g);
    }

    private static int[] pixels(PlatformImage image) {
        int[] out = new int[W * H];
        image.getRGB(out, 0, W, 0, 0, W, H);
        return out;
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return "0x" + s;
    }
}
