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
public final class RG35XXP2BJdkComplexWidthDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "Tie\u0302\u0301ng Vie\u0323\u0302t", "A\u0301", "سلام", "لا",
        "שלום", "नमस्ते", "ภาษาไทย", "A\u200DB"
    };
    private static final int[] SAMPLE_IDS = new int[] {5,6,7,8,9,10,11,13};
    private static final int[] SIZES = new int[] {12,14,16};

    private static Field findField(Class<?> c,String name) throws Exception {
        for(Class<?> k=c;k!=null;k=k.getSuperclass()) try {
            Field f=k.getDeclaredField(name); f.setAccessible(true); return f;
        } catch(NoSuchFieldException e) { }
        throw new NoSuchFieldException(c.getName()+"."+name);
    }
    private static Method findMethod(Class<?> c,String name,Class<?>[] sig) throws Exception {
        for(Class<?> k=c;k!=null;k=k.getSuperclass()) try {
            Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m;
        } catch(NoSuchMethodException e) { }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }
    private static String bits(float v) {
        String s=Integer.toHexString(Float.floatToIntBits(v)).toUpperCase();
        while(s.length()<8)s="0"+s; return s;
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=1) throw new IllegalArgumentException("usage: <font.ttf>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0]));
        BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics();
        FontRenderContext frc=g.getFontRenderContext();
        Field textLineField=findField(TextLayout.class,"textLine");

        int cases=0,padded=0,roundedExact=0,componentExact=0,gvExact=0;
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_BOOT=PASS");
        for(int style=0;style<=7;style++) for(int zi=0;zi<SIZES.length;zi++) {
            int size=SIZES[zi]; Font f=root.deriveFont(style,(float)size);
            g.setFont(f); FontMetrics fm=g.getFontMetrics();
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si]; TextLayout tl=new TextLayout(s,f,frc);
                Object line=textLineField.get(tl);
                Object[] comps=(Object[])findField(line.getClass(),"fComponents").get(line);
                int[] order=(int[])findField(line.getClass(),"fComponentVisualOrder").get(line);
                if(comps.length!=1) throw new IllegalStateException("expected one component, got "+comps.length);
                int li=(order==null)?0:order[0]; Object comp=comps[li];
                float compAdvance=((Float)findMethod(comp.getClass(),"getAdvance",new Class<?>[0]).invoke(comp,new Object[0])).floatValue();
                Object cm=findMethod(comp.getClass(),"getCoreMetrics",new Class<?>[0]).invoke(comp,new Object[0]);
                GlyphVector gv=(GlyphVector)findMethod(comp.getClass(),"getGV",new Class<?>[0]).invoke(comp,new Object[0]);
                int gc=gv.getNumGlyphs(); float[] gp=gv.getGlyphPositions(0,gc+1,null);
                float gvEndX=gp[gc*2], gvEndY=gp[gc*2+1];
                float ascent=findField(cm.getClass(),"ascent").getFloat(cm);
                float descent=findField(cm.getClass(),"descent").getFloat(cm);
                float leading=findField(cm.getClass(),"leading").getFloat(cm);
                float ssOffset=findField(cm.getClass(),"ssOffset").getFloat(cm);
                float italicAngle=findField(cm.getClass(),"italicAngle").getFloat(cm);
                int baselineIndex=findField(cm.getClass(),"baselineIndex").getInt(cm);
                float advance=tl.getAdvance(); float pad=advance-compAdvance;
                int width=fm.stringWidth(s); int rounded=(int)(0.5f+advance);
                if(Float.floatToIntBits(pad)!=Float.floatToIntBits(0.0f)) padded++;
                if(width==rounded) roundedExact++;
                if(Float.floatToIntBits(advance)==Float.floatToIntBits(compAdvance)) componentExact++;
                if(Float.floatToIntBits(compAdvance)==Float.floatToIntBits(gvEndX)) gvExact++;
                System.out.println("P2B_JDK8_COMPLEX_WIDTH_CASE STYLE="+style+" NORMALIZED="+f.getStyle()+" SIZE="+size+" SAMPLE="+SAMPLE_IDS[si]+
                    " WIDTH="+width+" ADV_BITS="+bits(advance)+" COMP_ADV_BITS="+bits(compAdvance)+" PAD_BITS="+bits(pad)+
                    " GV_END_X_BITS="+bits(gvEndX)+" GV_END_Y_BITS="+bits(gvEndY)+
                    " ASCENT_BITS="+bits(ascent)+" DESCENT_BITS="+bits(descent)+" LEADING_BITS="+bits(leading)+
                    " SSOFF_BITS="+bits(ssOffset)+" ITALIC_BITS="+bits(italicAngle)+" BASELINE_INDEX="+baselineIndex);
                cases++;
            }
        }
        g.dispose();
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_CASES="+cases);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_PADDED_CASES="+padded);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_COMPONENT_ADV_EXACT_CASES="+componentExact);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_GV_END_EXACT_CASES="+gvExact);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_ROUNDING_EXACT_CASES="+roundedExact);
        System.out.println("P2B_JDK8_COMPLEX_WIDTH_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
