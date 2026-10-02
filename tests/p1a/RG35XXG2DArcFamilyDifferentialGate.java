package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import java.util.Random;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/** Strict AWT-vs-Raw2D differential for MIDP drawArc/fillArc. */
public final class RG35XXG2DArcFamilyDifferentialGate {
    private static final int W=48, H=40, COLOR=0x3366CC;
    private static final int[] EXTENTS = new int[]{0,1,-1,17,-17,45,-45,89,-89,90,-90,120,-120,179,-179,230,-230,359,-359,360,-360,450,-450,720,-720};
    private static final class ArcCase {
        final boolean fill;
        final int x,y,w,h,start,extent;
        int clipX,clipY,clipW,clipH;
        boolean clip;
        int tx,ty;
        boolean dotted;
        ArcCase(boolean f,int ax,int ay,int aw,int ah,int as,int ae){fill=f;x=ax;y=ay;w=aw;h=ah;start=as;extent=ae;}
        ArcCase clip(int a,int b,int c,int d){clip=true;clipX=a;clipY=b;clipW=c;clipH=d;return this;}
        ArcCase trans(int a,int b){tx=a;ty=b;return this;}
        ArcCase dotted(){dotted=true;return this;}
        void run(PlatformGraphics g){
            if(clip) g.setClip(clipX,clipY,clipW,clipH);
            if(tx!=0 || ty!=0) g.translate(tx,ty);
            if(dotted) g.setStrokeStyle(PlatformGraphics.DOTTED);
            if(fill) g.fillArc(x,y,w,h,start,extent); else g.drawArc(x,y,w,h,start,extent);
        }
    }
    private static final class Result { final int[] pixels; final Throwable error; Result(int[] p,Throwable e){pixels=p;error=e;} }
    private static int failures;

    public static void main(String[] args){
        // 19 drawArc signatures from G2D characterization.
        fixed("DRAW_NORMAL_POS", c(false,5,4,23,17,25,230));
        fixed("DRAW_NORMAL_NEG", c(false,5,4,23,17,25,-230));
        fixed("DRAW_FULL_POS", c(false,5,4,23,17,17,360));
        fixed("DRAW_FULL_NEG", c(false,5,4,23,17,17,-360));
        fixed("DRAW_OVER_POS", c(false,5,4,23,17,17,450));
        fixed("DRAW_OVER_NEG", c(false,5,4,23,17,17,-450));
        fixed("DRAW_ZERO_EXTENT", c(false,5,4,23,17,25,0));
        fixed("DRAW_START_450", c(false,5,4,23,17,450,120));
        fixed("DRAW_START_NEG450", c(false,5,4,23,17,-450,120));
        fixed("DRAW_ZERO_WIDTH", c(false,8,5,0,17,25,230));
        fixed("DRAW_ZERO_HEIGHT", c(false,8,5,17,0,25,230));
        fixed("DRAW_NEGATIVE_WIDTH", c(false,8,5,-7,17,25,230));
        fixed("DRAW_NEGATIVE_HEIGHT", c(false,8,5,17,-7,25,230));
        fixed("DRAW_PARTIAL_NEGATIVE", c(false,-8,-5,25,21,20,250));
        fixed("DRAW_PARTIAL_RIGHT_BOTTOM", c(false,34,27,21,18,-40,250));
        fixed("DRAW_CLIP", c(false,3,2,30,24,25,260).clip(10,8,13,11));
        fixed("DRAW_TRANSLATE", c(false,1,1,23,17,25,230).trans(5,4));
        fixed("DRAW_CLIP_TRANSLATE", c(false,-3,-2,31,24,25,260).clip(10,8,15,12).trans(5,4));
        fixed("DRAW_DOTTED_CANONICAL", c(false,5,4,23,17,25,230).dotted());

        // 18 fillArc signatures from G2D characterization.
        fixed("FILL_NORMAL_POS", c(true,5,4,23,17,25,230));
        fixed("FILL_NORMAL_NEG", c(true,5,4,23,17,25,-230));
        fixed("FILL_FULL_POS", c(true,5,4,23,17,17,360));
        fixed("FILL_FULL_NEG", c(true,5,4,23,17,17,-360));
        fixed("FILL_OVER_POS", c(true,5,4,23,17,17,450));
        fixed("FILL_OVER_NEG", c(true,5,4,23,17,17,-450));
        fixed("FILL_ZERO_EXTENT", c(true,5,4,23,17,25,0));
        fixed("FILL_START_450", c(true,5,4,23,17,450,120));
        fixed("FILL_START_NEG450", c(true,5,4,23,17,-450,120));
        fixed("FILL_ZERO_WIDTH", c(true,8,5,0,17,25,230));
        fixed("FILL_ZERO_HEIGHT", c(true,8,5,17,0,25,230));
        fixed("FILL_NEGATIVE_WIDTH", c(true,8,5,-7,17,25,230));
        fixed("FILL_NEGATIVE_HEIGHT", c(true,8,5,17,-7,25,230));
        fixed("FILL_PARTIAL_NEGATIVE", c(true,-8,-5,25,21,20,250));
        fixed("FILL_PARTIAL_RIGHT_BOTTOM", c(true,34,27,21,18,-40,250));
        fixed("FILL_CLIP", c(true,3,2,30,24,25,260).clip(10,8,13,11));
        fixed("FILL_TRANSLATE", c(true,1,1,23,17,25,230).trans(5,4));
        fixed("FILL_CLIP_TRANSLATE", c(true,-3,-2,31,24,25,260).clip(10,8,15,12).trans(5,4));

        int fuzzCases=runFuzz();
        System.out.println("P1A_G2D_FIXED_CASE_COUNT=37");
        System.out.println("P1A_G2D_FUZZ_CASE_COUNT="+fuzzCases);
        System.out.println("P1A_G2D_STRICT_FAILURE_COUNT="+failures);
        if(failures!=0) throw new RuntimeException("P1A_G2D_STRICT_FAIL="+failures);
        System.out.println("P1A_G2D_ARC_FAMILY_DIFFERENTIAL_GATE=PASS");
        System.out.println("P1A_G2D_CANONICAL_EQUIVALENT=YES");
        System.out.println("P1A_G2D_SCOPE=Graphics.drawArc+Graphics.fillArc_ONLY");
    }

