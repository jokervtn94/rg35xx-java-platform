package org.recompile.rg35xx.p2a;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;
import org.recompile.rg35xx.RG35XXCore2D;

/** Strict host differential against the pinned JDK8 ImageIO backend. */
public final class RG35XXP2AImageDecodeDifferentialGate {
    private static final int W = 7;
    private static final int H = 5;
    private static int matrixTotal;
    private static int canonicalPass;
    private static int rawMatch;
    private static int rawMismatch;
    private static int rawUnsupported;

    public static void main(String[] args) throws Exception {
        int[][] matrix = {
            {0,1},{0,2},{0,4},{0,8},{0,16},
            {2,8},{2,16},
            {3,1},{3,2},{3,4},{3,8},
            {4,8},{4,16},
            {6,8},{6,16}
        };
        for (int i = 0; i < matrix.length; i++) {
            for (int interlace = 0; interlace <= 1; interlace++) {
                for (int filter = 0; filter <= 4; filter++) {
                    runMatrix(matrix[i][0], matrix[i][1], interlace, filter);
                }
            }
        }

        verifyExact(makeLowGraySweep(1), "GRAY1_SWEEP", 2);
        verifyExact(makeLowGraySweep(2), "GRAY2_SWEEP", 4);
        verifyExact(makeLowGraySweep(4), "GRAY4_SWEEP", 16);
        verifyExact(makeGraySweep(8), "GRAY8_SWEEP", 256);
        verifyExact(makeGraySweep(16), "GRAY16_SWEEP", 65536);
        verifyExact(makeRgb16Sweep(), "RGB16_SWEEP", 65536);
        verifyExact(makeRgba16AlphaSweep(), "RGBA16_ALPHA_SWEEP", 65536);

        System.out.println("P2A_IMAGE_MATRIX_CASE_COUNT=" + matrixTotal);
        System.out.println("P2A_IMAGE_CANONICAL_PASS_COUNT=" + canonicalPass);
        System.out.println("P2A_IMAGE_RAW_MATCH_COUNT=" + rawMatch);
        System.out.println("P2A_IMAGE_RAW_MISMATCH_COUNT=" + rawMismatch);
        System.out.println("P2A_IMAGE_RAW_UNSUPPORTED_COUNT=" + rawUnsupported);
        System.out.println("P2A_IMAGE_FILTER_SET=0,1,2,3,4");
        System.out.println("P2A_IMAGE_INTERLACE_SET=0,1");
        System.out.println("P2A_IMAGE_GRAY1_SWEEP_PIXELS=2");
        System.out.println("P2A_IMAGE_GRAY2_SWEEP_PIXELS=4");
        System.out.println("P2A_IMAGE_GRAY4_SWEEP_PIXELS=16");
        System.out.println("P2A_IMAGE_GRAY8_SWEEP_PIXELS=256");
        System.out.println("P2A_IMAGE_GRAY16_SWEEP_PIXELS=65536");
        System.out.println("P2A_IMAGE_RGB16_SWEEP_PIXELS=65536");
        System.out.println("P2A_IMAGE_RGBA16_ALPHA_SWEEP_PIXELS=65536");

        require(matrixTotal == 150, "matrix-total=" + matrixTotal);
        require(canonicalPass == 150, "canonical-pass=" + canonicalPass);
        require(rawMatch == 150, "raw-match=" + rawMatch);
        require(rawMismatch == 0, "raw-mismatch=" + rawMismatch);
        require(rawUnsupported == 0, "raw-unsupported=" + rawUnsupported);
        System.out.println("P2A_IMAGE_DIFFERENTIAL_GATE=PASS");
        System.out.println("P2A_IMAGE_CANONICAL_EQUIVALENT=YES");
    }

