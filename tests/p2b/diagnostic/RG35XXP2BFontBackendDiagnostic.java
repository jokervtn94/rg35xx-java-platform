import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.security.MessageDigest;

/** Diagnostic only. Replays the pinned Miyoo AWT font backend calls against
 * an externally supplied font.ttf. This is not RG35XX runtime code. */
public final class RG35XXP2BFontBackendDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09", "iiiiWWWW", "Tieng Viet", "Tiếng Việt", "Đặng", "中文"
    };

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("usage: RG35XXP2BFontBackendDiagnostic <font.ttf>");
        }
        File file = new File(args[0]);
        if (!file.isFile()) {
            throw new IllegalArgumentException("font file missing: " + file);
        }

        Font loaded = Font.createFont(Font.TRUETYPE_FONT, file);
        Font global = loaded.deriveFont(Font.PLAIN, 12f);

        System.out.println("P2B_FONT_DIAGNOSTIC_BOOT=PASS");
        System.out.println("P2B_JAVA_VERSION=" + System.getProperty("java.version"));
        System.out.println("P2B_FONT_FILE=" + file.getPath());
        System.out.println("P2B_FONT_NAME=" + clean(loaded.getFontName()));
        System.out.println("P2B_FONT_FAMILY=" + clean(loaded.getFamily()));
        System.out.println("P2B_FONT_PSNAME=" + clean(loaded.getPSName()));
        System.out.println("P2B_FONT_NUM_GLYPHS=" + loaded.getNumGlyphs());

        int[] sizes = new int[] {12, 14, 16};
        int[] styles = new int[] {0, 1, 2, 3, 4, 5, 6, 7};
        int cases = 0;
        for (int si = 0; si < styles.length; si++) {
            int style = styles[si];
            for (int zi = 0; zi < sizes.length; zi++) {
                int size = sizes[zi];
                Font derived = global.deriveFont(style, (float) size);
                BufferedImage metricImage = new BufferedImage(1, 1, BufferedImage.TYPE_BYTE_BINARY);
                Graphics2D mg = metricImage.createGraphics();
                mg.setFont(derived);
                FontMetrics fm = mg.getFontMetrics();

                String prefix = "P2B_STYLE=" + style + " SIZE=" + size;
                System.out.println(prefix
                    + " AWT_STYLE=" + derived.getStyle()
                    + " HEIGHT=" + fm.getHeight()
                    + " ASCENT=" + fm.getAscent()
                    + " DESCENT=" + fm.getDescent()
                    + " LEADING=" + fm.getLeading());
                for (int i = 0; i < SAMPLES.length; i++) {
                    String s = SAMPLES[i];
                    System.out.println(prefix
                        + " SAMPLE=" + i
                        + " WIDTH=" + fm.stringWidth(s)
                        + " DISPLAY=" + displayMask(derived, s)
                        + " RASTER_SHA256=" + rasterSha256(derived, fm, s));
                }
                mg.dispose();
                cases++;
            }
        }

        System.out.println("P2B_DERIVE_CASES=" + cases);
        System.out.println("P2B_FONT_DIAGNOSTIC_RESULT=PASS");
    }

    private static String displayMask(Font f, String s) {
        StringBuffer out = new StringBuffer();
        for (int i = 0; i < s.length(); i++) {
            if (i > 0) out.append(',');
            out.append(f.canDisplay(s.charAt(i)) ? '1' : '0');
        }
        return out.toString();
    }

    private static String rasterSha256(Font f, FontMetrics fm, String s) throws Exception {
        int width = Math.max(1, fm.stringWidth(s) + 8);
        int height = Math.max(1, fm.getHeight() + 8);
        BufferedImage bi = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = bi.createGraphics();
        g.setFont(f);
        g.setColor(new java.awt.Color(0, 0, 0, 255));
        g.drawString(s, 4, 4 + fm.getAscent());
        g.dispose();

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int p = bi.getRGB(x, y);
                md.update((byte) (p >>> 24));
                md.update((byte) (p >>> 16));
                md.update((byte) (p >>> 8));
                md.update((byte) p);
            }
        }
        return hex(md.digest());
    }

    private static String hex(byte[] b) {
        StringBuffer out = new StringBuffer();
        for (int i = 0; i < b.length; i++) {
            int v = b[i] & 0xff;
            if (v < 16) out.append('0');
            out.append(Integer.toHexString(v));
        }
        return out.toString();
    }

    private static String clean(String s) {
        if (s == null) return "NULL";
        return s.replace(' ', '_').replace('\t', '_').replace('\r', '_').replace('\n', '_');
    }
}
