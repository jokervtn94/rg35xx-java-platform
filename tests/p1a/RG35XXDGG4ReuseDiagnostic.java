package org.recompile.rg35xx.p1a;

import java.util.Arrays;
import java.util.Random;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.game.Sprite;
import com.nokia.mid.ui.DirectGraphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;

/**
 * G4 diagnostic only. No runtime modification.
 *
 * AWT side calls the pinned Miyoo DirectGraphics implementation.
 * Raw side models the smallest RG35XX delta: keep Miyoo argument/conversion
 * semantics and route the resulting image through the already-protected A5
 * drawRegion/transform/blit backing.
 */
public final class RG35XXDGG4ReuseDiagnostic {
    private static final int W=67,H=53;
    private static final long SEED=0x35A4001L;
    private static int cases, failures, drawImageCases, intCases, shortCases, byteCases;

    private static final int[] MANIPS={
        0,
        DirectGraphics.FLIP_HORIZONTAL,
        DirectGraphics.FLIP_VERTICAL,
        DirectGraphics.ROTATE_90,
        DirectGraphics.ROTATE_180,
        DirectGraphics.ROTATE_270,
        DirectGraphics.FLIP_HORIZONTAL|DirectGraphics.FLIP_VERTICAL,
        DirectGraphics.FLIP_HORIZONTAL|DirectGraphics.ROTATE_90
    };

    private static final class State {
        final int tx,ty,cx,cy,cw,ch;
        State(int tx,int ty,int cx,int cy,int cw,int ch){this.tx=tx;this.ty=ty;this.cx=cx;this.cy=cy;this.cw=cw;this.ch=ch;}
    }

