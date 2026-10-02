package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Diagnostic-only canonical characterization for MIDP drawArc/fillArc. */
public final class RG35XXG2DArcFamilyDiagnostic {
    private static final int W=48, H=40, COLOR=0x3366CC;
    private interface Op { void run(PlatformGraphics g); }
    private static final class Result {
        final int[] pixels; final Throwable error;
        Result(int[] p, Throwable e){ pixels=p; error=e; }
    }
    private static int failures;

    public static void main(String[] args) {
        // DRAW ARC canonical masks.
        sig("DRAW_NORMAL_POS", opDraw(5,4,23,17,25,230,false));
        sig("DRAW_NORMAL_NEG", opDraw(5,4,23,17,25,-230,false));
        sig("DRAW_FULL_POS", opDraw(5,4,23,17,17,360,false));
        sig("DRAW_FULL_NEG", opDraw(5,4,23,17,17,-360,false));
        sig("DRAW_OVER_POS", opDraw(5,4,23,17,17,450,false));
        sig("DRAW_OVER_NEG", opDraw(5,4,23,17,17,-450,false));
        sig("DRAW_ZERO_EXTENT", opDraw(5,4,23,17,25,0,false));
        sig("DRAW_START_450", opDraw(5,4,23,17,450,120,false));
        sig("DRAW_START_NEG450", opDraw(5,4,23,17,-450,120,false));
        sig("DRAW_ZERO_WIDTH", opDraw(8,5,0,17,25,230,false));
        sig("DRAW_ZERO_HEIGHT", opDraw(8,5,17,0,25,230,false));
        sig("DRAW_NEGATIVE_WIDTH", opDraw(8,5,-7,17,25,230,false));
        sig("DRAW_NEGATIVE_HEIGHT", opDraw(8,5,17,-7,25,230,false));
        sig("DRAW_PARTIAL_NEGATIVE", opDraw(-8,-5,25,21,20,250,false));
        sig("DRAW_PARTIAL_RIGHT_BOTTOM", opDraw(34,27,21,18,-40,250,false));
        sig("DRAW_CLIP", new Op(){public void run(PlatformGraphics g){g.setClip(10,8,13,11);g.drawArc(3,2,30,24,25,260);}});
        sig("DRAW_TRANSLATE", new Op(){public void run(PlatformGraphics g){g.translate(5,4);g.drawArc(1,1,23,17,25,230);}});
        sig("DRAW_CLIP_TRANSLATE", new Op(){public void run(PlatformGraphics g){g.setClip(10,8,15,12);g.translate(5,4);g.drawArc(-3,-2,31,24,25,260);}});
        sig("DRAW_DOTTED_CANONICAL", opDraw(5,4,23,17,25,230,true));

        // FILL ARC canonical masks (AWT fillArc is a pie fill).
        sig("FILL_NORMAL_POS", opFill(5,4,23,17,25,230));
        sig("FILL_NORMAL_NEG", opFill(5,4,23,17,25,-230));
        sig("FILL_FULL_POS", opFill(5,4,23,17,17,360));
        sig("FILL_FULL_NEG", opFill(5,4,23,17,17,-360));
        sig("FILL_OVER_POS", opFill(5,4,23,17,17,450));
        sig("FILL_OVER_NEG", opFill(5,4,23,17,17,-450));
        sig("FILL_ZERO_EXTENT", opFill(5,4,23,17,25,0));
        sig("FILL_START_450", opFill(5,4,23,17,450,120));
        sig("FILL_START_NEG450", opFill(5,4,23,17,-450,120));
        sig("FILL_ZERO_WIDTH", opFill(8,5,0,17,25,230));
        sig("FILL_ZERO_HEIGHT", opFill(8,5,17,0,25,230));
        sig("FILL_NEGATIVE_WIDTH", opFill(8,5,-7,17,25,230));
        sig("FILL_NEGATIVE_HEIGHT", opFill(8,5,17,-7,25,230));
        sig("FILL_PARTIAL_NEGATIVE", opFill(-8,-5,25,21,20,250));
        sig("FILL_PARTIAL_RIGHT_BOTTOM", opFill(34,27,21,18,-40,250));
        sig("FILL_CLIP", new Op(){public void run(PlatformGraphics g){g.setClip(10,8,13,11);g.fillArc(3,2,30,24,25,260);}});
        sig("FILL_TRANSLATE", new Op(){public void run(PlatformGraphics g){g.translate(5,4);g.fillArc(1,1,23,17,25,230);}});
        sig("FILL_CLIP_TRANSLATE", new Op(){public void run(PlatformGraphics g){g.setClip(10,8,15,12);g.translate(5,4);g.fillArc(-3,-2,31,24,25,260);}});

        rawGap("DRAW_RAW_GAP", opDraw(5,4,23,17,25,230,false));
        rawGap("FILL_RAW_GAP", opFill(5,4,23,17,25,230));

        compare("DRAW_DOTTED_EQUALS_SOLID", opDraw(5,4,23,17,25,230,false), opDraw(5,4,23,17,25,230,true));
        compare("DRAW_START_450_EQUALS_90", opDraw(5,4,23,17,450,120,false), opDraw(5,4,23,17,90,120,false));
        compare("FILL_START_450_EQUALS_90", opFill(5,4,23,17,450,120), opFill(5,4,23,17,90,120));
        compare("DRAW_OVER_450_EQUALS_FULL", opDraw(5,4,23,17,17,450,false), opDraw(5,4,23,17,17,360,false));
        compare("FILL_OVER_450_EQUALS_FULL", opFill(5,4,23,17,17,450), opFill(5,4,23,17,17,360));

        System.out.println("P1A_G2D_DIAGNOSTIC_FAILURE_COUNT="+failures);
        if(failures!=0) throw new RuntimeException("P1A_G2D_DIAGNOSTIC_FAIL="+failures);
        System.out.println("P1A_G2D_ARC_FAMILY_DIAGNOSTIC=PASS");
        System.out.println("P1A_G2D_RUNTIME_DELTA=NONE_DIAGNOSTIC_ONLY");
        System.out.println("P1A_G2D_NEXT=IMPLEMENT_FROM_CANONICAL_CHARACTERIZATION");
    }

