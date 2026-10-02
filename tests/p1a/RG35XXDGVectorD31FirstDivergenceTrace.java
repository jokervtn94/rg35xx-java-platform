package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

/**
 * D3.1 diagnostic-only trace for the two D3 generic polygon failures.
 * It compares the existing G2B-style Java float subtraction used to derive
 * bumperr with the exact OpenJDK8 C expression slope - floor(slope), where
 * floor() returns double and therefore forces the subtraction to double.
 * No RG35XX runtime class is exercised or modified.
 */
public final class RG35XXDGVectorD31FirstDivergenceTrace {
    private static final int W = 48;
    private static final int H = 40;
    private static final int BG = 0xFFFFFFFF;
    private static final int COLOR = 0xFF3366CC;
    private static final int ERRSTEP_MAX = 0x7fffffff;
    private static final long SEED = 0x35D3001L;

    private static final class Case {
        final String name;
        final int[] x, y;
        final boolean clip;
        final int cx, cy, cw, ch, tx, ty;
        Case(String n, int[] xx, int[] yy, boolean c,
             int ax, int ay, int aw, int ah, int dx, int dy) {
            name=n; x=xx; y=yy; clip=c;
            cx=ax; cy=ay; cw=aw; ch=ah; tx=dx; ty=dy;
        }
    }

    private static final class Edges {
        int count;
        int[] curX, curY, lastY, error, bumpX, bumpErr;
        float[] slope;
        Edges(int n) {
            curX=new int[n]; curY=new int[n]; lastY=new int[n];
            error=new int[n]; bumpX=new int[n]; bumpErr=new int[n];
            slope=new float[n];
        }
    }

    public static void main(String[] args) {
        Case star = new Case("STAR",
            a(24,29,40,31,34,24,14,17,8,19),
            a(3,14,14,21,35,27,35,21,14,14),
            false,0,0,0,0,0,0);
        Case fuzz253 = regenerateFuzz253();

        trace(star, 20, 11, 7);
        trace(fuzz253, 17, 3, 1);

        System.out.println("DGVD31_OWNER=OPENJDK8_SHAPESPANITERATOR_APPENDSEGMENT_FRACTTOJINT");
        System.out.println("DGVD31_ROOT_CAUSE=SLOPE_FLOOR_SUBTRACTION_PRECISION");
        System.out.println("DGVD31_OPENJDK_C_SUBTRACTION=DOUBLE");
        System.out.println("DGVD31_G2B_JAVA_SUBTRACTION=FLOAT");
        System.out.println("DGVD31_RUNTIME_CHANGE=NO");
        System.out.println("DGVD31_FIRST_DIVERGENCE_TRACE=PASS");
    }

    private static void trace(Case c, int diffX, int diffY, int edgeIndex) {
        int[] awt = awt(c);
        Edges oldEdges = buildEdges(c, false);
        Edges nativeEdges = buildEdges(c, true);
        int[] oldSim = render(c, oldEdges);
        int[] nativeSim = render(c, nativeEdges);

        int firstOld = firstDiff(awt, oldSim);
        if (firstOld < 0 || firstOld % W != diffX || firstOld / W != diffY)
            throw new RuntimeException("DGVD31_"+c.name+"_FIRST_DIFF_UNEXPECTED="+firstOld);
        if (!Arrays.equals(awt, nativeSim))
            throw new RuntimeException("DGVD31_"+c.name+"_NATIVE_PRECISION_NOT_FULLFRAME_EQUAL");
        if (edgeIndex >= oldEdges.count || edgeIndex >= nativeEdges.count)
            throw new RuntimeException("DGVD31_"+c.name+"_EDGE_INDEX_OOB");

        int rows = diffY - oldEdges.curY[edgeIndex];
        int oldX = edgeXAt(oldEdges, edgeIndex, diffY);
        int nativeX = edgeXAt(nativeEdges, edgeIndex, diffY);
        int oldBE = oldEdges.bumpErr[edgeIndex];
        int nativeBE = nativeEdges.bumpErr[edgeIndex];

        if (rows != 8 || nativeBE - oldBE != 64 || nativeX - oldX != 1)
            throw new RuntimeException("DGVD31_"+c.name+"_TRACE_INVARIANT_FAIL rows="+rows+
                " deltaBE="+(nativeBE-oldBE)+" deltaX="+(nativeX-oldX));

        int p = diffY*W + diffX;
        if (awt[p] != BG || oldSim[p] != COLOR || nativeSim[p] != BG)
            throw new RuntimeException("DGVD31_"+c.name+"_PIXEL_OWNER_FAIL");

        System.out.println("DGVD31_CASE="+c.name);
        System.out.println("DGVD31_"+c.name+"_VERTICES_X="+join(c.x));
        System.out.println("DGVD31_"+c.name+"_VERTICES_Y="+join(c.y));
        System.out.println("DGVD31_"+c.name+"_CLIP="+(c.clip ? (c.cx+","+c.cy+","+c.cw+","+c.ch) : "NONE"));
        System.out.println("DGVD31_"+c.name+"_TRANSLATE="+c.tx+","+c.ty);
        System.out.println("DGVD31_"+c.name+"_FIRST_DIFF="+diffX+","+diffY);
        System.out.println("DGVD31_"+c.name+"_EDGE_INDEX="+edgeIndex);
        System.out.println("DGVD31_"+c.name+"_EDGE_START_Y="+oldEdges.curY[edgeIndex]);
        System.out.println("DGVD31_"+c.name+"_EDGE_LAST_Y="+oldEdges.lastY[edgeIndex]);
        System.out.println("DGVD31_"+c.name+"_ROWS_TO_DIFF="+rows);
        System.out.println("DGVD31_"+c.name+"_SLOPE_BITS="+Integer.toHexString(Float.floatToIntBits(oldEdges.slope[edgeIndex])));
        System.out.println("DGVD31_"+c.name+"_BUMPERR_FLOAT_SUB="+oldBE);
        System.out.println("DGVD31_"+c.name+"_BUMPERR_NATIVE_DOUBLE_SUB="+nativeBE);
        System.out.println("DGVD31_"+c.name+"_BUMPERR_DELTA="+(nativeBE-oldBE));
        System.out.println("DGVD31_"+c.name+"_X_FLOAT_AT_DIFF="+oldX);
        System.out.println("DGVD31_"+c.name+"_X_NATIVE_AT_DIFF="+nativeX);
        System.out.println("DGVD31_"+c.name+"_AWT_PIXEL="+hex(awt[p]));
        System.out.println("DGVD31_"+c.name+"_FLOAT_PIXEL="+hex(oldSim[p]));
        System.out.println("DGVD31_"+c.name+"_NATIVE_PIXEL="+hex(nativeSim[p]));
        System.out.println("DGVD31_"+c.name+"_NATIVE_FULLFRAME_MATCH=YES");
    }