    public static void main(String[] args) {
        Random r=new Random(SEED);
        State[] states={
            new State(0,0,0,0,W,H),
            new State(4,-3,0,0,W,H),
            new State(0,0,5,4,43,34),
            new State(6,5,7,6,39,31)
        };

        int[] srcPattern=pattern(9,7,0x1234);
        for(int m=0;m<MANIPS.length;m++) for(int s=0;s<states.length;s++) {
            final int manip=MANIPS[m]; final State st=states[s];
            final int anchor=(m%3==0)?(Graphics.HCENTER|Graphics.VCENTER):((m%3==1)?(Graphics.RIGHT|Graphics.BOTTOM):0);
            compare("DRAW_IMAGE_M"+manip+"_S"+s,
                new CanonicalOp(){ public void run(PlatformGraphics g){ PlatformImage src=makeImage(false,srcPattern,9,7); g.drawImage(src,28,24,anchor,manip); }},
                new RawModelOp(){ public void run(PlatformGraphics g){ PlatformImage src=makeImage(true,srcPattern,9,7); int t=mapManip(manip); int ow=swaps(t)?7:9, oh=swaps(t)?9:7; int dx=anchorX(28,ow,anchor), dy=anchorY(24,oh,anchor); g.drawRegion(src,0,0,9,7,t,dx,dy,0); }}, st);
            drawImageCases++;
        }

        for(int i=0;i<96;i++) {
            final int width=2+r.nextInt(9), height=2+r.nextInt(7), scan=width+2, off=1;
            final int[] src=new int[off+scan*height+3];
            for(int p=0;p<src.length;p++) src[p]=r.nextInt();
            final int manip=MANIPS[i%MANIPS.length]; final State st=states[i%states.length];
            final int x=6+r.nextInt(38), y=5+r.nextInt(31);
            compare("INT_"+i,
                new CanonicalOp(){ public void run(PlatformGraphics g){ g.drawPixels(src,true,off,scan,x,y,width,height,manip,DirectGraphics.TYPE_INT_8888_ARGB); }},
                new RawModelOp(){ public void run(PlatformGraphics g){ int[] data=extractInt(src,off,scan,width,height); rawDrawPixels(g,data,width,height,x,y,manip); }}, st);
            intCases++;
        }

        final int[] shortFormats={
            DirectGraphics.TYPE_USHORT_1555_ARGB,
            DirectGraphics.TYPE_USHORT_444_RGB,
            DirectGraphics.TYPE_USHORT_4444_ARGB,
            DirectGraphics.TYPE_USHORT_555_RGB,
            DirectGraphics.TYPE_USHORT_565_RGB
        };
        for(int i=0;i<120;i++) {
            final int width=2+r.nextInt(8), height=2+r.nextInt(6), scan=width+1, off=1;
            final short[] src=new short[off+scan*height+2];
            for(int p=0;p<src.length;p++) src[p]=(short)r.nextInt();
            final int format=shortFormats[i%shortFormats.length]; final boolean transparency=(i&1)==0;
            final int manip=MANIPS[i%MANIPS.length]; final State st=states[i%states.length];
            final int x=4+r.nextInt(41), y=3+r.nextInt(34);
            compare("SHORT_"+i,
                new CanonicalOp(){ public void run(PlatformGraphics g){ g.drawPixels(src,transparency,off,scan,x,y,width,height,manip,format); }},
                new RawModelOp(){ public void run(PlatformGraphics g){ int[] converted=new int[src.length]; for(int p=0;p<src.length;p++){ converted[p]=pixelToColor(src[p],format); if(!transparency) converted[p]&=0x00FFFFFF; } int[] data=extractInt(converted,off,scan,width,height); rawDrawPixels(g,data,width,height,x,y,manip); }}, st);
            shortCases++;
        }

        for(int i=0;i<64;i++) {
            final boolean vertical=(i&1)==0;
            final int width=vertical?5:8, height=vertical?6:4, scan=vertical?5:8, off=0;
            final byte[] pix=vertical?new byte[scan]:new byte[height];
            final byte[] mask=(i%3==0)?(vertical?new byte[scan]:new byte[height]):null;
            r.nextBytes(pix); if(mask!=null)r.nextBytes(mask);
            final int manip=MANIPS[i%MANIPS.length]; final State st=states[i%states.length];
            final int format=vertical?-1:1; final int x=9+(i%19), y=8+(i%17);
            compare("BYTE_"+i,
                new CanonicalOp(){ public void run(PlatformGraphics g){ g.drawPixels(pix,mask,off,scan,x,y,width,height,manip,format); }},
                new RawModelOp(){ public void run(PlatformGraphics g){ int[] data=vertical?decodeByteVertical(pix,mask,off,scan,width,height):decodeByteHorizontal(pix,mask,off,scan,width,height); rawDrawPixels(g,data,width,height,x,y,manip); }}, st);
            byteCases++;
        }

        System.out.println("P1A_G4_REUSE_DRAWIMAGE_CASES="+drawImageCases);
        System.out.println("P1A_G4_REUSE_INT_CASES="+intCases);
        System.out.println("P1A_G4_REUSE_SHORT_CASES="+shortCases);
        System.out.println("P1A_G4_REUSE_BYTE_CASES="+byteCases);
        System.out.println("P1A_G4_REUSE_TOTAL_CASES="+cases);
        System.out.println("P1A_G4_REUSE_RANDOM_SEED="+Long.toHexString(SEED));
        System.out.println("P1A_G4_REUSE_FAILURE_COUNT="+failures);
        System.out.println("P1A_G4_REUSE_RUNTIME_CHANGE=NO");
        if(failures!=0) throw new RuntimeException("P1A_G4_REUSE_FAIL="+failures);
        System.out.println("P1A_G4_A5_REUSE_DIAGNOSTIC=PASS");
    }

    private interface CanonicalOp { void run(PlatformGraphics g); }
    private interface RawModelOp { void run(PlatformGraphics g); }

