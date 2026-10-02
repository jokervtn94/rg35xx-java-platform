package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;
import org.recompile.rg35xx.RG35XXCore2D;

/** Diagnostic only. Decomposes the four R1 8-bit mismatches and tRNS semantics. */
public final class RG35XXP2APngSemanticsR2Diagnostic {
    private static final int W=4,H=3;
    private static int cases;

    public static void main(String[] args) throws Exception {
        for (int interlace=0; interlace<=1; interlace++) {
            run("GRAY8_PLAIN",0,interlace,false,255);
            run("GRAY8_TRNS",0,interlace,true,255);
            run("RGB8_PLAIN",2,interlace,false,255);
            run("RGB8_TRNS",2,interlace,true,255);
            run("GA8_OPAQUE",4,interlace,false,255);
            run("GA8_ALPHA85",4,interlace,false,85);
            run("RGBA8_ALPHA85",6,interlace,false,85);
        }
        System.out.println("P2A_R2_CASE_COUNT="+cases);
        System.out.println("P2A_R2_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
        System.out.println("P2A_R2_RUNTIME_CHANGE=NO");
    }

    private static void run(String name,int ct,int interlace,boolean trns,int forcedAlpha) throws Exception {
        byte[] png=makePng(ct,interlace,trns,forcedAlpha);
        BufferedImage bi=ImageIO.read(new ByteArrayInputStream(png));
        if (bi==null) throw new RuntimeException("ImageIO null "+name);
        int[] canon=bi.getRGB(0,0,W,H,null,0,W);
        RG35XXCore2D.RawImage raw=RG35XXCore2D.decodePng(new ByteArrayInputStream(png));
        int first=-1; boolean same=true;
        for(int i=0;i<canon.length;i++) if(canon[i]!=raw.pixels[i]) { same=false; first=i; break; }
        int c0=canon[0],r0=raw.pixels[0];
        int c1=canon[1],r1=raw.pixels[1];
        System.out.println("P2A_R2_CASE="+name+"_I"+interlace+
            " RESULT="+(same?"MATCH":"MISMATCH")+
            " FIRST="+first+
            " C0="+hex(c0)+" R0="+hex(r0)+
            " C1="+hex(c1)+" R1="+hex(r1));
        if (trns) {
            boolean ca=((c0>>>24)&255)==0;
            boolean ra=((r0>>>24)&255)==0;
            System.out.println("P2A_R2_TRNS="+name+"_I"+interlace+
                " CANONICAL_ALPHA0="+(ca?"YES":"NO")+
                " RAW_ALPHA0="+(ra?"YES":"NO"));
            if (!ca) throw new RuntimeException("canonical tRNS sentinel did not become alpha0: "+name+" i="+interlace);
        }
        if (ct==4 || ct==6) {
            int ca=(c0>>>24)&255, ra=(r0>>>24)&255;
            System.out.println("P2A_R2_ALPHA="+name+"_I"+interlace+" CANONICAL="+ca+" RAW="+ra);
            if (ca!=forcedAlpha || ra!=forcedAlpha) throw new RuntimeException("alpha sentinel drift "+name+" c="+ca+" r="+ra);
        }
        cases++;
    }

    private static String hex(int v) {
        String s=Integer.toHexString(v).toUpperCase();
        while(s.length()<8)s="0"+s;
        return s;
    }

    private static byte[] makePng(int ct,int interlace,boolean trns,int forcedAlpha) throws Exception {
        ByteArrayOutputStream out=new ByteArrayOutputStream();
        out.write(new byte[]{(byte)137,80,78,71,13,10,26,10});
        ByteArrayOutputStream ih=new ByteArrayOutputStream();
        writeInt(ih,W);writeInt(ih,H);ih.write(8);ih.write(ct);ih.write(0);ih.write(0);ih.write(interlace);
        chunk(out,"IHDR",ih.toByteArray());
        if(trns && ct==0) chunk(out,"tRNS",new byte[]{0,(byte)gray(0,0)});
        if(trns && ct==2) chunk(out,"tRNS",new byte[]{0,(byte)red(0,0),0,(byte)green(0,0),0,(byte)blue(0,0)});
        ByteArrayOutputStream scan=new ByteArrayOutputStream();
        if(interlace==0) {
            for(int y=0;y<H;y++){scan.write(0);scan.write(row(ct,0,y,1,W,forcedAlpha));}
        } else {
            int[] sx={0,4,0,2,0,1,0},sy={0,0,4,0,2,0,1},dx={8,8,4,4,2,2,1},dy={8,8,8,4,4,2,2};
            for(int p=0;p<7;p++){
                int pw=size(W,sx[p],dx[p]), ph=size(H,sy[p],dy[p]);
                for(int py=0;py<ph;py++){scan.write(0);scan.write(row(ct,sx[p],sy[p]+py*dy[p],dx[p],pw,forcedAlpha));}
            }
        }
        ByteArrayOutputStream z=new ByteArrayOutputStream();
        DeflaterOutputStream def=new DeflaterOutputStream(z);def.write(scan.toByteArray());def.finish();def.close();
        chunk(out,"IDAT",z.toByteArray());chunk(out,"IEND",new byte[0]);return out.toByteArray();
    }

    private static byte[] row(int ct,int sx,int y,int dx,int count,int a) {
        ByteArrayOutputStream out=new ByteArrayOutputStream();
        for(int i=0;i<count;i++){
            int x=sx+i*dx;
            if(ct==0){out.write(gray(x,y));}
            else if(ct==2){out.write(red(x,y));out.write(green(x,y));out.write(blue(x,y));}
            else if(ct==4){out.write(gray(x,y));out.write(a);}
            else if(ct==6){out.write(red(x,y));out.write(green(x,y));out.write(blue(x,y));out.write(a);}
            else throw new IllegalArgumentException("ct"+ct);
        }
        return out.toByteArray();
    }
    private static int gray(int x,int y){return (17+x*37+y*61)&255;}
    private static int red(int x,int y){return (17+x*31+y*43)&255;}
    private static int green(int x,int y){return (100+x*29+y*47)&255;}
    private static int blue(int x,int y){return (183+x*23+y*53)&255;}
    private static int size(int n,int start,int step){return n<=start?0:(n-start+step-1)/step;}
    private static void chunk(ByteArrayOutputStream out,String type,byte[] data)throws Exception{
        byte[] t=type.getBytes("ISO-8859-1");writeInt(out,data.length);out.write(t);out.write(data);CRC32 c=new CRC32();c.update(t);c.update(data);writeInt(out,(int)c.getValue());
    }
    private static void writeInt(ByteArrayOutputStream out,int v){out.write(v>>>24);out.write(v>>>16);out.write(v>>>8);out.write(v);}
}
