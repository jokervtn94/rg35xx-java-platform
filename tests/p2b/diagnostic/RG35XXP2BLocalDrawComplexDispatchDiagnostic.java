import java.awt.Font;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * Audit-only source-derived reconstruction of OpenJDK8u504
 * TrueTypeGlyphMapper.charsToGlyphsNS draw-layout dispatch.
 *
 * It intentionally does not shape or render. The local side combines valid
 * UTF-16 surrogate pairs exactly as TrueTypeGlyphMapper does and applies only
 * the exact FontUtilities.isComplexCharCode ranges. No java.lang.Character
 * classification is used by the local dispatcher.
 */
public final class RG35XXP2BLocalDrawComplexDispatchDiagnostic {
    private static final int HI_START=0xD800, HI_END=0xDBFF;
    private static final int LO_START=0xDC00, LO_END=0xDFFF;
    private static final int MIN_LAYOUT=0x0300;

    private static Method findMethod(Class c,String name,Class[] sig) throws Exception {
        for(Class k=c;k!=null;k=k.getSuperclass()) {
            try { Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m; }
            catch(NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }

    private static boolean localComplexCode(int code) {
        if(code<0x0300 || code>0x206F) return false;
        if(code<=0x036F) return true;
        if(code<0x0590) return false;
        if(code<=0x06FF) return true;
        if(code<0x0900) return false;
        if(code<=0x0E7F) return true;
        if(code<0x0F00) return false;
        if(code<=0x0FFF) return true;
        if(code<0x1100) return false;
        if(code<0x11FF) return true;
        if(code<0x1780) return false;
        if(code<=0x17FF) return true;
        if(code<0x200C) return false;
        if(code<=0x200D) return true;
        if(code>=0x202A && code<=0x202E) return true;
        if(code>=0x206A && code<=0x206F) return true;
        return false;
    }

    public static boolean localDrawComplex(char[] chars) {
        for(int i=0;i<chars.length;i++) {
            int code=chars[i];
            if(code>=HI_START && code<=HI_END && i<chars.length-1) {
                int low=chars[i+1];
                if(low>=LO_START && low<=LO_END) {
                    code=(code-HI_START)*0x400 + low-LO_START + 0x10000;
                }
            }
            if(code<MIN_LAYOUT) continue;
            if(localComplexCode(code)) return true;
            if(code>=0x10000) { i++; continue; }
        }
        return false;
    }

    private static boolean mapperDraw(Method m,Object mapper,char[] chars) throws Exception {
        int[] glyphs=new int[chars.length];
        return ((Boolean)m.invoke(mapper,new Object[]{Integer.valueOf(chars.length),chars,glyphs})).booleanValue();
    }

    private static int next(int x) { return x*1103515245+12345; }

    public static void main(String[] args) throws Exception {
        if(args.length!=1) throw new IllegalArgumentException("usage: <font.ttf>");
        Class fu=Class.forName("sun.font.FontUtilities");
        Method complex=fu.getDeclaredMethod("isComplexCharCode",new Class[]{Integer.TYPE}); complex.setAccessible(true);
        Method getFont2D=fu.getDeclaredMethod("getFont2D",new Class[]{Font.class}); getFont2D.setAccessible(true);
        Font f=Font.createFont(Font.TRUETYPE_FONT,new File(args[0])).deriveFont(Font.PLAIN,12f);
        Object f2d=getFont2D.invoke(null,new Object[]{f});
        Method gm=findMethod(f2d.getClass(),"getMapper",new Class[0]);
        Object mapper=gm.invoke(f2d,new Object[0]);
        Method c2g=findMethod(mapper.getClass(),"charsToGlyphsNS",new Class[]{Integer.TYPE,char[].class,int[].class});

        int codeMismatch=0,complexCodes=0;
        for(int cp=0;cp<=0x10FFFF;cp++) {
            boolean r=((Boolean)complex.invoke(null,new Object[]{Integer.valueOf(cp)})).booleanValue();
            boolean l=localComplexCode(cp);
            if(r) complexCodes++;
            if(r!=l) {
                codeMismatch++;
                if(codeMismatch<=16) System.out.println("COMPLEX_CODE_MISMATCH=U+"+Integer.toHexString(cp));
            }
        }

        int bmpMismatch=0,bmpComplex=0;
        for(int cp=0;cp<=0xFFFF;cp++) {
            char[] a=new char[]{'A',(char)cp,'B'};
            boolean r=mapperDraw(c2g,mapper,a), l=localDrawComplex(a);
            if(r) bmpComplex++;
            if(r!=l) {
                bmpMismatch++;
                if(bmpMismatch<=16) System.out.println("BMP_DISPATCH_MISMATCH=U+"+Integer.toHexString(cp)+" ref="+r+" local="+l);
            }
        }

        String[] fixed=new String[]{
            "ABCxyz09","AVATAR","ToTo","ffi","Tiếng Việt","Tie\u0302\u0301ng Vie\u0323\u0302t","A\u0301",
            "سلام","لا","שלום","नमस्ते","ภาษาไทย","中文","A\u200DB",
            "abc שלום 123","abc العربية 123 עברית","A\uD800\uDF48B","A\uD83D\uDE00B",
            new String(new char[]{'A','\uD800','B'}),new String(new char[]{'A','\uDC00','B'}),
            "\u202Aabc\u202C","\u202BABC 123 שלום\u202C","\u206Aabc\u206F"
        };
        int fixedMismatch=0;
        for(int i=0;i<fixed.length;i++) {
            char[] a=fixed[i].toCharArray();
            boolean r=mapperDraw(c2g,mapper,a), l=localDrawComplex(a);
            if(r!=l) { fixedMismatch++; System.out.println("FIXED_DISPATCH_MISMATCH="+i); }
        }

        String[] tok=new String[]{
            "A","z","0","1"," ",".",",","\u0301","א","ש","ם","س","ل","م","ك","क","्","त","ग","า","ก","中","文",
            "あ","ア","α","Я","(",")","[","]","<",">","\u200C","\u200D","\u200E","\u200F","\u202A","\u202B","\u202C","\u202D","\u202E",
            "\u206A","\u206B","\u206C","\u206D","\u206E","\u206F","\uD800\uDF48","\uD83D\uDE00","\uD800","\uDC00"
        };
        int state=0x61c88647,randomMismatch=0,randomComplex=0;
        final int RANDOM_CASES=16384;
        for(int q=0;q<RANDOM_CASES;q++) {
            state=next(state); int parts=1+((state>>>1)&31); StringBuffer b=new StringBuffer();
            for(int j=0;j<parts;j++){state=next(state); b.append(tok[(state>>>1)%tok.length]);}
            char[] a=b.toString().toCharArray();
            boolean r=mapperDraw(c2g,mapper,a), l=localDrawComplex(a);
            if(r) randomComplex++;
            if(r!=l) {
                randomMismatch++;
                if(randomMismatch<=16) System.out.println("RANDOM_DISPATCH_MISMATCH="+q);
            }
        }

        System.out.println("P2B_LOCAL_DRAW_COMPLEX_BOOT=PASS");
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_FONT2D="+f2d.getClass().getName());
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_MAPPER="+mapper.getClass().getName());
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_CODEPOINTS=1114112");
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_CODE_TRUE="+complexCodes);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_CODE_MISMATCH_COUNT="+codeMismatch);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_BMP_CASES=65536");
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_BMP_TRUE="+bmpComplex);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_BMP_MISMATCH_COUNT="+bmpMismatch);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_FIXED_CASES="+fixed.length);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_FIXED_MISMATCH_COUNT="+fixedMismatch);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_RANDOM_CASES="+RANDOM_CASES);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_RANDOM_TRUE="+randomComplex);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_RANDOM_MISMATCH_COUNT="+randomMismatch);
        int total=codeMismatch+bmpMismatch+fixedMismatch+randomMismatch;
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_MISMATCH_COUNT="+total);
        if(total!=0) throw new RuntimeException("draw complex dispatch mismatch="+total);
        System.out.println("P2B_LOCAL_DRAW_COMPLEX_DIFFERENTIAL=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
