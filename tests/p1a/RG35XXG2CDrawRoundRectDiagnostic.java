package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Diagnostic-only canonical characterization for P1A G2C drawRoundRect. */
public final class RG35XXG2CDrawRoundRectDiagnostic {
    private static final int W = 40;
    private static final int H = 32;
    private static final int COLOR = 0x3366CC;

    private interface Op { void run(PlatformGraphics g); }
    private static final class Result {
        final int[] pixels; final Throwable error;
        Result(int[] p, Throwable e) { pixels = p; error = e; }
    }

    public static void main(String[] args) {
        int failures = 0;
        failures += capture("NORMAL", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(4,4,20,14,7,5); }});
        failures += capture("OVERSIZE_ARC", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(4,4,20,14,40,30); }});
        failures += capture("ZERO_ARC", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(4,4,20,14,0,0); }});
        failures += capture("ONE_ARC", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(4,4,20,14,1,1); }});
        failures += capture("CIRCLE", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(5,5,18,18,18,18); }});
        failures += capture("WIDE_FLAT", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(2,8,30,8,10,6); }});
        failures += capture("ZERO_WIDTH", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(8,5,0,14,7,5); }});
        failures += capture("ZERO_HEIGHT", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(8,5,14,0,7,5); }});
        failures += capture("NEGATIVE_WIDTH", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(18,5,-8,14,7,5); }});
        failures += capture("NEGATIVE_HEIGHT", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(8,18,14,-8,7,5); }});
        failures += capture("PARTIAL_NEGATIVE", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(-5,-3,22,16,8,6); }});
        failures += capture("PARTIAL_RIGHT_BOTTOM", new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(30,24,18,14,8,6); }});
        failures += capture("CLIP", new Op() { public void run(PlatformGraphics g) { g.setClip(8,7,12,9); g.drawRoundRect(4,4,20,14,7,5); }});
        failures += capture("TRANSLATE", new Op() { public void run(PlatformGraphics g) { g.translate(3,2); g.drawRoundRect(4,4,20,14,7,5); }});
        failures += capture("CLIP_TRANSLATE", new Op() { public void run(PlatformGraphics g) { g.setClip(7,6,14,10); g.translate(3,2); g.drawRoundRect(4,4,20,14,7,5); }});

        Result zeroArc = execute(false, new Op() { public void run(PlatformGraphics g) { g.drawRoundRect(4,4,20,14,0,0); }});
        Result rect = execute(false, new Op() { public void run(PlatformGraphics g) { g.drawRect(4,4,20,14); }});
        boolean zeroEqualsRect = zeroArc.error == null && rect.error == null && Arrays.equals(zeroArc.pixels, rect.pixels);
        System.out.println("P1A_G2C_QUIRK=ZERO_ARC_EQUALS_DRAWRECT " + zeroEqualsRect);

        System.out.println("P1A_G2C_DIAGNOSTIC_FAILURE_COUNT=" + failures);
        if (failures != 0) throw new RuntimeException("P1A_G2C_DIAGNOSTIC_FAIL=" + failures);
        System.out.println("P1A_G2C_DRAWROUNDRECT_DIAGNOSTIC=PASS");
        System.out.println("P1A_G2C_RUNTIME_CHANGE=NO");
    }

    private static int capture(String name, Op op) {
        Result awt = execute(false, op);
        Result raw = execute(true, op);
        String actual = classify(awt, raw);
        System.out.println("P1A_G2C_CASE=" + name + " EXPECTED=RAW_EXCEPTION ACTUAL=" + actual
                + " AWT=" + errorName(awt.error) + " RAW=" + errorName(raw.error));
        if (awt.error == null) {
            System.out.println("P1A_G2C_AWT_SIGNATURE=" + name + " CHECKSUM=" + checksum(awt.pixels)
                    + " COUNT=" + countPainted(awt.pixels) + " BOUNDS=" + bounds(awt.pixels));
            dumpMask(name, awt.pixels);
        }
        return "RAW_EXCEPTION".equals(actual) ? 0 : 1;
    }

    private static Result execute(boolean raw, Op op) {
        try {
            if (raw) System.setProperty("rg35xx.raw2d", "true"); else System.clearProperty("rg35xx.raw2d");
            PlatformImage image = new PlatformImage(W,H);
            PlatformGraphics g = image.getGraphics();
            g.setColor(COLOR);
            op.run(g);
            int[] out = new int[W*H];
            image.getRGB(out,0,W,0,0,W,H);
            return new Result(out,null);
        } catch (Throwable t) { return new Result(null,t); }
    }

    private static String classify(Result awt, Result raw) {
        if (awt.error != null) return "AWT_EXCEPTION";
        if (raw.error != null) return "RAW_EXCEPTION";
        return Arrays.equals(awt.pixels, raw.pixels) ? "MATCH" : "MISMATCH";
    }
    private static String errorName(Throwable t) { return t == null ? "NONE" : t.getClass().getName(); }
    private static int countPainted(int[] p) { int n=0; for(int i=0;i<p.length;i++) if((p[i]&0x00FFFFFF)==COLOR)n++; return n; }
    private static String bounds(int[] p) {
        int minX=W,minY=H,maxX=-1,maxY=-1;
        for(int y=0;y<H;y++) for(int x=0;x<W;x++) if((p[y*W+x]&0x00FFFFFF)==COLOR) {
            if(x<minX)minX=x;if(y<minY)minY=y;if(x>maxX)maxX=x;if(y>maxY)maxY=y;
        }
        return maxX<0?"EMPTY":(minX+","+minY+".."+maxX+","+maxY);
    }
    private static void dumpMask(String name, int[] p) {
        System.out.println("P1A_G2C_MASK_BEGIN="+name);
        for(int y=0;y<H;y++) {
            StringBuffer s=new StringBuffer(W);
            for(int x=0;x<W;x++) s.append(((p[y*W+x]&0x00FFFFFF)==COLOR)?'#':'.');
            System.out.println(s.toString());
        }
        System.out.println("P1A_G2C_MASK_END="+name);
    }
    private static String checksum(int[] p) {
        long h=1469598103934665603L;
        for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}
        return Long.toHexString(h);
    }
}
