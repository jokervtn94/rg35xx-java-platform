package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import javax.microedition.lcdui.Graphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

public final class RG35XXG2CDrawRoundRectDifferentialGate {
    private static final int W=40,H=32,COLOR=0x3366CC;
    private interface Op { void run(PlatformGraphics g); }
    private static final class Result { final int[] pixels; final Throwable error; Result(int[] p,Throwable e){pixels=p;error=e;} }

    public static void main(String[] args) {
        int failures=0;
        failures += check("NORMAL", op(4,4,20,14,7,5));
        failures += check("OVERSIZE_ARC", op(4,4,20,14,40,30));
        failures += check("ZERO_ARC", op(4,4,20,14,0,0));
        failures += check("ZERO_ARC_WIDTH", op(4,4,20,14,0,5));
        failures += check("ZERO_ARC_HEIGHT", op(4,4,20,14,7,0));
        failures += check("ONE_ARC", op(4,4,20,14,1,1));
        failures += check("NEGATIVE_ARCS", op(4,4,20,14,-7,-5));
        failures += check("CIRCLE", op(5,5,18,18,18,18));
        failures += check("WIDE_FLAT", op(2,8,30,8,10,6));
        failures += check("ZERO_WIDTH", op(8,5,0,14,7,5));
        failures += check("ZERO_HEIGHT", op(8,5,14,0,7,5));
        failures += check("NEGATIVE_WIDTH", op(18,5,-8,14,7,5));
        failures += check("NEGATIVE_HEIGHT", op(8,18,14,-8,7,5));
        failures += check("PARTIAL_NEGATIVE", op(-5,-3,22,16,8,6));
        failures += check("PARTIAL_RIGHT_BOTTOM", op(30,24,18,14,8,6));
        failures += check("CLIP", new Op(){public void run(PlatformGraphics g){g.setClip(8,7,12,9);g.drawRoundRect(4,4,20,14,7,5);}});
        failures += check("TRANSLATE", new Op(){public void run(PlatformGraphics g){g.translate(3,2);g.drawRoundRect(4,4,20,14,7,5);}});
        failures += check("CLIP_TRANSLATE", new Op(){public void run(PlatformGraphics g){g.setClip(7,6,14,10);g.translate(3,2);g.drawRoundRect(4,4,20,14,7,5);}});
        failures += check("DOTTED_CANONICAL_QUIRK", new Op(){public void run(PlatformGraphics g){g.setStrokeStyle(Graphics.DOTTED);g.drawRoundRect(4,4,20,14,7,5);}});

        Result solid=execute(false,op(4,4,20,14,7,5));
        Result dotted=execute(false,new Op(){public void run(PlatformGraphics g){g.setStrokeStyle(Graphics.DOTTED);g.drawRoundRect(4,4,20,14,7,5);}});
        boolean dottedEqualsSolid=solid.error==null && dotted.error==null && Arrays.equals(solid.pixels,dotted.pixels);
        System.out.println("P1A_G2C_CANONICAL_QUIRK=DOTTED_EQUALS_SOLID "+dottedEqualsSolid);
        if(!dottedEqualsSolid) failures++;

        Result zero=execute(false,op(4,4,20,14,0,0));
        Result rect=execute(false,new Op(){public void run(PlatformGraphics g){g.drawRect(4,4,20,14);}});
        boolean zeroEqualsRect=zero.error==null && rect.error==null && Arrays.equals(zero.pixels,rect.pixels);
        System.out.println("P1A_G2C_CANONICAL_QUIRK=ZERO_ARC_EQUALS_DRAWRECT "+zeroEqualsRect);
        if(!zeroEqualsRect) failures++;

        System.out.println("P1A_G2C_STRICT_FAILURE_COUNT="+failures);
        if(failures!=0) throw new RuntimeException("P1A_G2C_STRICT_FAIL="+failures);
        System.out.println("P1A_G2C_DRAWROUNDRECT_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_G2C_CANONICAL_EQUIVALENT=YES");
        System.out.println("P1A_G2C_SCOPE=Graphics.drawRoundRect_ONLY");
    }

    private static Op op(final int x,final int y,final int w,final int h,final int aw,final int ah){return new Op(){public void run(PlatformGraphics g){g.drawRoundRect(x,y,w,h,aw,ah);}};}
    private static int check(String name,Op op){
        Result a=execute(false,op),r=execute(true,op);
        boolean ok=a.error==null && r.error==null && Arrays.equals(a.pixels,r.pixels);
        System.out.println("P1A_G2C_CASE="+name+" RESULT="+(ok?"MATCH":"MISMATCH")+" AWT="+err(a.error)+" RAW="+err(r.error));
        if(a.error==null) System.out.println("P1A_G2C_AWT_SIGNATURE="+name+" CHECKSUM="+checksum(a.pixels)+" COUNT="+count(a.pixels)+" BOUNDS="+bounds(a.pixels));
        if(!ok && a.error==null && r.error==null) dumpDiff(name,a.pixels,r.pixels);
        return ok?0:1;
    }
    private static Result execute(boolean raw,Op op){try{if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");PlatformImage im=new PlatformImage(W,H);PlatformGraphics g=im.getGraphics();g.setColor(COLOR);op.run(g);int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return new Result(p,null);}catch(Throwable t){return new Result(null,t);}}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
    private static int count(int[] p){int n=0;for(int i=0;i<p.length;i++)if((p[i]&0xffffff)==COLOR)n++;return n;}
    private static String bounds(int[] p){int minx=W,miny=H,maxx=-1,maxy=-1;for(int y=0;y<H;y++)for(int x=0;x<W;x++)if((p[y*W+x]&0xffffff)==COLOR){if(x<minx)minx=x;if(y<miny)miny=y;if(x>maxx)maxx=x;if(y>maxy)maxy=y;}return maxx<0?"EMPTY":minx+","+miny+".."+maxx+","+maxy;}
    private static String checksum(int[] p){long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}return Long.toHexString(h);}
    private static void dumpDiff(String name,int[] a,int[] r){int shown=0,total=0;for(int i=0;i<a.length;i++)if(a[i]!=r[i]){total++;if(shown<24){System.out.println("P1A_G2C_DIFF="+name+" X="+(i%W)+" Y="+(i/W)+" AWT="+Integer.toHexString(a[i])+" RAW="+Integer.toHexString(r[i]));shown++;}}System.out.println("P1A_G2C_DIFF_COUNT="+name+" "+total);}
}
