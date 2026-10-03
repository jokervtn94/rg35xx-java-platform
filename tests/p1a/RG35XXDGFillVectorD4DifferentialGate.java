package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import java.util.Random;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Runtime differential gate for DirectGraphics fillTriangle(7arg) + fillPolygon. */
public final class RG35XXDGFillVectorD4DifferentialGate {
    private static final int W=48,H=40,BG=0x102030,STATE=0x884422;
    private static final long SEED=0x35D3001L;
    private static final int[] ALPHA_COLORS={0x003366CC,0x403366CC,0x803366CC,0xCC3366CC,0xFF3366CC};
    private static int failures,triCases,polyFixed,polyFuzz,offsetCases,stateFailures;

    private interface Op { void run(PlatformGraphics g); }
    private static final class Result {
        final int[] pixels; final Throwable error; final int color;
        Result(int[] p,Throwable e,int c){pixels=p;error=e;color=c;}
    }
    private static final class PCase {
        final String name; final int[] x,y; final boolean clip; final int cx,cy,cw,ch,tx,ty;
        PCase(String n,int[] xx,int[] yy){this(n,xx,yy,false,0,0,0,0,0,0);}
        PCase(String n,int[] xx,int[] yy,boolean c,int ax,int ay,int aw,int ah,int dx,int dy){name=n;x=xx;y=yy;clip=c;cx=ax;cy=ay;cw=aw;ch=ah;tx=dx;ty=dy;}
    }

    public static void main(String[] args){
        runTriangles(); runPolygonFixed(); runPolygonFuzz(); runOffsetWindow();
        System.out.println("P1A_DG_D4_TRIANGLE_CASE_COUNT="+triCases);
        System.out.println("P1A_DG_D4_POLYGON_FIXED_COUNT="+polyFixed);
        System.out.println("P1A_DG_D4_POLYGON_FUZZ_COUNT="+polyFuzz);
        System.out.println("P1A_DG_D4_OFFSET_CASE_COUNT="+offsetCases);
        System.out.println("P1A_DG_D4_STATE_FAILURE_COUNT="+stateFailures);
        System.out.println("P1A_DG_D4_RANDOM_SEED="+Long.toHexString(SEED));
        System.out.println("P1A_DG_D4_STRICT_FAILURE_COUNT="+failures);
        System.out.println("P1A_DG_D4_WINDING=EVEN_ODD");
        System.out.println("P1A_DG_D4_ALPHA_MODEL=G1_EXACT_8BIT_SRCOVER");
        if(failures!=0) throw new RuntimeException("P1A_DG_D4_FAIL="+failures);
        System.out.println("P1A_DG_D4_FILL_VECTOR_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_DG_D4_CANONICAL_EQUIVALENT=YES");
    }

    private static void runTriangles(){
        final int[][] t={
            {4,4,24,7,10,22},{10,22,24,7,4,4},{24,7,4,4,10,22},{24,7,10,22,4,4},{10,22,4,4,24,7},{10,22,24,7,4,4},
            {5,12,16,12,25,12},{12,4,12,16,12,25},{5,5,5,5,23,20},{5,5,23,20,23,20},{12,11,12,11,12,11},
            {10,3,11,27,12,3},{3,14,35,15,3,16},{10,10,11,10,10,11},{10,10,12,10,10,12},
            {3,3,31,8,12,27},{2,2,22,5,7,20},{-2,-1,26,4,8,24},{-12,-7,23,4,6,25},{17,9,51,14,28,42},{-20,-12,61,3,18,49}
        };
        for(int i=0;i<t.length;i++) for(int a=0;a<ALPHA_COLORS.length;a++){
            final int[] q=t[i]; final int argb=ALPHA_COLORS[a]; final int idx=i;
            compare("TRI_"+i+"_A"+a,new Op(){public void run(PlatformGraphics g){
                if(idx==15)g.setClip(9,8,13,11);
                if(idx==16)g.translate(5,4);
                if(idx==17){g.setClip(10,8,14,12);g.translate(5,4);}
                g.fillTriangle(q[0],q[1],q[2],q[3],q[4],q[5],argb);
            }}); triCases++;
        }
    }