    private static Case regenerateFuzz253() {
        Random r = new Random(SEED);
        Case result = null;
        for (int i=0; i<=253; i++) {
            int n = r.nextInt(10);
            int[] x = new int[n];
            int[] y = new int[n];
            for (int p=0; p<n; p++) {
                x[p]=r.nextInt(81)-16;
                y[p]=r.nextInt(69)-14;
                if (p>0 && i%13==0 && p==n-1) { x[p]=x[p-1]; y[p]=y[p-1]; }
            }
            boolean clip=(i%3)==0;
            int cx=r.nextInt(17), cy=r.nextInt(13), cw=8+r.nextInt(33), ch=7+r.nextInt(29);
            int tx=(i%4==0)?r.nextInt(13)-6:0;
            int ty=(i%4==0)?r.nextInt(11)-5:0;
            if (i==253) result=new Case("FUZZ_253",x,y,clip,cx,cy,cw,ch,tx,ty);
        }
        if (result==null) throw new RuntimeException("DGVD31_FUZZ253_REGEN_FAIL");
        if (!Arrays.equals(result.x,a(31,12,19,55)) || !Arrays.equals(result.y,a(34,28,-5,5)) ||
            result.clip || result.tx!=0 || result.ty!=0)
            throw new RuntimeException("DGVD31_FUZZ253_IDENTITY_FAIL");
        System.out.println("DGVD31_FUZZ253_SEED="+Long.toHexString(SEED));
        System.out.println("DGVD31_FUZZ253_IDENTITY=PASS");
        return result;
    }

    private static int[] awt(Case c) {
        BufferedImage im=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
        int[] p=new int[W*H]; Arrays.fill(p,BG); im.setRGB(0,0,W,H,p,0,W);
        Graphics2D g=im.createGraphics(); g.setColor(new Color(COLOR,true));
        if(c.clip) g.setClip(c.cx,c.cy,c.cw,c.ch);
        if(c.tx!=0 || c.ty!=0) g.translate(c.tx,c.ty);
        g.fillPolygon(c.x,c.y,c.x.length); g.dispose();
        return im.getRGB(0,0,W,H,null,0,W);
    }

