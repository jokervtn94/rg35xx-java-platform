import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;

/**
 * Audit-only reference for the exact JDK8 FontMetrics integer contract used by
 * pinned Miyoo Font/PlatformGraphics. No runtime classes are modified.
 */
public final class RG35XXP2BJdkFontMetricsContractDiagnostic {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("usage: <font.ttf>");
        }
        Font base = Font.createFont(Font.TRUETYPE_FONT, new File(args[0]));
        int[] sizes = new int[] {12, 14, 16};
        int cases = 0;
        System.out.println("P2B_JDK8_FONT_METRICS_BOOT=PASS");
        for (int style = 0; style <= 7; style++) {
            for (int zi = 0; zi < sizes.length; zi++) {
                int size = sizes[zi];
                Font f = base.deriveFont(style, (float)size);
                BufferedImage bi = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
                Graphics2D g = bi.createGraphics();
                g.setFont(f);
                FontMetrics fm = g.getFontMetrics();
                System.out.println("P2B_JDK8_FONT_METRIC STYLE=" + style
                    + " NORMALIZED=" + f.getStyle()
                    + " SIZE=" + size
                    + " HEIGHT=" + fm.getHeight()
                    + " ASCENT=" + fm.getAscent()
                    + " DESCENT=" + fm.getDescent()
                    + " LEADING=" + fm.getLeading());
                g.dispose();
                cases++;
            }
        }
        System.out.println("P2B_JDK8_FONT_METRICS_CASES=" + cases);
        System.out.println("P2B_JDK8_FONT_METRICS_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
