package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import java.util.Random;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Deterministic G2D fuzz gate with complete mismatch parameters. */
public final class RG35XXG2DFuzzTraceGate {
    private static final int W=48,H=40,COLOR=0x3366CC;
    private static final int[] EXTENTS=new int[]{0,1,-1,17,-17,45,-45,89,-89,90,-90,120,-120,179,-179,230,-230,359,-359,360,-360,450,-450,720,-720};
    private static final class C {
        boolean fill,dotted,clip; int x,y,w,h,start,extent,cx,cy,cw,ch,tx,ty;
        void run(PlatformGraphics g){if(clip)g.setClip(cx,cy,cw,ch);if(tx!=0||ty!=0)g.translate(tx,ty);if(dotted)g.setStrokeStyle(PlatformGraphics.DOTTED);if(fill)g.fillArc(x,y,w,h,start,extent);else g.drawArc(x,y,w,h,start,extent);}
        String spec(){return "FILL="+fill+" X="+x+" Y="+y+" W="+w+" H="+h+" START="+start+" EXTENT="+extent+" CLIP="+clip+(clip?("["+cx+","+cy+","+cw+","+ch+"]"):"")+" TX="+tx+" TY="+ty+" DOTTED="+dotted;}
    }
    private static final class R {final int[] p;final Throwable e;R(int[] a,Throwable b){p=a;e=b;}}
    public static void main(String[] args){
        Random r=new Random(0x35AA2D5L);int fail=0;
        for(int i=0;i<320;i++){
            C c=new C();c.fill=(i&1)!=0;c.x=r.nextInt(69)-18;c.y=r.nextInt(59)-14;c.w=r.nextInt(39)-4;c.h=r.nextInt(35)-4;c.start=r.nextInt(2881)-1440;c.extent=EXTENTS[r.nextInt(EXTENTS.length)];
            if((i%3)==0){c.clip=true;c.cx=r.nextInt(42)-5;c.cy=r.nextInt(34)-4;c.cw=1+r.nextInt(30);c.ch=1+r.nextInt(26);}
            if((i%4)==0){c.tx=r.nextInt(13)-6;c.ty=r.nextInt(13)-6;}
            if(!c.fill&&(i%11)==0)c.dotted=true;
            R a=exec(false,c),b=exec(true,c);boolean m=a.e==null&&b.e==null&&Arrays.equals(a.p,b.p);
            if(!m){fail++;System.out.println("P1A_G2D_FUZZ_MISMATCH="+i+" "+c.spec()+" AWT="+err(a.e)+" RAW="+err(b.e)+" AWT_SUM="+sum(a.p)+" RAW_SUM="+sum(b.p));first(i,a.p,b.p);}
        }
        System.out.println("P1A_G2D_FUZZ_TRACE_CASES=320");System.out.println("P1A_G2D_FUZZ_TRACE_FAILURE_COUNT="+fail);
        if(fail!=0)throw new RuntimeException("P1A_G2D_FUZZ_TRACE_FAIL="+fail);
        System.out.println("P1A_G2D_FUZZ_TRACE_GATE=PASS");
    }
    private static R exec(boolean raw,C c){try{if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");PlatformImage im=new PlatformImage(W,H);PlatformGraphics g=im.getGraphics();g.setColor(COLOR);c.run(g);int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return new R(p,null);}catch(Throwable t){return new R(null,t);}}
    private static void first(int id,int[] a,int[] b){if(a==null||b==null)return;for(int i=0;i<a.length;i++)if(a[i]!=b[i]){System.out.println("P1A_G2D_FUZZ_FIRST_DIFF="+id+" X="+(i%W)+" Y="+(i/W)+" AWT="+hex(a[i])+" RAW="+hex(b[i]));return;}}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){if(p==null)return "NONE";long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}return Long.toHexString(h);}
}
