import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Method;

/**
 * Audit-only diagnostic for the exact JDK8 FontDesignMetrics string-width split.
 *
 * This deliberately does not implement the complex path. It asks JDK8 itself
 * which UTF-16 code units are non-simple, verifies the exact Miyoo-created font
 * has no layout attributes, and checks that every simple sample is measured by
 * the source-described additive advance path.
 */
public final class RG35XXP2BJdkSimpleStringContractDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09",
        "AVATAR",
        "ToTo",
        "ffi",
        "Tiếng Việt",
        "Tie\u0302\u0301ng Vie\u0323\u0302t",
        "A\u0301",
        "سلام",
        "لا",
        "שלום",
        "नमस्ते",
        "ภาษาไทย",
        "中文",
        "A\u200DB"
    };

    private static Method nonSimpleMethod;

    private static boolean isNonSimple(char ch) throws Exception {
        return ((Boolean)nonSimpleMethod.invoke(null, Character.valueOf(ch))).booleanValue();
    }

    private static String hex4(char ch) {
        String s = Integer.toHexString((int)ch).toUpperCase();
        while (s.length() < 4) s = "0" + s;
        return s;
    }

    private static int firstNonSimpleIndex(String s) throws Exception {
        for (int i=0; i<s.length(); i++) {
            if (isNonSimple(s.charAt(i))) return i;
        }
        return -1;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("usage: <font.ttf>");
        }

        Class<?> fu = Class.forName("sun.font.FontUtilities");
        nonSimpleMethod = fu.getMethod("isNonSimpleChar", Character.TYPE);

        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0]));
        int[] sizes = {12,14,16};
        int cases = 0;
        int simpleCases = 0;
        int complexCases = 0;
        int layoutAttributeCases = 0;
        int aaCases = 0;
        int fmCases = 0;
        int simpleMismatch = 0;
        int stringCharsMismatch = 0;

        System.out.println("P2B_JDK_SIMPLE_STRING_BOOT=PASS");

        for (int style=0; style<=7; style++) {
            for (int zi=0; zi<sizes.length; zi++) {
                Font f = root.deriveFont(style, (float)sizes[zi]);
                BufferedImage bi = new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
                Graphics2D g = bi.createGraphics();
                g.setFont(f);
                FontMetrics fm = g.getFontMetrics();
                FontRenderContext frc = g.getFontRenderContext();

                boolean attrs = f.hasLayoutAttributes();
                boolean aa = frc.isAntiAliased();
                boolean frac = frc.usesFractionalMetrics();
                if (attrs) layoutAttributeCases++;
                if (aa) aaCases++;
                if (frac) fmCases++;

                System.out.println("P2B_JDK_SIMPLE_CONTEXT STYLE="+style+
                    " NORMALIZED="+f.getStyle()+" SIZE="+sizes[zi]+
                    " LAYOUT_ATTRS="+attrs+" AA="+aa+" FM="+frac);

                for (int si=0; si<SAMPLES.length; si++) {
                    String s = SAMPLES[si];
                    int trigger = firstNonSimpleIndex(s);
                    boolean simple = trigger < 0;
                    int sum = 0;
                    char[] chars = s.toCharArray();
                    for (int i=0; i<chars.length; i++) sum += fm.charWidth(chars[i]);
                    int sw = fm.stringWidth(s);
                    int cw = fm.charsWidth(chars, 0, chars.length);

                    if (simple) {
                        simpleCases++;
                        if (sw != sum || cw != sum) simpleMismatch++;
                    } else {
                        complexCases++;
                    }
                    if (sw != cw) stringCharsMismatch++;

                    String trig = simple ? "NONE" : (trigger+":U+"+hex4(s.charAt(trigger)));
                    System.out.println("P2B_JDK_SIMPLE_CASE STYLE="+style+
                        " NORMALIZED="+f.getStyle()+" SIZE="+sizes[zi]+" SAMPLE="+si+
                        " SIMPLE="+simple+" TRIGGER="+trig+
                        " UTF16="+chars.length+" STRING_WIDTH="+sw+
                        " CHARS_WIDTH="+cw+" SUM_CHAR_WIDTH="+sum+
                        " STRING_MINUS_SUM="+(sw-sum));
                    cases++;
                }
                g.dispose();
            }
        }

        System.out.println("P2B_JDK_SIMPLE_STRING_CASES="+cases);
        System.out.println("P2B_JDK_SIMPLE_STRING_SIMPLE_CASES="+simpleCases);
        System.out.println("P2B_JDK_SIMPLE_STRING_NONSIMPLE_CASES="+complexCases);
        System.out.println("P2B_JDK_SIMPLE_STRING_LAYOUT_ATTRIBUTE_CONTEXTS="+layoutAttributeCases);
        System.out.println("P2B_JDK_SIMPLE_STRING_AA_CONTEXTS="+aaCases);
        System.out.println("P2B_JDK_SIMPLE_STRING_FM_CONTEXTS="+fmCases);
        System.out.println("P2B_JDK_SIMPLE_STRING_SIMPLE_MISMATCHES="+simpleMismatch);
        System.out.println("P2B_JDK_SIMPLE_STRING_STRING_CHARS_MISMATCHES="+stringCharsMismatch);

        if (cases != 336) throw new AssertionError("case count " + cases);
        if (layoutAttributeCases != 0) throw new AssertionError("layout attrs present");
        if (aaCases != 0) throw new AssertionError("AA unexpectedly enabled");
        if (fmCases != 0) throw new AssertionError("fractional metrics unexpectedly enabled");
        if (simpleMismatch != 0) throw new AssertionError("simple path mismatch count " + simpleMismatch);
        if (stringCharsMismatch != 0) throw new AssertionError("stringWidth/charsWidth mismatch count " + stringCharsMismatch);

        System.out.println("P2B_JDK_SIMPLE_STRING_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