    private static void compare(String name, CanonicalOp awtOp, RawModelOp rawOp, State st) {
        cases++;
        int[] init=pattern(W,H,name.hashCode());
        PlatformImage awt=makeImage(false,init,W,H); PlatformGraphics ag=awt.getGraphics(); apply(ag,st);
        Throwable ae=null; try{awtOp.run(ag);}catch(Throwable t){ae=t;}
        int[] ap=read(awt);
        PlatformImage raw=makeImage(true,init,W,H); PlatformGraphics rg=raw.getGraphics(); apply(rg,st);
        Throwable re=null; try{rawOp.run(rg);}catch(Throwable t){re=t;}
        int[] rp=read(raw);
        if(!sameThrowable(ae,re) || !Arrays.equals(ap,rp)) {
            failures++; int d=firstDiff(ap,rp);
            System.out.println("P1A_G4_REUSE_FAIL_CASE="+name+" AWT_ERR="+err(ae)+" RAW_ERR="+err(re)+" FIRST_DIFF="+(d<0?"NONE":((d%W)+","+(d/W)))+" AWT_SUM="+sum(ap)+" RAW_SUM="+sum(rp));
        }
    }

    private static void apply(PlatformGraphics g,State s){ if(s.tx!=0||s.ty!=0)g.translate(s.tx,s.ty); g.setClip(s.cx,s.cy,s.cw,s.ch); }
    private static PlatformImage makeImage(boolean raw,int[] pixels,int w,int h){ if(raw)System.setProperty("rg35xx.raw2d","true"); else System.clearProperty("rg35xx.raw2d"); return new PlatformImage(pixels,w,h,true); }
    private static int[] read(PlatformImage im){int[] out=new int[W*H];im.getRGB(out,0,W,0,0,W,H);return out;}

    private static void rawDrawPixels(PlatformGraphics g,int[] data,int w,int h,int x,int y,int manipulation){ PlatformImage tmp=makeImage(true,data,w,h); int t=mapManip(manipulation); g.drawRegion(tmp,0,0,w,h,t,x,y,0); }

    private static int mapManip(int m){
        final int HV=DirectGraphics.FLIP_HORIZONTAL|DirectGraphics.FLIP_VERTICAL;
        final int H90=DirectGraphics.FLIP_HORIZONTAL|DirectGraphics.ROTATE_90;
        if(m==DirectGraphics.FLIP_HORIZONTAL)return Sprite.TRANS_MIRROR;
        if(m==DirectGraphics.FLIP_VERTICAL)return Sprite.TRANS_MIRROR_ROT180;
        if(m==DirectGraphics.ROTATE_90)return Sprite.TRANS_ROT270;
        if(m==DirectGraphics.ROTATE_180)return Sprite.TRANS_ROT180;
        if(m==DirectGraphics.ROTATE_270)return Sprite.TRANS_ROT90;
        if(m==HV)return Sprite.TRANS_ROT180;
        if(m==H90)return Sprite.TRANS_MIRROR_ROT270;
        return Sprite.TRANS_NONE;
    }
    private static boolean swaps(int t){return t==Sprite.TRANS_ROT90||t==Sprite.TRANS_ROT270||t==Sprite.TRANS_MIRROR_ROT90||t==Sprite.TRANS_MIRROR_ROT270;}
    private static int anchorX(int x,int w,int a){if((a&Graphics.HCENTER)!=0)return x-w/2;if((a&Graphics.RIGHT)!=0)return x-w;return x;}
    private static int anchorY(int y,int h,int a){if((a&Graphics.VCENTER)!=0)return y-h/2;if((a&Graphics.BOTTOM)!=0)return y-h;if((a&Graphics.BASELINE)!=0)return y+h;return y;}

    private static int[] extractInt(int[] src,int off,int scan,int w,int h){int[] out=new int[w*h];for(int row=0;row<h;row++)System.arraycopy(src,off+row*scan,out,row*w,w);return out;}

