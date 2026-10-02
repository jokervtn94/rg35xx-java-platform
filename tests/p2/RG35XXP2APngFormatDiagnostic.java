package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;
import org.recompile.rg35xx.RG35XXCore2D;

/** Diagnostic only: legal PNG matrix, canonical ImageIO vs materialized RG35XX raw decoder. */
public final class RG35XXP2APngFormatDiagnostic {
    private static final int W = 7, H = 5;
    private static int total, canonicalPass, rawMatch, rawMismatch, rawUnsupported;

    public static void main(String[] args) throws Exception {
        int[][] matrix = {
            {0,1},{0,2},{0,4},{0,8},{0,16},
            {2,8},{2,16},
            {3,1},{3,2},{3,4},{3,8},
            {4,8},{4,16},
            {6,8},{6,16}
        };
        for (int i = 0; i < matrix.length; i++) {
            run(matrix[i][0], matrix[i][1], 0);
            run(matrix[i][0], matrix[i][1], 1);
        }
        System.out.println("P2A_PNG_LEGAL_CASE_COUNT=" + total);
        System.out.println("P2A_PNG_CANONICAL_PASS_COUNT=" + canonicalPass);
        System.out.println("P2A_PNG_RAW_MATCH_COUNT=" + rawMatch);
        System.out.println("P2A_PNG_RAW_MISMATCH_COUNT=" + rawMismatch);
        System.out.println("P2A_PNG_RAW_UNSUPPORTED_COUNT=" + rawUnsupported);
        if (canonicalPass != total) throw new RuntimeException("canonical legal PNG matrix incomplete");
        if (rawMatch + rawMismatch + rawUnsupported != total) throw new RuntimeException("raw accounting");
        System.out.println("P2A_PNG_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
        System.out.println("P2A_RUNTIME_CHANGE=NO");
    }

    private static void run(int colorType, int bitDepth, int interlace) throws Exception {
        total++;
        byte[] png = makePng(colorType, bitDepth, interlace);
        BufferedImage bi = ImageIO.read(new ByteArrayInputStream(png));
        if (bi == null) throw new RuntimeException("ImageIO null ct=" + colorType + " bd=" + bitDepth + " i=" + interlace);
        canonicalPass++;
        int[] expected = bi.getRGB(0, 0, W, H, null, 0, W);
        String label = "CT" + colorType + "_BD" + bitDepth + "_I" + interlace;
        try {
            RG35XXCore2D.RawImage raw = RG35XXCore2D.decodePng(new ByteArrayInputStream(png));
            boolean same = raw.width == W && raw.height == H && raw.pixels.length == expected.length;
            int first = -1;
            if (same) {
                for (int p = 0; p < expected.length; p++) if (raw.pixels[p] != expected[p]) { same = false; first = p; break; }
            }
            if (same) {
                rawMatch++;
                System.out.println("P2A_PNG_CASE=" + label + " RAW=MATCH");
            } else {
                rawMismatch++;
                System.out.println("P2A_PNG_CASE=" + label + " RAW=MISMATCH FIRST_PIXEL=" + first);
            }
        } catch (IOException e) {
            rawUnsupported++;
            System.out.println("P2A_PNG_CASE=" + label + " RAW=UNSUPPORTED ERROR=" + oneLine(e.toString()));
        }
    }

    private static String oneLine(String s) { return s.replace('\n',' ').replace('\r',' '); }

    private static byte[] makePng(int ct, int bd, int interlace) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[]{(byte)137,80,78,71,13,10,26,10});
        ByteArrayOutputStream ih = new ByteArrayOutputStream();
        writeInt(ih,W); writeInt(ih,H); ih.write(bd); ih.write(ct); ih.write(0); ih.write(0); ih.write(interlace);
        chunk(out,"IHDR",ih.toByteArray());
        if (ct == 3) {
            int entries = bd == 8 ? 16 : (1 << bd);
            ByteArrayOutputStream plte = new ByteArrayOutputStream();
            ByteArrayOutputStream trns = new ByteArrayOutputStream();
            for (int i=0;i<entries;i++) {
                plte.write((i*47)&255); plte.write((255-i*29)&255); plte.write((i*91)&255);
                trns.write(i==1 ? 0 : (i==2 ? 96 : 255));
            }
            chunk(out,"PLTE",plte.toByteArray()); chunk(out,"tRNS",trns.toByteArray());
        } else if (ct == 0) {
            int g = sample(0,0,0,bd,ct); byte[] t = new byte[2]; t[0]=(byte)(g>>>8); t[1]=(byte)g; chunk(out,"tRNS",t);
        } else if (ct == 2) {
            byte[] t = new byte[6];
            for (int c=0;c<3;c++) { int v=sample(0,0,c,bd,ct); t[c*2]=(byte)(v>>>8); t[c*2+1]=(byte)v; }
            chunk(out,"tRNS",t);
        }
        ByteArrayOutputStream raw = new ByteArrayOutputStream();
        if (interlace == 0) {
            for (int y=0;y<H;y++) { raw.write(0); raw.write(packRow(ct,bd,0,y,1,W)); }
        } else {
            int[] sx={0,4,0,2,0,1,0}, sy={0,0,4,0,2,0,1}, dx={8,8,4,4,2,2,1}, dy={8,8,8,4,4,2,2};
            for (int pass=0;pass<7;pass++) {
                int pw=passSize(W,sx[pass],dx[pass]), ph=passSize(H,sy[pass],dy[pass]);
                for (int py=0;py<ph;py++) { raw.write(0); raw.write(packRow(ct,bd,sx[pass],sy[pass]+py*dy[pass],dx[pass],pw)); }
            }
        }
        ByteArrayOutputStream z = new ByteArrayOutputStream(); DeflaterOutputStream def = new DeflaterOutputStream(z); def.write(raw.toByteArray()); def.finish(); def.close();
        chunk(out,"IDAT",z.toByteArray()); chunk(out,"IEND",new byte[0]); return out.toByteArray();
    }

    private static int passSize(int size,int start,int step){ return size<=start?0:(size-start+step-1)/step; }

    private static byte[] packRow(int ct,int bd,int startX,int y,int stepX,int count) throws Exception {
        int channels = ct==0?1:(ct==2?3:(ct==3?1:(ct==4?2:4)));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (bd < 8) {
            int acc=0,bits=0;
            for(int i=0;i<count;i++) { int x=startX+i*stepX; int v=sample(x,y,0,bd,ct); acc=(acc<<bd)|v; bits+=bd; if(bits==8){out.write(acc);acc=0;bits=0;} }
            if(bits!=0) out.write(acc<<(8-bits));
        } else {
            for(int i=0;i<count;i++) { int x=startX+i*stepX; for(int c=0;c<channels;c++){int v=sample(x,y,c,bd,ct); if(bd==16) out.write(v>>>8); out.write(v); } }
        }
        return out.toByteArray();
    }

    private static int sample(int x,int y,int c,int bd,int ct) {
        int max = bd==16 ? 65535 : ((1<<bd)-1);
        if (ct==3) { int entries=bd==8?16:(1<<bd); return (x+y*3)%entries; }
        int seed = (x*37 + y*61 + c*83 + 17) & 255;
        int v = (int)(((long)seed * max + 127) / 255);
        if ((ct==4 && c==1) || (ct==6 && c==3)) {
            int a=(x+y)%4; v = a==0?0:(a==1?max/3:(a==2?(max*2)/3:max));
        }
        return v;
    }

    private static void chunk(ByteArrayOutputStream out,String type,byte[] data) throws Exception {
        byte[] tb=type.getBytes("ISO-8859-1"); writeInt(out,data.length); out.write(tb); out.write(data);
        CRC32 crc=new CRC32(); crc.update(tb); crc.update(data); writeInt(out,(int)crc.getValue());
    }
    private static void writeInt(ByteArrayOutputStream out,int v){out.write(v>>>24);out.write(v>>>16);out.write(v>>>8);out.write(v);}
}
