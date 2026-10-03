import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.lang.reflect.Method;

/** Diagnostic only. Emits the exact JDK8 complex-trigger set and compact
 * width/layout table used by R12. Runtime code must not depend on this class. */
public final class RG35XXP2BJdkComplexTableDiagnostic {
    private static String hex4(int v) {
        String s=Integer.toHexString(v).toUpperCase();
        while(s.length()<4)s="0"+s;
        return s;
    }
    private static int pos64(GlyphVector gv,int index) {
        return Math.round((float)gv.getGlyphPosition(index).getX()*64f);
    }
    public static void main(String[] args) throws Exception {
        if(args.length!=3) throw new IllegalArgumentException("usage: <font.ttf> <trigger.txt> <table.tsv>");
        Class<?> fu=Class.forName("sun.font.FontUtilities");
        Method nonSimple=fu.getDeclaredMethod("isNonSimpleChar",Character.TYPE);
        nonSimple.setAccessible(true);
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0])).deriveFont(Font.PLAIN,12f);
        int[] sizes=new int[]{12,14,16};
        BufferedWriter trig=new BufferedWriter(new FileWriter(args[1]));
        int triggerCount=0;
        for(int cp=0;cp<=0xFFFF;cp++) {
            if(((Boolean)nonSimple.invoke(null,Character.valueOf((char)cp))).booleanValue()) {
                trig.write(hex4(cp)); trig.newLine(); triggerCount++;
            }
        }
        trig.close();
        BufferedWriter out=new BufferedWriter(new FileWriter(args[2]));
        out.write("CP\tSIZE\tDISPLAY\tCHAR_WIDTH\tSUM_CHAR_WIDTH\tSTRING_WIDTH\tCHARS_WIDTH\tDIRECT_GLYPHS\tLAYOUT_GLYPHS\tDIRECT_ADV64\tLAYOUT_ADV64\n");
        int cases=0,widthDiff=0,layoutDiff=0;
        for(int zi=0;zi<sizes.length;zi++) {
            int size=sizes[zi];
            Font f=root.deriveFont(Font.PLAIN,(float)size);
            BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
            Graphics2D g=bi.createGraphics(); g.setFont(f);
            FontMetrics fm=g.getFontMetrics(); FontRenderContext frc=g.getFontRenderContext();
            for(int cp=0;cp<=0xFFFF;cp++) {
                char ch=(char)cp;
                if(!((Boolean)nonSimple.invoke(null,Character.valueOf(ch))).booleanValue()) continue;
                String s=new String(new char[]{'A',ch,'B'}); char[] ca=s.toCharArray();
                int sum=fm.charWidth('A')+fm.charWidth(ch)+fm.charWidth('B');
                int sw=fm.stringWidth(s), cw=fm.charsWidth(ca,0,ca.length);
                GlyphVector direct=f.createGlyphVector(frc,s);
                GlyphVector layout=f.layoutGlyphVector(frc,ca,0,ca.length,Font.LAYOUT_LEFT_TO_RIGHT);
                int da=pos64(direct,direct.getNumGlyphs()), la=pos64(layout,layout.getNumGlyphs());
                if(sw!=sum || cw!=sum) widthDiff++;
                if(direct.getNumGlyphs()!=layout.getNumGlyphs() || da!=la) layoutDiff++;
                out.write(hex4(cp)); out.write('\t'); out.write(Integer.toString(size)); out.write('\t');
                out.write(f.canDisplay(ch)?"1":"0"); out.write('\t'); out.write(Integer.toString(fm.charWidth(ch))); out.write('\t');
                out.write(Integer.toString(sum)); out.write('\t'); out.write(Integer.toString(sw)); out.write('\t'); out.write(Integer.toString(cw)); out.write('\t');
                out.write(Integer.toString(direct.getNumGlyphs())); out.write('\t'); out.write(Integer.toString(layout.getNumGlyphs())); out.write('\t');
                out.write(Integer.toString(da)); out.write('\t'); out.write(Integer.toString(la)); out.newLine();
                cases++;
            }
            g.dispose();
        }
        out.close();
        System.out.println("P2B_JDK_COMPLEX_TABLE_BOOT=PASS");
        System.out.println("P2B_JDK_COMPLEX_TRIGGER_UNITS="+triggerCount);
        System.out.println("P2B_JDK_COMPLEX_TABLE_CASES="+cases);
        System.out.println("P2B_JDK_COMPLEX_WIDTH_DIFF_CASES="+widthDiff);
        System.out.println("P2B_JDK_COMPLEX_LAYOUT_DIFF_CASES="+layoutDiff);
        System.out.println("P2B_JDK_COMPLEX_TABLE_RESULT=PASS");
    }
}