    private static int[] decodeByteVertical(byte[] pixels,byte[] mask,int offset,int scan,int w,int h){
        int[] type={0xFFFFFFFF,0xFF000000,0x00FFFFFF,0x00000000}; int[] data=new int[w*h];
        int ods=offset/scan, oms=offset%scan, bit=ods%8;
        for(int yy=0;yy<h;yy++){int tmp=(ods+yy)/8*scan+oms;for(int xx=0;xx<w;xx++){int c=(pixels[tmp+xx]>>bit)&1;if(mask!=null)c|=(((mask[tmp+xx]>>bit)&1)^1)<<1;data[yy*w+xx]=type[c];}bit++;if(bit>7)bit=0;}
        return data;
    }
    private static int[] decodeByteHorizontal(byte[] pixels,byte[] mask,int offset,int scan,int w,int h){
        int[] type={0xFFFFFFFF,0xFF000000,0x00FFFFFF,0x00000000};int[] expanded=new int[pixels.length*8];
        for(int i=offset/8;i<pixels.length;i++)for(int j=7;j>=0;j--){int c=(pixels[i]>>j)&1;if(mask!=null)c|=(((mask[i]>>j)&1)^1)<<1;expanded[i*8+(7-j)]=type[c];}
        int[] out=new int[w*h];for(int row=0;row<h;row++)System.arraycopy(expanded,row*scan,out,row*w,w);return out;
    }

    private static int pixelToColor(short c,int f){
        int a=255,r=0,g=0,b=0;
        switch(f){
            case DirectGraphics.TYPE_USHORT_1555_ARGB:a=((c>>15)&1)*255;r=(c>>10)&31;g=(c>>5)&31;b=c&31;r=(r<<3)|(r>>2);g=(g<<3)|(g>>2);b=(b<<3)|(b>>2);break;
            case DirectGraphics.TYPE_USHORT_444_RGB:r=(c>>8)&15;g=(c>>4)&15;b=c&15;r=(r<<4)|r;g=(g<<4)|g;b=(b<<4)|b;break;
            case DirectGraphics.TYPE_USHORT_4444_ARGB:a=(c>>12)&15;r=(c>>8)&15;g=(c>>4)&15;b=c&15;a=(a<<4)|a;r=(r<<4)|r;g=(g<<4)|g;b=(b<<4)|b;break;
            case DirectGraphics.TYPE_USHORT_555_RGB:r=(c>>10)&31;g=(c>>5)&31;b=c&31;r=(r<<3)|(r>>2);g=(g<<3)|(g>>2);b=(b<<3)|(b>>2);break;
            case DirectGraphics.TYPE_USHORT_565_RGB:r=(c>>11)&31;g=(c>>5)&63;b=c&31;r=(r<<3)|(r>>2);g=(g<<2)|(g>>4);b=(b<<3)|(b>>2);break;
        }
        return (a<<24)|(r<<16)|(g<<8)|b;
    }

    private static int[] pattern(int w,int h,int seed){int[] p=new int[w*h];for(int y=0;y<h;y++)for(int x=0;x<w;x++){int a=64+((x*31+y*17+seed) & 191);int r=(x*47+y*11+seed)&255,g=(x*13+y*43+(seed>>>8))&255,b=(x*7+y*29+(seed>>>16))&255;p[y*w+x]=(a<<24)|(r<<16)|(g<<8)|b;}return p;}
    private static boolean sameThrowable(Throwable a,Throwable b){return a==null?b==null:(b!=null&&a.getClass().getName().equals(b.getClass().getName()));}
    private static int firstDiff(int[]a,int[]b){for(int i=0;i<a.length;i++)if(a[i]!=b[i])return i;return -1;}
    private static String err(Throwable t){return t==null?"NONE":t.getClass().getName();}
    private static String sum(int[]p){long h=1469598103934665603L;for(int i=0;i<p.length;i++){h^=p[i]&0xffffffffL;h*=1099511628211L;}return Long.toHexString(h);}
}
