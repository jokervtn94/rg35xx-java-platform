package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Strict JDK8 differential gate for six-argument MIDP Graphics.fillTriangle. */
public final class RG35XXG2BFillTriangleDifferentialGate {
    private static final int W = 40, H = 32, COLOR = 0x3366CC;
    private interface Op { void run(PlatformGraphics g); }
    private static final class Result {
        final int[] pixels; final Throwable error;
        Result(int[] p, Throwable e) { pixels=p; error=e; }
    }
    private static int failures;

    public static void main(String[] args) {
        check("REFERENCE", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(4,4,24,7,10,22); }});
        check("REVERSED", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,22,24,7,4,4); }});
        check("PERM_BAC", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(24,7,4,4,10,22); }});
        check("PERM_BCA", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(24,7,10,22,4,4); }});
        check("PERM_CAB", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,22,4,4,24,7); }});
        check("PERM_CBA", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,22,24,7,4,4); }});
        check("FLAT_HORIZONTAL", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(5,12,16,12,25,12); }});
        check("FLAT_VERTICAL", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(12,4,12,16,12,25); }});
        check("DUPLICATE_AB", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(5,5,5,5,23,20); }});
        check("DUPLICATE_BC", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(5,5,23,20,23,20); }});
        check("ALL_DUPLICATE", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(12,11,12,11,12,11); }});
        check("SKINNY_VERTICAL", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,3,11,27,12,3); }});
        check("SKINNY_HORIZONTAL", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(3,14,35,15,3,16); }});
        check("TINY_RIGHT", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,10,11,10,10,11); }});
        check("TINY_TWO", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(10,10,12,10,10,12); }});
        check("CLIP", new Op(){ public void run(PlatformGraphics g){ g.setClip(9,8,13,11); g.fillTriangle(3,3,31,8,12,27); }});
        check("TRANSLATE", new Op(){ public void run(PlatformGraphics g){ g.translate(5,4); g.fillTriangle(2,2,22,5,7,20); }});
        check("CLIP_TRANSLATE", new Op(){ public void run(PlatformGraphics g){ g.setClip(10,8,14,12); g.translate(5,4); g.fillTriangle(-2,-1,26,4,8,24); }});
        check("PARTIAL_NEGATIVE", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(-12,-7,23,4,6,25); }});
        check("PARTIAL_RIGHT_BOTTOM", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(17,9,51,14,28,42); }});
        check("SPANNING", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(-20,-12,61,3,18,49); }});

        scopeMatch("PARENT_FILLROUNDRECT", new Op(){ public void run(PlatformGraphics g){ g.fillRoundRect(4,4,20,14,7,5); }});
        scopeException("SENTINEL_DRAWARC", new Op(){ public void run(PlatformGraphics g){ g.drawArc(5,4,17,13,25,230); }});
        scopeException("SENTINEL_FILLARC", new Op(){ public void run(PlatformGraphics g){ g.fillArc(5,4,17,13,25,230); }});
        if (Boolean.getBoolean("p1a.g2c.parentregression")) {
            scopeMatch("PARENT_DRAWROUNDRECT_G2C", new Op(){ public void run(PlatformGraphics g){ g.drawRoundRect(4,4,20,14,7,5); }});
        } else {
            scopeException("SENTINEL_DRAWROUNDRECT", new Op(){ public void run(PlatformGraphics g){ g.drawRoundRect(4,4,20,14,7,5); }});
        }
        scopeException("SENTINEL_DG_FILLTRIANGLE_7ARG", new Op(){ public void run(PlatformGraphics g){ g.fillTriangle(4,4,24,7,10,22,0xCC3366CC); }});

        System.out.println("P1A_G2B_STRICT_FAILURE_COUNT="+failures);
        if (failures != 0) throw new RuntimeException("P1A_G2B_STRICT_FAIL="+failures);
        System.out.println("P1A_G2B_FILLTRIANGLE_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_G2B_CANONICAL_EQUIVALENT=YES");
        System.out.println("P1A_G2B_SCOPE=Graphics.fillTriangle_6ARG_ONLY");
    }

    private static void check(String name, Op op) {
        Result a=exec(false,op), r=exec(true,op);
        boolean match=a.error==null && r.error==null && Arrays.equals(a.pixels,r.pixels);
        System.out.println("P1A_G2B_CASE="+name+" MATCH="+match+" AWT="+err(a.error)+" RAW="+err(r.error)
                +" AWT_CHECKSUM="+sum(a.pixels)+" RAW_CHECKSUM="+sum(r.pixels)
                +" AWT_COUNT="+count(a.pixels)+" RAW_COUNT="+count(r.pixels));
        if(!match){ failures++; firstDiff(name,a.pixels,r.pixels); }
    }
    private static void scopeMatch(String name, Op op) {
        Result a=exec(false,op),r=exec(true,op); String c=classify(a,r);
        System.out.println("P1A_G2B_SCOPE_CASE="+name+" EXPECTED=MATCH ACTUAL="+c+" AWT="+err(a.error)+" RAW="+err(r.error));
        if(!"MATCH".equals(c)) failures++;
    }
    private static void scopeException(String name, Op op) {
        Result a=exec(false,op),r=exec(true,op); String c=classify(a,r);
        System.out.println("P1A_G2B_SCOPE_CASE="+name+" EXPECTED=RAW_EXCEPTION ACTUAL="+c+" AWT="+err(a.error)+" RAW="+err(r.error));
        if(!"RAW_EXCEPTION".equals(c)) failures++;
    }
    private static Result exec(boolean raw, Op op){
        try{
            if(raw) System.setProperty("rg35xx.raw2d","true"); else System.clearProperty("rg35xx.raw2d");
            PlatformImage im=new PlatformImage(W,H); PlatformGraphics g=im.getGraphics(); g.setColor(COLOR); op.run(g); return new Result(pixels(im),null);
        }catch(Throwable t){ return new Result(null,t); }
    }
    private static String classify(Result a, Result r){ if(a.error!=null)return "AWT_EXCEPTION"; if(r.error!=null)return "RAW_EXCEPTION"; return Arrays.equals(a.pixels,r.pixels)?"MATCH":"MISMATCH"; }
    private static int[] pixels(PlatformImage im){ int[] p=new int[W*H]; im.getRGB(p,0,W,0,0,W,H); return p; }
    private static int count(int[] p){ if(p==null)return -1; int n=0; for(int i=0;i<p.length;i++) if((p[i]&0xFFFFFF)==COLOR)n++; return n; }
    private static void firstDiff(String name,int[] a,int[] r){ if(a==null||r==null)return; for(int i=0;i<a.length;i++) if(a[i]!=r[i]){ System.out.println("P1A_G2B_FIRST_DIFF="+name+" X="+(i%W)+" Y="+(i/W)+" AWT="+hex(a[i])+" RAW="+hex(r[i])); return; } }
    private static String err(Throwable t){ return t==null?"NONE":t.getClass().getName(); }
    private static String hex(int v){ String s=Integer.toHexString(v); while(s.length()<8)s="0"+s; return s; }
    private static String sum(int[] p){ if(p==null)return "NONE"; long h=1469598103934665603L; for(int i=0;i<p.length;i++){h^=(p[i]&0xFFFFFFFFL);h*=1099511628211L;} return Long.toHexString(h); }
}
