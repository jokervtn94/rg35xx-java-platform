package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;

/**
 * Diagnostic only. Locks pinned-JDK8 sample expansion/down-conversion rules
 * for legal PNG depths not yet backed by RG35XX Raw2D.
 */
public final class RG35XXP2ASampleScalingR4Diagnostic {
    public static void main(String[] args) throws Exception {
        int gray1 = verifyLowGray(1);
        int gray2 = verifyLowGray(2);
        int gray4 = verifyLowGray(4);
        ScaleResult rgb16 = verifyRgb16();
        ScaleResult alpha16 = verifyRgba16Alpha();

        System.out.println("P2A_R4_GRAY1_SAMPLE_COUNT=2");
        System.out.println("P2A_R4_GRAY1_MODEL_MISMATCH=" + gray1);
        System.out.println("P2A_R4_GRAY2_SAMPLE_COUNT=4");
        System.out.println("P2A_R4_GRAY2_MODEL_MISMATCH=" + gray2);
        System.out.println("P2A_R4_GRAY4_SAMPLE_COUNT=16");
        System.out.println("P2A_R4_GRAY4_MODEL_MISMATCH=" + gray4);
        System.out.println("P2A_R4_RGB16_SAMPLE_COUNT=65536");
        System.out.println("P2A_R4_RGB16_ROUND_SCALE_MISMATCH=" + rgb16.roundMismatch);
        System.out.println("P2A_R4_RGB16_HIGHBYTE_SCALE_MISMATCH=" + rgb16.highByteMismatch);
        System.out.println("P2A_R4_RGBA16_ALPHA_SAMPLE_COUNT=65536");
        System.out.println("P2A_R4_RGBA16_ALPHA_ROUND_SCALE_MISMATCH=" + alpha16.roundMismatch);
        System.out.println("P2A_R4_RGBA16_ALPHA_HIGHBYTE_SCALE_MISMATCH=" + alpha16.highByteMismatch);
        System.out.println("P2A_R4_LOWBIT_GRAY_MODEL=DIRECT_ROUND_SAMPLE_TIMES_255_OVER_MAX");
        System.out.println("P2A_R4_16BIT_RGB_ALPHA_MODEL=ROUND_SAMPLE_TIMES_255_OVER_65535");
        System.out.println("P2A_R4_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
        System.out.println("P2A_R4_RUNTIME_CHANGE=NO");

        if (gray1 != 0 || gray2 != 0 || gray4 != 0 ||
                rgb16.roundMismatch != 0 || alpha16.roundMismatch != 0) {
            throw new RuntimeException("JDK8 sample scaling differs from locked model");
        }
    }

    private static int verifyLowGray(int bitDepth) throws Exception {
        int max = (1 << bitDepth) - 1;
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(makeLowGrayPng(bitDepth)));
        if (image == null) throw new RuntimeException("ImageIO returned null for gray" + bitDepth);
        int mismatch = 0;
        for (int sample = 0; sample <= max; sample++) {
            int actual = image.getRGB(sample, 0);
            int c = scaleSampleTo8(sample, max);
            int expected = 0xFF000000 | (c << 16) | (c << 8) | c;
            if (actual != expected) mismatch++;
        }
        return mismatch;
    }