    private static Edges buildEdges(Case c, boolean nativeDoubleSub) {
        int lox=0,loy=0,hix=W,hiy=H;
        if(c.clip){lox=Math.max(lox,c.cx);loy=Math.max(loy,c.cy);hix=Math.min(hix,c.cx+c.cw);hiy=Math.min(hiy,c.cy+c.ch);}
        Edges e=new Edges(c.x.length);
        if(hix<=lox || hiy<=loy || c.x.length==0) return e;
        float xoff=(float)c.tx+0.25f, yoff=(float)c.ty+0.25f;
        float movx=c.x[0]+xoff,movy=c.y[0]+yoff,x0=movx,y0=movy;
        int out0=outcode(x0,y0,lox,loy,hix,hiy);
        for(int i=1;i<c.x.length;i++){
            float x1=c.x[i]+xoff,y1=c.y[i]+yoff;
            if(y1==y0){if(x1!=x0){out0=outcode(x1,y1,lox,loy,hix,hiy);x0=x1;}continue;}
            int out1=outcode(x1,y1,lox,loy,hix,hiy),common=out0&out1;
            if(common==0) append(e,x0,y0,x1,y1,lox,loy,hix,hiy,nativeDoubleSub);
            else if(common==1) append(e,(float)lox,y0,(float)lox,y1,lox,loy,hix,hiy,nativeDoubleSub);
            out0=out1;x0=x1;y0=y1;
        }
        if(x0!=movx || y0!=movy) appendClosing(e,x0,y0,movx,movy,lox,loy,hix,hiy,nativeDoubleSub);
        return e;
    }

    private static void appendClosing(Edges e,float x0,float y0,float x1,float y1,
            int lox,int loy,int hix,int hiy,boolean nativeDoubleSub){
        float miny=Math.min(y0,y1),maxy=Math.max(y0,y1),minx=Math.min(x0,x1),maxx=Math.max(x0,x1);
        if(maxy<=loy || miny>=hiy || minx>=hix)return;
        if(maxx<=lox)append(e,maxx,y0,maxx,y1,lox,loy,hix,hiy,nativeDoubleSub);
        else append(e,x0,y0,x1,y1,lox,loy,hix,hiy,nativeDoubleSub);
    }

    private static void append(Edges e,float x0,float y0,float x1,float y1,
            int lox,int loy,int hix,int hiy,boolean nativeDoubleSub){
        if(y0>y1){float t=x0;x0=x1;x1=t;t=y0;y0=y1;y1=t;}
        int sy=(int)Math.ceil(y0-0.5f),ey=(int)Math.ceil(y1-0.5f);
        if(sy>=ey || sy>=hiy || ey<=loy)return;
        float dx=x1-x0,dy=y1-y0,slope=dx/dy;
        float yb=sy+0.5f-y0; x0+=yb*dx/dy;
        int sx=(int)Math.ceil(x0-0.5f);
        float slopeFloor=(float)Math.floor(slope);
        double fraction=nativeDoubleSub ? ((double)slope-Math.floor((double)slope)) : (double)(slope-slopeFloor);
        int i=e.count++;
        e.curX[i]=sx;e.curY[i]=sy;e.lastY[i]=ey;e.slope[i]=slope;
        e.bumpX[i]=(int)slopeFloor;
        e.bumpErr[i]=(int)(fraction*(double)ERRSTEP_MAX);
        e.error[i]=(int)((x0-(sx-0.5f))*(double)ERRSTEP_MAX);
    }

    private static int[] render(Case c,Edges e){
        int[] dst=new int[W*H];Arrays.fill(dst,BG);
        int lox=0,loy=0,hix=W,hiy=H;
        if(c.clip){lox=Math.max(lox,c.cx);loy=Math.max(loy,c.cy);hix=Math.min(hix,c.cx+c.cw);hiy=Math.min(hiy,c.cy+c.ch);}
        int[] xs=new int[e.count];
        for(int y=loy;y<hiy;y++){
            int n=0;
            for(int i=0;i<e.count;i++){
                if(e.curY[i]>y || e.lastY[i]<=y)continue;
                xs[n++]=edgeXAt(e,i,y);
            }
            for(int i=1;i<n;i++){int v=xs[i],k=i-1;while(k>=0&&xs[k]>v){xs[k+1]=xs[k];k--;}xs[k+1]=v;}
            for(int i=0;i<n;i+=2){int x0=xs[i],x1=(i+1<n)?xs[i+1]:hix;if(x0<lox)x0=lox;if(x1>hix)x1=hix;if(x1>x0)Arrays.fill(dst,y*W+x0,y*W+x1,COLOR);}
        }
        return dst;
    }

    private static int edgeXAt(Edges e,int i,int y){
        int rows=y-e.curY[i];int x=e.curX[i]+rows*e.bumpX[i];
        if(rows!=0){long step=(long)e.error[i]+(long)rows*(long)e.bumpErr[i];x+=(int)(step>>31);}return x;
    }

    private static int outcode(float x,float y,int lox,int loy,int hix,int hiy){int o;if(y<=loy)o=4;else if(y>=hiy)o=8;else o=0;if(x<=lox)o|=1;else if(x>=hix)o|=2;return o;}
    private static int firstDiff(int[] a,int[] b){for(int i=0;i<a.length;i++)if(a[i]!=b[i])return i;return -1;}
    private static int[] a(int...v){return v;}
    private static String join(int[] v){StringBuilder s=new StringBuilder();for(int i=0;i<v.length;i++){if(i!=0)s.append(',');s.append(v[i]);}return s.toString();}
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
}