    private static void runMatrix(int colorType, int bitDepth, int interlace, int filter) throws Exception {
        matrixTotal++;
        byte[] png = makePng(colorType, bitDepth, interlace, filter);
        BufferedImage bi = ImageIO.read(new ByteArrayInputStream(png));
        if (bi == null) throw new RuntimeException("ImageIO null ct=" + colorType + " bd=" + bitDepth + " i=" + interlace + " f=" + filter);
        canonicalPass++;
        int[] expected = bi.getRGB(0, 0, W, H, null, 0, W);
        String label = "CT" + colorType + "_BD" + bitDepth + "_I" + interlace + "_F" + filter;
        try {
            RG35XXCore2D.RawImage raw = RG35XXCore2D.decodePng(new ByteArrayInputStream(png));
            int first = firstMismatch(expected, raw, W, H);
            if (first < 0) {
                rawMatch++;
                System.out.println("P2A_IMAGE_CASE=" + label + " RAW=MATCH");
            } else {
                rawMismatch++;
                System.out.println("P2A_IMAGE_CASE=" + label + " RAW=MISMATCH FIRST_PIXEL=" + first);
            }
        } catch (Exception e) {
            rawUnsupported++;
            System.out.println("P2A_IMAGE_CASE=" + label + " RAW=UNSUPPORTED ERROR=" + oneLine(e.toString()));
        }
    }

    private static void verifyExact(byte[] png, String label, int pixelCount) throws Exception {
        BufferedImage bi = ImageIO.read(new ByteArrayInputStream(png));
        require(bi != null, label + " ImageIO null");
        int width = bi.getWidth();
        int height = bi.getHeight();
        require(width * height == pixelCount, label + " canonical-pixel-count=" + (width * height));
        int[] expected = bi.getRGB(0, 0, width, height, null, 0, width);
        RG35XXCore2D.RawImage raw = RG35XXCore2D.decodePng(new ByteArrayInputStream(png));
        int first = firstMismatch(expected, raw, width, height);
        require(first < 0, label + " mismatch-pixel=" + first +
                (first >= 0 && first < expected.length && first < raw.pixels.length
                    ? " expected=" + hex(expected[first]) + " actual=" + hex(raw.pixels[first]) : ""));
        System.out.println("P2A_IMAGE_SWEEP=" + label + " PIXELS=" + pixelCount + " RESULT=MATCH");
    }

    private static int firstMismatch(int[] expected, RG35XXCore2D.RawImage raw, int width, int height) {
        if (raw.width != width || raw.height != height || raw.pixels.length != expected.length) return 0;
        for (int i = 0; i < expected.length; i++) if (expected[i] != raw.pixels[i]) return i;
        return -1;
    }

    private static byte[] makePng(int ct, int bd, int interlace, int filter) throws Exception {
        ByteArrayOutputStream out = pngHeader(W, H, bd, ct, interlace);
        addTransparencyChunks(out, ct, bd);
        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        int bpp = filterBpp(ct, bd);
        if (interlace == 0) {
            byte[] prev = null;
            for (int y = 0; y < H; y++) {
                byte[] row = packRow(ct, bd, 0, y, 1, W);
                scan.write(filter);
                scan.write(filterRow(row, prev, filter, bpp));
                prev = row;
            }
        } else {
            int[] sx = {0,4,0,2,0,1,0};
            int[] sy = {0,0,4,0,2,0,1};
            int[] dx = {8,8,4,4,2,2,1};
            int[] dy = {8,8,8,4,4,2,2};
            for (int pass = 0; pass < 7; pass++) {
                int pw = passSize(W, sx[pass], dx[pass]);
                int ph = passSize(H, sy[pass], dy[pass]);
                byte[] prev = null;
                for (int py = 0; py < ph; py++) {
                    byte[] row = packRow(ct, bd, sx[pass], sy[pass] + py * dy[pass], dx[pass], pw);
                    scan.write(filter);
                    scan.write(filterRow(row, prev, filter, bpp));
                    prev = row;
                }
            }
        }
        finishPng(out, scan.toByteArray());
        return out.toByteArray();
    }