    private static Op opDraw(final int x,final int y,final int w,final int h,final int s,final int a,final boolean dotted){
        return new Op(){public void run(PlatformGraphics g){if(dotted)g.setStrokeStyle(PlatformGraphics.DOTTED);g.drawArc(x,y,w,h,s,a);}};
    }
    private static Op opFill(final int x,final int y,final int w,final int h,final int s,final int a){
        return new Op(){public void run(PlatformGraphics g){g.fillArc(x,y,w,h,s,a);}};
    }
    private static void sig(String name, Op op){
        Result r=exec(false,op);
        if(r.error!=null){failures++;System.out.println("P1A_G2D_SIGNATURE="+name+" ERROR="+err(r.error));return;}
        System.out.println("P1A_G2D_SIGNATURE="+name+" CHECKSUM="+sum(r.pixels)+" COUNT="+count(r.pixels)+" BOUNDS="+bounds(r.pixels));
    }
    private static void rawGap(String name, Op op){
        Result a=exec(false,op),r=exec(true,op);
        boolean ok=a.error==null && r.error instanceof NullPointerException;
        System.out.println("P1A_G2D_RAW_GAP="+name+" EXPECTED=RAW_NPE ACTUAL="+(ok?"RAW_NPE":"UNEXPECTED")+" AWT="+err(a.error)+" RAW="+err(r.error));
        if(!ok) failures++;
    }
    private static void compare(String name, Op aop, Op bop){
        Result a=exec(false,aop),b=exec(false,bop);
        boolean eq=a.error==null&&b.error==null&&Arrays.equals(a.pixels,b.pixels);
        System.out.println("P1A_G2D_CANONICAL_RELATION="+name+" EQUAL="+eq+" A="+err(a.error)+" B="+err(b.error));
        if(a.error!=null||b.error!=null) failures++;
    }
    private static Result exec(boolean raw, Op op){
        try{
            if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");
            PlatformImage im=new PlatformImage(W,H); PlatformGraphics g=im.getGraphics(); g.setColor(COLOR); op.run(g);
            return new Result(pixels(im),null);
        }catch(Throwable t){return new Result(null,t);}
    }
    private static int[] pixels(PlatformImage im){int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return p;}
    private static int count(int[] p){int n=0;for(int i=0;i<p.length;i++)if((p[i]&0xFFFFFF)==COLOR)n++;return n;}
    private static String bounds(int[] p){int minx=W,miny=H,maxx=-1,maxy=-1;for(int i=0;i<p.length;i++)if((p[i]&0xFFFFFF)==COLOR){int x=i%W,y=i/W;if(x<minx)minx=x;if(y<miny)miny=y;if(x>maxx)maxx=x;if(y>maxy)maxy=y;}return maxx<0?"EMPTY":(minx+","+miny+".."+maxx+","+maxy);}
    private static String sum(int[] p){long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xFFFFFFFFL);h*=1099511628211L;}return Long.toHexString(h);}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
}
