import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.font.TextLayout;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/** Audit-only decomposition of the exact JDK8 TextLayout objects used by the
 * P2B complex drawString fallback. No runtime code depends on this class. */
public final class RG35XXP2BJdkTextLayoutComponentDiagnostic {
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
    private static final int[] SAMPLE_IDS = new int[] {5,6,7,8,9,10,11,13};
    private static final int[] SIZES = new int[] {12,14,16};

    private static Field findField(Class<?> c, String name) throws Exception {
        for (Class<?> k=c; k!=null; k=k.getSuperclass()) {
            try {
                Field f=k.getDeclaredField(name); f.setAccessible(true); return f;
            } catch (NoSuchFieldException e) { }
        }
        throw new NoSuchFieldException(c.getName()+"."+name);
    }
    private static Method findMethod(Class<?> c, String name, Class<?>[] sig) throws Exception {
        for (Class<?> k=c; k!=null; k=k.getSuperclass()) {
            try {
                Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m;
            } catch (NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }
    private static String hex8(int v) {
        String s=Integer.toHexString(v).toUpperCase(); while(s.length()<8)s="0"+s; return s;
    }
    private static String posBits(float[] a) {
        StringBuilder b=new StringBuilder();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(hex8(Float.floatToIntBits(a[i]))); }
        return b.toString();
    }
    private static String glyphs(int[] a) {
        StringBuilder b=new StringBuilder();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(hex8(a[i])); }
        return b.toString();
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=1) throw new IllegalArgumentException("usage: <font.ttf>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0]));
        BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics();
        FontRenderContext frc=g.getFontRenderContext();
        Field textLineField=findField(TextLayout.class,"textLine");
        int cases=0,componentsTotal=0,rtlComponents=0,multiComponentCases=0;
        System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT_BOOT=PASS");
        for(int zi=0;zi<SIZES.length;zi++) {
            int size=SIZES[zi]; Font f=root.deriveFont(Font.PLAIN,(float)size);
            for(int si=0;si<SAMPLES.length;si++) {
                TextLayout tl=new TextLayout(SAMPLES[si],f,frc);
                Object line=textLineField.get(tl);
                Object[] comps=(Object[])findField(line.getClass(),"fComponents").get(line);
                int[] order=(int[])findField(line.getClass(),"fComponentVisualOrder").get(line);
                float[] locs=(float[])findField(line.getClass(),"locs").get(line);
                if(comps.length>1) multiComponentCases++;
                System.out.println("P2B_JDK8_TEXTLAYOUT_CASE SIZE="+size+" SAMPLE="+SAMPLE_IDS[si]+" COMPONENTS="+comps.length+" ADV_BITS="+hex8(Float.floatToIntBits(tl.getAdvance())));
                for(int vi=0;vi<comps.length;vi++) {
                    int li=(order==null)?vi:order[vi];
                    Object comp=comps[li];
                    Field sourceField=findField(comp.getClass(),"source");
                    Object source=sourceField.get(comp);
                    Method getStart=findMethod(source.getClass(),"getStart",new Class<?>[0]);
                    Method getLength=findMethod(source.getClass(),"getLength",new Class<?>[0]);
                    Method getFlags=findMethod(source.getClass(),"getLayoutFlags",new Class<?>[0]);
                    int start=((Integer)getStart.invoke(source,new Object[0])).intValue();
                    int len=((Integer)getLength.invoke(source,new Object[0])).intValue();
                    int flags=((Integer)getFlags.invoke(source,new Object[0])).intValue();
                    Method getGV=findMethod(comp.getClass(),"getGV",new Class<?>[0]);
                    GlyphVector gv=(GlyphVector)getGV.invoke(comp,new Object[0]);
                    int gc=gv.getNumGlyphs();
                    int[] codes=gv.getGlyphCodes(0,gc,null);
                    float[] pos=gv.getGlyphPositions(0,gc+1,null);
                    if((flags & Font.LAYOUT_RIGHT_TO_LEFT)!=0) rtlComponents++;
                    System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT SIZE="+size+" SAMPLE="+SAMPLE_IDS[si]+" VIS="+vi+" LOG="+li+
                        " CLASS="+comp.getClass().getName()+" SOURCE="+source.getClass().getName()+
                        " START="+start+" LEN="+len+" FLAGS="+flags+
                        " ORIGIN_X_BITS="+hex8(Float.floatToIntBits(locs[vi*2]))+
                        " ORIGIN_Y_BITS="+hex8(Float.floatToIntBits(locs[vi*2+1]))+
                        " GLYPHS="+gc+" GLYPH_IDS="+glyphs(codes)+" POS_BITS="+posBits(pos));
                    componentsTotal++;
                }
                cases++;
            }
        }
        g.dispose();
        System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT_CASES="+cases);
        System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT_TOTAL="+componentsTotal);
        System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT_RTL="+rtlComponents);
        System.out.println("P2B_JDK8_TEXTLAYOUT_MULTI_COMPONENT_CASES="+multiComponentCases);
        System.out.println("P2B_JDK8_TEXTLAYOUT_COMPONENT_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
