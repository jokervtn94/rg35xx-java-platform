package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import java.util.Random;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Runtime differential for Nokia DirectGraphics drawPolygon/drawTriangle raw backing. */
public final class RG35XXDGDrawVectorD6DifferentialGate {
    private static final int W=64,H=48,BG=0x102030,STATE=0x884422;
    private static final long SEED=0x35D6001L;
    private static final int[] COLORS={0x003366CC,0x403366CC,0x803366CC,0xCC3366CC,0xFF3366CC};
    private static int failures,stateFailures,triangleCases,polygonFixed,polygonFuzz,offsetCases;

    private interface Op { void run(PlatformGraphics g); }
    private static final class Result {
        final int[] pixels; final Throwable error; final int color;
        Result(int[] p,Throwable e,int c){pixels=p;error=e;color=c;}
    }
    private static final class C {
        final String name; final int[] x,y; final boolean clip; final int cx,cy,cw,ch,tx,ty;
        C(String n,int[] xx,int[] yy){this(n,xx,yy,false,0,0,0,0,0,0);}
        C(String n,int[] xx,int[] yy,boolean c,int ax,int ay,int aw,int ah,int dx,int dy){name=n;x=xx;y=yy;clip=c;cx=ax;cy=ay;cw=aw;ch=ah;tx=dx;ty=dy;}
    }

    private static final C[] FIXED={
        new C("TRIANGLE_STANDARD",a(7,33,18),a(6,8,27)),
        new C("TRIANGLE_REVERSED",a(18,33,7),a(27,8,6)),
        new C("TRIANGLE_FLAT",a(6,22,38),a(15,15,15)),
        new C("TRIANGLE_DUPLICATE",a(10,10,31),a(9,9,28)),
        new C("TRIANGLE_CLIP",a(-5,38,17),a(2,8,39),true,4,5,31,26,0,0),
        new C("TRIANGLE_TRANSLATE",a(7,33,18),a(6,8,27),false,0,0,0,0,5,3),
        new C("POLYGON_SQUARE",a(6,34,34,6),a(6,6,30,30)),
        new C("POLYGON_CONCAVE",a(5,36,20,38,7),a(5,8,18,31,34)),
        new C("POLYGON_STAR",a(24,29,40,31,34,24,14,17,8,19),a(3,14,14,21,35,27,35,21,14,14)),
        new C("POLYGON_SELF_CROSS",a(7,39,8,38),a(6,32,31,7)),
        new C("POLYGON_DUPLICATE",a(5,33,33,20,7),a(7,7,7,29,30)),
        new C("POLYGON_ALREADY_CLOSED",a(7,36,29,9,7),a(6,8,31,28,6)),
        new C("POLYGON_ONE_POINT",a(17),a(13)),
        new C("POLYGON_TWO_POINTS",a(8,37),a(7,29)),
        new C("POLYGON_CLIP",a(-9,46,39,8),a(4,3,37,42),true,3,6,35,27,0,0),
        new C("POLYGON_TRANSLATE",a(5,34,26,38,8),a(6,7,18,29,31),false,0,0,0,0,4,-2),
        new C("POLYGON_CLIP_TRANSLATE",a(2,36,31,5),a(3,7,35,31),true,4,5,34,27,6,4),
        new C("POLYGON_PARTIAL_NEGATIVE",a(-18,22,47,5),a(-9,4,33,43)),
        new C("POLYGON_RIGHT_BOTTOM",a(42,75,70,48),a(30,27,61,55)),
        new C("POLYGON_OFFSCREEN",a(80,96,91,78),a(60,62,79,76))
    };

    public static void main(String[] args){
        runTriangles();runFixed();runFuzz();runOffset();
        System.out.println("P1A_DG_D6_TRIANGLE_CASE_COUNT="+triangleCases);
        System.out.println("P1A_DG_D6_POLYGON_FIXED_COUNT="+polygonFixed);
        System.out.println("P1A_DG_D6_POLYGON_FUZZ_COUNT="+polygonFuzz);
        System.out.println("P1A_DG_D6_OFFSET_CASE_COUNT="+offsetCases);
        System.out.println("P1A_DG_D6_STATE_FAILURE_COUNT="+stateFailures);
        System.out.println("P1A_DG_D6_RANDOM_SEED="+Long.toHexString(SEED));
        System.out.println("P1A_DG_D6_STRICT_FAILURE_COUNT="+failures);
        System.out.println("P1A_DG_D6_OPAQUE_BACKEND=OPENJDK8_GENERALRENDERER_DODRAWPOLY_DODRAWLINE_ADJUSTLINE");
        System.out.println("P1A_DG_D6_ALPHA_BACKEND=D53B_LINE_ONLY_CLOSED_MITER_W1_QUARTER_NORMALIZED_SOFTWARE_SSI");
        System.out.println("P1A_DG_D6_ALPHA_MODEL=G1_EXACT_8BIT_SRCOVER");
        if(failures!=0)throw new RuntimeException("P1A_DG_D6_FAIL="+failures);
        System.out.println("P1A_DG_D6_DRAW_VECTOR_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_DG_D6_CANONICAL_EQUIVALENT=YES");
    }

