package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;

/** Diagnostic only: pin JDK8 non-indexed tRNS behavior for every legal depth. */
public final class RG35XXP2ATrnsDepthR5Diagnostic {
    private static final int W = 7, H = 5;

    public static void main(String[] args) throws Exception {
        int[][] matrix = {
            {0,1},{0,2},{0,4},{0,8},{0,16},
            {2,8},{2,16}
        };
        int total = 0;
        int transparent = 0;
        for (int i = 0; i < matrix.length; i++) {
            for (int interlace = 0; interlace <= 1; interlace++) {
                byte[] png = makePng(matrix[i][0], matrix[i][1], interlace);
                BufferedImage image = ImageIO.read(new ByteArrayInputStream(png));
                if (image == null) throw new RuntimeException("ImageIO null");
                int alpha = (image.getRGB(0, 0) >>> 24) & 255;
                boolean effective = alpha == 0;
                if (effective) transparent++;
                total++;
                System.out.println("P2A_R5_CASE=CT" + matrix[i][0] + "_BD" + matrix[i][1] + "_I" + interlace
                        + " MATCHING_TRNS_ALPHA=" + alpha + " EFFECTIVE=" + (effective ? "YES" : "NO"));
            }
        }
        System.out.println("P2A_R5_NONINDEXED_TRNS_CASE_COUNT=" + total);
        System.out.println("P2A_R5_NONINDEXED_TRNS_EFFECTIVE_CASE_COUNT=" + transparent);
        System.out.println("P2A_R5_NONINDEXED_TRNS_JDK8_MODEL=" + (transparent == 0 ? "IGNORED_FOR_ALL_LEGAL_DEPTHS" : "DEPTH_DEPENDENT"));
        System.out.println("P2A_R5_RUNTIME_CHANGE=NO");
        if (total != 14) throw new RuntimeException("case count=" + total);
        if (transparent != 0) throw new RuntimeException("non-indexed tRNS is effective in " + transparent + " legal-depth cases");
        System.out.println("P2A_R5_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
    }

    private static byte[] makePng(int ct, int bd, int interlace) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[]{(byte)137,80,78,71,13,10,26,10});
        ByteArrayOutputStream ih = new ByteArrayOutputStream();
        writeInt(ih,W); writeInt(ih,H); ih.write(bd); ih.write(ct); ih.write(0); ih.write(0); ih.write(interlace);
        chunk(out,"IHDR",ih.toByteArray());
        if (ct == 0) {
            int g = sample(0,0,0,bd,ct);
            byte[] t = new byte[2]; t[0]=(byte)(g>>>8); t[1]=(byte)g; chunk(out,"tRNS",t);
        } else if (ct == 2) {
            byte[] t = new byte[6];
            for (int c=0;c<3;c++) {
                int v=sample(0,0,c,bd,ct); t[c*2]=(byte)(v>>>8); t[c*2+1]=(byte)v;
            }
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
        ByteArrayOutputStream z = new ByteArrayOutputStream();
        DeflaterOutputStream def = new DeflaterOutputStream(z); def.write(raw.toByteArray()); def.finish(); def.close();
        chunk(out,"IDAT",z.toByteArray()); chunk(out,"IEND",new byte[0]); return out.toByteArray();
    }

    private static byte[] packRow(int ct,int bd,int startX,int y,int stepX,int count) throws Exception {
        int channels = ct==0?1:3;
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (bd < 8) {
            int acc=0,bits=0;
            for(int i=0;i<count;i++) {
                int x=startX+i*stepX; int v=sample(x,y,0,bd,ct); acc=(acc<<bd)|v; bits+=bd;
                if(bits==8){out.write(acc);acc=0;bits=0;}
            }
            if(bits!=0) out.write(acc<<(8-bits));
        } else {
            for(int i=0;i<count;i++) {
                int x=startX+i*stepX;
                for(int c=0;c<channels;c++) { int v=sample(x,y,c,bd,ct); if(bd==16) out.write(v>>>8); out.write(v); }
            }
        }
        return out.toByteArray();
    }

    private static int sample(int x,int y,int c,int bd,int ct) {
        int max = bd==16 ? 65535 : ((1<<bd)-1);
        int seed = (x*37 + y*61 + c*83 + 17) & 255;
        return (int)(((long)seed * max + 127L) / 255L);
    }

    private static int passSize(int size,int start,int step) { return size<=start?0:(size-start+step-1)/step; }

    private static void chunk(ByteArrayOutputStream out,String type,byte[] data) throws Exception {
        byte[] tb=type.getBytes("ISO-8859-1"); writeInt(out,data.length); out.write(tb); out.write(data);
        CRC32 crc=new CRC32(); crc.update(tb); crc.update(data); writeInt(out,(int)crc.getValue());
    }

    private static void writeInt(ByteArrayOutputStream out,int v) { out.write(v>>>24); out.write(v>>>16); out.write(v>>>8); out.write(v); }
}
