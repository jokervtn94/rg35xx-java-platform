package org.recompile.rg35xx.p1a;

import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Diagnostic-only Raw2D execution of the exact G2D FUZZ_68 case. */
public final class RG35XXG2D6A4DFuzz68RawTrace {
    private static final int W=48, H=40, COLOR=0x3366CC;

    public static void main(String[] args) {
        System.setProperty("rg35xx.raw2d", "true");
        PlatformImage im = new PlatformImage(W,H);
        PlatformGraphics g = im.getGraphics();
        g.setColor(COLOR);
        g.translate(6,-3);
        g.drawArc(20,39,30,29,-971,-720);

        int[] p = new int[W*H];
        im.getRGB(p,0,W,0,0,W,H);
        System.out.println("G2D6A4D_CASE=FUZZ_68");
        System.out.println("G2D6A4D_RAW_COUNT="+count(p));
        System.out.println("G2D6A4D_RAW_CHECKSUM="+sum(p));
        System.out.println("G2D6A4D_RAW_PIXEL_31_39="+hex(p[39*W+31]));
        System.out.println("G2D6A4D_RAW_TRACE=PASS");
    }

    private static int count(int[] p){int n=0;for(int i=0;i<p.length;i++)if((p[i]&0xFFFFFF)==COLOR)n++;return n;}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xFFFFFFFFL);h*=1099511628211L;}return Long.toHexString(h);}
}
