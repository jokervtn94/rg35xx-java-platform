import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;

/** Diagnostic only. Introspects the exact JDK8/AWT width/layout paths used by
 * pinned Miyoo without changing runtime code. */
public final class RG35XXP2BJdkLayoutPathDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09", "AVATAR", "ToTo", "ffi", "Tiếng Việt",
        "Tie\u0302\u0301ng Vie\u0323\u0302t", "A\u0301", "سلام", "لا", "שלום",
        "नमस्ते", "ภาษาไทย", "中文", "A\u200DB"
    };

    private static String glyphs(GlyphVector gv) {
        StringBuffer b=new StringBuffer();
        int n=gv.getNumGlyphs();
        for(int i=0;i<n;i++) {
            if(i!=0)b.append(',');
            b.append(gv.getGlyphCode(i));
        }
        return b.toString();
    }
    private static String positions(GlyphVector gv) {
        StringBuffer b=new StringBuffer();
        int n=gv.getNumGlyphs();
        for(int i=0;i<=n;i++) {
            if(i!=0)b.append(',');
            java.awt.geom.Point2D p=gv.getGlyphPosition(i);
            b.append(Math.round((float)p.getX()*64f));
            b.append(':');
            b.append(Math.round((float)p.getY()*64f));
        }
        return b.toString();
    }
    private static int roundWidth(Rectangle2D r) {
        return (int)Math.round(r.getWidth());
    }
    public static void main(String[] args) throws Exception {
        if(args.length!=1)throw new IllegalArgumentException("usage: <font.ttf>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0])).deriveFont(Font.PLAIN,12f);
        int[] sizes={12,14,16}; int cases=0;
        System.out.println("P2B_JDK_LAYOUT_PATH_BOOT=PASS");
        for(int zi=0;zi<sizes.length;zi++) {
            Font f=root.deriveFont(Font.PLAIN,(float)sizes[zi]);
            BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
            Graphics2D g=bi.createGraphics(); g.setFont(f);
            FontMetrics fm=g.getFontMetrics(); FontRenderContext frc=g.getFontRenderContext();
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si]; char[] ca=s.toCharArray();
                int sum=0; for(int i=0;i<ca.length;i++)sum+=fm.charWidth(ca[i]);
                int sw=fm.stringWidth(s); int cw=fm.charsWidth(ca,0,ca.length);
                Rectangle2D sb=f.getStringBounds(s,frc);
                GlyphVector direct=f.createGlyphVector(frc,s);
                GlyphVector layout=f.layoutGlyphVector(frc,ca,0,ca.length,Font.LAYOUT_LEFT_TO_RIGHT);
                float da=(float)direct.getGlyphPosition(direct.getNumGlyphs()).getX();
                float la=(float)layout.getGlyphPosition(layout.getNumGlyphs()).getX();
                System.out.println("P2B_JDK_LAYOUT SIZE="+sizes[zi]+" SAMPLE="+si+
                    " UTF16="+ca.length+" STRING_WIDTH="+sw+" CHARS_WIDTH="+cw+" SUM_CHAR_WIDTH="+sum+
                    " BOUNDS_W64="+Math.round((float)sb.getWidth()*64f)+" BOUNDS_ROUND="+roundWidth(sb)+
                    " DIRECT_GLYPHS="+direct.getNumGlyphs()+" DIRECT_ADV64="+Math.round(da*64f)+
                    " LAYOUT_GLYPHS="+layout.getNumGlyphs()+" LAYOUT_ADV64="+Math.round(la*64f)+
                    " DIRECT_CODES="+glyphs(direct)+" LAYOUT_CODES="+glyphs(layout)+
                    " DIRECT_POS="+positions(direct)+" LAYOUT_POS="+positions(layout));
                cases++;
            }
            g.dispose();
        }
        System.out.println("P2B_JDK_LAYOUT_PATH_CASES="+cases);
        System.out.println("P2B_JDK_LAYOUT_PATH_RESULT=PASS");
    }
}
