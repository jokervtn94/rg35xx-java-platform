package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;

/** Diagnostic only: measure pinned JDK8 non-indexed PNG tRNS at every legal depth. */
public final class RG35XXP2ATransparencyR5Diagnostic {
    private static final int W = 8, H = 8;
    private static int cases, canonicalPass, matchAlpha0, nonmatchAlpha0;

    public static void main(String[] args) throws Exception {
        int[] grayDepths = {1,2,4,8,16};
        int[] rgbDepths = {8,16};
        for (int interlace = 0; interlace <= 1; interlace++) {
            for (int i = 0; i < grayDepths.length; i++) run(0, grayDepths[i], interlace);
            for (int i = 0; i < rgbDepths.length; i++) run(2, rgbDepths[i], interlace);
        }
        System.out.println("P2A_R5_CASE_COUNT=" + cases);
        System.out.println("P2A_R5_CANONICAL_PASS_COUNT=" + canonicalPass);
        System.out.println("P2A_R5_MATCH_ALPHA0_COUNT=" + matchAlpha0);
        System.out.println("P2A_R5_NONMATCH_ALPHA0_COUNT=" + nonmatchAlpha0);
        System.out.println("P2A_R5_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
        System.out.println("P2A_R5_RUNTIME_CHANGE=NO");
        if (cases != 14 || canonicalPass != 14) throw new RuntimeException("R5 canonical coverage");
    }

    private static void run(int ct, int bd, int interlace) throws Exception {
        cases++;
        byte[] png = makePng(ct, bd, interlace);
        BufferedImage bi = ImageIO.read(new ByteArrayInputStream(png));
        if (bi == null) throw new RuntimeException("ImageIO null ct=" + ct + " bd=" + bd + " i=" + interlace);
        canonicalPass++;
        int match = bi.getRGB(0, 0);
        int nonmatch = bi.getRGB(1, 0);
        int ma = (match >>> 24) & 255;
        int na = (nonmatch >>> 24) & 255;
        if (ma == 0) matchAlpha0++;
        if (na == 0) nonmatchAlpha0++;
        System.out.println("P2A_R5_TRNS=CT" + ct + "_BD" + bd + "_I" + interlace
                + " MATCH_ALPHA=" + ma + " NONMATCH_ALPHA=" + na
                + " HAS_ALPHA=" + (bi.getColorModel().hasAlpha() ? "YES" : "NO")
                + " TYPE=" + bi.getType()
                + " MATCH_ARGB=" + hex(match) + " NONMATCH_ARGB=" + hex(nonmatch));
    }

    private static byte[] makePng(int ct, int bd, int interlace) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[]{(byte)137,80,78,71,13,10,26,10});
        ByteArrayOutputStream ih = new ByteArrayOutputStream();
        writeInt(ih, W); writeInt(ih, H); ih.write(bd); ih.write(ct); ih.write(0); ih.write(0); ih.write(interlace);
        chunk(out, "IHDR", ih.toByteArray());

        if (ct == 0) {
            int g = graySample(0, 0, bd);
            chunk(out, "tRNS", new byte[]{(byte)(g >>> 8), (byte)g});
        } else {
            ByteArrayOutputStream trns = new ByteArrayOutputStream();
            for (int c = 0; c < 3; c++) {
                int v = rgbSample(0, 0, c, bd);
                trns.write(v >>> 8); trns.write(v);
            }
            chunk(out, "tRNS", trns.toByteArray());
        }

        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        if (interlace == 0) {
            for (int y = 0; y < H; y++) {
                scan.write(0);
                scan.write(packRow(ct, bd, 0, y, 1, W));
            }
        } else {
            int[] sx={0,4,0,2,0,1,0}, sy={0,0,4,0,2,0,1}, dx={8,8,4,4,2,2,1}, dy={8,8,8,4,4,2,2};
            for (int pass = 0; pass < 7; pass++) {
                int pw = passSize(W, sx[pass], dx[pass]);
                int ph = passSize(H, sy[pass], dy[pass]);
                if (pw == 0 || ph == 0) continue;
                for (int py = 0; py < ph; py++) {
                    scan.write(0);
                    scan.write(packRow(ct, bd, sx[pass], sy[pass] + py * dy[pass], dx[pass], pw));
                }
            }
        }
        ByteArrayOutputStream z = new ByteArrayOutputStream();
        DeflaterOutputStream def = new DeflaterOutputStream(z);
        def.write(scan.toByteArray()); def.finish(); def.close();
        chunk(out, "IDAT", z.toByteArray());
        chunk(out, "IEND", new byte[0]);
        return out.toByteArray();
    }

    private static byte[] packRow(int ct, int bd, int startX, int y, int stepX, int count) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (ct == 0 && bd < 8) {
            int acc = 0, bits = 0;
            for (int i = 0; i < count; i++) {
                int v = graySample(startX + i * stepX, y, bd);
                acc = (acc << bd) | v; bits += bd;
                if (bits == 8) { out.write(acc); acc = 0; bits = 0; }
            }
            if (bits != 0) out.write(acc << (8 - bits));
            return out.toByteArray();
        }
        for (int i = 0; i < count; i++) {
            int x = startX + i * stepX;
            int channels = ct == 0 ? 1 : 3;
            for (int c = 0; c < channels; c++) {
                int v = ct == 0 ? graySample(x, y, bd) : rgbSample(x, y, c, bd);
                if (bd == 16) out.write(v >>> 8);
                out.write(v);
            }
        }
        return out.toByteArray();
    }

    private static int graySample(int x, int y, int bd) {
        int max = bd == 16 ? 65535 : ((1 << bd) - 1);
        int match = max == 1 ? 0 : max / 3;
        if (x == 0 && y == 0) return match;
        if (x == 1 && y == 0) return match == max ? 0 : max;
        return (int)(((long)(x * 37 + y * 61 + 17) * (long)max + 127L) / 255L);
    }

    private static int rgbSample(int x, int y, int c, int bd) {
        int max = bd == 16 ? 65535 : 255;
        int[] seed = bd == 16 ? new int[]{0x1234,0x8000,0xFEDC} : new int[]{17,100,183};
        if (x == 0 && y == 0) return seed[c];
        if (x == 1 && y == 0) return max - seed[c];
        int v = (x * 79 + y * 113 + c * 173 + 29) & 255;
        return bd == 16 ? (int)(((long)v * 65535L + 127L) / 255L) : v;
    }

    private static int passSize(int size, int start, int step) {
        return size <= start ? 0 : (size - start + step - 1) / step;
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v).toUpperCase();
        while (s.length() < 8) s = "0" + s;
        return s;
    }

    private static void chunk(ByteArrayOutputStream out, String type, byte[] data) throws Exception {
        byte[] tb = type.getBytes("ISO-8859-1");
        writeInt(out, data.length); out.write(tb); out.write(data);
        CRC32 crc = new CRC32(); crc.update(tb); crc.update(data); writeInt(out, (int)crc.getValue());
    }

    private static void writeInt(ByteArrayOutputStream out, int v) {
        out.write(v >>> 24); out.write(v >>> 16); out.write(v >>> 8); out.write(v);
    }
}
