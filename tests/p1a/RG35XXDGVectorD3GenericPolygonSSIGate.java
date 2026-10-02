package org.recompile.rg35xx.p1a;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Arrays;
import java.util.Random;

/**
 * D3 diagnostic-only proof that the accepted G2B ShapeSpanIterator raster
 * can be generalized from 3 vertices to N vertices for java.awt.Polygon.
 * No RG35XX runtime classes are exercised or modified here.
 */
public final class RG35XXDGVectorD3GenericPolygonSSIGate {
    private static final int W = 48;
    private static final int H = 40;
    private static final int BG = 0xFFFFFFFF;
    private static final int COLOR = 0xFF3366CC;
    private static final long SEED = 0x35D3001L;
    private static int fixedCount;
    private static int fuzzCount;
    private static int failures;

    private static final class Case {
        final String name;
        final int[] x;
        final int[] y;
        final boolean clip;
        final int cx, cy, cw, ch;
        final int tx, ty;
        Case(String n, int[] xx, int[] yy) {
            this(n, xx, yy, false, 0, 0, 0, 0, 0, 0);
        }
        Case(String n, int[] xx, int[] yy, boolean c, int ax, int ay, int aw, int ah, int dx, int dy) {
            name=n; x=xx; y=yy; clip=c; cx=ax; cy=ay; cw=aw; ch=ah; tx=dx; ty=dy;
        }
    }

    public static void main(String[] args) {
        selfCheck();
        runFixed();
        runFuzz();
        System.out.println("DGVD3_FIXED_COUNT=" + fixedCount);
        System.out.println("DGVD3_FUZZ_COUNT=" + fuzzCount);
        System.out.println("DGVD3_RANDOM_SEED=" + Long.toHexString(SEED));
        System.out.println("DGVD3_STRICT_FAILURE_COUNT=" + failures);
        System.out.println("DGVD3_GENERIC_POLYGON_WINDING=EVEN_ODD");
        System.out.println("DGVD3_OWNER=OPENJDK8_SHAPESPANITERATOR_APPENDPOLY");
        System.out.println("DGVD3_G2B_GENERALIZATION=3_POINTS_TO_N_POINTS");
        System.out.println("DGVD3_RUNTIME_CHANGE=NO");
        if (failures != 0) throw new RuntimeException("DGVD3_FAIL=" + failures);
        System.out.println("DGVD3_GENERIC_POLYGON_SSI_DIFFERENTIAL=PASS");
    }

    private static void selfCheck() {
        // Pixel-center convention from ShapeSpanIterator.c appendSegment.
        if (startY(4.25f) != 4 || startY(4.50f) != 4 || startY(4.75f) != 5)
            throw new RuntimeException("DGVD3_HPC_SELF_CHECK_FAIL");
        if (startX(7.25f) != 7 || startX(7.50f) != 7 || startX(7.75f) != 8)
            throw new RuntimeException("DGVD3_VPC_SELF_CHECK_FAIL");
        System.out.println("DGVD3_PIXEL_CENTER_SELF_CHECK=PASS");
    }

    private static void runFixed() {
        check(new Case("CONVEX", a(5,34,26,38,8), a(6,7,18,29,31)));
        check(new Case("CONCAVE", a(4,34,20,12,5), a(5,6,18,31,22)));
        check(new Case("REVERSED", a(8,38,26,34,5), a(31,29,18,7,6)));
        check(new Case("BOW_TIE", a(5,36,7,34), a(5,30,30,5)));
        check(new Case("STAR", a(24,29,40,31,34,24,14,17,8,19), a(3,14,14,21,35,27,35,21,14,14)));
        check(new Case("DUPLICATE_VERTEX", a(5,34,34,26,8), a(6,7,7,29,31)));
        check(new Case("ALL_HORIZONTAL", a(3,12,25,39), a(14,14,14,14)));
        check(new Case("ALL_VERTICAL", a(15,15,15,15), a(2,11,24,37)));
        check(new Case("ONE_POINT", a(12), a(9)));
        check(new Case("TWO_POINTS", a(5,32), a(6,28)));
        check(new Case("ZERO_POINTS", new int[0], new int[0]));
        check(new Case("PARTIAL_NEGATIVE", a(-18,25,40,7), a(5,-12,25,45)));
        check(new Case("PARTIAL_RIGHT_BOTTOM", a(20,61,54,35), a(7,12,47,35)));
        check(new Case("CLIP", a(2,43,30,8), a(3,8,36,28), true, 9,8,22,18,0,0));
        check(new Case("TRANSLATE", a(2,26,34,9), a(2,5,25,30), false,0,0,0,0,6,4));
        check(new Case("CLIP_TRANSLATE", a(-5,31,40,5), a(-4,2,31,35), true, 10,8,20,17,5,4));
        // Same loop traversed twice: even-odd must cancel its interior.
        check(new Case("DOUBLE_LOOP_EVEN_ODD", a(7,34,34,7,7,34,34,7), a(6,6,30,30,6,6,30,30)));
    }