    private static void runTriangles(){
        for(int i=0;i<6;i++)for(int a=0;a<COLORS.length;a++){
            final C c=FIXED[i];final int col=COLORS[a];
            compare("TRI_"+c.name+"_A"+a,new Op(){public void run(PlatformGraphics g){applyState(g,c);g.drawTriangle(c.x[0],c.y[0],c.x[1],c.y[1],c.x[2],c.y[2],col);}});
            triangleCases++;
        }
    }

    private static void runFixed(){
        for(int i=0;i<FIXED.length;i++)for(int a=0;a<COLORS.length;a++){
            final C c=FIXED[i];final int col=COLORS[a];
            compare("POLY_"+c.name+"_A"+a,new Op(){public void run(PlatformGraphics g){applyState(g,c);g.drawPolygon(c.x,0,c.y,0,c.x.length,col);}});
            polygonFixed++;
        }
    }

    private static void runFuzz(){
        Random r=new Random(SEED);
        for(int i=0;i<320;i++){
            int n=r.nextInt(10);int[] x=new int[n],y=new int[n];
            for(int p=0;p<n;p++){x[p]=r.nextInt(90)-13;y[p]=r.nextInt(72)-11;if(p>0&&i%17==0&&p==n-1){x[p]=x[p-1];y[p]=y[p-1];}}
            boolean clip=(i%3)==0;int cx=r.nextInt(10),cy=r.nextInt(8),cw=20+r.nextInt(45),ch=16+r.nextInt(37);
            int tx=(i%4==0)?r.nextInt(11)-5:0,ty=(i%4==0)?r.nextInt(9)-4:0;
            final C c=new C("FUZZ_"+i,x,y,clip,cx,cy,cw,ch,tx,ty);final int col=COLORS[i%COLORS.length];
            compare(c.name,new Op(){public void run(PlatformGraphics g){applyState(g,c);g.drawPolygon(c.x,0,c.y,0,c.x.length,col);}});
            polygonFuzz++;
        }
    }

    private static void runOffset(){
        final int[] x={999,5,34,26,8,777};final int[] y={888,6,7,29,31,666};
        for(int a=0;a<COLORS.length;a++){
            final int col=COLORS[a];
            compare("OFFSET_A"+a,new Op(){public void run(PlatformGraphics g){g.drawPolygon(x,1,y,1,4,col);}});offsetCases++;
        }
    }

    private static void applyState(PlatformGraphics g,C c){if(c.clip)g.setClip(c.cx,c.cy,c.cw,c.ch);if(c.tx!=0||c.ty!=0)g.translate(c.tx,c.ty);}

    private static void compare(String name,Op op){
        Result awt=exec(false,op),raw=exec(true,op);
        boolean state=awt.error==null&&raw.error==null&&awt.color==STATE&&raw.color==STATE;
        boolean match=state&&Arrays.equals(awt.pixels,raw.pixels);
        if(!state)stateFailures++;
        if(!match){failures++;int d=firstDiff(awt.pixels,raw.pixels);System.out.println("P1A_DG_D6_FAIL_CASE="+name+" AWT_ERR="+err(awt.error)+" RAW_ERR="+err(raw.error)+" AWT_COLOR="+hex(awt.color)+" RAW_COLOR="+hex(raw.color)+" FIRST_DIFF="+(d<0?"NONE":((d%W)+","+(d/W)))+" AWT_SUM="+sum(awt.pixels)+" RAW_SUM="+sum(raw.pixels));}
    }

    private static Result exec(boolean raw,Op op){
        try{
            if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");
            PlatformImage im=new PlatformImage(W,H);PlatformGraphics g=im.getGraphics();
            g.setColor(BG);g.fillRect(0,0,W,H);g.setColor(STATE);op.run(g);
            return new Result(pixels(im),null,g.getColor());
        }catch(Throwable t){return new Result(null,t,-1);}
    }
    private static int[] pixels(PlatformImage im){int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return p;}
    private static int firstDiff(int[] a,int[] b){if(a==null||b==null)return -1;for(int i=0;i<a.length;i++)if(a[i]!=b[i])return i;return -1;}
    private static int[] a(int...v){return v;}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName()+":"+String.valueOf(t.getMessage());}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){if(p==null)return "NONE";long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}return Long.toHexString(h);}
}