    private static void runPolygonFixed(){
        PCase[] c={
            new PCase("CONVEX",a(5,34,26,38,8),a(6,7,18,29,31)),
            new PCase("CONCAVE",a(4,34,20,12,5),a(5,6,18,31,22)),
            new PCase("REVERSED",a(8,38,26,34,5),a(31,29,18,7,6)),
            new PCase("BOW_TIE",a(5,36,7,34),a(5,30,30,5)),
            new PCase("STAR",a(24,29,40,31,34,24,14,17,8,19),a(3,14,14,21,35,27,35,21,14,14)),
            new PCase("DUPLICATE_VERTEX",a(5,34,34,26,8),a(6,7,7,29,31)),
            new PCase("ALL_HORIZONTAL",a(3,12,25,39),a(14,14,14,14)),
            new PCase("ALL_VERTICAL",a(15,15,15,15),a(2,11,24,37)),
            new PCase("ONE_POINT",a(12),a(9)),new PCase("TWO_POINTS",a(5,32),a(6,28)),new PCase("ZERO_POINTS",new int[0],new int[0]),
            new PCase("PARTIAL_NEGATIVE",a(-18,25,40,7),a(5,-12,25,45)),
            new PCase("PARTIAL_RIGHT_BOTTOM",a(20,61,54,35),a(7,12,47,35)),
            new PCase("CLIP",a(2,43,30,8),a(3,8,36,28),true,9,8,22,18,0,0),
            new PCase("TRANSLATE",a(2,26,34,9),a(2,5,25,30),false,0,0,0,0,6,4),
            new PCase("CLIP_TRANSLATE",a(-5,31,40,5),a(-4,2,31,35),true,10,8,20,17,5,4),
            new PCase("DOUBLE_LOOP_EVEN_ODD",a(7,34,34,7,7,34,34,7),a(6,6,30,30,6,6,30,30))
        };
        for(int i=0;i<c.length;i++){checkPoly(c[i],ALPHA_COLORS[i%ALPHA_COLORS.length]);polyFixed++;}
    }

    private static void runPolygonFuzz(){
        Random r=new Random(SEED);
        for(int i=0;i<320;i++){
            int n=r.nextInt(10); int[] x=new int[n],y=new int[n];
            for(int p=0;p<n;p++){x[p]=r.nextInt(81)-16;y[p]=r.nextInt(69)-14;if(p>0&&i%13==0&&p==n-1){x[p]=x[p-1];y[p]=y[p-1];}}
            boolean clip=(i%3)==0; int cx=r.nextInt(17),cy=r.nextInt(13),cw=8+r.nextInt(33),ch=7+r.nextInt(29);
            int tx=(i%4==0)?r.nextInt(13)-6:0,ty=(i%4==0)?r.nextInt(11)-5:0;
            checkPoly(new PCase("FUZZ_"+i,x,y,clip,cx,cy,cw,ch,tx,ty),ALPHA_COLORS[i%ALPHA_COLORS.length]);polyFuzz++;
        }
    }

    private static void runOffsetWindow(){
        final int[] x={999,5,34,26,8,777}; final int[] y={888,6,7,29,31,666};
        compare("OFFSET_WINDOW",new Op(){public void run(PlatformGraphics g){g.fillPolygon(x,1,y,1,4,0x803366CC);}});offsetCases++;
    }

    private static void checkPoly(final PCase c,final int argb){
        compare(c.name,new Op(){public void run(PlatformGraphics g){if(c.clip)g.setClip(c.cx,c.cy,c.cw,c.ch);if(c.tx!=0||c.ty!=0)g.translate(c.tx,c.ty);g.fillPolygon(c.x,0,c.y,0,c.x.length,argb);}});
    }

    private static void compare(String name,Op op){
        Result awt=exec(false,op),raw=exec(true,op);
        boolean state=awt.error==null&&raw.error==null&&awt.color==STATE&&raw.color==STATE;
        boolean match=state&&Arrays.equals(awt.pixels,raw.pixels);
        if(!state)stateFailures++;
        if(!match){failures++;int d=firstDiff(awt.pixels,raw.pixels);System.out.println("P1A_DG_D4_FAIL_CASE="+name+" AWT_ERR="+err(awt.error)+" RAW_ERR="+err(raw.error)+" AWT_COLOR="+hex(awt.color)+" RAW_COLOR="+hex(raw.color)+" FIRST_DIFF="+(d<0?"NONE":((d%W)+","+(d/W)))+" AWT_SUM="+sum(awt.pixels)+" RAW_SUM="+sum(raw.pixels));}
    }

    private static Result exec(boolean raw,Op op){
        try{
            if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");
            PlatformImage im=new PlatformImage(W,H);PlatformGraphics g=im.getGraphics();
            g.setColor(BG);g.fillRect(0,0,W,H);g.setColor(STATE);op.run(g);
            int c=g.getColor();return new Result(pixels(im),null,c);
        }catch(Throwable t){return new Result(null,t,-1);}
    }
    private static int[] pixels(PlatformImage im){int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return p;}
    private static int firstDiff(int[] a,int[] b){if(a==null||b==null)return -1;for(int i=0;i<a.length;i++)if(a[i]!=b[i])return i;return -1;}
    private static int[] a(int...v){return v;}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){if(p==null)return "NONE";long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}return Long.toHexString(h);}
}