    private static void runFuzz() {
        Random r = new Random(SEED);
        for (int i=0; i<320; i++) {
            int n = r.nextInt(10); // includes 0/1/2-point degenerates
            int[] x = new int[n];
            int[] y = new int[n];
            for (int p=0; p<n; p++) {
                x[p] = r.nextInt(81) - 16;
                y[p] = r.nextInt(69) - 14;
                if (p > 0 && i % 13 == 0 && p == n-1) {
                    x[p] = x[p-1]; y[p] = y[p-1];
                }
            }
            boolean clip = (i % 3) == 0;
            int cx = r.nextInt(17);
            int cy = r.nextInt(13);
            int cw = 8 + r.nextInt(33);
            int ch = 7 + r.nextInt(29);
            int tx = (i % 4 == 0) ? r.nextInt(13)-6 : 0;
            int ty = (i % 4 == 0) ? r.nextInt(11)-5 : 0;
            checkFuzz(new Case("FUZZ_"+i,x,y,clip,cx,cy,cw,ch,tx,ty));
        }
    }

    private static void check(Case c) { fixedCount++; compare(c); }
    private static void checkFuzz(Case c) { fuzzCount++; compare(c); }

    private static void compare(Case c) {
        int[] awt = awt(c);
        int[] sim = sim(c);
        boolean match = Arrays.equals(awt, sim);
        if (!match) {
            failures++;
            int d = firstDiff(awt,sim);
            System.out.println("DGVD3_FAIL_CASE="+c.name+" N="+c.x.length+" X="+(d%W)+" Y="+(d/W)
                    +" AWT="+hex(awt[d])+" SIM="+hex(sim[d])
                    +" AWT_SUM="+sum(awt)+" SIM_SUM="+sum(sim));
        }
    }

    private static int[] awt(Case c) {
        BufferedImage im = new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
        int[] p = new int[W*H]; Arrays.fill(p,BG); im.setRGB(0,0,W,H,p,0,W);
        Graphics2D g = im.createGraphics();
        g.setColor(new Color(COLOR,true));
        if (c.clip) g.setClip(c.cx,c.cy,c.cw,c.ch);
        if (c.tx != 0 || c.ty != 0) g.translate(c.tx,c.ty);
        g.fillPolygon(c.x,c.y,c.x.length);
        g.dispose();
        return im.getRGB(0,0,W,H,null,0,W);
    }

