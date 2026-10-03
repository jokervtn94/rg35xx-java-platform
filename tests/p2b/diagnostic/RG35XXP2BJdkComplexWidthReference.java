import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.font.TextLayout;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/** Audit-only decomposition of the exact JDK8 complex stringWidth path. */
public final class RG35XXP2BJdkComplexWidthReference {
    private static final String[] SAMPLES = new String[] {
        "Tie\u0302\u0301ng Vie\u0323\u0302t", "A\u0301", "سلام", "لا",
        "שלום", "नमस्ते", "ภาษาไทย", "A\u200DB"
    };
    private static final int[] SAMPLE_IDS = new int[] {5,6,7,8,9,10,11,13};
    private static final int[] SIZES = new int[] {12,14,16};

    private static Field field(Class<?> c, String n) throws Exception {
        for (Class<?> k=c;k!=null;k=k.getSuperclass()) try {
            Field f=k.getDeclaredField(n); f.setAccessible(true); return f;
        } catch (NoSuchFieldException e) { }
        throw new NoSuchFieldException(n);
    }
    private static Method method(Class<?> c, String n, Class<?>[] s) throws Exception {
        for (Class<?> k=c;k!=null;k=k.getSuperclass()) try {
            Method m=k.getDeclaredMethod(n,s); m.setAccessible(true); return m;
        } catch (NoSuchMethodException e) { }
        throw new NoSuchMethodException(n);
    }
    private static String bits(float f) {
        String s=Integer.toHexString(Float.floatToIntBits(f)).toUpperCase();
        while(s.length()<8)s="0"+s; return s;
    }
    private static float f(Object o, String n) throws Exception { return field(o.getClass(),n).getFloat(o); }
    private static int i(Object o, String n) throws Exception { return field(o.getClass(),n).getInt(o); }

    public static void main(String[] args) throws Exception {
        if(args.length!=1) throw new IllegalArgumentException("usage: <font.ttf>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0]));
        BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics();
        FontRenderContext frc=g.getFontRenderContext();
        int cases=0, padZero=0, padNonzero=0, widthRoundExact=0;
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_BOOT=PASS");
        for(int style=0;style<=7;style++) for(int size:SIZES) {
            Font font=root.deriveFont(style,(float)size);
            g.setFont(font); FontMetrics fm=g.getFontMetrics();
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si];
                TextLayout tl=new TextLayout(s,font,frc);
                Object line=field(TextLayout.class,"textLine").get(tl);
                Object[] comps=(Object[])field(line.getClass(),"fComponents").get(line);
                int[] order=(int[])field(line.getClass(),"fComponentVisualOrder").get(line);
                if(comps.length!=1) throw new IllegalStateException("components="+comps.length);
                int li=(order==null)?0:order[0]; Object comp=comps[li];
                float componentAdvance=((Float)method(comp.getClass(),"getAdvance",new Class<?>[0]).invoke(comp,new Object[0])).floatValue();
                Object cm=method(comp.getClass(),"getCoreMetrics",new Class<?>[0]).invoke(comp,new Object[0]);
                GlyphVector gv=(GlyphVector)method(comp.getClass(),"getGV",new Class<?>[0]).invoke(comp,new Object[0]);
                int gc=gv.getNumGlyphs(); float[] pos=gv.getGlyphPositions(0,gc+1,null);
                float gvEndX=pos[gc*2], gvEndY=pos[gc*2+1];
                float advance=tl.getAdvance(); float pad=advance-componentAdvance;
                int width=fm.stringWidth(s); int rounded=(int)(0.5+advance);
                if(Float.floatToIntBits(pad)==Float.floatToIntBits(0.0f))padZero++; else padNonzero++;
                if(width==rounded)widthRoundExact++;
                System.out.println("P2B_JDK8_COMPLEX_WIDTH CASE="+cases+" STYLE="+style+" NORMALIZED="+font.getStyle()+" SIZE="+size+" SAMPLE="+SAMPLE_IDS[si]+
                    " WIDTH="+width+" ROUND="+rounded+" ADV="+bits(advance)+" COMP_ADV="+bits(componentAdvance)+" PAD="+bits(pad)+
                    " GV_END_X="+bits(gvEndX)+" GV_END_Y="+bits(gvEndY)+" CM_ASC="+bits(f(cm,"ascent"))+" CM_DESC="+bits(f(cm,"descent"))+
                    " CM_LEAD="+bits(f(cm,"leading"))+" CM_SS="+bits(f(cm,"ssOffset"))+" CM_ITALIC="+bits(f(cm,"italicAngle"))+" CM_BASE="+i(cm,"baselineIndex"));
                cases++;
            }
        }
        g.dispose();
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_CASES="+cases);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_PAD_ZERO="+padZero);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_PAD_NONZERO="+padNonzero);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_ROUND_EXACT="+widthRoundExact);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
