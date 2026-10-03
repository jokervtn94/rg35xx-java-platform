import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.TextLayout;
import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

/**
 * Audit-only exact JDK8 reference for the generic P2B TextLayout planner gap.
 *
 * This class does not implement an RG35XX planner. It only records the exact
 * JDK8 fast TextLayout component plan and nested ScriptRun plan for an expanded
 * mixed-script/mixed-bidi corpus. Runtime/production code must not depend on it.
 */
public final class RG35XXP2BJdkTextLayoutExpandedPlanReference {
    private static final String[] IDS = new String[] {
        "ASCII",
        "VIET_COMBINING",
        "ARABIC",
        "HEBREW",
        "DEVANAGARI",
        "THAI",
        "CJK_KANA",
        "LATIN_CYRILLIC_GREEK",
        "LATIN_HEBREW_NUM",
        "HEBREW_LATIN",
        "LATIN_ARABIC_NUM_HEBREW",
        "RTL_NUM_MIX",
        "PAIRED_MULTI_RTL",
        "LTR_RTL_PAIRED",
        "EMBED_LTR",
        "EMBED_RTL",
        "OVERRIDE_RTL",
        "LRM_RLM",
        "ZWJ",
        "ZWNJ",
        "SUPPLEMENTARY_GOTHIC",
        "SUPPLEMENTARY_EMOJI",
        "MULTISCRIPT_COMBINING",
        "MULTISCRIPT_MULTIBIDI"
    };

    private static final String[] SAMPLES = new String[] {
        "ABC xyz 123",
        "Tie\u0302\u0301ng Vie\u0323\u0302t",
        "سلام",
        "שלום",
        "नमस्ते",
        "ภาษาไทย",
        "漢かなカナ",
        "A(Б)Γ",
        "abc שלום 123",
        "שלום abc",
        "abc العربية 123 עברית",
        "123 אבג 456 العربية XYZ",
        "(abc) [שלום] <سلام>",
        "(A[שלום]ب)",
        "\u202Aabc שלום 123\u202C",
        "\u202BABC 123 שלום\u202C",
        "\u202EABC 123\u202C",
        "\u200Fשלום\u200EABC",
        "A\u200Dسلام",
        "A\u200Cسلام",
        "A\uD800\uDF48B",
        "A\uD83D\uDE00שלום",
        "A\u0301 Б\u0301 α\u0301 नमस्ते",
        "Latin العربية Devanagari नमस्ते Hebrew שלום 123"
    };

    private static Field findField(Class c, String name) throws Exception {
        for (Class k=c; k!=null; k=k.getSuperclass()) {
            try {
                Field f=k.getDeclaredField(name); f.setAccessible(true); return f;
            } catch (NoSuchFieldException e) { }
        }
        throw new NoSuchFieldException(c.getName()+"."+name);
    }

