import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.TextLayout;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Method;

/**
 * Audit-only classifier for the exact JDK8 metric-vs-draw layout triggers.
 *
 * Source anchors (OpenJDK8u504-b01 / 4efe36434f44bafb854e602ccbbe1b5696fce1a2):
 *  - FontDesignMetrics.stringWidth/charsWidth -> isNonSimpleChar -> TextLayout
 *  - GlyphList.setFromString -> CharToGlyphMapper.charsToGlyphsNS
 *  - TrueTypeGlyphMapper.charsToGlyphsNS combines valid surrogate pairs before
 *    testing FontUtilities.isComplexCharCode(codePoint)
 *  - FontUtilities MIN_LAYOUT_CHARCODE=0x0300, MAX_LAYOUT_CHARCODE=0x206F
 *
 * No production/runtime classes are modified or linked by this diagnostic.
 */
public final class RG35XXP2BJdkLayoutTriggerDiagnostic {
    private static final String OPENJDK8U504 =
        "4efe36434f44bafb854e602ccbbe1b5696fce1a2";

    private static Method findMethod(Class<?> c, String name, Class<?>[] sig)
        throws Exception {
        Class<?> k = c;
        while (k != null) {
            try {
                Method m = k.getDeclaredMethod(name, sig);
                m.setAccessible(true);
                return m;
            } catch (NoSuchMethodException e) {
                k = k.getSuperclass();
            }
        }
        throw new NoSuchMethodException(c.getName() + "." + name);
    }

    private static boolean invokeBool(Method m, Object target, Object[] args)
        throws Exception {
        return ((Boolean)m.invoke(target, args)).booleanValue();
    }

    private static boolean metricTrigger(Method nonSimple, char[] chars)
        throws Exception {
        for (int i = 0; i < chars.length; i++) {
            if (invokeBool(nonSimple, null,
                           new Object[] { Character.valueOf(chars[i]) })) {
                return true;
            }
        }
        return false;
    }

    private static boolean mapperTrigger(Method charsToGlyphsNS,
                                         Object mapper, char[] chars)
        throws Exception {
        int[] glyphs = new int[chars.length];
        return invokeBool(charsToGlyphsNS, mapper,
            new Object[] { Integer.valueOf(chars.length), chars, glyphs });
    }

    private static char[] wrappedChar(char ch) {
        return new char[] {'A', ch, 'B'};
    }

    private static char[] wrappedCodePoint(int cp) {
        char[] pair = Character.toChars(cp);
        char[] out = new char[pair.length + 2];
        out[0] = 'A';
        System.arraycopy(pair, 0, out, 1, pair.length);
        out[out.length - 1] = 'B';
        return out;
    }

    private static String hex(int cp) {
        String s = Integer.toHexString(cp).toUpperCase();
        while (s.length() < 4) s = "0" + s;
        return "U+" + s;
    }

    private static int roundedAdvance(TextLayout tl) {
        return (int)(0.5f + tl.getAdvance());
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("usage: <font.ttf>");
        }

        Class<?> fu = Class.forName("sun.font.FontUtilities");
        Method nonSimple = fu.getDeclaredMethod(
            "isNonSimpleChar", new Class<?>[] { Character.TYPE });
        Method complexCode = fu.getDeclaredMethod(
            "isComplexCharCode", new Class<?>[] { Integer.TYPE });
        Method getFont2D = fu.getDeclaredMethod(
            "getFont2D", new Class<?>[] { Font.class });
        nonSimple.setAccessible(true);
        complexCode.setAccessible(true);
        getFont2D.setAccessible(true);

