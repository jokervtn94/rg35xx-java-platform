package org.recompile.rg35xx.a6;

import java.io.ByteArrayInputStream;
import org.recompile.rg35xx.RG35XXCore2D;

public final class RG35XXAdam7HostGate {
    private static final String PNG_HEX =
        "89504e470d0a1a0a0000000d494844520000000900000009080600000197963686000001624944415478da015701a8fe00000000fff85888ff0038e8" +
        "68ff3040f0ff007c2c44ff00b414acff001c7434ff98a078ff14ccbcff003e1622ffba4266ff005a8a56ffd6b69aff0076fe8afff22aceff000e3a1a" +
        "ff4c503cff8a665effc87c80ff0692a2ff002aae4eff68c470ffa6da92ffe4f0b4ff2206d6ff001f0b11605d2133609b375560d94d7760002d452b60" +
        "6b5b4d60a9716f60e7879160003b7f456079956760b7ab8960f5c1ab600049b95f6087cf8160c5e5a36003fbc5600057f3796095099b60d31fbd6011" +
        "35df6000071d0d6026281eff45332f60643e40ff83495160a25462ffc15f7360e06a84ffff7595600015572760346238ff536d496072785aff91836b" +
        "60b08e7cffcf998d60eea49eff0dafaf600023914160429c52ff61a7636080b274ff9fbd8560bec896ffddd3a760fcdeb8ff1be9c9600031cb5b6050" +
        "d66cff6fe17d608eec8effadf79f60cc02b0ffeb0dc1600a18d2ff2923e3607420ab8829d6537d0000000049454e44ae426082";

    public static void main(String[] args) throws Exception {
        byte[] png = hex(PNG_HEX);
        RG35XXCore2D.RawImage image = RG35XXCore2D.decodePng(new ByteArrayInputStream(png));
        require(image.width == 9 && image.height == 9, "dimensions");
        require(image.pixels.length == 81, "pixel-count");
        require(image.pixels[0] == 0xFF000000, "pixel-0");
        require(image.pixels[40] == 0xFF98A078, "pixel-center");
        require(image.pixels[80] == 0xFF3040F0, "pixel-last");
        long checksum = 0;
        for (int i = 0; i < image.pixels.length; i++) {
            checksum = ((checksum * 31L) + (image.pixels[i] & 0xFFFFFFFFL)) & 0xFFFFFFFFL;
        }
        require(checksum == 0x10EA8778L, "checksum=" + Long.toHexString(checksum));
        System.out.println("A6_ADAM7_SYNTHETIC_DIM=9x9");
        System.out.println("A6_ADAM7_SYNTHETIC_CHECKSUM=10ea8778");
        System.out.println("A6_ADAM7_HOST_GATE=PASS");
    }

    private static byte[] hex(String s) {
        byte[] out = new byte[s.length() / 2];
        for (int i = 0; i < out.length; i++) {
            out[i] = (byte)Integer.parseInt(s.substring(i * 2, i * 2 + 2), 16);
        }
        return out;
    }

    private static void require(boolean ok, String label) {
        if (!ok) throw new RuntimeException("A6_ADAM7_HOST_GATE_FAIL=" + label);
    }
}