    private static Method findMethod(Class c, String name, Class[] sig) throws Exception {
        for (Class k=c; k!=null; k=k.getSuperclass()) {
            try {
                Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m;
            } catch (NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }

    private static String hex4(int v) {
        String s=Integer.toHexString(v & 0xffff).toUpperCase();
        while(s.length()<4)s="0"+s;
        return s;
    }

    private static String utf16Hex(char[] a) {
        StringBuffer b=new StringBuffer(a.length*4);
        for(int i=0;i<a.length;i++) b.append(hex4(a[i]));
        return b.toString();
    }

    private static String bytes(byte[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(a[i]&0xff); }
        return b.toString();
    }

    private static String ints(int[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(a[i]); }
        return b.toString();
    }

    private static int engineFlags(char[] chars, int start, int limit) {
        for(int i=start;i<limit;i++) {
            int ch=chars[i];
            if(Character.isHighSurrogate((char)ch) && i<limit-1 && Character.isLowSurrogate(chars[i+1])) {
                ch=Character.toCodePoint((char)ch,chars[++i]);
            }
            int gc=Character.getType(ch);
            if(gc==Character.NON_SPACING_MARK || gc==Character.ENCLOSING_MARK || gc==Character.COMBINING_SPACING_MARK) return 0x4;
        }
        return 0;
    }

    private static String scriptRuns(char[] chars,int start,int count) throws Exception {
        Class sr=Class.forName("sun.font.ScriptRun");
        Constructor ctor=sr.getConstructor(new Class[]{char[].class,Integer.TYPE,Integer.TYPE});
        Object it=ctor.newInstance(new Object[]{chars,Integer.valueOf(start),Integer.valueOf(count)});
        Method next=sr.getMethod("next",new Class[0]);
        Method gs=sr.getMethod("getScriptStart",new Class[0]);
        Method gl=sr.getMethod("getScriptLimit",new Class[0]);
        Method gc=sr.getMethod("getScriptCode",new Class[0]);
        StringBuffer b=new StringBuffer();
        int n=0;
        while(((Boolean)next.invoke(it,new Object[0])).booleanValue()) {
            int s=((Integer)gs.invoke(it,new Object[0])).intValue();
            int l=((Integer)gl.invoke(it,new Object[0])).intValue();
            int c=((Integer)gc.invoke(it,new Object[0])).intValue();
            if(n++!=0)b.append('|');
            b.append(s).append(':').append(l).append(':').append(c).append(':').append(engineFlags(chars,s,l));
        }
        return b.toString();
    }

    private static int scriptRunCount(String s) {
        if(s.length()==0) return 0;
        int n=1;
        for(int i=0;i<s.length();i++) if(s.charAt(i)=='|') n++;
        return n;
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=2) throw new IllegalArgumentException("usage: <font.ttf> <out.tsv>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0])).deriveFont(Font.PLAIN,14.0f);
        BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics();
        FontRenderContext frc=g.getFontRenderContext();

        Field textLineField=findField(TextLayout.class,"textLine");
        BufferedWriter out=new BufferedWriter(new FileWriter(args[1]));
        out.write("CASE\tID\tUTF16HEX\tLINE_LTR\tLEVELS\tCHAR_L2V\tCOMPONENT_VISUAL_ORDER\tCOMPONENTS\n");

        int cases=0;
        int multiComponentCases=0;
        int multiScriptCases=0;
        int mixedBidiCases=0;
        int lineRtlCases=0;
        int rtlComponents=0;
        int visualReorderedCases=0;
        int totalComponents=0;
        int totalScriptRuns=0;
        int combiningScriptRuns=0;

        for(int si=0;si<SAMPLES.length;si++) {
            String sample=SAMPLES[si];
            char[] chars=sample.toCharArray();
            TextLayout tl=new TextLayout(sample,root,frc);
            Object line=textLineField.get(tl);
            Object[] comps=(Object[])findField(line.getClass(),"fComponents").get(line);
            int[] order=(int[])findField(line.getClass(),"fComponentVisualOrder").get(line);
            int[] l2v=(int[])findField(line.getClass(),"fCharLogicalOrder").get(line);
            byte[] levels=(byte[])findField(line.getClass(),"fCharLevels").get(line);
            boolean lineLtr=((Boolean)findField(line.getClass(),"fIsDirectionLTR").get(line)).booleanValue();

            if(comps.length>1) multiComponentCases++;
            if(!lineLtr) lineRtlCases++;
            if(order!=null) visualReorderedCases++;
            if(levels!=null) {
                int first=levels.length==0?0:(levels[0]&0xff);
                boolean mixed=false;
                for(int i=1;i<levels.length;i++) if((levels[i]&0xff)!=first) { mixed=true; break; }
                if(mixed) mixedBidiCases++;
            }

            StringBuffer cp=new StringBuffer();
            int caseScriptRuns=0;
            for(int li=0;li<comps.length;li++) {
                Object comp=comps[li];
                Object source=findField(comp.getClass(),"source").get(comp);
                Method getStart=findMethod(source.getClass(),"getStart",new Class[0]);
                Method getLength=findMethod(source.getClass(),"getLength",new Class[0]);
                Method getFlags=findMethod(source.getClass(),"getLayoutFlags",new Class[0]);
                Method getLevel=findMethod(source.getClass(),"getBidiLevel",new Class[0]);
                int start=((Integer)getStart.invoke(source,new Object[0])).intValue();
                int len=((Integer)getLength.invoke(source,new Object[0])).intValue();
                int flags=((Integer)getFlags.invoke(source,new Object[0])).intValue();
                int level=((Integer)getLevel.invoke(source,new Object[0])).intValue();
                String sr=scriptRuns(chars,start,len);
                int src=scriptRunCount(sr);
                caseScriptRuns+=src;
                totalScriptRuns+=src;
                for(int p=0;p<sr.length()-1;p++) {
                    if(sr.charAt(p)==':' && sr.charAt(p+1)=='4' && (p+2==sr.length() || sr.charAt(p+2)=='|')) combiningScriptRuns++;
                }
                if((flags&1)!=0) rtlComponents++;
                if(li!=0) cp.append(';');
                cp.append(li).append(':').append(start).append(':').append(len).append(':').append(level).append(':').append(flags).append(':').append(sr);
                totalComponents++;
            }
            if(caseScriptRuns>1) multiScriptCases++;

            out.write(Integer.toString(cases)); out.write('\t');
            out.write(IDS[si]); out.write('\t');
            out.write(utf16Hex(chars)); out.write('\t');
            out.write(lineLtr?"1":"0"); out.write('\t');
            out.write(bytes(levels)); out.write('\t');
            out.write(ints(l2v)); out.write('\t');
            out.write(ints(order)); out.write('\t');
            out.write(cp.toString()); out.newLine();
            cases++;
        }
        out.close();
        g.dispose();

        System.out.println("P2B_JDK8_EXPANDED_PLAN_BOOT=PASS");
        System.out.println("P2B_JDK8_EXPANDED_PLAN_CASES="+cases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_TOTAL_COMPONENTS="+totalComponents);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_MULTI_COMPONENT_CASES="+multiComponentCases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_MULTI_SCRIPT_CASES="+multiScriptCases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_MIXED_BIDI_CASES="+mixedBidiCases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_LINE_RTL_CASES="+lineRtlCases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_RTL_COMPONENTS="+rtlComponents);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_VISUAL_REORDERED_CASES="+visualReorderedCases);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_SCRIPT_RUNS="+totalScriptRuns);
        System.out.println("P2B_JDK8_EXPANDED_PLAN_COMBINING_SCRIPT_RUNS="+combiningScriptRuns);
        if(multiComponentCases<=0 || multiScriptCases<=0 || mixedBidiCases<=0 || rtlComponents<=0 || visualReorderedCases<=0) {
            throw new RuntimeException("expanded planner corpus did not exercise required dimensions");
        }
        System.out.println("P2B_JDK8_EXPANDED_PLAN_CORPUS_COVERAGE=PASS");
        System.out.println("P2B_JDK8_EXPANDED_PLAN_REFERENCE_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
        System.out.println("P2B_DEVICE_PACKAGE=FORBIDDEN");
    }
}