    private static void addTransparencyChunks(ByteArrayOutputStream out, int ct, int bd) throws Exception {
        if (ct == 3) {
            int entries = bd == 8 ? 16 : (1 << bd);
            ByteArrayOutputStream plte = new ByteArrayOutputStream();
            ByteArrayOutputStream trns = new ByteArrayOutputStream();
            for (int i = 0; i < entries; i++) {
                plte.write((i * 47) & 255);
                plte.write((255 - i * 29) & 255);
                plte.write((i * 91) & 255);
                trns.write(i == 1 ? 0 : (i == 2 ? 96 : 255));
            }
            chunk(out, "PLTE", plte.toByteArray());
            chunk(out, "tRNS", trns.toByteArray());
        } else if (ct == 0) {
            int g = sample(0, 0, 0, bd, ct);
            byte[] t = new byte[2];
            t[0] = (byte)(g >>> 8);
            t[1] = (byte)g;
            chunk(out, "tRNS", t);
        } else if (ct == 2) {
            byte[] t = new byte[6];
            for (int c = 0; c < 3; c++) {
                int v = sample(0, 0, c, bd, ct);
                t[c * 2] = (byte)(v >>> 8);
                t[c * 2 + 1] = (byte)v;
            }
            chunk(out, "tRNS", t);
        }
    }

    private static byte[] packRow(int ct, int bd, int startX, int y, int stepX, int count) throws Exception {
        int channels = channels(ct);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (bd < 8) {
            int acc = 0, bits = 0;
            for (int i = 0; i < count; i++) {
                int x = startX + i * stepX;
                int v = sample(x, y, 0, bd, ct);
                acc = (acc << bd) | v;
                bits += bd;
                if (bits == 8) { out.write(acc); acc = 0; bits = 0; }
            }
            if (bits != 0) out.write(acc << (8 - bits));
        } else {
            for (int i = 0; i < count; i++) {
                int x = startX + i * stepX;
                for (int c = 0; c < channels; c++) {
                    int v = sample(x, y, c, bd, ct);
                    if (bd == 16) out.write(v >>> 8);
                    out.write(v);
                }
            }
        }
        return out.toByteArray();
    }

    private static byte[] filterRow(byte[] row, byte[] prev, int filter, int bpp) {
        byte[] out = new byte[row.length];
        for (int i = 0; i < row.length; i++) {
            int raw = row[i] & 255;
            int left = i >= bpp ? row[i - bpp] & 255 : 0;
            int up = prev == null ? 0 : prev[i] & 255;
            int upLeft = prev == null || i < bpp ? 0 : prev[i - bpp] & 255;
            int predictor;
            switch (filter) {
                case 0: predictor = 0; break;
                case 1: predictor = left; break;
                case 2: predictor = up; break;
                case 3: predictor = (left + up) >>> 1; break;
                case 4: predictor = paeth(left, up, upLeft); break;
                default: throw new IllegalArgumentException("filter=" + filter);
            }
            out[i] = (byte)((raw - predictor) & 255);
        }
        return out;
    }

    private static int paeth(int a, int b, int c) {
        int p = a + b - c;
        int pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        return pa <= pb && pa <= pc ? a : (pb <= pc ? b : c);
    }

    private static int filterBpp(int ct, int bd) {
        int bits = channels(ct) * bd;
        int bytes = (bits + 7) / 8;
        return bytes < 1 ? 1 : bytes;
    }

    private static int channels(int ct) {
        return ct == 0 ? 1 : (ct == 2 ? 3 : (ct == 3 ? 1 : (ct == 4 ? 2 : 4)));
    }

    private static int sample(int x, int y, int c, int bd, int ct) {
        int max = bd == 16 ? 65535 : ((1 << bd) - 1);
        if (ct == 3) {
            int entries = bd == 8 ? 16 : (1 << bd);
            return (x + y * 3) % entries;
        }
        int seed = (x * 37 + y * 61 + c * 83 + 17) & 255;
        int v = (int)(((long)seed * max + 127L) / 255L);
        if ((ct == 4 && c == 1) || (ct == 6 && c == 3)) {
            int a = (x + y) % 4;
            v = a == 0 ? 0 : (a == 1 ? max / 3 : (a == 2 ? (max * 2) / 3 : max));
        }
        return v;
    }

    private static byte[] makeLowGraySweep(int bitDepth) throws Exception {
        int width = 1 << bitDepth;
        ByteArrayOutputStream out = pngHeader(width, 1, bitDepth, 0, 0);
        ByteArrayOutputStream row = new ByteArrayOutputStream();
        row.write(0);
        int acc = 0, bits = 0;
        for (int sample = 0; sample < width; sample++) {
            acc = (acc << bitDepth) | sample;
            bits += bitDepth;
            if (bits == 8) { row.write(acc); acc = 0; bits = 0; }
        }
        if (bits != 0) row.write(acc << (8 - bits));
        finishPng(out, row.toByteArray());
        return out.toByteArray();
    }