    private static int[] sim(Case c) {
        int[] dst = new int[W*H]; Arrays.fill(dst,BG);
        int lox=0, loy=0, hix=W, hiy=H;
        if (c.clip) {
            lox=Math.max(lox,c.cx); loy=Math.max(loy,c.cy);
            hix=Math.min(hix,c.cx+c.cw); hiy=Math.min(hiy,c.cy+c.ch);
        }
        if (hix<=lox || hiy<=loy || c.x.length==0) return dst;

        int npts=c.x.length;
        float xoff=(float)c.tx+0.25f, yoff=(float)c.ty+0.25f;
        int[] curX=new int[npts]; int[] curY=new int[npts]; int[] lastY=new int[npts];
        int[] err=new int[npts]; int[] bumpX=new int[npts]; int[] bumpErr=new int[npts];
        int count=0;
        float movx=c.x[0]+xoff, movy=c.y[0]+yoff, x0=movx, y0=movy;
        int out0=outcode(x0,y0,lox,loy,hix,hiy);
        for (int i=1;i<npts;i++) {
            float x1=c.x[i]+xoff, y1=c.y[i]+yoff;
            if (y1==y0) {
                if (x1!=x0) { out0=outcode(x1,y1,lox,loy,hix,hiy); x0=x1; }
                continue;
            }
            int out1=outcode(x1,y1,lox,loy,hix,hiy);
            int common=out0 & out1;
            if (common==0) count=append(x0,y0,x1,y1,lox,loy,hix,hiy,curX,curY,lastY,err,bumpX,bumpErr,count);
            else if (common==1) count=append((float)lox,y0,(float)lox,y1,lox,loy,hix,hiy,curX,curY,lastY,err,bumpX,bumpErr,count);
            out0=out1; x0=x1; y0=y1;
        }
        if (x0!=movx || y0!=movy) count=appendClosing(x0,y0,movx,movy,lox,loy,hix,hiy,curX,curY,lastY,err,bumpX,bumpErr,count);
        if (count==0) return dst;

        int[] xs=new int[count];
        for (int yy=loy;yy<hiy;yy++) {
            int nx=0;
            for (int e=0;e<count;e++) {
                if (curY[e]>yy || lastY[e]<=yy) continue;
                int rows=yy-curY[e];
                int xx=curX[e]+rows*bumpX[e];
                if (rows!=0) {
                    long se=((long)err[e])+((long)rows*(long)bumpErr[e]);
                    xx+=(int)(se>>31);
                }
                xs[nx++]=xx;
            }
            if (nx==0) continue;
            for (int i=1;i<nx;i++) {
                int v=xs[i], k=i-1;
                while (k>=0 && xs[k]>v) { xs[k+1]=xs[k]; k--; }
                xs[k+1]=v;
            }
            for (int i=0;i<nx;i+=2) {
                int sx0=xs[i]; int sx1=(i+1<nx)?xs[i+1]:hix;
                if (sx0<lox) sx0=lox; if (sx1>hix) sx1=hix;
                if (sx1<=sx0) continue;
                Arrays.fill(dst,yy*W+sx0,yy*W+sx1,COLOR);
            }
        }
        return dst;
    }

    private static int appendClosing(float x0,float y0,float x1,float y1,int lox,int loy,int hix,int hiy,
            int[] cx,int[] cy,int[] ly,int[] er,int[] bx,int[] be,int count) {
        float miny=Math.min(y0,y1), maxy=Math.max(y0,y1), minx=Math.min(x0,x1), maxx=Math.max(x0,x1);
        if (maxy<=loy || miny>=hiy || minx>=hix) return count;
        if (maxx<=lox) return append(maxx,y0,maxx,y1,lox,loy,hix,hiy,cx,cy,ly,er,bx,be,count);
        return append(x0,y0,x1,y1,lox,loy,hix,hiy,cx,cy,ly,er,bx,be,count);
    }

    private static int append(float x0,float y0,float x1,float y1,int lox,int loy,int hix,int hiy,
            int[] cx,int[] cy,int[] ly,int[] er,int[] bx,int[] be,int count) {
        if (y0>y1) { float t=x0;x0=x1;x1=t; t=y0;y0=y1;y1=t; }
        int sy=startY(y0), ey=startY(y1);
        if (sy>=ey || sy>=hiy || ey<=loy) return count;
        float dx=x1-x0, dy=y1-y0, slope=dx/dy;
        float yb=sy+0.5f-y0; x0+=yb*dx/dy;
        int sx=startX(x0);
        float sf=(float)Math.floor(slope);
        cx[count]=sx; cy[count]=sy; ly[count]=ey;
        bx[count]=(int)sf;
        be[count]=(int)((slope-sf)*(double)0x7fffffff);
        er[count]=(int)((x0-(sx-0.5f))*(double)0x7fffffff);
        return count+1;
    }

    private static int outcode(float x,float y,int lox,int loy,int hix,int hiy) {
        int o; if (y<=loy)o=4; else if(y>=hiy)o=8; else o=0;
        if(x<=lox)o|=1; else if(x>=hix)o|=2; return o;
    }
    private static int startY(float y) { return (int)Math.ceil(y-0.5f); }
    private static int startX(float x) { return (int)Math.ceil(x-0.5f); }
    private static int[] a(int... v) { return v; }
    private static int firstDiff(int[] a,int[] b) { for(int i=0;i<a.length;i++)if(a[i]!=b[i])return i; return -1; }
    private static String hex(int v){String s=Integer.toHexString(v);while(s.length()<8)s="0"+s;return s;}
    private static String sum(int[] p){long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=(p[i]&0xffffffffL);h*=1099511628211L;}return Long.toHexString(h);}
}
