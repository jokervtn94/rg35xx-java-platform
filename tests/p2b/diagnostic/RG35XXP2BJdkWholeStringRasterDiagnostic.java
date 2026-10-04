import java.awt.Font;
import java.awt.FontMetrics;
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
 * Audit-only exact JDK8 Graphics2D.drawString raster reference for the full
 * established P2B 14-string corpus. For complex strings it also records the
 * exact one-component TextLayout flags plus ScriptRun engine records needed
 * to reproduce the native JDK8 layout path. Runtime code must not depend on
 * this class.
 */
public final class RG35XXP2BJdkWholeStringRasterDiagnostic {
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
    private static final int[] SIZES = new int[] {12,14,16};
    private static final int W=512, H=192, X=64, BASE=112;
    private static final long FNV_OFFSET=0xcbf29ce484222325L;
    private static final long FNV_PRIME=0x100000001b3L;

    private static final class RunRec {
        int start;
        int limit;
        int script;
        int flags;
    }

    private static Method findMethod(Class<?> c,String name,Class<?>[] sig) throws Exception {
        for(Class<?> k=c;k!=null;k=k.getSuperclass()) {
            try { Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m; }
            catch(NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }
    private static Field findField(Class<?> c,String name) throws Exception {
        for(Class<?> k=c;k!=null;k=k.getSuperclass()) {
            try { Field f=k.getDeclaredField(name); f.setAccessible(true); return f; }
            catch(NoSuchFieldException e) { }
        }
        throw new NoSuchFieldException(c.getName()+"."+name);
    }
    private static long mix(long h,int v) {
        h^=(v>>>24)&255;h*=FNV_PRIME; h^=(v>>>16)&255;h*=FNV_PRIME;
        h^=(v>>>8)&255;h*=FNV_PRIME; h^=v&255;h*=FNV_PRIME; return h;
    }
    private static String hex4(int v) {
        String s=Integer.toHexString(v&0xffff).toUpperCase(); while(s.length()<4)s="0"+s; return s;
    }
    private static String utf16Hex(char[] a) {
        StringBuilder b=new StringBuilder(a.length*4); for(int i=0;i<a.length;i++)b.append(hex4(a[i])); return b.toString();
    }
    private static boolean drawComplex(Method charsToGlyphsNS,Object mapper,char[] chars) throws Exception {
        int[] glyphs=new int[chars.length];
        return ((Boolean)charsToGlyphsNS.invoke(mapper,new Object[]{Integer.valueOf(chars.length),chars,glyphs})).booleanValue();
    }
    private static int engineFlags(char[] chars,int start,int limit) {
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
    private static List scriptRuns(char[] chars) throws Exception {
        Class<?> sr=Class.forName("sun.font.ScriptRun");
        Constructor<?> ctor=sr.getConstructor(new Class<?>[]{char[].class,Integer.TYPE,Integer.TYPE});
        Object it=ctor.newInstance(new Object[]{chars,Integer.valueOf(0),Integer.valueOf(chars.length)});
        Method next=sr.getMethod("next",new Class<?>[0]);
        Method getStart=sr.getMethod("getScriptStart",new Class<?>[0]);
        Method getLimit=sr.getMethod("getScriptLimit",new Class<?>[0]);
        Method getCode=sr.getMethod("getScriptCode",new Class<?>[0]);
        List out=new ArrayList();
        while(((Boolean)next.invoke(it,new Object[0])).booleanValue()) {
            RunRec r=new RunRec();
            r.start=((Integer)getStart.invoke(it,new Object[0])).intValue();
            r.limit=((Integer)getLimit.invoke(it,new Object[0])).intValue();
            r.script=((Integer)getCode.invoke(it,new Object[0])).intValue();
            r.flags=engineFlags(chars,r.start,r.limit);
            out.add(r);
        }
        return out;
    }
    private static String runsString(List runs) {
        StringBuilder b=new StringBuilder();
        for(int i=0;i<runs.size();i++) {
            RunRec r=(RunRec)runs.get(i);
            if(i!=0)b.append('|');
            b.append(r.start).append(':').append(r.limit).append(':').append(r.script).append(':').append(r.flags);
        }
        return b.toString();
    }
    private static int textLayoutFlags(String s,Font f,FontRenderContext frc,char[] chars) throws Exception {
        TextLayout tl=new TextLayout(s,f,frc);
        Object line=findField(TextLayout.class,"textLine").get(tl);
        Object[] comps=(Object[])findField(line.getClass(),"fComponents").get(line);
        int[] order=(int[])findField(line.getClass(),"fComponentVisualOrder").get(line);
        if(comps.length!=1) throw new IllegalStateException("P2B complex corpus expected one TextLayout component, got "+comps.length);
        int li=(order==null)?0:order[0];
        Object comp=comps[li];
        Object source=findField(comp.getClass(),"source").get(comp);
        int start=((Integer)findMethod(source.getClass(),"getStart",new Class<?>[0]).invoke(source,new Object[0])).intValue();
        int len=((Integer)findMethod(source.getClass(),"getLength",new Class<?>[0]).invoke(source,new Object[0])).intValue();
        int flags=((Integer)findMethod(source.getClass(),"getLayoutFlags",new Class<?>[0]).invoke(source,new Object[0])).intValue();
        if(start!=0 || len!=chars.length) throw new IllegalStateException("unexpected TextLayout source slice "+start+"+"+len+"/"+chars.length);
        return flags;
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=2) throw new IllegalArgumentException("usage: <font.ttf> <reference.tsv>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0]));
        Class<?> fu=Class.forName("sun.font.FontUtilities");
        Method getFont2D=fu.getDeclaredMethod("getFont2D",new Class<?>[]{Font.class}); getFont2D.setAccessible(true);
        BufferedImage fri=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
        Graphics2D frg=fri.createGraphics();
        FontRenderContext frc=frg.getFontRenderContext();
        frg.dispose();
        BufferedWriter out=new BufferedWriter(new FileWriter(args[1]));
        out.write("CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tDRAW_COMPLEX\tUTF16HEX\tWIDTH\tINK\tX0\tY0\tX1\tY1\tFP\tLAYOUT_FLAGS\tRUNS\n");
        int cases=0,complexCases=0,directCases=0,rtlCases=0;
        System.out.println("P2B_JDK8_WHOLE_RASTER_BOOT=PASS");
        for(int style=0;style<=7;style++) for(int zi=0;zi<SIZES.length;zi++) {
            int size=SIZES[zi]; Font f=root.deriveFont(style,(float)size);
            BufferedImage mi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
            Graphics2D mg=mi.createGraphics(); mg.setFont(f); FontMetrics fm=mg.getFontMetrics(); mg.dispose();
            Object f2d=getFont2D.invoke(null,new Object[]{f});
            Method gm=findMethod(f2d.getClass(),"getMapper",new Class<?>[0]);
            Object mapper=gm.invoke(f2d,new Object[0]);
            Method c2g=findMethod(mapper.getClass(),"charsToGlyphsNS",new Class<?>[]{Integer.TYPE,char[].class,int[].class});
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si]; char[] ca=s.toCharArray(); boolean complex=drawComplex(c2g,mapper,ca);
                int layoutFlags=0; String runs="-";
                if(complex) {
                    complexCases++;
                    layoutFlags=textLayoutFlags(s,f,frc,ca);
                    if((layoutFlags & Font.LAYOUT_RIGHT_TO_LEFT)!=0) rtlCases++;
                    runs=runsString(scriptRuns(ca));
                } else directCases++;
                BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
                Graphics2D g=bi.createGraphics(); g.setFont(f); g.setColor(new java.awt.Color(0,0,0,255)); g.drawString(s,X,BASE); g.dispose();
                int ink=0,x0=99999,y0=99999,x1=-99999,y1=-99999; long fp=FNV_OFFSET;
                for(int y=0;y<H;y++) for(int x=0;x<W;x++) {
                    if(((bi.getRGB(x,y)>>>24)&255)!=0) {
                        int rx=x-X, ry=y-BASE; ink++;
                        if(rx<x0)x0=rx; if(rx>x1)x1=rx; if(ry<y0)y0=ry; if(ry>y1)y1=ry;
                        fp=mix(fp,rx); fp=mix(fp,ry);
                    }
                }
                if(ink==0)x0=y0=x1=y1=-1;
                out.write(Integer.toString(cases));out.write('\t');
                out.write(Integer.toString(style));out.write('\t');
                out.write(Integer.toString(f.getStyle()));out.write('\t');
                out.write(Integer.toString(size));out.write('\t');
                out.write(Integer.toString(si));out.write('\t');
                out.write(complex?"1":"0");out.write('\t');
                out.write(utf16Hex(ca));out.write('\t');
                out.write(Integer.toString(fm.stringWidth(s)));out.write('\t');
                out.write(Integer.toString(ink));out.write('\t');
                out.write(Integer.toString(x0));out.write('\t');out.write(Integer.toString(y0));out.write('\t');
                out.write(Integer.toString(x1));out.write('\t');out.write(Integer.toString(y1));out.write('\t');
                out.write(Long.toHexString(fp));out.write('\t');
                out.write(Integer.toString(layoutFlags));out.write('\t');
                out.write(runs);out.newLine();
                cases++;
            }
        }
        out.close();
        System.out.println("P2B_JDK8_WHOLE_RASTER_CASES="+cases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_COMPLEX_CASES="+complexCases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_DIRECT_CASES="+directCases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_RTL_CASES="+rtlCases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
