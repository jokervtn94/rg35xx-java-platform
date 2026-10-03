import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

/**
 * Audit-only JDK8 reference for the bundled LayoutEngine semantic probe.
 *
 * It deliberately lets the exact JDK8 ScriptRun implementation define the
 * native engine records, then records the final GlyphVector fields produced by
 * Font.layoutGlyphVector for the already-established non-simple P2B corpus.
 * Runtime/production code must not depend on this class.
 */
public final class RG35XXP2BJdkLayoutEngineSemanticReference {
    private static final String[] SAMPLES = new String[] {
        "Tie\u0302\u0301ng Vie\u0323\u0302t",
        "A\u0301",
        "سلام",
        "لا",
        "שלום",
        "नमस्ते",
        "ภาษาไทย",
        "A\u200DB"
    };

    private static final int[] SAMPLE_IDS = new int[] {5, 6, 7, 8, 9, 10, 11, 13};
    private static final int[] SIZES = new int[] {12, 14, 16};

    private static final class RunRec {
        int start;
        int limit;
        int script;
        int flags;
    }

    private static String hex4(int v) {
        String s = Integer.toHexString(v & 0xffff).toUpperCase();
        while (s.length() < 4) s = "0" + s;
        return s;
    }

    private static String utf16Hex(char[] chars) {
        StringBuilder b = new StringBuilder(chars.length * 4);
        for (int i = 0; i < chars.length; i++) b.append(hex4(chars[i]));
        return b.toString();
    }

    private static String hex8(int v) {
        String s = Integer.toHexString(v).toUpperCase();
        while (s.length() < 8) s = "0" + s;
        return s;
    }

    private static String ints(int[] a) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < a.length; i++) {
            if (i != 0) b.append(',');
            b.append(a[i]);
        }
        return b.toString();
    }

    private static String glyphs(int[] a) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < a.length; i++) {
            if (i != 0) b.append(',');
            b.append(hex8(a[i]));
        }
        return b.toString();
    }

    private static String posBits(float[] a) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < a.length; i++) {
            if (i != 0) b.append(',');
            b.append(hex8(Float.floatToIntBits(a[i])));
        }
        return b.toString();
    }

    private static String pos64(float[] a) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < a.length; i++) {
            if (i != 0) b.append(',');
            b.append(Math.round(a[i] * 64.0f));
        }
        return b.toString();
    }

    private static int engineFlags(char[] chars, int start, int limit) {
        for (int i = start; i < limit; i++) {
            int ch = chars[i];
            if (Character.isHighSurrogate((char)ch) && i < limit - 1 &&
                Character.isLowSurrogate(chars[i + 1])) {
                ch = Character.toCodePoint((char)ch, chars[++i]);
            }
            int gc = Character.getType(ch);
            if (gc == Character.NON_SPACING_MARK ||
                gc == Character.ENCLOSING_MARK ||
                gc == Character.COMBINING_SPACING_MARK) {
                return 0x4;
            }
        }
        return 0;
    }

    private static List scriptRuns(char[] chars) throws Exception {
        Class<?> sr = Class.forName("sun.font.ScriptRun");
        Constructor<?> ctor = sr.getConstructor(new Class<?>[] {
            char[].class, Integer.TYPE, Integer.TYPE
        });
        Object it = ctor.newInstance(new Object[] {
            chars, Integer.valueOf(0), Integer.valueOf(chars.length)
        });
        Method next = sr.getMethod("next", new Class<?>[0]);
        Method getStart = sr.getMethod("getScriptStart", new Class<?>[0]);
        Method getLimit = sr.getMethod("getScriptLimit", new Class<?>[0]);
        Method getCode = sr.getMethod("getScriptCode", new Class<?>[0]);
        List out = new ArrayList();
        while (((Boolean)next.invoke(it, new Object[0])).booleanValue()) {
            RunRec r = new RunRec();
            r.start = ((Integer)getStart.invoke(it, new Object[0])).intValue();
            r.limit = ((Integer)getLimit.invoke(it, new Object[0])).intValue();
            r.script = ((Integer)getCode.invoke(it, new Object[0])).intValue();
            r.flags = engineFlags(chars, r.start, r.limit);
            out.add(r);
        }
        return out;
    }

    private static String runs(List runs) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < runs.size(); i++) {
            RunRec r = (RunRec)runs.get(i);
            if (i != 0) b.append('|');
            b.append(r.start).append(':').append(r.limit).append(':')
             .append(r.script).append(':').append(r.flags);
        }
        return b.toString();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("usage: <font.ttf> <out.tsv>");
        }

        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0]));
        BufferedImage bi = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = bi.createGraphics();
        FontRenderContext frc = g.getFontRenderContext();

        BufferedWriter out = new BufferedWriter(new FileWriter(args[1]));
        out.write("CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tUTF16HEX\tRUNS\tGLYPH_COUNT\tGLYPHS\tINDICES\tPOS_BITS\tPOS64\n");

        int cases = 0;
        int totalRuns = 0;
        int combiningFlagRuns = 0;
        for (int style = 0; style <= 7; style++) {
            for (int zi = 0; zi < SIZES.length; zi++) {
                int size = SIZES[zi];
                Font f = root.deriveFont(style, (float)size);
                for (int si = 0; si < SAMPLES.length; si++) {
                    String s = SAMPLES[si];
                    char[] ca = s.toCharArray();
                    List rs = scriptRuns(ca);
                    for (int ri = 0; ri < rs.size(); ri++) {
                        RunRec rr = (RunRec)rs.get(ri);
                        totalRuns++;
                        if ((rr.flags & 0x4) != 0) combiningFlagRuns++;
                    }

                    GlyphVector gv = f.layoutGlyphVector(
                        frc, ca, 0, ca.length, Font.LAYOUT_LEFT_TO_RIGHT);
                    int gc = gv.getNumGlyphs();
                    int[] codes = gv.getGlyphCodes(0, gc, null);
                    int[] indices = gv.getGlyphCharIndices(0, gc, null);
                    float[] positions = gv.getGlyphPositions(0, gc + 1, null);

                    out.write(Integer.toString(cases)); out.write('\t');
                    out.write(Integer.toString(style)); out.write('\t');
                    out.write(Integer.toString(f.getStyle())); out.write('\t');
                    out.write(Integer.toString(size)); out.write('\t');
                    out.write(Integer.toString(SAMPLE_IDS[si])); out.write('\t');
                    out.write(utf16Hex(ca)); out.write('\t');
                    out.write(runs(rs)); out.write('\t');
                    out.write(Integer.toString(gc)); out.write('\t');
                    out.write(glyphs(codes)); out.write('\t');
                    out.write(ints(indices)); out.write('\t');
                    out.write(posBits(positions)); out.write('\t');
                    out.write(pos64(positions)); out.newLine();
                    cases++;
                }
            }
        }
        out.close();
        g.dispose();

        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_BOOT=PASS");
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_CASES=" + cases);
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_RUNS=" + totalRuns);
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_COMBINING_FLAG_RUNS=" + combiningFlagRuns);
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_DIRECTION=LTR");
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_LANGUAGE=-1");
        System.out.println("P2B_JDK8_LAYOUTENGINE_SEMANTIC_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