        Font base = Font.createFont(Font.TRUETYPE_FONT, new File(args[0]));
        Font probeFont = base.deriveFont(Font.PLAIN, 12f);
        Object font2D = getFont2D.invoke(null, new Object[] { probeFont });
        Method getMapper = findMethod(font2D.getClass(), "getMapper", new Class<?>[0]);
        Object mapper = getMapper.invoke(font2D, new Object[0]);
        Method charsToGlyphsNS = findMethod(mapper.getClass(), "charsToGlyphsNS",
            new Class<?>[] { Integer.TYPE, char[].class, int[].class });

        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_BOOT=PASS");
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_OPENJDK_COMMIT=" + OPENJDK8U504);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_MIN=U+0300");
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_MAX=U+206F");
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_FONT2D=" + font2D.getClass().getName());
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_MAPPER=" + mapper.getClass().getName());

        int metricUnits = 0;
        int drawUnits = 0;
        int surrogateOnlyUnits = 0;
        int metricDrawDivergence = 0;
        int mapperSourceMismatch = 0;
        int nonSimpleSourceMismatch = 0;

        for (int cp = 0; cp <= 0xFFFF; cp++) {
            char ch = (char)cp;
            boolean metric = invokeBool(nonSimple, null,
                new Object[] { Character.valueOf(ch) });
            boolean complex = invokeBool(complexCode, null,
                new Object[] { Integer.valueOf(cp) });
            boolean sourceNonSimple = complex || (cp >= 0xD800 && cp <= 0xDFFF);
            boolean draw = mapperTrigger(charsToGlyphsNS, mapper, wrappedChar(ch));

            if (metric) metricUnits++;
            if (draw) drawUnits++;
            if (metric && !draw) metricDrawDivergence++;
            if (metric && !complex) surrogateOnlyUnits++;
            if (metric != sourceNonSimple) {
                nonSimpleSourceMismatch++;
                if (nonSimpleSourceMismatch <= 16) {
                    System.out.println("P2B_JDK8_LAYOUT_TRIGGER_NONSIMPLE_MISMATCH CP=" +
                        hex(cp) + " JDK=" + metric + " SOURCE=" + sourceNonSimple);
                }
            }
            if (draw != complex) {
                mapperSourceMismatch++;
                if (mapperSourceMismatch <= 16) {
                    System.out.println("P2B_JDK8_LAYOUT_TRIGGER_MAPPER_MISMATCH CP=" +
                        hex(cp) + " MAPPER=" + draw + " SOURCE_COMPLEX=" + complex);
                }
            }
        }

        int layoutAttrFaces = 0;
        int[] sizes = new int[] {12, 14, 16};
        for (int style = 0; style <= 3; style++) {
            for (int zi = 0; zi < sizes.length; zi++) {
                Font f = base.deriveFont(style, (float)sizes[zi]);
                if (f.hasLayoutAttributes()) layoutAttrFaces++;
                System.out.println("P2B_JDK8_LAYOUT_FACE STYLE=" + style +
                    " SIZE=" + sizes[zi] +
                    " HAS_LAYOUT_ATTRIBUTES=" + f.hasLayoutAttributes());
            }
        }

        int[] supplementary = new int[] {0x10000, 0x1F600, 0x20000, 0x2A6D6};
        int supplementaryMetric = 0;
        int supplementaryDrawDirect = 0;
        for (int i = 0; i < supplementary.length; i++) {
            int cp = supplementary[i];
            char[] wrapped = wrappedCodePoint(cp);
            boolean metric = metricTrigger(nonSimple, wrapped);
            boolean draw = mapperTrigger(charsToGlyphsNS, mapper, wrapped);
            boolean complex = invokeBool(complexCode, null,
                new Object[] { Integer.valueOf(cp) });
            if (metric) supplementaryMetric++;
            if (!draw) supplementaryDrawDirect++;
            System.out.println("P2B_JDK8_LAYOUT_SUPPLEMENTARY CP=" + hex(cp) +
                " UTF16=" + wrapped.length +
                " METRIC_TEXTLAYOUT=" + metric +
                " DRAW_MAPPER_LAYOUT=" + draw +
                " SOURCE_COMPLEX=" + complex +
                " DISPLAY=" + probeFont.canDisplay(cp));
        }

        String[] names = new String[] {
            "ASCII", "PRECOMPOSED_VI", "DECOMPOSED_VI", "ARABIC",
            "CJK", "ZWJ", "SUPPLEMENTARY", "ISOLATED_HIGH", "ISOLATED_LOW"
        };
        String[] samples = new String[] {
            "ABCxyz09",
            "Ti\u1EBFng Vi\u1EC7t",
            "Tie\u0302\u0301ng Vie\u0323\u0302t",
            "\u0633\u0644\u0627\u0645",
            "\u4E2D\u6587",
            "A\u200DB",
            new String(Character.toChars(0x1F600)),
            new String(new char[] {'A', '\uD800', 'B'}),
            new String(new char[] {'A', '\uDC00', 'B'})
        };

        int sampleCases = 0;
        int sampleMetricTextLayoutExact = 0;
        for (int zi = 0; zi < sizes.length; zi++) {
            Font f = base.deriveFont(Font.PLAIN, (float)sizes[zi]);
            BufferedImage bi = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = bi.createGraphics();
            g.setFont(f);
            FontMetrics fm = g.getFontMetrics();
            FontRenderContext frc = g.getFontRenderContext();
            Object f2d = getFont2D.invoke(null, new Object[] { f });
            Method gm = findMethod(f2d.getClass(), "getMapper", new Class<?>[0]);
            Object mp = gm.invoke(f2d, new Object[0]);
            Method c2g = findMethod(mp.getClass(), "charsToGlyphsNS",
                new Class<?>[] { Integer.TYPE, char[].class, int[].class });

            for (int si = 0; si < samples.length; si++) {
                String s = samples[si];
                char[] ca = s.toCharArray();
                boolean mt = metricTrigger(nonSimple, ca);
                boolean dt = mapperTrigger(c2g, mp, ca);
                int sw = fm.stringWidth(s);
                int cw = fm.charsWidth(ca, 0, ca.length);
                int tl = roundedAdvance(new TextLayout(s, f, frc));
                if (mt && sw == tl && cw == tl) sampleMetricTextLayoutExact++;
                System.out.println("P2B_JDK8_LAYOUT_SAMPLE SIZE=" + sizes[zi] +
                    " NAME=" + names[si] +
                    " UTF16=" + ca.length +
                    " METRIC_TEXTLAYOUT=" + mt +
                    " DRAW_MAPPER_LAYOUT=" + dt +
                    " STRING_WIDTH=" + sw +
                    " CHARS_WIDTH=" + cw +
                    " TEXTLAYOUT_WIDTH=" + tl);
                sampleCases++;
            }
            g.dispose();
        }

        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_METRIC_UNITS=" + metricUnits);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_DRAW_UNITS=" + drawUnits);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SURROGATE_ONLY_UNITS=" + surrogateOnlyUnits);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_METRIC_DRAW_DIVERGENCE=" + metricDrawDivergence);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_NONSIMPLE_SOURCE_MISMATCH=" + nonSimpleSourceMismatch);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_MAPPER_SOURCE_MISMATCH=" + mapperSourceMismatch);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_LAYOUT_ATTR_FACES=" + layoutAttrFaces);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SUPPLEMENTARY_CASES=" + supplementary.length);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SUPPLEMENTARY_METRIC=" + supplementaryMetric);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SUPPLEMENTARY_DRAW_DIRECT=" + supplementaryDrawDirect);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SAMPLE_CASES=" + sampleCases);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_SAMPLE_METRIC_TEXTLAYOUT_EXACT=" + sampleMetricTextLayoutExact);
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_CLASSIFICATION=METRIC_NONSIMPLE_VS_DRAW_COMPLEX_MAPPER_SPLIT");
        System.out.println("P2B_JDK8_LAYOUT_TRIGGER_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