    private static byte[] makeGraySweep(int bitDepth) throws Exception {
        int width = 256;
        int height = bitDepth == 8 ? 1 : 256;
        ByteArrayOutputStream out = pngHeader(width, height, bitDepth, 0, 0);
        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        for (int y = 0; y < height; y++) {
            scan.write(0);
            for (int x = 0; x < width; x++) {
                int s = bitDepth == 8 ? x : ((y << 8) | x);
                if (bitDepth == 16) scan.write(s >>> 8);
                scan.write(s);
            }
        }
        finishPng(out, scan.toByteArray());
        return out.toByteArray();
    }

    private static byte[] makeRgb16Sweep() throws Exception {
        int width = 256, height = 256;
        ByteArrayOutputStream out = pngHeader(width, height, 16, 2, 0);
        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        for (int y = 0; y < height; y++) {
            scan.write(0);
            for (int x = 0; x < width; x++) {
                int s = (y << 8) | x;
                writeSample16(scan, s);
                writeSample16(scan, 0);
                writeSample16(scan, 65535);
            }
        }
        finishPng(out, scan.toByteArray());
        return out.toByteArray();
    }

    private static byte[] makeRgba16AlphaSweep() throws Exception {
        int width = 256, height = 256;
        ByteArrayOutputStream out = pngHeader(width, height, 16, 6, 0);
        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        for (int y = 0; y < height; y++) {
            scan.write(0);
            for (int x = 0; x < width; x++) {
                int s = (y << 8) | x;
                writeSample16(scan, 65535);
                writeSample16(scan, 0);
                writeSample16(scan, 0);
                writeSample16(scan, s);
            }
        }
        finishPng(out, scan.toByteArray());
        return out.toByteArray();
    }

    private static ByteArrayOutputStream pngHeader(int width, int height, int bd, int ct, int interlace) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[] {(byte)137,80,78,71,13,10,26,10});
        ByteArrayOutputStream ih = new ByteArrayOutputStream();
        writeInt(ih, width); writeInt(ih, height);
        ih.write(bd); ih.write(ct); ih.write(0); ih.write(0); ih.write(interlace);
        chunk(out, "IHDR", ih.toByteArray());
        return out;
    }

    private static void finishPng(ByteArrayOutputStream out, byte[] scan) throws Exception {
        ByteArrayOutputStream z = new ByteArrayOutputStream();
        DeflaterOutputStream def = new DeflaterOutputStream(z);
        def.write(scan);
        def.finish();
        def.close();
        chunk(out, "IDAT", z.toByteArray());
        chunk(out, "IEND", new byte[0]);
    }

    private static void writeSample16(ByteArrayOutputStream out, int sample) {
        out.write(sample >>> 8);
        out.write(sample);
    }

    private static int passSize(int size, int start, int step) {
        return size <= start ? 0 : (size - start + step - 1) / step;
    }

    private static void chunk(ByteArrayOutputStream out, String type, byte[] data) throws Exception {
        byte[] tb = type.getBytes("ISO-8859-1");
        writeInt(out, data.length);
        out.write(tb);
        out.write(data);
        CRC32 crc = new CRC32();
        crc.update(tb);
        crc.update(data);
        writeInt(out, (int)crc.getValue());
    }

    private static void writeInt(ByteArrayOutputStream out, int v) {
        out.write(v >>> 24); out.write(v >>> 16); out.write(v >>> 8); out.write(v);
    }

    private static String oneLine(String s) {
        return s.replace('\n', ' ').replace('\r', ' ');
    }

    private static String hex(int value) {
        String s = Integer.toHexString(value).toUpperCase();
        while (s.length() < 8) s = "0" + s;
        return s;
    }

    private static void require(boolean ok, String label) {
        if (!ok) throw new RuntimeException("P2A_IMAGE_DIFFERENTIAL_FAIL=" + label);
    }
}