    private static ScaleResult verifyRgb16() throws Exception {
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(makeSweepPng(2)));
        if (image == null) throw new RuntimeException("ImageIO returned null for RGB16");
        ScaleResult result = new ScaleResult();
        for (int sample = 0; sample <= 65535; sample++) {
            int pixel = image.getRGB(sample & 255, sample >>> 8);
            int actual = (pixel >>> 16) & 255;
            int rounded = scale16To8(sample);
            int highByte = sample >>> 8;
            if (actual != rounded) result.roundMismatch++;
            if (actual != highByte) result.highByteMismatch++;
            if (((pixel >>> 24) & 255) != 255 || ((pixel >>> 8) & 255) != 0 || (pixel & 255) != 255) {
                throw new RuntimeException("RGB16 sentinel channel drift sample=" + sample + " pixel=" + hex(pixel));
            }
        }
        return result;
    }

    private static ScaleResult verifyRgba16Alpha() throws Exception {
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(makeSweepPng(6)));
        if (image == null) throw new RuntimeException("ImageIO returned null for RGBA16");
        ScaleResult result = new ScaleResult();
        for (int sample = 0; sample <= 65535; sample++) {
            int pixel = image.getRGB(sample & 255, sample >>> 8);
            int actual = (pixel >>> 24) & 255;
            int rounded = scale16To8(sample);
            int highByte = sample >>> 8;
            if (actual != rounded) result.roundMismatch++;
            if (actual != highByte) result.highByteMismatch++;
        }
        return result;
    }

    private static int scale16To8(int sample) {
        return scaleSampleTo8(sample, 65535);
    }

    private static int scaleSampleTo8(int sample, int max) {
        return (int) ((((long) sample) * 255L + ((long) max / 2L)) / (long) max);
    }

    private static byte[] makeLowGrayPng(int bitDepth) throws Exception {
        int count = 1 << bitDepth;
        ByteArrayOutputStream out = pngStart(count, 1, bitDepth, 0);
        ByteArrayOutputStream row = new ByteArrayOutputStream();
        row.write(0);
        int acc = 0;
        int bits = 0;
        for (int sample = 0; sample < count; sample++) {
            acc = (acc << bitDepth) | sample;
            bits += bitDepth;
            if (bits == 8) {
                row.write(acc);
                acc = 0;
                bits = 0;
            }
        }
        if (bits != 0) row.write(acc << (8 - bits));
        finishPng(out, row.toByteArray());
        return out.toByteArray();
    }

    private static byte[] makeSweepPng(int colorType) throws Exception {
        int width = 256;
        int height = 256;
        ByteArrayOutputStream out = pngStart(width, height, 16, colorType);
        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        for (int y = 0; y < height; y++) {
            scan.write(0);
            for (int x = 0; x < width; x++) {
                int sample = (y << 8) | x;
                if (colorType == 2) {
                    writeSample16(scan, sample);
                    writeSample16(scan, 0);
                    writeSample16(scan, 65535);
                } else if (colorType == 6) {
                    writeSample16(scan, 65535);
                    writeSample16(scan, 0);
                    writeSample16(scan, 0);
                    writeSample16(scan, sample);
                } else {
                    throw new IllegalArgumentException("colorType=" + colorType);
                }
            }
        }
        finishPng(out, scan.toByteArray());
        return out.toByteArray();
    }

    private static ByteArrayOutputStream pngStart(int width, int height, int bitDepth, int colorType) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[] {(byte) 137, 80, 78, 71, 13, 10, 26, 10});
        ByteArrayOutputStream ihdr = new ByteArrayOutputStream();
        writeInt(ihdr, width);
        writeInt(ihdr, height);
        ihdr.write(bitDepth);
        ihdr.write(colorType);
        ihdr.write(0);
        ihdr.write(0);
        ihdr.write(0);
        chunk(out, "IHDR", ihdr.toByteArray());
        return out;
    }

    private static void finishPng(ByteArrayOutputStream out, byte[] scan) throws Exception {
        ByteArrayOutputStream compressed = new ByteArrayOutputStream();
        DeflaterOutputStream def = new DeflaterOutputStream(compressed);
        def.write(scan);
        def.finish();
        def.close();
        chunk(out, "IDAT", compressed.toByteArray());
        chunk(out, "IEND", new byte[0]);
    }

    private static void writeSample16(ByteArrayOutputStream out, int sample) {
        out.write(sample >>> 8);
        out.write(sample);
    }

    private static void chunk(ByteArrayOutputStream out, String type, byte[] data) throws Exception {
        byte[] typeBytes = type.getBytes("ISO-8859-1");
        writeInt(out, data.length);
        out.write(typeBytes);
        out.write(data);
        CRC32 crc = new CRC32();
        crc.update(typeBytes);
        crc.update(data);
        writeInt(out, (int) crc.getValue());
    }

    private static void writeInt(ByteArrayOutputStream out, int value) {
        out.write(value >>> 24);
        out.write(value >>> 16);
        out.write(value >>> 8);
        out.write(value);
    }

    private static String hex(int value) {
        String s = Integer.toHexString(value).toUpperCase();
        while (s.length() < 8) s = "0" + s;
        return s;
    }

    private static final class ScaleResult {
        int roundMismatch;
        int highByteMismatch;
    }
}