    private static ArcCase c(boolean f,int x,int y,int w,int h,int s,int e){return new ArcCase(f,x,y,w,h,s,e);}

    private static int runFuzz(){
        Random r=new Random(0x35AA2D5L);
        int n=320;
        for(int i=0;i<n;i++){
            boolean fill=(i&1)!=0;
            int x=r.nextInt(69)-18;
            int y=r.nextInt(59)-14;
            int w=r.nextInt(39)-4;
            int h=r.nextInt(35)-4;
            int start=r.nextInt(2881)-1440;
            int extent=EXTENTS[r.nextInt(EXTENTS.length)];
            ArcCase ac=c(fill,x,y,w,h,start,extent);
            if((i%3)==0){
                int cx=r.nextInt(42)-5, cy=r.nextInt(34)-4;
                int cw=1+r.nextInt(30), ch=1+r.nextInt(26);
                ac.clip(cx,cy,cw,ch);
            }
            if((i%4)==0) ac.trans(r.nextInt(13)-6,r.nextInt(13)-6);
            if(!fill && (i%11)==0) ac.dotted();
            compare("FUZZ_"+i,ac,false);
        }
        return n;
    }

    private static void fixed(String name,ArcCase ac){compare(name,ac,true);}

    private static void compare(String name,ArcCase ac,boolean logPass){
        Result a=exec(false,ac), raw=exec(true,ac);
        boolean match=a.error==null && raw.error==null && Arrays.equals(a.pixels,raw.pixels);
        if(logPass || !match){
            System.out.println("P1A_G2D_CASE="+name+" MATCH="+match+" AWT="+err(a.error)+" RAW="+err(raw.error)
                    +" AWT_CHECKSUM="+sum(a.pixels)+" RAW_CHECKSUM="+sum(raw.pixels)
                    +" AWT_COUNT="+count(a.pixels)+" RAW_COUNT="+count(raw.pixels));
        }
        if(!match){failures++;firstDiff(name,a.pixels,raw.pixels);}
    }

    private static Result exec(boolean raw,ArcCase ac){
        try{
            if(raw)System.setProperty("rg35xx.raw2d","true");else System.clearProperty("rg35xx.raw2d");
            PlatformImage im=new PlatformImage(W,H); PlatformGraphics g=im.getGraphics(); g.setColor(COLOR); ac.run(g);
            return new Result(pixels(im),null);
        }catch(Throwable t){return new Result(null,t);}
    }
    private static int[] pixels(PlatformImage im){int[] p=new int[W*H];im.getRGB(p,0,W,0,0,W,H);return p;}
    private static int count(int[] p){if(p==null)return -1;int n=0;for(int i=0;i<p.length;i++)if((p[i]&0xFFFFFF)==COLOR)n++;return n;}
    private static void firstDiff(String n,int[] a,int[] b){if(a==null||b==null)return;for(int i=0;i<a.length;i++)if(a[i]!=b[i]){System.out.println("P1A_G2D_FIRST_DIFF="+n+" X="+(i%W)+" Y="+(i/W)+" AWT="+hex(a[i])+" RAW="+hex(b[i]));return;}}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){if(p==null)return "NONE";long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xFFFFFFFFL);h*=1099511628211L;}return Long.toHexString(h);}
}
