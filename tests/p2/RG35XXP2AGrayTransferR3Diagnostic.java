package org.recompile.rg35xx.p2;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;

/**
 * Diagnostic only. Locks the exact pinned-JDK8 gray-sample -> sRGB getRGB()
 * transfer used by the Miyoo ImageIO-backed PlatformImage path.
 */
public final class RG35XXP2AGrayTransferR3Diagnostic {
    public static void main(String[] args) throws Exception {
        int mismatch8 = verify(8);
        int mismatch16 = verify(16);

        System.out.println("P2A_R3_GRAY8_SAMPLE_COUNT=256");
        System.out.println("P2A_R3_GRAY8_FORMULA_MISMATCH=" + mismatch8);
        System.out.println("P2A_R3_GRAY16_SAMPLE_COUNT=65536");
        System.out.println("P2A_R3_GRAY16_FORMULA_MISMATCH=" + mismatch16);
        System.out.println("P2A_R3_GRAY_TRANSFER_MODEL=LINEAR_GRAY_TO_SRGB_IEC61966_2_1");
        System.out.println("P2A_R3_DIAGNOSTIC=PASS_EVIDENCE_ONLY");
        System.out.println("P2A_R3_RUNTIME_CHANGE=NO");

        if (mismatch8 != 0 || mismatch16 != 0) {
            throw new RuntimeException("JDK8 grayscale transfer differs from locked formula");
        }
    }

    private static int verify(int bitDepth) throws Exception {
        int max = bitDepth == 8 ? 255 : 65535;
        int width = 256;
        int height = bitDepth == 8 ? 1 : 256;
        byte[] png = makeGrayPng(bitDepth, width, height);
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(png));
        if (image == null) throw new RuntimeException("ImageIO returned null for gray" + bitDepth);
        if (image.getWidth() != width || image.getHeight() != height) {
            throw new RuntimeException("ImageIO dimensions drift for gray" + bitDepth);
        }

        int mismatch = 0;
        int firstSample = -1;
        int firstExpected = -1;
        int firstActual = -1;
        for (int sample = 0; sample <= max; sample++) {
            int x = sample & 255;
            int y = bitDepth == 8 ? 0 : (sample >>> 8);
            int actual = image.getRGB(x, y);
            int channel = linearGrayToSrgb8(sample, max);
            int expected = 0xFF000000 | (channel << 16) | (channel << 8) | channel;
            if (actual != expected) {
                mismatch++;
                if (firstSample < 0) {
                    firstSample = sample;
                    firstExpected = expected;
                    firstActual = actual;
                }
            }
        }
        System.out.println("P2A_R3_GRAY" + bitDepth + "_FIRST_MISMATCH_SAMPLE=" + firstSample
                + " EXPECTED=" + hex(firstExpected) + " ACTUAL=" + hex(firstActual));
        return mismatch;
    }

    private static int linearGrayToSrgb8(int sample, int max) {
        double linear = ((double) sample) / ((double) max);
        double srgb;
        if (linear <= 0.0031308d) {
            srgb = 12.92d * linear;
        } else {
            srgb = 1.055d * Math.pow(linear, 1.0d / 2.4d) - 0.055d;
        }
        int out = (int) Math.round(srgb * 255.0d);
        if (out < 0) return 0;
        if (out > 255) return 255;
        return out;
    }

    private static byte[] makeGrayPng(int bitDepth, int width, int height) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(new byte[] {(byte) 137, 80, 78, 71, 13, 10, 26, 10});

        ByteArrayOutputStream ihdr = new ByteArrayOutputStream();
        writeInt(ihdr, width);
        writeInt(ihdr, height);
        ihdr.write(bitDepth);
        ihdr.write(0); // grayscale
        ihdr.write(0); // compression
        ihdr.write(0); // filter
        ihdr.write(0); // non-interlaced; transfer is independent of Adam7 layout
        chunk(out, "IHDR", ihdr.toByteArray());

        ByteArrayOutputStream scan = new ByteArrayOutputStream();
        for (int y = 0; y < height; y++) {
            scan.write(0); // PNG filter None
            for (int x = 0; x < width; x++) {
                int sample = bitDepth == 8 ? x : ((y << 8) | x);
                if (bitDepth == 16) scan.write(sample >>> 8);
                scan.write(sample);
            }
        }

        ByteArrayOutputStream compressed = new ByteArrayOutputStream();
        DeflaterOutputStream def = new DeflaterOutputStream(compressed);
        def.write(scan.toByteArray());
        def.finish();
        def.close();
        chunk(out, "IDAT", compressed.toByteArray());
        chunk(out, "IEND", new byte[0]);
        return out.toByteArray();
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
        if (value == -1) return "NA";
        String s = Integer.toHexString(value).toUpperCase();
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
