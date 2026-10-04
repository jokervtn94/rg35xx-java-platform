import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Method;

/**
 * Diagnostic only. Uses JDK8's own sun.font.FontUtilities.isNonSimpleChar(char)
 * via reflection, then measures the exact FontDesignMetrics/TextLayout behavior
 * of A + <BMP char> + B for every triggered UTF-16 code unit.
 */
public final class RG35XXP2BJdkComplexTriggerSweep {
    private static int pos64(GlyphVector gv, int index) {
        return Math.round((float)gv.getGlyphPosition(index).getX() * 64f);
    }

    private static String hex4(int v) {
        String s = Integer.toHexString(v).toUpperCase();
        while (s.length() < 4) s = "0" + s;
        return s;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("usage: <font.ttf>");

        Class<?> fu = Class.forName("sun.font.FontUtilities");
        Method nonSimple = fu.getDeclaredMethod("isNonSimpleChar", Character.TYPE);
        nonSimple.setAccessible(true);

        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0])).deriveFont(Font.PLAIN, 12f);
        int[] sizes = new int[] {12, 14, 16};
        int triggeredUnits = 0;
        for (int cp = 0; cp <= 0xFFFF; cp++) {
            if (((Boolean)nonSimple.invoke(null, Character.valueOf((char)cp))).booleanValue()) triggeredUnits++;
        }

        System.out.println("P2B_JDK_COMPLEX_SWEEP_BOOT=PASS");
        System.out.println("P2B_JDK_COMPLEX_TRIGGER_UNITS=" + triggeredUnits);

        int cases = 0;
        int widthDiffCases = 0;
        int layoutDiffCases = 0;
        int exceptionCases = 0;
        int uniqueWidthDiffUnits = 0;
        boolean[] widthDiffUnit = new boolean[65536];
        long absDeltaTotal = 0;
        int absDeltaMax = 0;

        for (int zi = 0; zi < sizes.length; zi++) {
            int size = sizes[zi];
            Font f = root.deriveFont(Font.PLAIN, (float)size);
            BufferedImage bi = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = bi.createGraphics();
            g.setFont(f);
            FontMetrics fm = g.getFontMetrics();
            FontRenderContext frc = g.getFontRenderContext();

            for (int cp = 0; cp <= 0xFFFF; cp++) {
                char ch = (char)cp;
                if (!((Boolean)nonSimple.invoke(null, Character.valueOf(ch))).booleanValue()) continue;
                cases++;
                try {
                    String s = new String(new char[] {'A', ch, 'B'});
                    char[] ca = s.toCharArray();
                    int sum = fm.charWidth('A') + fm.charWidth(ch) + fm.charWidth('B');
                    int sw = fm.stringWidth(s);
                    int cw = fm.charsWidth(ca, 0, ca.length);
                    GlyphVector direct = f.createGlyphVector(frc, s);
                    GlyphVector layout = f.layoutGlyphVector(frc, ca, 0, ca.length, Font.LAYOUT_LEFT_TO_RIGHT);
                    int directAdv64 = pos64(direct, direct.getNumGlyphs());
                    int layoutAdv64 = pos64(layout, layout.getNumGlyphs());
                    boolean widthDiff = (sw != sum) || (cw != sum);
                    boolean layoutDiff = direct.getNumGlyphs() != layout.getNumGlyphs() || directAdv64 != layoutAdv64;
                    if (widthDiff) {
                        widthDiffCases++;
                        if (!widthDiffUnit[cp]) { widthDiffUnit[cp] = true; uniqueWidthDiffUnits++; }
                        int d = Math.abs(sw - sum); absDeltaTotal += d; if (d > absDeltaMax) absDeltaMax = d;
                    }
                    if (layoutDiff) layoutDiffCases++;
                    if (widthDiff || layoutDiff) {
                        int directMiddle = direct.getNumGlyphs() > 1 ? direct.getGlyphCode(1) : -1;
                        int layoutMiddle = layout.getNumGlyphs() > 1 ? layout.getGlyphCode(1) : -1;
                        int directP1 = direct.getNumGlyphs() >= 1 ? pos64(direct, 1) : -1;
                        int directP2 = direct.getNumGlyphs() >= 2 ? pos64(direct, 2) : -1;
                        int layoutP1 = layout.getNumGlyphs() >= 1 ? pos64(layout, 1) : -1;
                        int layoutP2 = layout.getNumGlyphs() >= 2 ? pos64(layout, 2) : -1;
                        System.out.println(
                            "P2B_JDK_COMPLEX_DIFF SIZE=" + size +
                            " CP=U+" + hex4(cp) +
                            " DISPLAY=" + (f.canDisplay(ch) ? 1 : 0) +
                            " CHAR_WIDTH=" + fm.charWidth(ch) +
                            " SUM_CHAR_WIDTH=" + sum +
                            " STRING_WIDTH=" + sw +
                            " CHARS_WIDTH=" + cw +
                            " WIDTH_DELTA=" + (sw - sum) +
                            " DIRECT_GLYPHS=" + direct.getNumGlyphs() +
                            " LAYOUT_GLYPHS=" + layout.getNumGlyphs() +
                            " DIRECT_MIDDLE=" + directMiddle +
                            " LAYOUT_MIDDLE=" + layoutMiddle +
                            " DIRECT_ADV64=" + directAdv64 +
                            " LAYOUT_ADV64=" + layoutAdv64 +
                            " DIRECT_P1_64=" + directP1 +
                            " DIRECT_P2_64=" + directP2 +
                            " LAYOUT_P1_64=" + layoutP1 +
                            " LAYOUT_P2_64=" + layoutP2
                        );
                    }
                } catch (Throwable t) {
                    exceptionCases++;
                    System.out.println("P2B_JDK_COMPLEX_EXCEPTION SIZE=" + size + " CP=U+" + hex4(cp) + " TYPE=" + t.getClass().getName());
                }
            }
            g.dispose();
        }

        System.out.println("P2B_JDK_COMPLEX_SWEEP_CASES=" + cases);
        System.out.println("P2B_JDK_COMPLEX_WIDTH_DIFF_CASES=" + widthDiffCases);
        System.out.println("P2B_JDK_COMPLEX_LAYOUT_DIFF_CASES=" + layoutDiffCases);
        System.out.println("P2B_JDK_COMPLEX_UNIQUE_WIDTH_DIFF_UNITS=" + uniqueWidthDiffUnits);
        System.out.println("P2B_JDK_COMPLEX_WIDTH_ABS_DELTA_TOTAL=" + absDeltaTotal);
        System.out.println("P2B_JDK_COMPLEX_WIDTH_ABS_DELTA_MAX=" + absDeltaMax);
        System.out.println("P2B_JDK_COMPLEX_EXCEPTION_CASES=" + exceptionCases);
        System.out.println("P2B_JDK_COMPLEX_SWEEP_RESULT=PASS");
    }
}
